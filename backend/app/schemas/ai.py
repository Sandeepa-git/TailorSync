from pydantic import BaseModel, validator
from typing import Dict, List, Optional

# ── Measurement Prediction ──
class MeasurementPredictIn(BaseModel):
    garment_type: str
    measurements: Dict[str, str]  # canonical field names → values

class MeasurementPredictionItem(BaseModel):
    measurement: str        # canonical API field name
    recommended: str
    alternatives: List[str]
    reason: str

class MeasurementPredictOut(BaseModel):
    garment_type: str
    predictions: List[MeasurementPredictionItem]

# ── Fabric Recommendation ──
class FabricRecommendIn(BaseModel):
    garment_type: str
    occasion: str
    weather: str
    fabric_preferences: List[str]
    fit: str

class FabricRecommendationItem(BaseModel):
    fabric_name: str
    suitability_percentage: int
    reason: str

class FabricRecommendOut(BaseModel):
    recommendations: List[FabricRecommendationItem]

    @validator('recommendations')
    def must_have_three(cls, v):
        if len(v) != 3:
            raise ValueError(f'Expected 3 recommendations, got {len(v)}')
        return v

# ── Fabric Estimation ──
class FabricEstimateIn(BaseModel):
    garment_type: str
    measurements: Dict[str, str]
    fabric: str

class EstimatedRange(BaseModel):
    min: float
    max: float

class FabricEstimateOut(BaseModel):
    recommended_quantity_meters: float
    estimated_range: Optional[EstimatedRange] = None
    fabric_width_inches: int
    reason: str
