from fastapi import Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer
from jose import jwt, JWTError, ExpiredSignatureError
from sqlalchemy.orm import Session
from app.database.session import get_db
from app.core.config import settings
from app.models.user import User
import logging

logger = logging.getLogger(__name__)

oauth2_scheme = OAuth2PasswordBearer(tokenUrl="api/v1/auth/login")

def get_current_user(db: Session = Depends(get_db), token: str = Depends(oauth2_scheme)) -> User:
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Could not validate credentials",
        headers={"WWW-Authenticate": "Bearer"},
    )
    try:
        payload = jwt.decode(token, settings.SECRET_KEY, algorithms=["HS256"])
        user_id: str = payload.get("sub")
        if user_id is None:
            logger.warning("Token decode: missing 'sub' claim")
            raise credentials_exception
    except ExpiredSignatureError:
        logger.info("Token expired")
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Token has expired. Please login again.",
            headers={"WWW-Authenticate": "Bearer"},
        )
    except JWTError as e:
        logger.warning(f"Token decode error: {e}")
        raise credentials_exception
        
    user = db.query(User).filter(User.user_id == int(user_id)).first()
    if user is None:
        logger.warning(f"Token valid but user {user_id} not found in database")
        raise credentials_exception
    if not user.is_active:
        raise HTTPException(status_code=400, detail="Inactive user")
    return user

import time
from collections import defaultdict

# Simple in-memory rate limiter: dict of {user_id: [timestamps]}
rate_limits = defaultdict(list)

def rate_limit_ai(user: User = Depends(get_current_user)) -> User:
    now = time.time()
    # Keep only timestamps from the last hour (3600 seconds)
    timestamps = [t for t in rate_limits[user.user_id] if now - t < 3600]
    if len(timestamps) >= 50:
        raise HTTPException(status_code=429, detail="Rate limit exceeded for AI endpoints. Please try again later.")
    timestamps.append(now)
    rate_limits[user.user_id] = timestamps
    return user
