from typing import Optional

from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel, Field
from sqlalchemy.orm import Session

from app.api.deps import get_current_active_user
from app.database.session import get_db
from app.models.inventory import InventoryItem
from app.models.user import User
from app.services import inventory_service as inv

router = APIRouter()


def owner_only(user: User = Depends(get_current_active_user)) -> User:
    role = user.role.value if hasattr(user.role, "value") else str(user.role)
    if role != "OWNER":
        raise HTTPException(status_code=403, detail="Only the business owner can manage inventory.")
    return user


class ItemCreate(BaseModel):
    fabric_name: str = Field(..., min_length=1)
    quantity_m: float = Field(0, ge=0)
    low_stock_threshold_m: float = Field(5, ge=0)


class ItemUpdate(BaseModel):
    fabric_name: Optional[str] = None
    quantity_m: Optional[float] = Field(None, ge=0)   # exact stock count (sets tracked)
    low_stock_threshold_m: Optional[float] = Field(None, ge=0)


class Restock(BaseModel):
    meters: float = Field(..., gt=0)
    note: Optional[str] = None


def _get(db: Session, item_id: int, user: User) -> InventoryItem:
    item = db.query(InventoryItem).filter(InventoryItem.item_id == item_id,
                                          InventoryItem.business_id == user.business_id).first()
    if not item:
        raise HTTPException(status_code=404, detail="Fabric not found")
    return item


@router.get("/")
def list_items(db: Session = Depends(get_db), user: User = Depends(owner_only)):
    items = db.query(InventoryItem).filter(InventoryItem.business_id == user.business_id).all()
    order = {"out": 0, "low": 1, "ok": 2, "untracked": 3}
    data = sorted((inv.to_dict(i) for i in items), key=lambda d: (order[d["status"]], d["fabric_name"]))
    return data


@router.get("/alerts")
def alerts(db: Session = Depends(get_db), user: User = Depends(get_current_active_user)):
    role = user.role.value if hasattr(user.role, "value") else str(user.role)
    if role != "OWNER":
        return {"low": [], "count": 0, "untracked": 0}
    items = db.query(InventoryItem).filter(InventoryItem.business_id == user.business_id).all()
    low = [inv.to_dict(i) for i in items if inv.status_of(i) in ("low", "out")]
    untracked = sum(1 for i in items if not i.is_tracked)
    return {"low": low, "count": len(low), "untracked": untracked}


@router.post("/")
def create_item(payload: ItemCreate, db: Session = Depends(get_db), user: User = Depends(owner_only)):
    if inv.find_item(db, user.business_id, payload.fabric_name):
        raise HTTPException(status_code=409, detail="This fabric is already in your inventory.")
    item = inv.ensure_items(db, user.business_id, [payload.fabric_name])[0]
    item.low_stock_threshold_m = payload.low_stock_threshold_m
    if payload.quantity_m > 0:
        inv.set_quantity(db, item, payload.quantity_m, note="Opening stock", user_id=user.user_id)
    else:
        item.is_tracked = True  # owner added it on purpose -> track it from 0
    db.commit()
    db.refresh(item)
    return inv.to_dict(item)


@router.put("/{item_id}")
def update_item(item_id: int, payload: ItemUpdate, db: Session = Depends(get_db), user: User = Depends(owner_only)):
    item = _get(db, item_id, user)
    if payload.fabric_name and inv.name_key(payload.fabric_name) != item.name_key:
        if inv.find_item(db, user.business_id, payload.fabric_name):
            raise HTTPException(status_code=409, detail="Another fabric already has that name.")
        item.fabric_name = inv.display_name(payload.fabric_name)
        item.name_key = inv.name_key(payload.fabric_name)
    if payload.low_stock_threshold_m is not None:
        item.low_stock_threshold_m = payload.low_stock_threshold_m
    if payload.quantity_m is not None:
        inv.set_quantity(db, item, payload.quantity_m, user_id=user.user_id)
    db.commit()
    db.refresh(item)
    return inv.to_dict(item)


@router.post("/{item_id}/restock")
def restock_item(item_id: int, payload: Restock, db: Session = Depends(get_db), user: User = Depends(owner_only)):
    item = _get(db, item_id, user)
    return inv.to_dict(inv.restock(db, item, payload.meters, payload.note, user.user_id))


# Common tailoring fabrics: (name, opening stock m, low-stock alert m)
SAMPLE_FABRICS = [
    ("Cotton", 60, 10), ("Linen", 35, 8), ("Cotton Linen Blend", 30, 8),
    ("Poplin", 45, 10), ("Oxford Cotton", 25, 6), ("Chambray", 20, 5),
    ("Denim", 30, 8), ("Polyester Viscose", 40, 10), ("Wool Blend", 18, 5),
    ("Poly Wool", 22, 5), ("Silk", 12, 4), ("Satin", 15, 4),
    ("Chiffon", 14, 4), ("Georgette", 16, 4), ("Rayon", 24, 6),
    ("Batik Cotton", 20, 5), ("Twill", 28, 6), ("Gabardine", 26, 6),
]


@router.post("/samples")
def add_sample_fabrics(db: Session = Depends(get_db), user: User = Depends(owner_only)):
    """Add a starter set of common fabrics with stock. Existing fabrics are never changed."""
    added, skipped = [], []
    for name, qty, threshold in SAMPLE_FABRICS:
        if inv.find_item(db, user.business_id, name):
            skipped.append(name)
            continue
        item = inv.ensure_items(db, user.business_id, [name])[0]
        item.low_stock_threshold_m = threshold
        inv.set_quantity(db, item, qty, note="Sample opening stock", user_id=user.user_id)
        added.append(name)
    db.commit()
    return {"added": added, "skipped": skipped, "added_count": len(added)}


@router.get("/{item_id}/history")
def history(item_id: int, db: Session = Depends(get_db), user: User = Depends(owner_only)):
    item = _get(db, item_id, user)
    return [{
        "id": t.transaction_id, "change_m": float(t.change_m), "balance_after_m": float(t.balance_after_m),
        "kind": t.kind, "order_id": t.order_id, "note": t.note, "created_at": t.created_at,
    } for t in item.transactions[:100]]


@router.delete("/{item_id}")
def delete_item(item_id: int, db: Session = Depends(get_db), user: User = Depends(owner_only)):
    item = _get(db, item_id, user)
    db.delete(item)
    db.commit()
    return {"deleted": True}
