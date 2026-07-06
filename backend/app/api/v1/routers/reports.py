from fastapi import APIRouter, Depends
from typing import List
from app.schemas.report import ReportList, ReportSummary
from app.api.deps import get_current_user
from app.models.user import User

router = APIRouter()


@router.get("/dashboard", response_model=ReportList)
def dashboard(from_date: str = None, to_date: str = None, current_user: User = Depends(get_current_user)):
    # TODO: implement aggregates
    return {"items": []}


@router.get("/staff-performance", response_model=ReportList)
def staff_performance(from_date: str = None, to_date: str = None, current_user: User = Depends(get_current_user)):
    return {"items": []}
