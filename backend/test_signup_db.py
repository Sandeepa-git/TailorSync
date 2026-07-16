import app.models.user
import app.models.business
import app.models.customer
import app.models.order
import app.models.measurement
import app.models.measurement_template
import app.models.measurement_field
import app.models.customer_measurement
import app.models.ai_prediction
import app.models.fabric_estimation
import app.models.fabric_recommendation
import app.models.staff_assignment
import app.models.note
import app.models.fabric_catalog

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
