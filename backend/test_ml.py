import pytest
from app.services.ml_service import ml_service
from app.schemas.ml import MLPredictIn

@pytest.fixture(autouse=True)
def load_models():
    ml_service.load_models()

def test_valid_shirt():
    req = MLPredictIn(garment_type="shirt", shoulder=10.0, height=30.0, chest=30.0)
    options = ml_service.predict_measurements(req)
    assert len(options) >= 1
    assert "collar_size" in options[0]["measurements"]

def test_valid_trouser():
    req = MLPredictIn(garment_type="trouser", height=30.0, waist=30.0, seat=35.0)
    options = ml_service.predict_measurements(req)
    assert len(options) >= 1
    assert "height_till_knee" in options[0]["measurements"]

def test_out_of_range():
    req = MLPredictIn(garment_type="shirt", shoulder=1.0, height=30.0, chest=30.0)
    with pytest.raises(ValueError) as e:
        ml_service.predict_measurements(req)
    assert "between" in str(e.value)

def test_missing_field():
    req = MLPredictIn(garment_type="shirt", shoulder=10.0, height=30.0)
    with pytest.raises(ValueError) as e:
        ml_service.predict_measurements(req)
    assert "Missing required field" in str(e.value)

def test_mid_range_input():
    req = MLPredictIn(garment_type="shirt", shoulder=10.0, height=30.0, chest=30.0)
    options = ml_service.predict_measurements(req)
    
    assert len(options) > 0
    # Option numbers sequential
    for i, opt in enumerate(options):
        assert opt["option_number"] == i + 1
        
        # Snapped to 0.25
        for m_val in opt["measurements"].values():
            assert (m_val * 4) % 1 == 0
            
        # valid sources
        assert opt["source"] in ["model_central", "model_mode", "similar_record"]
        
        # Support percentage
        if opt["source"] == "model_mode":
            assert opt["support_percent"] is not None
        else:
            assert opt["support_percent"] is None
