from pydantic import BaseModel
from typing import Any, Dict, List, Optional

class FabricEstimateIn(BaseModel):
    items: List[Dict[str, Any]]
    measurements: Optional[Dict[str, float]]

class FabricEstimateOut(BaseModel):
    fabric_required_meters: float
    breakdown: Optional[Dict[str, float]]

class RecommendFabricsIn(BaseModel):
    style: str
    constraints: Optional[Dict[str, Any]]

class RecommendFabricsOut(BaseModel):
    recommendations: List[Dict[str, Any]]

class PredictMeasurementsIn(BaseModel):
    profile: Dict[str, Any]

class PredictMeasurementsOut(BaseModel):
    predictions: Dict[str, float]
