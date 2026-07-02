from pydantic import BaseModel
from typing import Optional

class TaskCreate(BaseModel):
    order_id: Optional[int]
    title: str
    description: Optional[str]
    assigned_to: Optional[int]
    type: Optional[str]
    due_date: Optional[str]

class TaskRead(TaskCreate):
    id: int
    status: str

    class Config:
        orm_mode = True
