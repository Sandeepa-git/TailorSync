"""Fabric inventory: auto-create rows for new fabrics, deduct on orders, restock."""
import logging
import re
from decimal import Decimal
from typing import Iterable, List, Optional

from sqlalchemy.orm import Session

from app.models.inventory import InventoryItem, InventoryTransaction

logger = logging.getLogger(__name__)


def name_key(name: str) -> str:
    """'  Pure  LINEN ' -> 'pure linen' so the same fabric always matches."""
    return re.sub(r"\s+", " ", (name or "").strip().lower())


def display_name(name: str) -> str:
    return re.sub(r"\s+", " ", (name or "").strip()).title()


def _d(v) -> Decimal:
    return Decimal(str(round(float(v or 0), 2)))


def find_item(db: Session, business_id: int, fabric_name: str) -> Optional[InventoryItem]:
    return db.query(InventoryItem).filter(
        InventoryItem.business_id == business_id,
        InventoryItem.name_key == name_key(fabric_name),
    ).first()


def ensure_items(db: Session, business_id: int, names: Iterable[str]) -> List[InventoryItem]:
    """Create untracked (0 m) rows for fabrics we haven't seen. Does not commit."""
    items = []
    for n in names:
        if not n or not n.strip() or name_key(n) in ("manual fabric",):
            continue
        item = find_item(db, business_id, n)
        if not item:
            item = InventoryItem(business_id=business_id, fabric_name=display_name(n), name_key=name_key(n),
                                 quantity_m=0, is_tracked=False)
            db.add(item)
            db.flush()
            logger.info(f"Inventory: new fabric '{item.fabric_name}' added for business {business_id} (untracked)")
        items.append(item)
    return items


def _record(db: Session, item: InventoryItem, change: Decimal, kind: str, order_id=None, note=None, user_id=None):
    item.quantity_m = _d(item.quantity_m) + change
    db.add(InventoryTransaction(item_id=item.item_id, change_m=change, balance_after_m=item.quantity_m,
                                kind=kind, order_id=order_id, note=note, user_id=user_id))


def deduct_for_order(db: Session, business_id: int, order_id: int, fabric_name: Optional[str], meters) -> None:
    """Subtract the order's estimated fabric. Only for tracked items. Does not commit."""
    if not fabric_name or not meters or float(meters) <= 0:
        return
    items = ensure_items(db, business_id, [fabric_name])
    if not items:
        return
    item = items[0]
    if not item.is_tracked:
        return  # owner hasn't set a stock amount yet -> nothing to deduct
    _record(db, item, -_d(meters), "ORDER", order_id=order_id, note=f"Used by order #{order_id}")


def restore_for_order(db: Session, business_id: int, order_id: int) -> None:
    """Put back fabric used by an order that is being deleted. Does not commit."""
    txs = db.query(InventoryTransaction).join(InventoryItem).filter(
        InventoryItem.business_id == business_id,
        InventoryTransaction.order_id == order_id,
        InventoryTransaction.kind == "ORDER",
    ).all()
    for t in txs:
        _record(db, t.item, -_d(t.change_m), "REVERSAL", order_id=order_id, note=f"Order #{order_id} deleted")


def restock(db: Session, item: InventoryItem, meters, note: str = None, user_id: int = None) -> InventoryItem:
    item.is_tracked = True
    _record(db, item, _d(meters), "RESTOCK", note=note or "Stock added", user_id=user_id)
    db.commit()
    db.refresh(item)
    return item


def set_quantity(db: Session, item: InventoryItem, meters, note: str = None, user_id: int = None) -> InventoryItem:
    item.is_tracked = True
    change = _d(meters) - _d(item.quantity_m)
    _record(db, item, change, "ADJUST", note=note or "Stock count corrected", user_id=user_id)
    return item


def status_of(item: InventoryItem) -> str:
    if not item.is_tracked:
        return "untracked"
    q, t = float(item.quantity_m or 0), float(item.low_stock_threshold_m or 0)
    if q <= 0:
        return "out"
    if q <= t:
        return "low"
    return "ok"


def to_dict(item: InventoryItem) -> dict:
    return {
        "id": item.item_id,
        "fabric_name": item.fabric_name,
        "quantity_m": float(item.quantity_m or 0),
        "is_tracked": bool(item.is_tracked),
        "low_stock_threshold_m": float(item.low_stock_threshold_m or 0),
        "status": status_of(item),
        "updated_at": item.updated_at,
    }


def stock_lookup(db: Session, business_id: int, names: Iterable[str]) -> dict:
    """{name_key: item_dict} for showing stock next to AI recommendations."""
    out = {}
    for n in names:
        item = find_item(db, business_id, n)
        if item:
            out[name_key(n)] = to_dict(item)
    return out
