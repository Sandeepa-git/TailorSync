from fastapi import APIRouter, Depends
from typing import List
from sqlalchemy.orm import Session
from app.schemas.customer import CustomerCreate, CustomerRead, CustomerUpdate
from app.database.session import get_db

router = APIRouter()

@router.get("/", response_model=List[CustomerRead])
def list_customers(db: Session = Depends(get_db)):
    from app.services.customer_service import list_customers as svc_list
    return svc_list(db)

@router.post("/", response_model=CustomerRead)
def create_customer(payload: CustomerCreate, db: Session = Depends(get_db)):
    from app.services.customer_service import create_customer as svc_create
    return svc_create(db, payload)

@router.put("/{customer_id}", response_model=CustomerRead)
def update_customer(customer_id: int, payload: CustomerUpdate, db: Session = Depends(get_db)):
    from app.services.customer_service import update_customer as svc_update
    from fastapi import HTTPException
    updated = svc_update(db, customer_id, payload)
    if not updated:
        raise HTTPException(status_code=404, detail="Customer not found")
    return updated
