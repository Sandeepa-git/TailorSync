from fastapi import APIRouter
from app.api.v1.routers import auth, users, staff, customers, orders, measurements, reports, ai, business

api_router = APIRouter()

api_router.include_router(auth.router, prefix="/auth", tags=["auth"])
api_router.include_router(users.router, prefix="/users", tags=["users"])
api_router.include_router(staff.router, prefix="/staff", tags=["staff"])
api_router.include_router(customers.router, prefix="/customers", tags=["customers"])
api_router.include_router(orders.router, prefix="/orders", tags=["orders"])
api_router.include_router(measurements.router, prefix="/measurements", tags=["measurements"])
api_router.include_router(reports.router, prefix="/reports", tags=["reports"])
api_router.include_router(ai.router, prefix="/ai", tags=["ai"])
api_router.include_router(business.router, prefix="/business", tags=["business"])
