from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from app.database.session import get_db
from app.models.business import Business
from app.models.user import User
from app.schemas.business import BusinessRead, BusinessUpdate

router = APIRouter()

@router.get("/me", response_model=BusinessRead)
def get_my_business(db: Session = Depends(get_db)):
    """Get the business of the current user."""
    # Assuming first user for now
    user = db.query(User).first()
    if not user or not user.business_id:
        # Create a default business if none exists for the user
        if user and not user.business_id:
            new_biz = Business(name="TailorSync Default")
            db.add(new_biz)
            db.commit()
            db.refresh(new_biz)
            user.business_id = new_biz.id
            db.commit()
            return new_biz
        raise HTTPException(status_code=404, detail="Business not found")
    
    business = db.query(Business).filter(Business.id == user.business_id).first()
    if not business:
        raise HTTPException(status_code=404, detail="Business not found")
    return business

@router.put("/me", response_model=BusinessRead)
def update_my_business(payload: BusinessUpdate, db: Session = Depends(get_db)):
    """Update the business of the current user."""
    user = db.query(User).first()
    if not user or not user.business_id:
        raise HTTPException(status_code=404, detail="Business not found")
    
    business = db.query(Business).filter(Business.id == user.business_id).first()
    if not business:
        raise HTTPException(status_code=404, detail="Business not found")
    
    if payload.name is not None:
        business.name = payload.name
    if payload.address is not None:
        business.address = payload.address
    if payload.phone is not None:
        business.phone = payload.phone
    
    db.commit()
    db.refresh(business)
    return business
