from app.database.session import SessionLocal
from app.models.user import User
from app.core.security import get_password_hash

db = SessionLocal()
try:
    user = User(
        email="test_crash2@example.com",
        full_name="Test Crash",
        phone="1234",
        hashed_password=get_password_hash("password")
    )
    db.add(user)
    db.commit()
    print("Success")
except Exception as e:
    import traceback
    traceback.print_exc()
