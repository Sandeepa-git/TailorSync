"""Adds sample fabrics (with stock) straight into the Fabric Inventory table in YOUR database.

    venv\\Scripts\\python scripts\\add_sample_fabrics.py                 (every business)
    venv\\Scripts\\python scripts\\add_sample_fabrics.py --email owner@x  (only that owner's business)

Fabrics that already exist are left unchanged, so it's safe to run more than once.
"""
import argparse, os, sys
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
from dotenv import load_dotenv
load_dotenv()
import app.models  # noqa
from app.models.inventory import InventoryItem, InventoryTransaction
from app.database.session import SessionLocal, engine
from app.models.user import User
from app.services import inventory_service as inv
from app.api.v1.routers.inventory import SAMPLE_FABRICS

ap = argparse.ArgumentParser(); ap.add_argument("--email")
a = ap.parse_args()

InventoryItem.metadata.create_all(bind=engine, tables=[InventoryItem.__table__, InventoryTransaction.__table__])
db = SessionLocal()
q = db.query(User)
if a.email:
    q = q.filter(User.email == a.email.strip())
business_ids = sorted({u.business_id for u in q.all() if u.business_id})
if not business_ids:
    sys.exit("No matching user/business found.")

for bid in business_ids:
    owner = db.query(User).filter(User.business_id == bid).first()
    added = []
    for name, qty, threshold in SAMPLE_FABRICS:
        if inv.find_item(db, bid, name):
            continue
        item = inv.ensure_items(db, bid, [name])[0]
        item.low_stock_threshold_m = threshold
        inv.set_quantity(db, item, qty, note="Sample opening stock", user_id=owner.user_id if owner else None)
        added.append(name)
    db.commit()
    total = db.query(InventoryItem).filter(InventoryItem.business_id == bid).count()
    print(f"Business {bid}: added {len(added)} fabrics -> {total} fabrics in inventory now")
print("Done.")
