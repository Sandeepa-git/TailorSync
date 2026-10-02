import joblib
import json

def test_load():
    model_data = joblib.load("c:/Users/Sandeepa/Desktop/TailorSync/backend/models/shirt_measurement_model.joblib")
    print(model_data.keys())
    
    # print input/output columns and ranges to understand format
    print("Input cols:", model_data.get("input_cols"))
    print("Output cols:", model_data.get("output_cols"))
    print("Input ranges:", model_data.get("input_ranges"))
    print("Settings:", model_data.get("settings"))
    
if __name__ == "__main__":
    test_load()
