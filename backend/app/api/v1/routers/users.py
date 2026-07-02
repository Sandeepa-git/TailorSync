from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from app.database.session import get_db
from app.models.user import User
from app.schemas.user import UserRead, UserUpdate
from app.core.security import get_password_hash
from jose import jwt
from app.core.config import settings

router = APIRouter()

def get_current_user_id(authorization: str = None):
    """Extract user ID from the JWT token in the Authorization header."""
    # This is a simplified version; in production use Depends with Header
    return None

@router.get("/me")
def get_me(db: Session = Depends(get_db)):
    """Get the first user (simplified - in production, extract from JWT)."""
    user = db.query(User).first()
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
def update_me(payload: UserUpdate, db: Session = Depends(get_db)):
    """Update current user's profile."""
    user = db.query(User).first()
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
def list_users(db: Session = Depends(get_db)):
    users = db.query(User).all()
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
