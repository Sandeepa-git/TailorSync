import firebase_admin
from firebase_admin import auth as firebase_auth
from fastapi import HTTPException
from sqlalchemy.orm import Session
from app.models.user import User, RoleEnum
from app.core.jwt import create_access_token
from app.core.security import get_password_hash, verify_password
from app.models.business import Business
import logging

logger = logging.getLogger(__name__)

# Initialize Firebase Admin App
try:
    firebase_admin.get_app()
except ValueError:
    try:
        firebase_admin.initialize_app(options={'projectId': 'tailorsync-dd5e3'})
    except Exception as e:
        logger.warning(f"Firebase init failed (non-fatal for email auth): {e}")

def _get_role_value(user: User) -> str:
    """Safely get role value, defaulting to OWNER if None."""
    if user.role is None:
        return RoleEnum.OWNER.value
    if isinstance(user.role, str):
        return user.role
    return user.role.value

def _ensure_business(db: Session, user: User) -> None:
    """Ensure the user has an associated business, create one if not."""
    if user.business_id:
        return
    try:
        biz_name = f"{user.full_name}'s Tailor Shop" if user.full_name else "My Tailor Shop"
        new_biz = Business(business_name=biz_name)
        db.add(new_biz)
        db.flush()
        user.business_id = new_biz.id
        db.commit()
        db.refresh(user)
    except Exception as e:
        db.rollback()
        logger.error(f"Failed to create business for user {user.id}: {e}")

def _generate_token(user: User) -> dict:
    """Generate access token response for a user."""
    role_value = _get_role_value(user)
    return {
        "access_token": create_access_token(str(user.id), {"role": role_value}),
        "token_type": "bearer"
    }

def email_login(db: Session, email: str, password: str):
    user = db.query(User).filter(User.email == email).first()
    if not user:
        logger.info(f"Login failed: no user found for email {email}")
        raise HTTPException(status_code=401, detail="Incorrect email or password")
    
    if user.hashed_password == "firebase_managed":
        raise HTTPException(status_code=401, detail="This account uses Google Sign-In. Please use the Google login option.")
    
    if not verify_password(password, user.hashed_password):
        logger.info(f"Login failed: wrong password for {email}")
        raise HTTPException(status_code=401, detail="Incorrect email or password")
    
    _ensure_business(db, user)
    return _generate_token(user)

def email_signup(db: Session, email: str, password: str, full_name: str = "", phone: str = ""):
    existing = db.query(User).filter(User.email == email).first()
    if existing:
        raise HTTPException(status_code=400, detail="Email already registered")
    
    try:
        user = User(
            email=email,
            full_name=full_name,
            phone=phone,
            hashed_password=get_password_hash(password),
            role=RoleEnum.OWNER,
        )
        db.add(user)
        db.flush()
        
        biz_name = f"{full_name}'s Tailor Shop" if full_name else "My Tailor Shop"
        new_biz = Business(business_name=biz_name)
        db.add(new_biz)
        db.flush()
        
        user.business_id = new_biz.id
        db.commit()
        db.refresh(user)
    except Exception as e:
        db.rollback()
        logger.error(f"Signup failed for {email}: {e}")
        raise HTTPException(status_code=500, detail="Registration failed. Please try again.")
    
    return _generate_token(user)

def google_login(db: Session, firebase_token: str):
    try:
        decoded_token = firebase_auth.verify_id_token(firebase_token)
    except Exception as e:
        logger.error(f"Firebase token verification failed: {e}")
        raise HTTPException(status_code=401, detail=f"Invalid Firebase token: {str(e)}")
        
    email = decoded_token.get("email")
    if not email:
        raise HTTPException(status_code=400, detail="Google account must have an email")
        
    user = db.query(User).filter(User.email == email).first()
    if not user:
        try:
            user = User(
                email=email,
                full_name=decoded_token.get("name", "Google User"),
                hashed_password="firebase_managed",
                role=RoleEnum.OWNER,
            )
            db.add(user)
            db.flush()
            
            biz_name = f"{user.full_name}'s Tailor Shop" if user.full_name else "My Tailor Shop"
            new_biz = Business(business_name=biz_name)
            db.add(new_biz)
            db.flush()
            
            user.business_id = new_biz.id
            db.commit()
            db.refresh(user)
        except Exception as e:
            db.rollback()
            logger.error(f"Google signup failed for {email}: {e}")
            raise HTTPException(status_code=500, detail="Registration failed. Please try again.")
    else:
        _ensure_business(db, user)
        
    return _generate_token(user)

