class FabricRecommender:
    def recommend(self, garment_type: str, occasion: str, style: str, budget: str) -> dict:
        # placeholder rules-based recommender
        recs = []
        if garment_type.lower() == "suit":
            recs = [
                {"name": "Wool Mix", "suitable_for": ["formal"], "approx_price": "high"},
                {"name": "Poly Wool", "suitable_for": ["formal"], "approx_price": "medium"}
            ]
        else:
            recs = [
                {"name": "Cotton", "suitable_for": ["casual"], "approx_price": "low"},
                {"name": "Linen", "suitable_for": ["summer"], "approx_price": "medium"}
            ]
        return {"recommendations": recs}
