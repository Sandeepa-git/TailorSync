from fastapi import APIRouter, Depends, HTTPException
from app.api.deps import get_current_user, get_current_active_user, rate_limit_ai
from app.models.user import User
from app.schemas.ai import (
    MeasurementPredictIn, MeasurementPredictOut,
    FabricRecommendIn, FabricRecommendOut,
    FabricEstimateIn, FabricEstimateOut,
)

from app.schemas.ml import MLPredictIn, MLPredictOut, InputRangesOut
from app.services.ml_service import ml_service

router = APIRouter()

@router.get("/input-ranges/{garment_type}", response_model=InputRangesOut)
def get_input_ranges(garment_type: str, current_user: User = Depends(get_current_active_user)):
    try:
        ranges = ml_service.get_input_ranges(garment_type.lower())
        return InputRangesOut(garment_type=garment_type, ranges=ranges)
    except ValueError as e:
        raise HTTPException(status_code=422, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/predict-measurements", response_model=MLPredictOut)
def predict_ml(payload: MLPredictIn, current_user: User = Depends(get_current_active_user)):
    try:
        options = ml_service.predict_measurements(payload)
        return MLPredictOut(options=options)
    except ValueError as e:
        raise HTTPException(status_code=422, detail=str(e))
    except Exception as e:
        import traceback
        traceback.print_exc()
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/foundry-predict", response_model=MeasurementPredictOut)
def predict_foundry(payload: MeasurementPredictIn, current_user: User = Depends(rate_limit_ai)):
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
