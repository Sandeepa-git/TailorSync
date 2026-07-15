from fastapi import APIRouter, Depends
from pydantic import BaseModel
from sqlalchemy.orm import Session
from app.database.session import get_db
from app.schemas.token import Token
from app.services import auth_service
from app.api.deps import get_current_user
from app.models.user import User

router = APIRouter()

class EmailLoginIn(BaseModel):
    email: str
    password: str

class EmailSignupIn(BaseModel):
    email: str
    password: str
    full_name: str = ""
    phone: str = ""

class GoogleLoginIn(BaseModel):
    firebase_token: str

class RefreshTokenIn(BaseModel):
    refresh_token: str

@router.post("/login", response_model=Token)
def login(payload: EmailLoginIn, db: Session = Depends(get_db)):
    return auth_service.email_login(db, payload.email, payload.password)

@router.post("/signup", response_model=Token)
def signup(payload: EmailSignupIn, db: Session = Depends(get_db)):
    return auth_service.email_signup(db, payload.email, payload.password, payload.full_name, payload.phone)

@router.post("/google", response_model=Token)
def google_login(payload: GoogleLoginIn, db: Session = Depends(get_db)):
    return auth_service.google_login(db, payload.firebase_token)

@router.get("/verify")
def verify_token(current_user: User = Depends(get_current_user)):
    """Verify that the current token is valid and return basic user info."""
    return {
        "valid": True,
        "user_id": current_user.id,
        "email": current_user.email,
        "full_name": current_user.full_name,
        "role": current_user.role.value if current_user.role else "OWNER",
    }

@router.post("/refresh")
def refresh_token(payload: RefreshTokenIn):
    """Refresh token endpoint stub — currently returns error since refresh tokens aren't yet implemented."""
    from fastapi import HTTPException
    raise HTTPException(status_code=501, detail="Refresh tokens not yet implemented. Please re-login.")

