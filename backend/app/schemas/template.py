from pydantic import BaseModel
from typing import Optional, List
from datetime import datetime

class MeasurementFieldBase(BaseModel):
    field_name: str
    unit: Optional[str] = "cm"
    is_required: Optional[bool] = True
    placeholder: Optional[str] = None
    display_order: Optional[int] = 0

class MeasurementFieldCreate(MeasurementFieldBase):
    pass

class MeasurementFieldRead(MeasurementFieldBase):
    id: int
    template_id: int

    class Config:
        orm_mode = True

class MeasurementTemplateBase(BaseModel):
    category_name: str
    display_order: Optional[int] = 0

class MeasurementTemplateCreate(MeasurementTemplateBase):
    fields: List[MeasurementFieldCreate] = []

class MeasurementTemplateRead(MeasurementTemplateBase):
    id: int
    business_id: Optional[int]
    fields: List[MeasurementFieldRead] = []

    class Config:
        orm_mode = True

class MeasurementTemplateUpdate(BaseModel):
    category_name: Optional[str] = None
    display_order: Optional[int] = None

class CustomerMeasurementBase(BaseModel):
    field_id: int
    value: float

class CustomerMeasurementCreate(CustomerMeasurementBase):
    pass

class CustomerMeasurementRead(CustomerMeasurementBase):
    id: int
    customer_id: int
    order_id: Optional[int]
    recorded_at: datetime
    field: Optional[MeasurementFieldRead]

    class Config:
        orm_mode = True
