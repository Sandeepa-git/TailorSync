import logging
from app.services.foundry_client import get_foundry_client
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
    client = get_foundry_client()
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
    client = get_foundry_client()
    data = client.recommend_fabric(
        garment_type=request.garment_type,
        occasion=request.occasion,
        weather=request.weather,
        fabric_preferences=request.fabric_preferences,
        fit=request.fit
    )
    _attach_inventory(data, business_id)
    return FabricRecommendOut(**data)


def _attach_inventory(data: dict, business_id: int) -> None:
    """Add each recommended fabric to the inventory (untracked, 0 m) if new,
    and attach its current stock so the app can show it."""
    try:
        from app.database.session import SessionLocal
        from app.services import inventory_service as inv
        recs = data.get("recommendations") or []
        names = [r.get("fabric_name") for r in recs if r.get("fabric_name")]
        db = SessionLocal()
        try:
            inv.ensure_items(db, business_id, names)
            db.commit()
            stock = inv.stock_lookup(db, business_id, names)
        finally:
            db.close()
        for r in recs:
            s = stock.get(inv.name_key(r.get("fabric_name", "")))
            if s:
                r["stock_m"] = s["quantity_m"]
                r["stock_tracked"] = s["is_tracked"]
                r["stock_status"] = s["status"]
    except Exception as e:
        logger.error(f"Inventory lookup for recommendations failed: {e}")

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
    client = get_foundry_client()
    data = client.estimate_fabric(
        garment_type=request.garment_type,
        fabric=request.fabric,
        measurements=request.measurements
    )
    return FabricEstimateOut(**data)

