import time
from collections import defaultdict
from fastapi import APIRouter, Depends, HTTPException, Request
from pydantic import BaseModel, EmailStr
from sqlalchemy.orm import Session
from app.database.session import get_db
from app.schemas.token import Token
from app.services import auth_service
from app.api.deps import get_current_user, get_current_active_user
from app.models.user import User
import random
from app.services.email_service import send_email_async
from app.core.security import validate_password_strength, get_password_hash

router = APIRouter()

# In-memory rate limiting tracker: key -> list of timestamps
_failed_attempts = defaultdict(list)
MAX_FAILED_ATTEMPTS = 5
WINDOW_SECONDS = 900  # 15 minutes

def _check_rate_limit(key: str):
    now = time.time()
    # Filter attempts within window
    _failed_attempts[key] = [t for t in _failed_attempts[key] if now - t < WINDOW_SECONDS]
    if len(_failed_attempts[key]) >= MAX_FAILED_ATTEMPTS:
        raise HTTPException(
            status_code=429,
            detail="Too many failed login attempts. Please wait 15 minutes before trying again."
        )

def _record_failed_attempt(key: str):
    _failed_attempts[key].append(time.time())

def _clear_rate_limit(key: str):
    if key in _failed_attempts:
        del _failed_attempts[key]

class EmailLoginIn(BaseModel):
    email: str
    password: str

class EmailSignupIn(BaseModel):
    business_name: str
    business_registration_number: str
    business_contact_number: str
    email: str
    password: str
    full_name: str = ""
    phone: str = ""

class ForgotPasswordIn(BaseModel):
    email: str

class GoogleLoginIn(BaseModel):
    firebase_token: str

class RefreshTokenIn(BaseModel):
    refresh_token: str

@router.post("/login", response_model=Token)
def login(payload: EmailLoginIn, request: Request, db: Session = Depends(get_db)):
    client_ip = request.client.host if request.client else "unknown"
    rate_key = f"{client_ip}:{payload.email.strip().lower()}"
    
    _check_rate_limit(rate_key)
    
    try:
        token = auth_service.email_login(db, payload.email, payload.password)
        _clear_rate_limit(rate_key)
        return token
    except HTTPException as e:
        if e.status_code == 401:
            _record_failed_attempt(rate_key)
        raise e

@router.post("/signup", response_model=Token)
def signup(payload: EmailSignupIn, request: Request, db: Session = Depends(get_db)):
    client_ip = request.client.host if request.client else "unknown"
    rate_key = f"signup:{client_ip}"
    
    _check_rate_limit(rate_key)
    
    try:
        token = auth_service.email_signup(
            db, 
            payload.email, 
            payload.password, 
            payload.business_name,
            payload.business_registration_number,
            payload.business_contact_number,
            payload.full_name, 
            payload.phone
        )
        _clear_rate_limit(rate_key)
        return token
    except HTTPException as e:
        if e.status_code == 400:
            _record_failed_attempt(rate_key)
        raise e

_otp_store = {}
OTP_EXPIRY_SECONDS = 300

@router.post("/forgot-password")
def forgot_password(payload: ForgotPasswordIn, db: Session = Depends(get_db)):
    """
    Safely process forgot password requests without leaking user existence.
    """
    normalized = payload.email.strip().lower()
    user = db.query(User).filter(User.email == normalized).first()
    if user:
        otp = str(random.randint(100000, 999999))
        _otp_store[normalized] = (otp, time.time())
        subject = "TailorSync - Password Reset OTP"
        content = f"Your OTP for password reset is: {otp}\n\nIt expires in 5 minutes."
        send_email_async(normalized, subject, content)
    return {
        "message": "If an account associated with this email exists, password reset instructions have been sent."
    }

class ResetPasswordIn(BaseModel):
    email: str
    otp: str
    new_password: str

@router.post("/reset-password")
def reset_password(payload: ResetPasswordIn, db: Session = Depends(get_db)):
    normalized = payload.email.strip().lower()
    
    if normalized not in _otp_store:
        raise HTTPException(status_code=400, detail="Invalid or expired OTP")
        
    otp, timestamp = _otp_store[normalized]
    if time.time() - timestamp > OTP_EXPIRY_SECONDS:
        del _otp_store[normalized]
        raise HTTPException(status_code=400, detail="Invalid or expired OTP")
        
    if otp != payload.otp:
        raise HTTPException(status_code=400, detail="Invalid OTP")
        
    user = db.query(User).filter(User.email == normalized).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
        
    is_valid, msg = validate_password_strength(payload.new_password)
    if not is_valid:
        raise HTTPException(status_code=400, detail=msg)
        
    user.hashed_password = get_password_hash(payload.new_password)
    db.commit()
    
    del _otp_store[normalized]
    
    return {"message": "Password updated successfully"}

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
    raise HTTPException(status_code=501, detail="Refresh tokens not yet implemented. Please re-login.")
