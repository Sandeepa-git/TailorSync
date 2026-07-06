from fastapi import APIRouter, Depends
from app.api.deps import get_current_user
from app.models.user import User

router = APIRouter()

@router.post("/predict")
def predict_measurements(current_user: User = Depends(get_current_user)):
    return {"predictions": {}}

@router.get("/orders/{order_id}")
def get_measurements(order_id: int, current_user: User = Depends(get_current_user)):
    return {"order_id": order_id, "measurements": []}
