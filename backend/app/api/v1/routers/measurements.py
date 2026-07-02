from fastapi import APIRouter

router = APIRouter()

@router.post("/predict")
def predict_measurements():
    return {"predictions": {}}

@router.get("/orders/{order_id}")
def get_measurements(order_id: int):
    return {"order_id": order_id, "measurements": []}
