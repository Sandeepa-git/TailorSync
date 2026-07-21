from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from app.database.session import get_db
from app.models.user import User, RoleEnum
from app.schemas.user import UserRead, UserCreate
from app.core.security import get_password_hash
from app.api.deps import get_current_user

router = APIRouter()

@router.get("/", response_model=list[UserRead])
def list_staff(db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    """List all staff for the current user's business."""
    if not current_user or not current_user.business_id:
        return []
    
    staff = db.query(User).filter(
        User.business_id == current_user.business_id,
        User.user_id != current_user.user_id,
        User.is_active == True
    ).all()
    return staff

@router.post("/", response_model=UserRead)
def add_staff(payload: UserCreate, db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    """Add a new staff member to the current user's business."""
    if not current_user or not current_user.business_id:
        raise HTTPException(status_code=400, detail="You must have a business to add staff")
    
    # Check if email exists
    if db.query(User).filter(User.email == payload.email).first():
        raise HTTPException(status_code=400, detail="Email already registered")
        
    new_staff = User(
        email=payload.email,
        full_name=payload.full_name,
        phone=payload.phone,
        hashed_password=get_password_hash(payload.password),
        role=RoleEnum.STAFF,
        business_id=current_user.business_id,
        is_active=True
    )
    db.add(new_staff)
    db.commit()
    db.refresh(new_staff)
    return new_staff

@router.delete("/{staff_id}")
def deactivate_staff(staff_id: int, db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    """Deactivate a staff member."""
    if not current_user or not current_user.business_id:
        raise HTTPException(status_code=403, detail="Not authorized")
        
    staff = db.query(User).filter(
        User.user_id == staff_id,
        User.business_id == current_user.business_id
    ).first()
    
    if not staff:
        raise HTTPException(status_code=404, detail="Staff not found")
        
    staff.is_active = False
    db.commit()
    return {"status": "success", "message": "Staff deactivated"}
