from pydantic import BaseModel
from typing import Optional

class BusinessBase(BaseModel):
    name: str
    address: Optional[str] = None
    phone: Optional[str] = None

class BusinessCreate(BusinessBase):
    pass

class BusinessRead(BusinessBase):
    id: int

    class Config:
        orm_mode = True

class BusinessUpdate(BaseModel):
    name: Optional[str] = None
    address: Optional[str] = None
    phone: Optional[str] = None
