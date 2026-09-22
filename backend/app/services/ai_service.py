import logging
from app.services.gemini_client import GeminiClient
from app.schemas.ai import (
    MeasurementPredictIn, MeasurementPredictOut,
    FabricRecommendIn, FabricRecommendOut,
    FabricEstimateIn, FabricEstimateOut
)

logger = logging.getLogger(__name__)

GARMENT_FABRIC_WIDTH = {
    "Short Sleeve Shirt": 45,
    "Long Sleeve Shirt": 45,
    "Short Trouser": 60,
    "Long Trouser": 60,
}

def predict_measurements(request: MeasurementPredictIn, user_id: int, business_id: int, order_id: int = None) -> MeasurementPredictOut:
    client = GeminiClient()
    
    # We pass the raw measurements, and GeminiClient + DatasetService handles mapping
    data = client.predict_measurements(
        garment_type=request.garment_type,
        provided_measurements=request.measurements,
        business_id=business_id,
        user_id=user_id,
        order_id=order_id
    )
    
    return MeasurementPredictOut(**data)

def recommend_fabrics(request: FabricRecommendIn, user_id: int, business_id: int, order_id: int = None) -> FabricRecommendOut:
    client = GeminiClient()
    
    data = client.recommend_fabric(
        garment_type=request.garment_type,
        occasion=request.occasion,
        weather=request.weather,
        fabric_preferences=request.fabric_preferences,
        fit=request.fit,
        business_id=business_id,
        user_id=user_id,
        order_id=order_id
    )
    
    return FabricRecommendOut(**data)

def estimate_fabric(request: FabricEstimateIn, user_id: int, business_id: int, order_id: int = None) -> FabricEstimateOut:
    client = GeminiClient()
    
    data = client.estimate_fabric(
        garment_type=request.garment_type,
        fabric=request.fabric,
        measurements=request.measurements,
        business_id=business_id,
        user_id=user_id,
        order_id=order_id
    )
    
    return FabricEstimateOut(**data)
