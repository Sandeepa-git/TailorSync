from fastapi import APIRouter, Depends
from pydantic import BaseModel
from sqlalchemy.orm import Session
from app.database.session import get_db
from app.schemas.token import Token
from app.services import auth_service

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

@router.post("/login", response_model=Token)
def login(payload: EmailLoginIn, db: Session = Depends(get_db)):
    return auth_service.email_login(db, payload.email, payload.password)

@router.post("/signup", response_model=Token)
def signup(payload: EmailSignupIn, db: Session = Depends(get_db)):
    return auth_service.email_signup(db, payload.email, payload.password, payload.full_name, payload.phone)

@router.post("/google", response_model=Token)
def google_login(payload: GoogleLoginIn, db: Session = Depends(get_db)):
    return auth_service.google_login(db, payload.firebase_token)
