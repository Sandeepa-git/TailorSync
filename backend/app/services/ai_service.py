import joblib
import pandas as pd
import os
from typing import Dict, Any

# Load models if they exist
BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
MEASUREMENT_MODEL_PATH = os.path.join(BASE_DIR, "ai_models", "measurement_predictor.joblib")
FABRIC_MODEL_PATH = os.path.join(BASE_DIR, "ai_models", "fabric_recommender.joblib")

measurement_model = None
fabric_model = None

if os.path.exists(MEASUREMENT_MODEL_PATH):
    measurement_model = joblib.load(MEASUREMENT_MODEL_PATH)

if os.path.exists(FABRIC_MODEL_PATH):
    fabric_model = joblib.load(FABRIC_MODEL_PATH)

def predict_measurements(profile: Dict[str, Any]) -> Dict[str, float]:
    """Predicts missing measurements given height and weight."""
    if not measurement_model:
        return {}
    
    height = profile.get("height")
    weight = profile.get("weight")
    
    if not height or not weight:
        return {} # Not enough data
        
    X_pred = pd.DataFrame([{'height': height, 'weight': weight}])
    predictions = measurement_model.predict(X_pred)[0]
    
    return {
        "chest": round(predictions[0], 2),
        "waist": round(predictions[1], 2),
        "hip": round(predictions[2], 2),
        "shoulder": round(predictions[3], 2),
        "sleeve_length": round(predictions[4], 2),
        "inseam": round(predictions[5], 2),
    }

def estimate_fabric(items: list, measurements: dict) -> Dict[str, Any]:
    """Estimates fabric yardage based on measurements and item type."""
    total_meters = 0.0
    breakdown = {}
    
    height = measurements.get("height", 170) if measurements else 170
    
    for item in items:
        garment = item.get("garment_type", "").lower()
        if "shirt" in garment:
            req = (height / 100) * 1.5 
        elif "trouser" in garment or "pant" in garment:
            req = (height / 100) * 1.3
        elif "suit" in garment:
            req = (height / 100) * 3.5
        elif "dress" in garment:
            req = (height / 100) * 2.5
        else:
            req = 2.0
            
        req = round(req, 2)
        total_meters += req
        breakdown[garment or "unknown"] = req
        
    return {"fabric_required_meters": round(total_meters, 2), "breakdown": breakdown}

def recommend_fabrics(style: str, constraints: Dict[str, Any] = None):
    if not fabric_model:
        return []
        
    occasion = constraints.get("occasion", "casual") if constraints else "casual"
    
    garment_map = {"shirt": 0, "trouser": 1, "suit": 2, "dress": 3}
    occasion_map = {"casual": 0, "formal": 1, "party": 2, "summer": 3}
    
    g_idx = garment_map.get(style.lower(), 0)
    o_idx = occasion_map.get(occasion.lower(), 0)
    
    fabric_idx = fabric_model.predict([[g_idx, o_idx]])[0]
    
    fabrics = {0: "Cotton", 1: "Wool", 2: "Silk", 3: "Linen"}
    recommended = fabrics.get(fabric_idx, "Cotton")
    
    return [
        {
            "fabric_type": recommended,
            "reason": f"AI matched {recommended} as the best fabric for a {occasion} {style}."
        }
    ]
