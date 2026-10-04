from fastapi import APIRouter, Depends
from typing import List, Dict, Any
from sqlalchemy.orm import Session
from sqlalchemy import func, desc, extract
from datetime import datetime, date, timedelta
from app.schemas.report import ReportList, ReportSummary
from app.api.deps import get_current_user, get_db
from app.models.user import User, RoleEnum
from app.models.order import Order
from app.models.customer import Customer
from app.models.garment_type import GarmentType
from app.models.staff_assignment import StaffAssignment

router = APIRouter()

@router.get("/dashboard", response_model=ReportList)
def dashboard(
    from_date: str = None, 
    to_date: str = None, 
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    # Parse dates or default to current month
    today = datetime.utcnow().date()
    if from_date == 'all':
        start_dt = None
        end_dt = None
    else:
        if from_date:
            start_dt = datetime.strptime(from_date, "%Y-%m-%d").date()
        else:
            start_dt = today.replace(day=1)
            
        if to_date:
            end_dt = datetime.strptime(to_date, "%Y-%m-%d").date()
        else:
            end_dt = today

    base_query = db.query(Order).filter(Order.business_id == current_user.business_id)
    if start_dt and end_dt:
        period_query = base_query.filter(func.date(Order.created_at) >= start_dt, func.date(Order.created_at) <= end_dt)
    else:
        period_query = base_query
    
    # 1. Overall Metrics
    total_orders = period_query.count()
    active_orders = base_query.filter(Order.status != 'Delivered').count()
    orders_completed = period_query.filter(Order.status == 'Delivered').count()
    total_revenue_q = period_query.with_entities(func.sum(Order.total_price)).scalar()
    total_revenue = float(total_revenue_q) if total_revenue_q else 0.0

    # Orders Delayed (completed after expected date or not completed and expected date passed)
    delayed_query = base_query.filter(
        Order.expected_delivery_date != None,
        (
            (Order.completed_date != None) & (Order.completed_date > Order.expected_delivery_date)
        ) | (
            (Order.completed_date == None) & (Order.expected_delivery_date < today)
        )
    )
    orders_delayed = delayed_query.count()

    # 2. Order Performance (Daily Completed)
    daily_completed_query = (
        db.query(func.date(Order.completed_date).label("date"), func.count(Order.order_id).label("count"))
        .filter(Order.business_id == current_user.business_id)
        .filter(Order.status == 'Delivered')
    )
    if start_dt and end_dt:
        daily_completed_query = daily_completed_query.filter(Order.completed_date >= start_dt, Order.completed_date <= end_dt)
        
    daily_completed = daily_completed_query.group_by(func.date(Order.completed_date)).order_by("date").all()
    daily_completed_data = [{"date": str(d), "count": c} for d, c in daily_completed]

    # 3. Garment Performance (Top 5)
    top_garments = (
        period_query.join(GarmentType, Order.garment_type_id == GarmentType.garment_type_id)
        .with_entities(GarmentType.name, func.count(Order.order_id).label("count"))
        .group_by(GarmentType.name)
        .order_by(desc("count"))
        .limit(5)
        .all()
    )
    garment_data = [{"garment_type": g, "count": c} for g, c in top_garments]

    # 4. Customer Analytics (Top 5)
    top_customers = (
        period_query.join(Customer, Order.customer_id == Customer.customer_id)
        .with_entities(Customer.full_name, func.count(Order.order_id).label("count"))
        .group_by(Customer.full_name)
        .order_by(desc("count"))
        .limit(5)
        .all()
    )
    customer_data = [{"customer_name": c, "count": n} for c, n in top_customers]

    # 5. Fabric Usage (Sum of required_length from FabricEstimation)
    from app.models.fabric_estimation import FabricEstimation
    fabric_usage_query = (
        period_query.join(FabricEstimation, Order.order_id == FabricEstimation.order_id)
        .join(GarmentType, Order.garment_type_id == GarmentType.garment_type_id)
        .with_entities(GarmentType.name, func.sum(FabricEstimation.required_length).label("total_length"))
        .group_by(GarmentType.name)
        .order_by(desc("total_length"))
        .all()
    )
    fabric_data = [{"fabric_name": f"{g} (Est. Fabric)", "quantity": float(l) if l else 0.0, "unit": "meters"} for g, l in fabric_usage_query]

    # Combine into metrics
    metrics = {
        "overall": {
            "total_revenue": total_revenue,
            "active_orders": active_orders,
            "orders_completed": orders_completed,
            "orders_delayed": orders_delayed,
            "total_orders": total_orders
        },
        "order_performance": daily_completed_data,
        "garment_performance": garment_data,
        "customer_analytics": customer_data,
        "fabric_usage": fabric_data
    }

    return {"items": [ReportSummary(period=f"{start_dt} to {end_dt}", metrics=metrics)]}


@router.get("/staff-performance", response_model=ReportList)
def staff_performance(
    from_date: str = None, 
    to_date: str = None, 
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    if current_user.role != RoleEnum.OWNER:
        return {"items": []}

    today = datetime.utcnow().date()
    if from_date == 'all':
        start_dt = None
        end_dt = None
    else:
        if from_date:
            start_dt = datetime.strptime(from_date, "%Y-%m-%d").date()
        else:
            start_dt = today.replace(day=1)
            
        if to_date:
            end_dt = datetime.strptime(to_date, "%Y-%m-%d").date()
        else:
            end_dt = today

    staff_members = db.query(User).filter(User.business_id == current_user.business_id, User.role == RoleEnum.STAFF).all()
    metrics = []

    for staff in staff_members:
        # Assigned tasks
        assigned_query = db.query(StaffAssignment).filter(StaffAssignment.staff_id == staff.user_id)
        if start_dt and end_dt:
            assigned_query = assigned_query.join(Order, StaffAssignment.order_id == Order.order_id).filter(Order.created_at >= start_dt, Order.created_at <= end_dt)
        tasks_assigned = assigned_query.count()
        
        # Completed tasks (approximation based on Order status)
        completed_orders = (
            db.query(Order)
            .join(StaffAssignment, Order.order_id == StaffAssignment.order_id)
            .filter(StaffAssignment.staff_id == staff.user_id, Order.status == 'Delivered')
        )
        if start_dt and end_dt:
            completed_orders = completed_orders.filter(Order.completed_date >= start_dt, Order.completed_date <= end_dt)
            
        tasks_completed = completed_orders.count()
        
        on_time = completed_orders.filter(
            (Order.expected_delivery_date == None) | (Order.completed_date <= Order.expected_delivery_date)
        ).count()
        
        rate = (on_time / tasks_completed * 100) if tasks_completed > 0 else 0.0

        metrics.append({
            "staff_name": staff.full_name or staff.email,
            "tasks_assigned": tasks_assigned,
            "tasks_completed": tasks_completed,
            "on_time_completion_rate": round(rate, 1)
        })

    return {"items": [ReportSummary(period="All Time", metrics={"staff_performance": metrics})]}


# ---------------------------------------------------------------------------
# /reports/overview - everything the Reports page needs, in one call.
# Computed in Python over this business's orders (small data sets), so it works
# the same on Postgres and SQLite.
# ---------------------------------------------------------------------------
@router.get("/overview")
def overview(
    days: int = 90,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Safe wrapper: logs the real error and returns it as a readable message."""
    import logging, traceback
    from fastapi import HTTPException
    try:
        return build_overview(days, current_user, db)
    except HTTPException:
        raise
    except Exception as e:
        db.rollback()
        logging.getLogger(__name__).error("Reports overview failed:\n" + traceback.format_exc())
        raise HTTPException(status_code=500, detail=f"Reports error: {type(e).__name__}: {e}")


def build_overview(days: int, current_user: User, db: Session):
    from collections import defaultdict
    from datetime import timedelta
    from sqlalchemy.orm import joinedload
    from app.models.fabric_recommendation import FabricRecommendation
    from app.models.inventory import InventoryItem, InventoryTransaction
    from app.services.inventory_service import status_of

    biz = current_user.business_id
    is_owner = (current_user.role.value if hasattr(current_user.role, "value") else str(current_user.role)) == "OWNER"
    today = datetime.utcnow().date()

    orders = (
        db.query(Order)
        .filter(Order.business_id == biz)
        .options(
            joinedload(Order.customer),
            joinedload(Order.garment_type_rel),
            joinedload(Order.fabric_estimations),
            joinedload(Order.fabric_recommendations).joinedload(FabricRecommendation.fabric),
            joinedload(Order.staff_assignments).joinedload(StaffAssignment.staff),
        )
        .all()
    )

    def cdate(o):
        return o.created_at.date() if o.created_at else today

    if days and days > 0:
        start = today - timedelta(days=days - 1)
    else:
        start = min((cdate(o) for o in orders), default=today)
    span = (today - start).days + 1
    prev_start, prev_end = start - timedelta(days=span), start - timedelta(days=1)

    def in_range(d, a=start, b=today):
        return d is not None and a <= d <= b

    def fabric_of(o):
        recs = list(o.fabric_recommendations or [])
        return recs[-1].fabric.fabric_name if recs and recs[-1].fabric else None

    def meters_of(o):
        ests = list(o.fabric_estimations or [])
        return float(ests[-1].required_length or 0) if ests else 0.0

    def price_of(o):
        return float(o.total_price) if o.total_price is not None else 0.0

    def status_of_order(o):
        return o.status.value if hasattr(o.status, "value") else (o.status or "Order Received")

    period = [o for o in orders if in_range(cdate(o))]
    prev = [o for o in orders if in_range(cdate(o), prev_start, prev_end)]
    delivered_in_period = [o for o in orders if status_of_order(o) == "Delivered" and in_range(o.completed_date)]

    # ---------- KPIs
    on_time = [o for o in delivered_in_period
               if o.expected_delivery_date is None or o.completed_date <= o.expected_delivery_date]
    turnaround = [(o.completed_date - cdate(o)).days for o in delivered_in_period if o.completed_date]
    active = [o for o in orders if status_of_order(o) != "Delivered"]
    overdue = [o for o in active if o.expected_delivery_date and o.expected_delivery_date < today]
    priced = [o for o in period if o.total_price is not None]
    revenue = sum(price_of(o) for o in period)
    prev_revenue = sum(price_of(o) for o in prev)
    methods = defaultdict(int)
    for o in period:
        methods[{"FOUNDRY": "AI Foundry", "CUSTOM_ML": "Custom ML"}.get(o.prediction_method or "", "Manual")] += 1

    kpis = {
        "total_orders": len(period),
        "prev_total_orders": len(prev),
        "completed": len(delivered_in_period),
        "active": len(active),
        "overdue": len(overdue),
        "delayed": len(delivered_in_period) - len(on_time),
        "revenue": round(revenue, 2),
        "prev_revenue": round(prev_revenue, 2),
        "avg_order_value": round(sum(price_of(o) for o in priced) / len(priced), 2) if priced else 0.0,
        "on_time_rate": round(len(on_time) / len(delivered_in_period) * 100, 1) if delivered_in_period else None,
        "avg_turnaround_days": round(sum(turnaround) / len(turnaround), 1) if turnaround else None,
        "fabric_used_m": round(sum(meters_of(o) for o in period), 2),
        "prediction_methods": dict(methods),
    }

    # ---------- trend (daily <= 31 days, weekly <= 120, else monthly)
    if span <= 31:
        unit = "day"
        def bucket(d): return d
        def label(d): return d.strftime("%d %b")
        def nxt(d): return d + timedelta(days=1)
        cur = start
    elif span <= 120:
        unit = "week"
        def bucket(d): return d - timedelta(days=d.weekday())
        def label(d): return d.strftime("%d %b")
        def nxt(d): return d + timedelta(days=7)
        cur = bucket(start)
    else:
        unit = "month"
        def bucket(d): return d.replace(day=1)
        def label(d): return d.strftime("%b %y")
        def nxt(d): return (d.replace(day=28) + timedelta(days=4)).replace(day=1)
        cur = bucket(start)
    buckets = {}
    while cur <= today:
        buckets[cur] = {"label": label(cur), "start": str(cur), "created": 0, "completed": 0, "revenue": 0.0, "fabric_m": 0.0}
        cur = nxt(cur)
    for o in period:
        b = buckets.get(bucket(cdate(o)))
        if b:
            b["created"] += 1
            b["revenue"] += price_of(o)
            b["fabric_m"] = round(b["fabric_m"] + meters_of(o), 2)
    for o in delivered_in_period:
        b = buckets.get(bucket(o.completed_date))
        if b:
            b["completed"] += 1

    # ---------- breakdowns
    status_counts = defaultdict(int)
    for o in period:
        status_counts[status_of_order(o)] += 1
    status_order = ["Order Received", "Cutting", "Sewing", "Fitting", "Quality Check", "Ready", "Delivered"]
    statuses = [{"status": s, "count": status_counts.get(s, 0)} for s in status_order if status_counts.get(s)]

    g_stats = defaultdict(lambda: {"count": 0, "revenue": 0.0})
    c_stats = defaultdict(lambda: {"count": 0, "revenue": 0.0})
    f_stats = defaultdict(lambda: {"meters": 0.0, "orders": 0})
    for o in period:
        g = (o.garment_type or "Other").strip().title()
        g_stats[g]["count"] += 1
        g_stats[g]["revenue"] += price_of(o)
        if o.customer:
            c_stats[o.customer.full_name]["count"] += 1
            c_stats[o.customer.full_name]["revenue"] += price_of(o)
        f = fabric_of(o)
        if f:
            f_stats[f]["meters"] += meters_of(o)
            f_stats[f]["orders"] += 1
    garments = sorted(({"garment_type": k, **v} for k, v in g_stats.items()), key=lambda x: -x["count"])
    customers = sorted(({"customer_name": k, **v} for k, v in c_stats.items()), key=lambda x: (-x["count"], -x["revenue"]))[:5]
    fabrics = sorted(({"fabric_name": k, "meters": round(v["meters"], 2), "orders": v["orders"]} for k, v in f_stats.items()),
                     key=lambda x: -x["meters"])

    # ---------- staff
    staff_rows = []
    s_stats = defaultdict(lambda: {"name": "", "assigned": 0, "completed": 0, "on_time": 0, "active": 0})
    for o in orders:
        for a in (o.staff_assignments or []):
            s = s_stats[a.staff_id]
            s["name"] = (a.staff.full_name or a.staff.email) if a.staff else f"Staff #{a.staff_id}"
            if in_range(cdate(o)):
                s["assigned"] += 1
            if status_of_order(o) != "Delivered":
                s["active"] += 1
            elif in_range(o.completed_date):
                s["completed"] += 1
                if o.expected_delivery_date is None or o.completed_date <= o.expected_delivery_date:
                    s["on_time"] += 1
    for sid, s in s_stats.items():
        staff_rows.append({
            "staff_name": s["name"], "tasks_assigned": s["assigned"], "tasks_completed": s["completed"],
            "active_tasks": s["active"],
            "on_time_completion_rate": round(s["on_time"] / s["completed"] * 100, 1) if s["completed"] else 0.0,
        })
    staff_rows.sort(key=lambda x: (-x["tasks_completed"], -x["tasks_assigned"]))

    # ---------- inventory (owners only): stock + how long it will last
    inventory = None
    if is_owner:
      try:
        since = datetime.utcnow() - timedelta(days=30)
        items = db.query(InventoryItem).filter(InventoryItem.business_id == biz).all()
        inv_rows = []
        for it in items:
            used_30 = -sum(float(t.change_m) for t in it.transactions
                           if t.kind == "ORDER" and t.created_at and t.created_at >= since)
            rate = used_30 / 30.0
            qty = float(it.quantity_m or 0)
            inv_rows.append({
                "fabric_name": it.fabric_name, "quantity_m": round(qty, 2), "status": status_of(it),
                "is_tracked": bool(it.is_tracked), "low_stock_threshold_m": float(it.low_stock_threshold_m or 0),
                "used_30d_m": round(used_30, 2),
                "days_left": (round(qty / rate) if rate > 0 and qty > 0 else (0 if it.is_tracked and qty <= 0 else None)),
            })
        rank = {"out": 0, "low": 1, "ok": 2, "untracked": 3}
        inv_rows.sort(key=lambda r: (rank[r["status"]], r["days_left"] if r["days_left"] is not None else 9999))
        tracked = [r for r in inv_rows if r["is_tracked"]]
        inventory = {
            "items": inv_rows,
            "tracked_count": len(tracked),
            "low_count": sum(1 for r in tracked if r["status"] in ("low", "out")),
            "total_stock_m": round(sum(r["quantity_m"] for r in tracked if r["quantity_m"] > 0), 2),
            "used_30d_m": round(sum(r["used_30d_m"] for r in inv_rows), 2),
        }
      except Exception as e:
        import logging
        db.rollback()
        logging.getLogger(__name__).error(f"Reports: inventory section skipped: {e}")
        inventory = {"items": [], "tracked_count": 0, "low_count": 0, "total_stock_m": 0, "used_30d_m": 0,
                     "error": "Inventory data unavailable"}

    return {
        "period": {"start": str(start), "end": str(today), "days": span, "unit": unit},
        "kpis": kpis,
        "trend": list(buckets.values()),
        "status_breakdown": statuses,
        "garments": garments,
        "customers": customers,
        "fabrics": fabrics,
        "staff": staff_rows,
        "inventory": inventory,
    }
