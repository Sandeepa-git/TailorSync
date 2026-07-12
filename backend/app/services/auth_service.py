import firebase_admin
from firebase_admin import auth as firebase_auth
from fastapi import HTTPException
from sqlalchemy.orm import Session
from app.models.user import User
from app.core.jwt import create_access_token
from app.core.security import get_password_hash, verify_password
from app.models.business import Business

# Initialize Firebase Admin App
try:
    firebase_admin.get_app()
except ValueError:
    firebase_admin.initialize_app(options={'projectId': 'tailorsync-dd5e3'})

def email_login(db: Session, email: str, password: str):
    user = db.query(User).filter(User.email == email).first()
    if not user or not verify_password(password, user.hashed_password):
        raise HTTPException(status_code=401, detail="Incorrect email or password")
    if not user.business_id:
        biz_name = f"{user.full_name}'s Tailor Shop" if user.full_name else "My Tailor Shop"
        new_biz = Business(name=biz_name)
        db.add(new_biz)
        db.commit()
        db.refresh(new_biz)
        user.business_id = new_biz.id
        db.commit()

    return {
        "access_token": create_access_token(str(user.id), {"role": user.role.value}),
        "token_type": "bearer"
    }

def email_signup(db: Session, email: str, password: str, full_name: str = "", phone: str = ""):
    user = db.query(User).filter(User.email == email).first()
    if user:
        raise HTTPException(status_code=400, detail="Email already registered")
        
    user = User(
        email=email,
        full_name=full_name,
        phone=phone,
        hashed_password=get_password_hash(password)
    )
    db.add(user)
    db.commit()
    db.refresh(user)
    
    biz_name = f"{full_name}'s Tailor Shop" if full_name else "My Tailor Shop"
    new_biz = Business(name=biz_name)
    db.add(new_biz)
    db.commit()
    db.refresh(new_biz)
    user.business_id = new_biz.id
    db.commit()
    
    return {
        "access_token": create_access_token(str(user.id), {"role": user.role.value}),
        "token_type": "bearer"
    }

def google_login(db: Session, firebase_token: str):
    try:
        decoded_token = firebase_auth.verify_id_token(firebase_token)
    except Exception as e:
        raise HTTPException(status_code=401, detail=f"Invalid Firebase token: {str(e)}")
        
    email = decoded_token.get("email")
    if not email:
        raise HTTPException(status_code=400, detail="Google account must have an email")
        
    user = db.query(User).filter(User.email == email).first()
    if not user:
        user = User(
            email=email,
            full_name=decoded_token.get("name", "Google User"),
            hashed_password="firebase_managed"
        )
        db.add(user)
        db.commit()
        db.refresh(user)
        
        biz_name = f"{user.full_name}'s Tailor Shop" if user.full_name else "My Tailor Shop"
        new_biz = Business(name=biz_name)
        db.add(new_biz)
        db.commit()
        db.refresh(new_biz)
        user.business_id = new_biz.id
        db.commit()
    elif not user.business_id:
        biz_name = f"{user.full_name}'s Tailor Shop" if user.full_name else "My Tailor Shop"
        new_biz = Business(name=biz_name)
        db.add(new_biz)
        db.commit()
        db.refresh(new_biz)
        user.business_id = new_biz.id
        db.commit()
        
    return {
        "access_token": create_access_token(str(user.id), {"role": user.role.value}),
        "token_type": "bearer"
    }
