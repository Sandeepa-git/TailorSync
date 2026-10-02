from app.database.session import SessionLocal
from sqlalchemy import text

db = SessionLocal()
try:
    db.execute(text("ALTER TABLE orders ADD COLUMN prediction_method VARCHAR(255);"))
    db.commit()
    print("Column 'prediction_method' added successfully")
except Exception as e:
    import traceback
    traceback.print_exc()
