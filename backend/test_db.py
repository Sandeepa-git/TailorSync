from app.database.session import SessionLocal
from app.models.user import User
import app.models.business
import app.models.customer
import app.models.order
import app.models.measurement
import app.models.ai_prediction
import app.models.fabric_estimation
import app.models.fabric_recommendation
import app.models.staff_assignment
import app.models.note
import app.models.fabric_catalog
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
