from pydantic import BaseModel
from typing import Optional, List
from datetime import datetime

class MeasurementInput(BaseModel):
    height: Optional[float] = None
    weight: Optional[float] = None
    chest: Optional[float] = None
    waist: Optional[float] = None
    hip: Optional[float] = None
    shoulder: Optional[float] = None
    sleeve_length: Optional[float] = None
    inseam: Optional[float] = None
    predicted_fields: Optional[List[str]] = []

class OrderCreate(BaseModel):
    customer_id: int
    garment_type: str
    occasion: Optional[str] = None
    due_date: Optional[datetime] = None
    priority: Optional[str] = "Medium"
    tailor_remarks: Optional[str] = None
    customer_instructions: Optional[str] = None
    measurements: Optional[MeasurementInput] = None
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

    class Config:
        orm_mode = True

class OrderUpdate(BaseModel):
    status: Optional[str] = None
    priority: Optional[str] = None
    due_date: Optional[datetime] = None
    tailor_remarks: Optional[str] = None
    customer_instructions: Optional[str] = None
    staff_id: Optional[int] = None
