from fastapi import APIRouter
from typing import List
from app.schemas.report import ReportList, ReportSummary

router = APIRouter()


@router.get("/dashboard", response_model=ReportList)
def dashboard(from_date: str = None, to_date: str = None):
    # TODO: implement aggregates
    return {"items": []}


@router.get("/staff-performance", response_model=ReportList)
def staff_performance(from_date: str = None, to_date: str = None):
    return {"items": []}
