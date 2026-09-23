import logging
from app.services.foundry_client import FoundryClient
from app.schemas.ai import (
    MeasurementPredictIn, MeasurementPredictOut, MeasurementPredictionItem,
    FabricRecommendIn, FabricRecommendOut, FabricRecommendationItem,
    FabricEstimateIn, FabricEstimateOut, EstimatedRange
)

logger = logging.getLogger(__name__)

def predict_measurements(request: MeasurementPredictIn, user_id: int, business_id: int, order_id: int = None) -> MeasurementPredictOut:
    logger.info(f"AI [predict_measurements] called for user {user_id} using Microsoft Foundry")
    client = FoundryClient()
    data = client.predict_measurements(request.garment_type, request.measurements)
    return MeasurementPredictOut(**data)

def recommend_fabrics(request: FabricRecommendIn, user_id: int, business_id: int, order_id: int = None) -> FabricRecommendOut:
    logger.info(f"AI [recommend_fabrics] called for user {user_id} using Microsoft Foundry")
    client = FoundryClient()
    data = client.recommend_fabric(
        garment_type=request.garment_type,
        occasion=request.occasion,
        weather=request.weather,
        fabric_preferences=request.fabric_preferences,
        fit=request.fit
    )
    return FabricRecommendOut(**data)

def estimate_fabric(request: FabricEstimateIn, user_id: int, business_id: int, order_id: int = None) -> FabricEstimateOut:
    logger.info(f"AI [estimate_fabric] called for user {user_id} using Microsoft Foundry")
    client = FoundryClient()
    data = client.estimate_fabric(
        garment_type=request.garment_type,
        fabric=request.fabric,
        measurements=request.measurements
    )
    return FabricEstimateOut(**data)

