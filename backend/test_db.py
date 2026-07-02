from app.database.session import SessionLocal
from app.models.user import User

db = SessionLocal()
try:
    user = db.query(User).filter(User.email == "t@e.com").first()
    if not user:
        user = User(
            email="t@e.com",
            full_name="a",
            hashed_password="firebase_managed"
        )
        db.add(user)
        db.commit()
        print("Success")
    else:
        print("User already exists")
except Exception as e:
    import traceback
    traceback.print_exc()
