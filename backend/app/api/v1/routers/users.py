from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from app.database.session import get_db
from app.models.user import User
from app.schemas.user import UserRead, UserUpdate
from app.core.security import get_password_hash
from jose import jwt
from app.core.config import settings
from app.api.deps import get_current_user

router = APIRouter()

@router.get("/me")
def get_me(current_user: User = Depends(get_current_user)):
    """Get the current authenticated user."""
    user = current_user
    if not user:
        raise HTTPException(status_code=404, detail="No user found")
    return {
        "id": user.id,
        "email": user.email,
        "full_name": user.full_name,
        "phone": user.phone,
        "role": user.role.value if user.role else "STAFF",
        "is_active": user.is_active,
    }

@router.put("/me")
def update_me(payload: UserUpdate, db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    """Update current user's profile."""
    user = current_user
    if not user:
        raise HTTPException(status_code=404, detail="No user found")
    
    if payload.full_name is not None:
        user.full_name = payload.full_name
    if payload.phone is not None:
        user.phone = payload.phone
    if payload.password is not None:
        user.hashed_password = get_password_hash(payload.password)
    
    db.commit()
    db.refresh(user)
    return {
        "id": user.id,
        "email": user.email,
        "full_name": user.full_name,
        "phone": user.phone,
        "role": user.role.value if user.role else "STAFF",
        "is_active": user.is_active,
    }

@router.get("/")
def list_users(db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    if not current_user.business_id:
        return []
    users = db.query(User).filter(User.business_id == current_user.business_id).all()
    return [
        {
            "id": u.id,
            "email": u.email,
            "full_name": u.full_name,
            "phone": u.phone,
            "role": u.role.value if u.role else "STAFF",
            "is_active": u.is_active,
        }
        for u in users
    ]
