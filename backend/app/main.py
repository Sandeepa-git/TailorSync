from dotenv import load_dotenv
load_dotenv()

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.api.v1.api import api_router
from app.core.config import settings
import logging

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(name)s - %(levelname)s - %(message)s"
)
logger = logging.getLogger(__name__)

# Import all models to populate SQLAlchemy metadata registry
import app.models.user
import app.models.business
import app.models.customer
import app.models.order
import app.models.measurement
import app.models.measurement_template
import app.models.measurement_field
import app.models.garment_type
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
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
)

from app.api.v1.routers import style_preview

app.include_router(api_router, prefix="/api/v1")
app.include_router(style_preview.router, prefix="/api", tags=["Style Preview"])

@app.on_event("startup")
def startup_event():
    try:
        from app.services.ml_service import ml_service
        ml_service.load_models()
    except Exception as e:
        logger.error(f"Error loading models: {e}")
        # Not failing hard to allow server to start if model isn't completely critical,
        # but the prompt says: "Fail clearly during startup if the model cannot be loaded."
        raise e


@app.get("/")
def root():
    return {"message": "TailorSync API"}

@app.get("/health")
def health():
    """Health check endpoint for deployment verification."""
    return {"status": "healthy", "service": "TailorSync API"}

