import joblib
import os
import numpy as np
from sklearn.cluster import KMeans
import logging
from app.schemas.ml import MLPredictIn

logger = logging.getLogger(__name__)

class MLMeasurementService:
    def __init__(self):
        self.models = {}
        
    def load_models(self):
        models_dir = os.path.join(os.path.dirname(os.path.dirname(os.path.dirname(__file__))), 'models')
        try:
            self.models['shirt'] = joblib.load(os.path.join(models_dir, 'shirt_measurement_model.joblib'))
            self.models['trouser'] = joblib.load(os.path.join(models_dir, 'trouser_measurement_model.joblib'))
            logger.info("ML Models loaded successfully.")
        except Exception as e:
            logger.error(f"Failed to load ML models: {e}")
            raise e

    def get_input_ranges(self, garment_type: str):
        if garment_type not in self.models:
            raise ValueError(f"Unknown garment type: {garment_type}")
        ranges_tuple = self.models[garment_type]["input_ranges"]
        
        ranges = {}
        for col, (min_v, max_v) in ranges_tuple.items():
            # e.g., 'Shoulder' -> 'shoulder'
            ranges[col.lower()] = {"min": min_v, "max": max_v}
        return ranges

    def predict_measurements(self, request: MLPredictIn):
        garment_type = request.garment_type
        if garment_type not in self.models:
            raise ValueError(f"Unknown garment type: {garment_type}")
        
        model_data = self.models[garment_type]
        model = model_data["model"]
        input_cols = model_data["input_cols"]
        output_cols = model_data["output_cols"]
        input_ranges = model_data["input_ranges"]
        nn_index = model_data["nn_index"]
        train_outputs = model_data["y_values"]
        
        # Validation
        X = []
        for col in input_cols:
            col_lower = col.lower()
            val = getattr(request, col_lower, None)
            if val is None:
                raise ValueError(f"Missing required field: {col_lower}")
            val = float(val)
            min_val, max_val = input_ranges[col]
            if val < min_val or val > max_val:
                raise ValueError(f"{col} must be between {min_val} and {max_val} inches.")
            X.append(val)
        
        X_arr = np.array([X])
        
        # 1. Central Model Prediction
        central_pred = model.predict(X_arr)[0]
        central_pred = self._snap_to_quarter(central_pred)
        
        def format_out(vals):
            # 'Collar Size' -> 'collar_size'
            return {col.lower().replace(" ", "_"): val for col, val in zip(output_cols, vals)}
            
        options = []
        options.append({
            "option_number": 1,
            "source": "model_central",
            "support_percent": None,
            "measurements": format_out(central_pred)
        })
        
        # 2. Model Modes (Trees)
        tree_preds = []
        for estimator in model.estimators_:
            tree_pred = estimator.predict(X_arr)[0]
            tree_preds.append(tree_pred)
            
        tree_preds = np.array(tree_preds)
        n_trees = len(tree_preds)
        
        kmeans = KMeans(n_clusters=min(5, n_trees), random_state=42)
        kmeans.fit(tree_preds)
        
        # Calculate support
        unique, counts = np.unique(kmeans.labels_, return_counts=True)
        cluster_info = []
        for cluster_id, count in zip(unique, counts):
            support = count / n_trees
            center = kmeans.cluster_centers_[cluster_id]
            snapped_center = self._snap_to_quarter(center)
            cluster_info.append({
                "center": snapped_center,
                "support": support
            })
            
        # Sort by support descending
        cluster_info.sort(key=lambda x: x["support"], reverse=True)
        
        for info in cluster_info:
            if len(options) >= 5:
                break
            
            support = info["support"]
            center = info["center"]
            
            # Minimum support 10%
            if support < 0.10:
                continue
                
            # Plausibility: within 1.5 inches of central prediction
            if np.any(np.abs(center - central_pred) > 1.5):
                continue
                
            # Difference from existing options: at least 0.5 inch in at least one measurement
            differs = True
            for opt in options:
                # convert dict values back to array for comparison in correct order
                opt_vals = np.array([opt["measurements"][col.lower().replace(" ", "_")] for col in output_cols])
                if not np.any(np.abs(center - opt_vals) >= 0.5):
                    differs = False
                    break
                    
            if differs:
                options.append({
                    "option_number": len(options) + 1,
                    "source": "model_mode",
                    "support_percent": round(support * 100, 2),
                    "measurements": format_out(center)
                })
                
        # 3. Similar Training Record Options
        if len(options) < 5:
            distances, indices = nn_index.kneighbors(X_arr, n_neighbors=20)
            for idx in indices[0]:
                if len(options) >= 5:
                    break
                record = train_outputs.iloc[idx].values if hasattr(train_outputs, 'iloc') else train_outputs[idx]
                snapped_record = self._snap_to_quarter(record)
                
                # Plausibility
                if np.any(np.abs(snapped_record - central_pred) > 1.5):
                    continue
                    
                # Difference
                differs = True
                for opt in options:
                    opt_vals = np.array([opt["measurements"][col.lower().replace(" ", "_")] for col in output_cols])
                    if not np.any(np.abs(snapped_record - opt_vals) >= 0.5):
                        differs = False
                        break
                        
                if differs:
                    options.append({
                        "option_number": len(options) + 1,
                        "source": "similar_record",
                        "support_percent": None,
                        "measurements": format_out(snapped_record)
                    })
                    
        return options

    def _snap_to_quarter(self, vals):
        return np.round(vals * 4) / 4

ml_service = MLMeasurementService()
