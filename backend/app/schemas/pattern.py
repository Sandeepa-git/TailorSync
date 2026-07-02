from pydantic import BaseModel
from typing import Optional, Dict, Any

class PatternCreate(BaseModel):
    name: str
    metadata: Optional[Dict[str, Any]]

class PatternRead(PatternCreate):
    id: int
    file_ref: Optional[str]
    width: Optional[float]
    height: Optional[float]

    class Config:
        orm_mode = True
