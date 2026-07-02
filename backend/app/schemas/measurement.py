from pydantic import BaseModel
from typing import Optional, List
from datetime import datetime

class MeasurementCreate(BaseModel):
    customer_id: int
    height: Optional[float] = None
    weight: Optional[float] = None
    chest: Optional[float] = None
    waist: Optional[float] = None
    hip: Optional[float] = None
    shoulder: Optional[float] = None
    sleeve_length: Optional[float] = None
    inseam: Optional[float] = None
    predicted_fields: List[str] = []

class MeasurementRead(MeasurementCreate):
    id: int
    recorded_at: datetime
    
    class Config:
        orm_mode = True
