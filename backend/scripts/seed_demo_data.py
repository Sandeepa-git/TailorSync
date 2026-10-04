"""Add ~30 realistic PAST demo orders (plus demo customers + fabric stock history)
to one business, so the reports and inventory have data to show.

Your existing customers, orders and stock are NOT changed. Demo customers use
fake @example.com emails and are tagged "[DEMO]" so they can be removed later.

Run from the backend folder (uses DATABASE_URL from backend/.env):
    venv\\Scripts\\python scripts\\seed_demo_data.py --email owner@yourmail.com
    venv\\Scripts\\python scripts\\seed_demo_data.py --email owner@yourmail.com --count 40
Remove all demo data again:
    venv\\Scripts\\python scripts\\seed_demo_data.py --email owner@yourmail.com --remove
"""
import argparse
import os
import random
import sys
from datetime import datetime, timedelta, time

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
from dotenv import load_dotenv  # noqa: E402
load_dotenv()

import app.models  # noqa: E402,F401  (registers all tables)
from app.database.session import SessionLocal, engine  # noqa: E402
from app.database.base import Base  # noqa: E402
from app.models.user import User, RoleEnum  # noqa: E402
from app.models.customer import Customer  # noqa: E402
from app.models.order import Order  # noqa: E402
from app.models.inventory import InventoryItem, InventoryTransaction  # noqa: E402
from app.models.measurement import Measurement  # noqa: E402
from app.models.staff_assignment import StaffAssignment  # noqa: E402
from app.schemas.order import OrderCreate  # noqa: E402
from app.services.order_service import create_order  # noqa: E402
from app.services import inventory_service as inv  # noqa: E402

DEMO_TAG = "[DEMO]"
RNG = random.Random(42)  # same data every run

CUSTOMERS = [
    ("Kasun Perera", "M"), ("Nimal Fernando", "M"), ("Dilshan Jayasuriya", "M"), ("Chamara Silva", "M"),
    ("Tharindu Wijesinghe", "M"), ("Ruwan Bandara", "M"), ("Sahan Rathnayake", "M"), ("Isuru Gunawardena", "M"),
    ("Pradeep Kumara", "M"), ("Amila Dissanayake", "M"), ("Heshan Abeysekara", "M"), ("Lahiru Senanayake", "M"),
]

GARMENTS = {
    # name: (weight, price range LKR, fabric meters range, fabrics)
    "Long Sleeve Shirt": (0.32, (3800, 5800), (2.0, 2.5), ["Cotton", "Poplin", "Oxford Cotton", "Linen", "Chambray"]),
    "Short Sleeve Shirt": (0.24, (3000, 4500), (1.6, 2.0), ["Cotton", "Linen", "Poplin", "Chambray"]),
    "Long Trouser": (0.30, (4500, 7000), (1.2, 1.5), ["Wool Blend", "Gabardine", "Cotton Twill", "Linen"]),
    "Short Trouser": (0.14, (2500, 3800), (0.8, 1.0), ["Cotton Twill", "Linen", "Denim"]),
}
OCCASIONS = ["Office / Formal", "Everyday / Casual", "Wedding", "Party", "Travel"]
INSTRUCTIONS = [None, None, "Slim fit please", "Add a chest pocket", "Keep the length slightly longer",
                "Needs to be ready before the weekend", "Same style as the last order", None]


def q(x):  # round to quarter inch
    return round(x * 4) / 4


def measurements_for(garment):
    """Realistic measurements in inches; first three are tailor-entered, rest AI-predicted."""
    if "Shirt" in garment:
        shoulder, height, chest = q(RNG.uniform(16.5, 19.5)), q(RNG.uniform(27, 31)), q(RNG.uniform(36, 46))
        rows = [("Shoulder", shoulder, False), ("Height", height, False), ("Chest", chest, False),
                ("Collar Size", q(chest * 0.37 + RNG.uniform(-0.3, 0.3)), True)]
        if "Long" in garment:
            rows += [("Long Sleeve Length", q(RNG.uniform(22.5, 25.5)), True),
                     ("Sleeve Opening", q(RNG.uniform(9, 10.5)), True)]
        else:
            rows += [("Short Sleeve Length", q(RNG.uniform(8.5, 10.5)), True),
                     ("Sleeve Opening", q(RNG.uniform(13, 15.5)), True)]
        return rows
    waist, seat = q(RNG.uniform(28, 38)), 0.0
    seat = q(waist + RNG.uniform(5, 8))
    if "Long" in garment:
        height = q(RNG.uniform(38, 42))
        end = q(RNG.uniform(14, 17))
    else:
        height = q(RNG.uniform(19, 22))
        end = q(RNG.uniform(20, 24))
    return [("Height", height, False), ("Waist", waist, False), ("Seat", seat, False),
            ("Height Till Knee", q(RNG.uniform(21, 24)), True), ("Around Knee", q(seat * 0.47), True),
            ("Round End", end, True), ("Crotch", q(RNG.uniform(10, 12.5)), True)]


