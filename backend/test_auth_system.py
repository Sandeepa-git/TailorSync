import sys
import os
import requests

# Add current directory to path
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from app.database.session import SessionLocal
import app.main
from app.models.user import User
from app.core.security import validate_password_strength

def test_database_and_security():
    print("--- 1. Testing Password Strength Validator ---")
    valid, msg = validate_password_strength("Short1!")
    assert not valid, f"Expected invalid for short pass: {msg}"
    print("✓ Short password rejected correctly:", msg)

    valid, msg = validate_password_strength("nouppercase1!")
    assert not valid, f"Expected invalid for missing uppercase: {msg}"
    print("✓ Missing uppercase rejected correctly:", msg)

    valid, msg = validate_password_strength("NOLOWERCASE1!")
    assert not valid, f"Expected invalid for missing lowercase: {msg}"
    print("✓ Missing lowercase rejected correctly:", msg)

    valid, msg = validate_password_strength("NoNumberSpecial!")
    assert not valid, f"Expected invalid for missing number: {msg}"
    print("✓ Missing number rejected correctly:", msg)

    valid, msg = validate_password_strength("NoSpecialNumber12")
    assert not valid, f"Expected invalid for missing special char: {msg}"
    print("✓ Missing special character rejected correctly:", msg)

    valid, msg = validate_password_strength("SecurePass123!")
    assert valid, f"Expected valid password: {msg}"
    print("✓ Strong password passed validation:", msg)

    print("\n--- 2. Database Email Normalization Migration Check ---")
    db = SessionLocal()
    try:
        users = db.query(User).all()
        normalized_count = 0
        for u in users:
            if u.email != u.email.strip().lower():
                u.email = u.email.strip().lower()
                normalized_count += 1
        if normalized_count > 0:
            db.commit()
            print(f"✓ Safely normalized {normalized_count} user email addresses in database.")
        else:
            print("✓ All existing user email addresses are already normalized.")
    finally:
        db.close()

if __name__ == "__main__":
    test_database_and_security()
