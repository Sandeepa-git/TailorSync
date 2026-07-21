from sqlalchemy.orm import Session, joinedload
from app.models.order import Order, OrderStatus, OrderPriority
from app.models.measurement import Measurement
from app.models.staff_assignment import StaffAssignment
from app.schemas.order import OrderCreate, OrderUpdate
from datetime import datetime

def list_orders(db: Session, business_id: int, skip: int = 0, limit: int = 100, status: str = None):
    query = db.query(Order).filter(Order.business_id == business_id).options(
        joinedload(Order.customer),
        joinedload(Order.staff_assignments).joinedload(StaffAssignment.staff),
        joinedload(Order.measurements).joinedload(Measurement.field)
    )
    if status:
        query = query.filter(Order.status == status)
    return query.order_by(Order.created_at.desc()).offset(skip).limit(limit).all()

def create_order(db: Session, order: OrderCreate, business_id: int):
    # Create the order itself (exclude nested objects)
    order_data = order.dict(exclude={'measurements', 'staff_id'})
    order_data['business_id'] = business_id
    
    # Clean and query garment type lookups via the model property setter
    garment_type_name = order_data.pop('garment_type', '')
    
    # Convert priority string to status/priority
    priority_str = order_data.pop('priority', 'Medium')
    
    db_order = Order(**order_data)
    # Set priority and garment type name (which triggers the lookup/creation)
    db_order.priority = priority_str
    db.add(db_order)
    db.flush()  # Get the order ID before committing
    
    db_order.garment_type = garment_type_name
    db.flush()
    
    # Create measurements if provided
    if order.measurements:
        for m_data in order.measurements:
            db_measurement = Measurement(
                customer_id=order.customer_id,
                order_id=db_order.order_id,
                field_id=m_data.field_id,
                value=m_data.value
            )
            db.add(db_measurement)
    
    # Create staff assignment if provided
    if order.staff_id:
        assignment = StaffAssignment(
            order_id=db_order.order_id,
            staff_id=order.staff_id,
            assigned_role="Assigned"
        )
        db.add(assignment)
    
    db.commit()
    db.refresh(db_order)
    return db_order

def get_order(db: Session, order_id: int, business_id: int):
    return db.query(Order).options(
        joinedload(Order.customer),
        joinedload(Order.measurements).joinedload(Measurement.field),
        joinedload(Order.staff_assignments).joinedload(StaffAssignment.staff),
        joinedload(Order.notes),
    ).filter(Order.order_id == order_id, Order.business_id == business_id).first()

def update_order(db: Session, order_id: int, updates: OrderUpdate, business_id: int):
    order = db.query(Order).filter(Order.order_id == order_id, Order.business_id == business_id).first()
    if not order:
        return None
    
    if updates.status is not None:
        order.status = updates.status
        if updates.status == "Delivered":
            order.completed_at = datetime.utcnow()
    
    if updates.priority is not None:
        order.priority = updates.priority
    
    if updates.due_date is not None:
        order.due_date = updates.due_date
    if updates.tailor_remarks is not None:
        order.tailor_remarks = updates.tailor_remarks
    if updates.customer_instructions is not None:
        order.customer_instructions = updates.customer_instructions
    
    if updates.staff_id is not None:
        # Replace existing assignment
        existing = db.query(StaffAssignment).filter(
            StaffAssignment.order_id == order_id
        ).first()
        if existing:
            existing.staff_id = updates.staff_id
        else:
            assignment = StaffAssignment(
                order_id=order_id,
                staff_id=updates.staff_id,
                assigned_role="Assigned"
            )
            db.add(assignment)
    
    db.commit()
    db.refresh(order)
    return order

def get_dashboard_stats(db: Session, business_id: int):
    total_orders = db.query(Order).filter(Order.business_id == business_id).count()
    ongoing = db.query(Order).filter(Order.business_id == business_id, Order.status != "Delivered").count()
    completed = db.query(Order).filter(Order.business_id == business_id, Order.status == "Delivered").count()
    from app.models.customer import Customer
    total_customers = db.query(Customer).filter(Customer.business_id == business_id).count()
    return {
        "total_orders": total_orders,
        "ongoing_orders": ongoing,
        "completed_orders": completed,
        "total_customers": total_customers,
    }

def delete_order(db: Session, order_id: int, business_id: int):
    order = db.query(Order).filter(Order.order_id == order_id, Order.business_id == business_id).first()
    if not order:
        return False
    
    db.query(Measurement).filter(Measurement.order_id == order_id).delete()
    db.query(StaffAssignment).filter(StaffAssignment.order_id == order_id).delete()
    
    db.delete(order)
    db.commit()
    return True
