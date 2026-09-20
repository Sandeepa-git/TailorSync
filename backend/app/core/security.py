import re
import bcrypt

def verify_password(plain_password: str, hashed_password: str) -> bool:
    try:
        if not plain_password or not hashed_password:
            return False
        pw_bytes = plain_password.encode('utf-8')
        if len(pw_bytes) > 72:
            pw_bytes = pw_bytes[:72]
        hash_bytes = hashed_password.encode('utf-8')
        return bcrypt.checkpw(pw_bytes, hash_bytes)
    except Exception:
        return False

def needs_rehash(hashed_password: str) -> bool:
    return False

def get_password_hash(password: str) -> str:
    pw_bytes = password.encode('utf-8')
    if len(pw_bytes) > 72:
        pw_bytes = pw_bytes[:72]
    salt = bcrypt.gensalt()
    return bcrypt.hashpw(pw_bytes, salt).decode('utf-8')

def validate_password_strength(password: str) -> tuple[bool, str]:
    """
    Validates password strength against security criteria:
    - Min 8 characters
    - At least 1 uppercase letter
    - At least 1 lowercase letter
    - At least 1 number
    - At least 1 special character
    """
    if len(password) < 8:
        return False, "Password must be at least 8 characters long"
    if not re.search(r'[A-Z]', password):
        return False, "Password must contain at least one uppercase letter (A-Z)"
    if not re.search(r'[a-z]', password):
        return False, "Password must contain at least one lowercase letter (a-z)"
    if not re.search(r'[0-9]', password):
        return False, "Password must contain at least one number (0-9)"
    if not re.search(r'[!@#$%^&*(),.?":{}|<>\_\+\-=\[\]\\/]', password):
        return False, "Password must contain at least one special character"
    return True, "Password meets strength requirements"
