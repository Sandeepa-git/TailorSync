from sqlalchemy.orm import Session
from app.models.customer import Customer
from app.schemas.customer import CustomerCreate, CustomerUpdate

def list_customers(db: Session, skip: int = 0, limit: int = 100):
    return db.query(Customer).offset(skip).limit(limit).all()

def create_customer(db: Session, customer: CustomerCreate):
    db_customer = Customer(**customer.dict())
    db.add(db_customer)
    db.commit()
    db.refresh(db_customer)
    return db_customer

def update_customer(db: Session, customer_id: int, updates: CustomerUpdate):
    customer = db.query(Customer).filter(Customer.id == customer_id).first()
    if customer:
        if updates.name is not None:
            customer.name = updates.name
        if updates.phone is not None:
            customer.phone = updates.phone
        db.commit()
        db.refresh(customer)
    return customer
