from pydantic import BaseModel
from typing import Optional, List
from datetime import datetime

class DynamicMeasurementInput(BaseModel):
    field_id: int
    value: float

class OrderCreate(BaseModel):
    customer_id: int
    garment_type: str
    occasion: Optional[str] = None
    due_date: Optional[datetime] = None
    priority: Optional[str] = "Medium"
    tailor_remarks: Optional[str] = None
    customer_instructions: Optional[str] = None
    measurements: Optional[List[DynamicMeasurementInput]] = None
    staff_id: Optional[int] = None

class OrderRead(BaseModel):
    id: int
    customer_id: int
    garment_type: str
    occasion: Optional[str] = None
    status: str
    priority: Optional[str] = "Medium"
    due_date: Optional[datetime] = None
    completed_at: Optional[datetime] = None
    created_at: Optional[datetime] = None
    tailor_remarks: Optional[str] = None
    customer_instructions: Optional[str] = None
    customer_name: Optional[str] = None
    customer_phone: Optional[str] = None
    staff_id: Optional[int] = None
    staff_name: Optional[str] = None
    measurements: List[dict] = []

    class Config:
        orm_mode = True

class OrderUpdate(BaseModel):
    status: Optional[str] = None
    priority: Optional[str] = None
    due_date: Optional[datetime] = None
    tailor_remarks: Optional[str] = None
    customer_instructions: Optional[str] = None
    staff_id: Optional[int] = None