def at(day, hour=None):
    return datetime.combine(day, time(hour if hour is not None else RNG.randint(9, 18), RNG.randint(0, 59)))


def resolve_business(db, email):
    if email:
        owner = db.query(User).filter(User.email == email.strip().lower()).first() or \
                db.query(User).filter(User.email == email.strip()).first()
        if not owner or not owner.business_id:
            sys.exit(f"No account with business found for {email}")
        return owner.business_id, owner
    owners = db.query(User).filter(User.role == RoleEnum.OWNER, User.business_id != None).all()  # noqa: E711
    if len(owners) == 1:
        return owners[0].business_id, owners[0]
    print("Several businesses found - run again with --email <owner email>:")
    for o in owners:
        print(f"  {o.email}  (business {o.business_id})")
    sys.exit(1)


def remove_demo(db, business_id):
    customers = db.query(Customer).filter(Customer.business_id == business_id,
                                          Customer.notes.like(f"%{DEMO_TAG}%")).all()
    cust_ids = [c.customer_id for c in customers]
    orders = db.query(Order).filter(Order.customer_id.in_(cust_ids)).all() if cust_ids else []
    order_ids = [o.order_id for o in orders]
    # undo stock changes made by demo orders and demo restocks
    txs = db.query(InventoryTransaction).join(InventoryItem).filter(InventoryItem.business_id == business_id).all()
    removed = 0
    for t in txs:
        if (t.order_id in order_ids) or (t.note and DEMO_TAG in t.note):
            t.item.quantity_m = inv._d(t.item.quantity_m) - inv._d(t.change_m)
            db.delete(t)
            removed += 1
    db.flush()
    for item in db.query(InventoryItem).filter(InventoryItem.business_id == business_id).all():
        if not item.transactions and float(item.quantity_m or 0) == 0:
            item.is_tracked = False
    for o in orders:
        db.query(Measurement).filter(Measurement.order_id == o.order_id).delete()
        db.query(StaffAssignment).filter(StaffAssignment.order_id == o.order_id).delete()
        db.delete(o)
    db.flush()
    for c in customers:
        db.query(Measurement).filter(Measurement.customer_id == c.customer_id).delete()
        db.delete(c)
    db.commit()
    print(f"Removed {len(orders)} demo orders, {len(customers)} demo customers, {removed} demo stock entries.")


