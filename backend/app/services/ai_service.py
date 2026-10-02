import logging
from app.services.foundry_client import FoundryClient
from app.schemas.ai import (
    MeasurementPredictIn, MeasurementPredictOut, MeasurementPredictionItem,
    FabricRecommendIn, FabricRecommendOut, FabricRecommendationItem,
    FabricEstimateIn, FabricEstimateOut, EstimatedRange
)

logger = logging.getLogger(__name__)

def predict_measurements(request: MeasurementPredictIn, user_id: int, business_id: int, order_id: int = None) -> MeasurementPredictOut:
    """
    Predict missing measurements for a specific garment using Azure AI Foundry.
    
    Args:
        request: The input data containing garment type and provided measurements.
        user_id: ID of the user requesting the prediction.
        business_id: ID of the business context.
        order_id: Optional ID of the associated order.
        
    Returns:
        MeasurementPredictOut containing AI-generated predictions.
    """
    logger.info(f"AI [predict_measurements] called for user {user_id} using Microsoft Foundry")
    client = FoundryClient()
    data = client.predict_measurements(request.garment_type, request.measurements)
    if "garment_type" not in data:
        data["garment_type"] = request.garment_type
    return MeasurementPredictOut(**data)

def recommend_fabrics(request: FabricRecommendIn, user_id: int, business_id: int, order_id: int = None) -> FabricRecommendOut:
    """
    Recommend suitable fabrics based on garment type, occasion, weather, and fit preferences.
    
    Args:
        request: Input preferences for fabric recommendation.
        user_id: ID of the user requesting the recommendation.
        business_id: ID of the business context.
        order_id: Optional ID of the associated order.
        
    Returns:
        FabricRecommendOut containing top fabric choices and suitability percentages.
    """
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
    """
    Estimate the required fabric quantity (in meters) based on precise measurements.
    
    Args:
        request: Input data containing garment type, chosen fabric, and exact measurements.
        user_id: ID of the user requesting the estimation.
        business_id: ID of the business context.
        order_id: Optional ID of the associated order.
        
    Returns:
        FabricEstimateOut containing the recommended quantity in meters and a min/max range.
    """
    logger.info(f"AI [estimate_fabric] called for user {user_id} using Microsoft Foundry")
    client = FoundryClient()
    data = client.estimate_fabric(
        garment_type=request.garment_type,
        fabric=request.fabric,
        measurements=request.measurements
    )
    return FabricEstimateOut(**data)

