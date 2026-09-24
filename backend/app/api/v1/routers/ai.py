from fastapi import APIRouter, Depends, HTTPException
from app.api.deps import get_current_user, rate_limit_ai
from app.models.user import User
from app.schemas.ai import (
    MeasurementPredictIn, MeasurementPredictOut,
    FabricRecommendIn, FabricRecommendOut,
    FabricEstimateIn, FabricEstimateOut,
)

router = APIRouter()

@router.post("/predict-measurements", response_model=MeasurementPredictOut)
def predict(payload: MeasurementPredictIn, current_user: User = Depends(rate_limit_ai)):
    try:
        from app.services.ai_service import predict_measurements
        return predict_measurements(
            payload, current_user.user_id, current_user.business_id
        )
    except Exception as e:
        import traceback
        traceback.print_exc()
        raise HTTPException(
            status_code=503,
            detail=f"AI prediction unavailable: {str(e)}"
        )

@router.post("/recommend-fabric", response_model=FabricRecommendOut)
def recommend(payload: FabricRecommendIn, current_user: User = Depends(rate_limit_ai)):
    try:
        from app.services.ai_service import recommend_fabrics
        return recommend_fabrics(
            payload, current_user.user_id, current_user.business_id
        )
    except Exception as e:
        raise HTTPException(
            status_code=503,
            detail=f"AI recommendation unavailable: {str(e)}"
        )

@router.post("/estimate-fabric", response_model=FabricEstimateOut)
def estimate(payload: FabricEstimateIn, current_user: User = Depends(rate_limit_ai)):
    try:
        from app.services.ai_service import estimate_fabric
        return estimate_fabric(
            payload, current_user.user_id, current_user.business_id
        )
    except Exception as e:
        raise HTTPException(
            status_code=503,
            detail=f"AI estimation unavailable: {str(e)}"
        )
