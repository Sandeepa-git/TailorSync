from fastapi import APIRouter, Depends, HTTPException
from app.api.deps import get_current_user
from app.models.user import User
from app.schemas.ai import (
    MeasurementPredictIn, MeasurementPredictOut,
    FabricRecommendIn, FabricRecommendOut,
    FabricEstimateIn, FabricEstimateOut,
)

router = APIRouter()

@router.post("/predict-measurements", response_model=MeasurementPredictOut)
def predict(payload: MeasurementPredictIn, current_user: User = Depends(get_current_user)):
    try:
        from app.services.ai_service import predict_measurements
        return predict_measurements(
            payload, current_user.user_id, current_user.business_id
        )
    except Exception as e:
        raise HTTPException(
            status_code=503,
            detail="AI prediction is temporarily unavailable. You can enter the measurements manually."
        )

@router.post("/recommend-fabric", response_model=FabricRecommendOut)
def recommend(payload: FabricRecommendIn, current_user: User = Depends(get_current_user)):
    try:
        from app.services.ai_service import recommend_fabrics
        return recommend_fabrics(
            payload, current_user.user_id, current_user.business_id
        )
    except Exception as e:
        raise HTTPException(
            status_code=503,
            detail="Fabric recommendations are temporarily unavailable. Please select a fabric manually."
        )

@router.post("/estimate-fabric", response_model=FabricEstimateOut)
def estimate(payload: FabricEstimateIn, current_user: User = Depends(get_current_user)):
    try:
        from app.services.ai_service import estimate_fabric
        return estimate_fabric(
            payload, current_user.user_id, current_user.business_id
        )
    except Exception as e:
        raise HTTPException(
            status_code=503,
            detail="Automatic fabric estimation is temporarily unavailable. Please enter the required quantity manually."
        )
