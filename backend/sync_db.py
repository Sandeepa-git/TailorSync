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
    print("Dropping existing database tables to apply schema updates...")
    Base.metadata.drop_all(bind=engine)
    print("Creating new database tables...")
    Base.metadata.create_all(bind=engine)
    print("Database tables created successfully!")

if __name__ == "__main__":
    sync()
