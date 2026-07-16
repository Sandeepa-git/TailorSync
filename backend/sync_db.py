from app.database.session import engine
from app.database.base import Base

# Import all models so they register with Base.metadata
from app.models.user import User
from app.models.business import Business
from app.models.customer import Customer
from app.models.order import Order
from app.models.measurement import Measurement
from app.models.ai_prediction import AIPrediction
from app.models.fabric_estimation import FabricEstimation
from app.models.fabric_recommendation import FabricRecommendation
from app.models.staff_assignment import StaffAssignment
from app.models.note import Note
from app.models.fabric_catalog import FabricCatalog

def sync():
    print("Dropping public schema to apply clean schema updates...")
    from sqlalchemy import text
    with engine.connect() as conn:
        conn.execute(text("DROP SCHEMA public CASCADE;"))
        conn.execute(text("CREATE SCHEMA public;"))
        # Neon might not need grant all if it's default owner, but it's safe to add
        try:
            conn.execute(text("GRANT ALL ON SCHEMA public TO public;"))
        except Exception:
            pass
        conn.commit()
    print("Creating new database tables...")
    Base.metadata.create_all(bind=engine)
    print("Database tables created successfully!")

if __name__ == "__main__":
    sync()
