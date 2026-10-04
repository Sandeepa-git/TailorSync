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
