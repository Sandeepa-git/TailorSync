from pydantic import BaseModel
from typing import Any, Dict, List, Optional

class ReportSummary(BaseModel):
    period: str
    metrics: Dict[str, Any]

class ReportList(BaseModel):
    items: List[ReportSummary]
