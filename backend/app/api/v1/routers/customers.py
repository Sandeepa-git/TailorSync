from fastapi import APIRouter, Depends, HTTPException
from typing import List
from sqlalchemy.orm import Session
from app.schemas.customer import CustomerCreate, CustomerRead, CustomerUpdate
from app.database.session import get_db
from app.api.deps import get_current_user
from app.models.user import User

router = APIRouter()

@router.get("/", response_model=List[CustomerRead])
def list_customers(db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    from app.services.customer_service import list_customers as svc_list
    return svc_list(db, current_user.business_id)

@router.post("/", response_model=CustomerRead)
def create_customer(payload: CustomerCreate, db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    from app.services.customer_service import create_customer as svc_create
    return svc_create(db, payload, current_user.business_id)

@router.put("/{customer_id}", response_model=CustomerRead)
def update_customer(customer_id: int, payload: CustomerUpdate, db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    from app.services.customer_service import update_customer as svc_update
    updated = svc_update(db, customer_id, payload, current_user.business_id)
    if not updated:
        raise HTTPException(status_code=404, detail="Customer not found")
    return updated

@router.delete("/{customer_id}")
def delete_customer(customer_id: int, db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    from app.services.customer_service import delete_customer as svc_delete
    success, message = svc_delete(db, customer_id, current_user.business_id)
    if not success:
        raise HTTPException(status_code=400, detail=message)
    return {"detail": message}