def seed(db, business_id, owner, count):
    if db.query(Customer).filter(Customer.business_id == business_id, Customer.notes.like(f"%{DEMO_TAG}%")).count():
        sys.exit("Demo data already exists for this business. Run with --remove first if you want to re-create it.")

    staff = db.query(User).filter(User.business_id == business_id, User.role == RoleEnum.STAFF,
                                  User.is_active == True).all() or [owner]  # noqa: E712
    today = datetime.utcnow().date()

    # 1) demo customers (fake contact details)
    customers = []
    for i, (name, gender) in enumerate(CUSTOMERS):
        first = name.split()[0].lower()
        c = Customer(business_id=business_id, full_name=name, gender=gender,
                     email=f"{first}.demo{i + 1}@example.com", phone=f"07{RNG.randint(0, 8)}{RNG.randint(1000000, 9999999)}",
                     address=f"No. {RNG.randint(1, 250)}, Galle Road, Colombo {RNG.randint(1, 15)}",
                     notes=f"{DEMO_TAG} sample customer for demonstrations",
                     created_at=at(today - timedelta(days=RNG.randint(95, 120))))
        db.add(c)
        customers.append(c)
    db.flush()

    # 2) plan orders over the last 90 days (a little busier recently)
    garments, weights = zip(*[(g, v[0]) for g, v in GARMENTS.items()])
    plans = []
    for _ in range(count):
        age = int(RNG.triangular(0, 90, 15))
        g = RNG.choices(garments, weights)[0]
        _, price_rng, m_rng, fabrics = GARMENTS[g]
        plans.append(dict(day=today - timedelta(days=age), garment=g, fabric=RNG.choice(fabrics),
                          meters=round(RNG.uniform(*m_rng), 2), price=round(RNG.uniform(*price_rng) / 50) * 50))
    plans.sort(key=lambda p: p["day"])

    # 3) opening stock (95 days ago) + mid-period deliveries, so inventory history is realistic
    used = {}
    for p in plans:
        used[p["fabric"]] = used.get(p["fabric"], 0) + p["meters"]
    events = []
    names = sorted(used)
    low_ones = set(names[:2])  # leave a couple of fabrics running low for the alerts demo
    for name in names:
        need = used[name]
        opening = round(need * (0.6 if name in low_ones else 0.9) + RNG.uniform(2, 5), 1)
        events.append((today - timedelta(days=95), "open", name, opening))
        if name not in low_ones:
            events.append((today - timedelta(days=RNG.randint(35, 55)), "restock", name, round(need * 0.6 + 10, 1)))
        else:
            events.append((today - timedelta(days=RNG.randint(40, 60)), "restock", name, round(need * 0.25, 1)))
    for p in plans:
        events.append((p["day"], "order", p, None))
    events.sort(key=lambda e: (e[0], {"open": 0, "restock": 1, "order": 2}[e[1]]))

    stats = {"orders": 0, "delivered": 0, "late": 0}
    for day, kind, payload, amount in events:
        if kind in ("open", "restock"):
            item = inv.ensure_items(db, business_id, [payload])[0]
            item.low_stock_threshold_m = 5
            if kind == "open":
                inv.set_quantity(db, item, inv._d(item.quantity_m) + inv._d(amount), note=f"Opening stock {DEMO_TAG}")
                db.commit()
            else:
                inv.restock(db, item, amount, note=f"Supplier delivery {DEMO_TAG}")
            tx = db.query(InventoryTransaction).filter(InventoryTransaction.item_id == item.item_id) \
                .order_by(InventoryTransaction.transaction_id.desc()).first()
            tx.created_at = at(day, 10)
            db.commit()
            continue

        p = payload
        created = at(day)
        age = (today - day).days
        due = created + timedelta(days=RNG.randint(10, 18))
        if age > 21:
            turnaround = RNG.choices([RNG.randint(4, 9), RNG.randint(10, 16)], [0.8, 0.2])[0]
            status, completed = "Delivered", (created + timedelta(days=turnaround)).date()
        elif age > 12:
            status, completed = RNG.choice(["Ready", "Quality Check", "Fitting"]), None
        elif age > 5:
            status, completed = RNG.choice(["Sewing", "Cutting", "Fitting"]), None
        else:
            status, completed = RNG.choice(["Order Received", "Cutting"]), None

        payload_order = OrderCreate(
            customer_id=RNG.choice(customers).customer_id,
            garment_type=p["garment"],
            occasion=RNG.choice(OCCASIONS),
            due_date=due,
            priority=RNG.choices(["Low", "Medium", "High"], [0.25, 0.55, 0.2])[0],
            customer_instructions=RNG.choice(INSTRUCTIONS),
            measurements=[{"field_name": n, "value": v, "is_ai_generated": ai} for n, v, ai in measurements_for(p["garment"])],
            staff_id=RNG.choice(staff).user_id,
            selected_fabric=p["fabric"],
            fabric_estimation={"recommended_quantity_meters": p["meters"]},
            prediction_method=RNG.choice(["FOUNDRY", "CUSTOM_ML"]),
            total_price=p["price"],
        )
        o = create_order(db, payload_order, business_id)
        # back-date everything that belongs to this order
        o.created_at = created
        o.updated_at = datetime.combine(completed, time(17)) if completed else created
        o.status = status
        o.completed_date = completed
        for rel in (o.measurements or []):
            rel.recorded_at = created
        for rel in (o.staff_assignments or []):
            rel.assigned_at = created
        for rel in (o.fabric_estimations or []) + (o.fabric_recommendations or []):
            rel.created_at = created
        for tx in db.query(InventoryTransaction).filter(InventoryTransaction.order_id == o.order_id).all():
            tx.created_at = created
            tx.note = f"Used by order #{o.order_id} {DEMO_TAG}"
        db.commit()
        stats["orders"] += 1
        if completed:
            stats["delivered"] += 1
            if completed > due.date():
                stats["late"] += 1

    print(f"Added {len(customers)} demo customers and {stats['orders']} demo orders "
          f"({stats['delivered']} delivered, {stats['late']} of them late).")
    print("Fabric stock now:")
    for item in db.query(InventoryItem).filter(InventoryItem.business_id == business_id, InventoryItem.is_tracked == True).all():  # noqa: E712
        print(f"  {item.fabric_name:<15} {float(item.quantity_m):6.2f} m  ({inv.status_of(item)})")


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--email", help="owner email of the business to fill")
    ap.add_argument("--count", type=int, default=30)
    ap.add_argument("--remove", action="store_true", help="delete all demo data")
    args = ap.parse_args()

    Base.metadata.create_all(bind=engine, tables=[InventoryItem.__table__, InventoryTransaction.__table__])
    db = SessionLocal()
    try:
        business_id, owner = resolve_business(db, args.email)
        print(f"Business #{business_id} (owner {owner.email})")
        if args.remove:
            remove_demo(db, business_id)
        else:
            seed(db, business_id, owner, args.count)
    finally:
        db.close()


if __name__ == "__main__":
    main()
