from sqlalchemy.orm import Session
from app.models.customer import Customer
from app.schemas.customer import CustomerCreate, CustomerUpdate

def list_customers(db: Session, business_id: int, skip: int = 0, limit: int = 100):
    return db.query(Customer).filter(Customer.business_id == business_id).offset(skip).limit(limit).all()

def create_customer(db: Session, customer: CustomerCreate, business_id: int):
    db_customer = Customer(**customer.dict(), business_id=business_id)
    db.add(db_customer)
    db.commit()
    db.refresh(db_customer)
    return db_customer

def update_customer(db: Session, customer_id: int, updates: CustomerUpdate, business_id: int):
    customer = db.query(Customer).filter(Customer.customer_id == customer_id, Customer.business_id == business_id).first()
    if customer:
        if updates.name is not None:
            customer.name = updates.name
        if updates.phone is not None:
            customer.phone = updates.phone
        db.commit()
        db.refresh(customer)
        db.refresh(customer)
    return customer

def delete_customer(db: Session, customer_id: int, business_id: int):
    customer = db.query(Customer).filter(Customer.customer_id == customer_id, Customer.business_id == business_id).first()
    if not customer:
        return False, "Customer not found"
    
    # Check for active orders
    from app.models.order import Order, OrderStatus
    active_orders = db.query(Order).filter(
        Order.customer_id == customer_id, 
        Order.status != OrderStatus.DELIVERED
    ).count()
    
    if active_orders > 0:
        return False, f"Cannot delete customer with {active_orders} active orders"
    
    db.delete(customer)
    db.commit()
    return True, "Customer deleted successfully"
