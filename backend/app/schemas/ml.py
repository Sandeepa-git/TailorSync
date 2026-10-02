from pydantic import BaseModel, root_validator
from typing import Dict, List, Optional, Any

class MLPredictIn(BaseModel):
    garment_type: str
    shoulder: Optional[float] = None
    height: Optional[float] = None
    chest: Optional[float] = None
    waist: Optional[float] = None
    seat: Optional[float] = None

class MLPredictOption(BaseModel):
    option_number: int
    source: str
    support_percent: Optional[float]
    measurements: Dict[str, float]

class MLPredictOut(BaseModel):
    options: List[MLPredictOption]

class RangeData(BaseModel):
    min: float
    max: float

class InputRangesOut(BaseModel):
    garment_type: str
    ranges: Dict[str, RangeData]
