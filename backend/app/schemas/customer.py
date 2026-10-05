from pydantic import BaseModel
from typing import Optional

class CustomerCreate(BaseModel):
    name: str
    email: Optional[str] = None
    phone: Optional[str] = None
    address: Optional[str] = None

class CustomerUpdate(BaseModel):
    name: Optional[str] = None
    phone: Optional[str] = None
    email: Optional[str] = None
    address: Optional[str] = None

class CustomerRead(CustomerCreate):
    id: int

    class Config:
        orm_mode = True
