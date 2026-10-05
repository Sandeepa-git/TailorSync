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
import app.models.inventory

app = FastAPI(title="TailorSync API")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.middleware("http")
async def timing_middleware(request, call_next):
    """Logs how long the SERVER spends on each request (compare with what the phone sees)."""
    import time as _t
    start = _t.perf_counter()
    response = await call_next(request)
    took = _t.perf_counter() - start
    response.headers["X-Server-Time"] = f"{took:.2f}s"
    if took > 1 or "/ai/" in request.url.path:
        logger.info(f"TIMING {request.method} {request.url.path} -> {response.status_code} in {took:.2f}s")
    return response

app.include_router(api_router, prefix="/api/v1")

@app.on_event("startup")
def startup_event():
    # Create the inventory tables if they don't exist yet (other tables untouched).
    try:
        from app.database.session import engine
        from app.database.base import Base
        from app.models.inventory import InventoryItem, InventoryTransaction
        Base.metadata.create_all(bind=engine, tables=[InventoryItem.__table__, InventoryTransaction.__table__])
    except Exception as e:
        logger.error(f"Could not create inventory tables: {e}")
    try:
        from app.services.ml_service import ml_service
        ml_service.load_models()
        # Warm up the Foundry client in the background so the first AI request is faster.
        import threading
        from app.services.foundry_client import get_foundry_client
        threading.Thread(target=lambda: get_foundry_client().warm_up(), daemon=True).start()
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

