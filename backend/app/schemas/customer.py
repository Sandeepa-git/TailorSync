from pydantic import BaseModel
from typing import Optional

class CustomerCreate(BaseModel):
    name: str
    email: Optional[str]
    phone: Optional[str]

class CustomerUpdate(BaseModel):
    name: Optional[str] = None
    phone: Optional[str] = None

class CustomerRead(CustomerCreate):
    id: int

    class Config:
        orm_mode = True
