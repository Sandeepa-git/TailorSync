import json
import logging
from typing import Dict, Any
from app.services.foundry_client import FoundryClient
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

FIELD_DISPLAY_MAP = {
    "shoulder_length": "Shoulder Length",
    "height": "Height",
    "height_till_knee": "Height Till Knee",
    "waist": "Waist",
    "around_knee": "Round Knee",
    "seat": "Seat",
    "crotch": "Crotch",
    "short_trouser_leg_opening": "Round End",
    "long_trouser_leg_opening": "Round End",
    "chest": "Chest",
    "collar_size": "Collar Size",
    "short_sleeve_length": "Short Sleeve Length",
    "long_sleeve_length": "Long Sleeve Length",
    "sleeve_opening": "Sleeve Opening",
}

def extract_json_from_response(response_text: str) -> dict:
    try:
        # Strip markdown json blocks if present
        text = response_text.strip()
        if text.startswith("```json"):
            text = text[7:]
        if text.startswith("```"):
            text = text[3:]
        if text.endswith("```"):
            text = text[:-3]
        return json.loads(text.strip())
    except json.JSONDecodeError as e:
        logger.error(f"Failed to parse JSON from agent: {e} - Content: {response_text}")
        raise ValueError("Invalid JSON response from AI")

def predict_measurements(request: MeasurementPredictIn, user_id: int, business_id: int, order_id: int = None) -> MeasurementPredictOut:
    client = FoundryClient.get_instance()
    
    # Map API names to display names for the prompt
    mapped_measurements = {
        FIELD_DISPLAY_MAP.get(k, k): v 
        for k, v in request.measurements.items()
    }
    
    prompt = f"""
    Operation: Predict Measurements
    Garment Type: {request.garment_type}
    Provided Measurements: {json.dumps(mapped_measurements)}
    
    Predict the missing measurements for this garment type.
    Return ONLY a JSON object matching this schema exactly:
    {{
      "garment_type": "{request.garment_type}",
      "predictions": [
        {{
          "measurement": "<API field name from schema>",
          "recommended": "<value as string>",
          "alternatives": ["<val1>", "<val2>"],
          "reason": "<brief explanation>"
        }}
      ]
    }}
    
    Use these exact measurement names for the "measurement" field: {list(FIELD_DISPLAY_MAP.keys())}
    """
    
    raw_response = client.invoke_agent(
        prompt, 
        operation="measurement_prediction", 
        user_id=user_id, 
        business_id=business_id, 
        order_id=order_id
    )
    
    data = extract_json_from_response(raw_response)
    return MeasurementPredictOut(**data)

def recommend_fabrics(request: FabricRecommendIn, user_id: int, business_id: int, order_id: int = None) -> FabricRecommendOut:
    client = FoundryClient.get_instance()
    
    prompt = f"""
    Operation: Fabric Recommendation
    Garment Type: {request.garment_type}
    Occasion: {request.occasion}
    Weather: {request.weather}
    Preferences: {', '.join(request.fabric_preferences)}
    Fit: {request.fit}
    
    Recommend exactly 3 fabrics for this garment and context.
    Return ONLY a JSON object matching this schema exactly:
    {{
      "recommendations": [
        {{
          "fabric_name": "<name>",
          "suitability_percentage": <integer 0-100>,
          "reason": "<brief explanation>"
        }}
      ]
    }}
    """
    
    raw_response = client.invoke_agent(
        prompt, 
        operation="fabric_recommendation", 
        user_id=user_id, 
        business_id=business_id, 
        order_id=order_id
    )
    
    data = extract_json_from_response(raw_response)
    return FabricRecommendOut(**data)

def estimate_fabric(request: FabricEstimateIn, user_id: int, business_id: int, order_id: int = None) -> FabricEstimateOut:
    client = FoundryClient.get_instance()
    
    fabric_width = GARMENT_FABRIC_WIDTH.get(request.garment_type, 45)
    
    # Map API names to display names for the prompt
    mapped_measurements = {
        FIELD_DISPLAY_MAP.get(k, k): v 
        for k, v in request.measurements.items()
    }
    
    prompt = f"""
    Operation: Fabric Estimation
    Garment Type: {request.garment_type}
    Fabric Name: {request.fabric}
    Fabric Width (inches): {fabric_width}
    Confirmed Measurements: {json.dumps(mapped_measurements)}
    
    Estimate the required fabric quantity in meters.
    Return ONLY a JSON object matching this schema exactly:
    {{
      "recommended_quantity_meters": <float>,
      "estimated_range": {{
        "min": <float>,
        "max": <float>
      }},
      "fabric_width_inches": {fabric_width},
      "reason": "<brief explanation>"
    }}
    """
    
    raw_response = client.invoke_agent(
        prompt, 
        operation="fabric_estimation", 
        user_id=user_id, 
        business_id=business_id, 
        order_id=order_id
    )
    
    data = extract_json_from_response(raw_response)
    return FabricEstimateOut(**data)
