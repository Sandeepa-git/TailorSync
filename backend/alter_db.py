from app.database.session import SessionLocal
from sqlalchemy import text

db = SessionLocal()
try:
    db.execute(text("ALTER TABLE users ADD COLUMN phone VARCHAR(20);"))
    db.commit()
    print("Column 'phone' added successfully")
except Exception as e:
    import traceback
    traceback.print_exc()
