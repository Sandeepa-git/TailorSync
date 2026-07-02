from fastapi import APIRouter, Depends, HTTPException
from typing import List, Optional
from sqlalchemy.orm import Session
from app.schemas.order import OrderCreate, OrderRead, OrderUpdate
from app.database.session import get_db

router = APIRouter()

@router.get("/", response_model=List[OrderRead])
def list_orders(status: Optional[str] = None, db: Session = Depends(get_db)):
    from app.services.order_service import list_orders as svc_list
    orders = svc_list(db, status=status)
    result = []
    for o in orders:
        assignment = o.staff_assignments[0] if o.staff_assignments else None
        data = {
            "id": o.id,
            "customer_id": o.customer_id,
            "garment_type": o.garment_type,
            "occasion": o.occasion,
            "status": o.status.value if o.status else "Order Received",
            "priority": o.priority.value if o.priority else "Medium",
            "due_date": o.due_date,
            "completed_at": o.completed_at,
            "created_at": o.created_at,
            "tailor_remarks": o.tailor_remarks,
            "customer_instructions": o.customer_instructions,
            "customer_name": o.customer.name if o.customer else None,
            "customer_phone": o.customer.phone if o.customer else None,
            "staff_id": assignment.staff_id if assignment else None,
            "staff_name": assignment.staff.full_name if assignment and assignment.staff else None,
        }
        result.append(data)
    return result

@router.post("/", response_model=OrderRead)
def create_order(payload: OrderCreate, db: Session = Depends(get_db)):
    from app.services.order_service import create_order as svc_create
    o = svc_create(db, payload)
    return {
        "id": o.id,
        "customer_id": o.customer_id,
        "garment_type": o.garment_type,
        "occasion": o.occasion,
        "status": o.status.value if o.status else "Order Received",
        "priority": o.priority.value if o.priority else "Medium",
        "due_date": o.due_date,
        "completed_at": o.completed_at,
        "created_at": o.created_at,
        "tailor_remarks": o.tailor_remarks,
        "customer_instructions": o.customer_instructions,
        "customer_name": None,
        "customer_phone": None,
    }

@router.get("/stats")
def get_stats(db: Session = Depends(get_db)):
    from app.services.order_service import get_dashboard_stats
    return get_dashboard_stats(db)

@router.get("/{order_id}", response_model=OrderRead)
def get_order(order_id: int, db: Session = Depends(get_db)):
    from app.services.order_service import get_order as svc_get
    o = svc_get(db, order_id)
    if not o:
        raise HTTPException(status_code=404, detail="Order not found")
    assignment = o.staff_assignments[0] if getattr(o, 'staff_assignments', None) else None
    return {
        "id": o.id,
        "customer_id": o.customer_id,
        "garment_type": o.garment_type,
        "occasion": o.occasion,
        "status": o.status.value if o.status else "Order Received",
        "priority": o.priority.value if o.priority else "Medium",
        "due_date": o.due_date,
        "completed_at": o.completed_at,
        "created_at": o.created_at,
        "tailor_remarks": o.tailor_remarks,
        "customer_instructions": o.customer_instructions,
        "customer_name": o.customer.name if o.customer else None,
        "customer_phone": o.customer.phone if o.customer else None,
        "staff_id": assignment.staff_id if assignment else None,
        "staff_name": assignment.staff.full_name if assignment and assignment.staff else None,
    }

@router.put("/{order_id}", response_model=OrderRead)
def update_order(order_id: int, payload: OrderUpdate, db: Session = Depends(get_db)):
    from app.services.order_service import update_order as svc_update
    o = svc_update(db, order_id, payload)
    if not o:
        raise HTTPException(status_code=404, detail="Order not found")
    assignment = o.staff_assignments[0] if getattr(o, 'staff_assignments', None) else None
    return {
        "id": o.id,
        "customer_id": o.customer_id,
        "garment_type": o.garment_type,
        "occasion": o.occasion,
        "status": o.status.value if o.status else "Order Received",
        "priority": o.priority.value if o.priority else "Medium",
        "due_date": o.due_date,
        "completed_at": o.completed_at,
        "created_at": o.created_at,
        "tailor_remarks": o.tailor_remarks,
        "customer_instructions": o.customer_instructions,
        "customer_name": o.customer.name if o.customer else None,
        "customer_phone": o.customer.phone if o.customer else None,
        "staff_id": assignment.staff_id if assignment else None,
        "staff_name": assignment.staff.full_name if assignment and assignment.staff else None,
    }
