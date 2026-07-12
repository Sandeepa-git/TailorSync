from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.api.v1.api import api_router
from app.core.config import settings

# Import all models to populate SQLAlchemy metadata registry
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

app = FastAPI(title="TailorSync API")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(api_router, prefix="/api/v1")

@app.get("/")
def root():
    return {"message": "TailorSync API"}
