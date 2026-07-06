from sqlalchemy.orm import Session, joinedload
from app.models.order import Order, OrderStatus, OrderPriority
from app.models.measurement import Measurement
from app.models.staff_assignment import StaffAssignment
from app.schemas.order import OrderCreate, OrderUpdate
from datetime import datetime

def list_orders(db: Session, business_id: int, skip: int = 0, limit: int = 100, status: str = None):
    query = db.query(Order).filter(Order.business_id == business_id).options(
        joinedload(Order.customer),
        joinedload(Order.staff_assignments).joinedload(StaffAssignment.staff)
    )
    if status:
        try:
            status_enum = OrderStatus(status)
            query = query.filter(Order.status == status_enum)
        except ValueError:
            pass
    return query.order_by(Order.created_at.desc()).offset(skip).limit(limit).all()

def create_order(db: Session, order: OrderCreate, business_id: int):
    # Create the order itself (exclude nested objects)
    order_data = order.dict(exclude={'measurements', 'staff_id'})
    order_data['business_id'] = business_id
    
    # Convert priority string to enum
    priority_str = order_data.pop('priority', 'Medium')
    try:
        order_data['priority'] = OrderPriority(priority_str)
    except (ValueError, KeyError):
        order_data['priority'] = OrderPriority.MEDIUM
    
    db_order = Order(**order_data)
    db.add(db_order)
    db.flush()  # Get the order ID before committing
    
    # Create measurements if provided
    if order.measurements:
        m_data = order.measurements.dict()
        m_data['customer_id'] = order.customer_id
        m_data['order_id'] = db_order.id
        db_measurement = Measurement(**m_data)
        db.add(db_measurement)
    
    # Create staff assignment if provided
    if order.staff_id:
        assignment = StaffAssignment(
            order_id=db_order.id,
            staff_id=order.staff_id,
            role="Assigned"
        )
        db.add(assignment)
    
    db.commit()
    db.refresh(db_order)
    return db_order

def get_order(db: Session, order_id: int, business_id: int):
    return db.query(Order).options(
        joinedload(Order.customer),
        joinedload(Order.measurements),
        joinedload(Order.staff_assignments).joinedload(StaffAssignment.staff),
        joinedload(Order.notes),
    ).filter(Order.id == order_id, Order.business_id == business_id).first()

def update_order(db: Session, order_id: int, updates: OrderUpdate, business_id: int):
    order = db.query(Order).filter(Order.id == order_id, Order.business_id == business_id).first()
    if not order:
        return None
    
    if updates.status is not None:
        try:
            order.status = OrderStatus(updates.status)
            if updates.status == "Delivered":
                order.completed_at = datetime.utcnow()
        except ValueError:
            pass
    
    if updates.priority is not None:
        try:
            order.priority = OrderPriority(updates.priority)
        except ValueError:
            pass
    
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
                role="Assigned"
            )
            db.add(assignment)
    
    db.commit()
    db.refresh(order)
    return order

def get_dashboard_stats(db: Session, business_id: int):
    total_orders = db.query(Order).filter(Order.business_id == business_id).count()
    ongoing = db.query(Order).filter(Order.business_id == business_id, Order.status.notin_([OrderStatus.DELIVERED])).count()
    completed = db.query(Order).filter(Order.business_id == business_id, Order.status == OrderStatus.DELIVERED).count()
    from app.models.customer import Customer
    total_customers = db.query(Customer).filter(Customer.business_id == business_id).count()
    return {
        "total_orders": total_orders,
        "ongoing_orders": ongoing,
        "completed_orders": completed,
        "total_customers": total_customers,
    }

def delete_order(db: Session, order_id: int, business_id: int):
    order = db.query(Order).filter(Order.id == order_id, Order.business_id == business_id).first()
    if not order:
        return False
    
    # Let SQLAlchemy handle cascade deletions if configured, or manually delete related rows.
    # Note: StaffAssignment and Measurements usually cascade delete or can be manually deleted.
    db.query(Measurement).filter(Measurement.order_id == order_id).delete()
    db.query(StaffAssignment).filter(StaffAssignment.order_id == order_id).delete()
    
    db.delete(order)
    db.commit()
    return True
