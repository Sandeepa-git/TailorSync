class FabricEstimator:
    def estimate_length(self, garment_type: str, measurements: dict) -> dict:
        # simple heuristic: sum of key vertical measurements / 100 -> meters
        total_cm = 0
        for k, v in measurements.items():
            try:
                total_cm += float(v)
            except Exception:
                continue
        length_m = max(0.5, total_cm / 100)
        return {"required_length_m": round(length_m, 2)}
