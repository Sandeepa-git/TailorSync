from fastapi import APIRouter
from app.schemas.ai import (
    PredictMeasurementsIn,
    PredictMeasurementsOut,
    FabricEstimateIn,
    FabricEstimateOut,
    RecommendFabricsIn,
    RecommendFabricsOut,
)

router = APIRouter()


@router.post("/predict-measurements", response_model=PredictMeasurementsOut)
def predict(payload: PredictMeasurementsIn):
    from app.services.ai_service import predict_measurements
    return {"predictions": predict_measurements(payload.profile)}


@router.post("/estimate-fabric", response_model=FabricEstimateOut)
def estimate(payload: FabricEstimateIn):
    from app.services.ai_service import estimate_fabric
    return estimate_fabric(payload.items, payload.measurements)


@router.post("/recommend-fabric", response_model=RecommendFabricsOut)
def recommend(payload: RecommendFabricsIn):
    from app.services.ai_service import recommend_fabrics
    return {"recommendations": recommend_fabrics(payload.style, payload.constraints)}
