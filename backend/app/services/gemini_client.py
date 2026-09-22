import os
import time
import json
import logging
import google.generativeai as genai
from dotenv import load_dotenv
from app.services.dataset_service import DatasetService

logger = logging.getLogger(__name__)

load_dotenv()
api_key = os.environ.get("GEMINI_API_KEY", "")
if api_key:
    genai.configure(api_key=api_key)
else:
    logger.warning("GEMINI_API_KEY is not set.")

class GeminiClient:
    def __init__(self):
        # We will use gemini-3.8-flash which works with the new token
        self._model_name = "models/gemini-3.8-flash"
        self._dataset_service = DatasetService()

    def _call_gemini(self, prompt: str, operation: str, business_id: int, user_id: int, order_id: int, system_instruction: str = None) -> str:
        """Helper to invoke Gemini."""
        start = time.time()
        try:
            model = genai.GenerativeModel(
                model_name=self._model_name,
                system_instruction=system_instruction
            )
            response = model.generate_content(
                prompt,
                generation_config=genai.types.GenerationConfig(
                    response_mime_type="application/json",
                ),
            )
            elapsed = time.time() - start
            logger.info(f"AI [{operation}] ok business={business_id} user={user_id} order={order_id} time={elapsed:.2f}s")
            return response.text
        except Exception as e:
            elapsed = time.time() - start
            logger.error(f"AI [{operation}] error business={business_id} user={user_id} time={elapsed:.2f}s err={e}")
            raise e

    def predict_measurements(self, 
                             garment_type: str, 
                             provided_measurements: dict, 
                             business_id: int, 
                             user_id: int, 
                             order_id: int) -> dict:
        
        # 1. Fetch exact match if it exists
        exact_match = self._dataset_service.get_exact_match(garment_type, provided_measurements)
        
        # 2. Fetch context
        context = self._dataset_service.get_dataset_context(garment_type)
        
        system_instruction = f"""
You are the AI intelligence engine for TailorSync.
Role: Predict missing measurements for a garment.
Rules:
1. Analyze the provided dataset context.
2. If an EXACT MATCH is provided, use its values as the primary recommendation.
3. Look for variation in similar records to provide alternatives.
4. Do NOT fake precision (e.g., if data uses '10 1/2', don't use '10.51').
5. Output strict JSON exactly matching the requested format.

{context}
"""
        
        exact_match_str = ""
        if exact_match:
            exact_match_str = f"Found an exact match in the dataset: {json.dumps(exact_match)}\nUse these values as the primary 'recommended' predictions where possible."

        prompt = f"""
Garment Type: {garment_type}
Tailor's Provided Measurements:
{json.dumps(provided_measurements, indent=2)}

{exact_match_str}

Predict the missing measurements appropriate for a {garment_type} based on the dataset.
Return ONLY a JSON object with this exact structure:
{{
  "predictions": [
    {{
      "measurement": "Name of missing measurement",
      "recommended": "Value as string, e.g. '12 1/2'",
      "alternatives": ["Alternative 1", "Alternative 2"],
      "reason": "Brief explanation"
    }}
  ]
}}
"""
        response_text = self._call_gemini(prompt, "predict_measurements", business_id, user_id, order_id, system_instruction)
        return json.loads(response_text)

    def recommend_fabric(self, 
                         garment_type: str, 
                         occasion: str, 
                         weather: str, 
                         fabric_preferences: list, 
                         fit: str, 
                         business_id: int, 
                         user_id: int, 
                         order_id: int) -> dict:
        
        system_instruction = """
You are the AI fabric advisor for TailorSync.
Rules:
1. Recommend exactly 3 fabrics based on garment, occasion, weather, and preferences.
2. Provide a 'suitability_percentage' (e.g. 91).
3. Return strict JSON.
"""
        
        prompt = f"""
Recommend fabrics for a {garment_type}.
Preferences:
- Occasion: {occasion}
- Weather: {weather}
- Fabric Feel: {', '.join(fabric_preferences)}
- Fit: {fit}

Return ONLY a JSON object with exactly 3 recommendations in this structure:
{{
  "recommendations": [
    {{
      "fabric_name": "Linen",
      "suitability_percentage": 91,
      "reason": "Highly suitable for hot weather because it is breathable."
    }}
  ]
}}
"""
        response_text = self._call_gemini(prompt, "recommend_fabric", business_id, user_id, order_id, system_instruction)
        return json.loads(response_text)

    def estimate_fabric(self, 
                        garment_type: str, 
                        fabric: str, 
                        measurements: dict, 
                        business_id: int, 
                        user_id: int, 
                        order_id: int) -> dict:
        
        context = self._dataset_service.get_dataset_context(garment_type)
        
        system_instruction = f"""
You are the AI fabric estimator for TailorSync.
Rules:
1. Estimate fabric in meters based on the dataset.
2. For short trousers, use 'Fabric estimation_short in meter'.
3. For long trousers, use 'Fabric estimation_long in meter'.
4. Note that shirt datasets are based on 45-inch width, and trousers on 60-inch width.
5. Return strict JSON.

{context}
"""

        prompt = f"""
Garment Type: {garment_type}
Selected Fabric: {fabric}
Confirmed Measurements:
{json.dumps(measurements, indent=2)}

Estimate the required fabric quantity in meters based on the dataset.
Return ONLY a JSON object in this structure:
{{
  "recommended_quantity_meters": 2.10,
  "estimated_range": {{
    "min": 2.00,
    "max": 2.25
  }},
  "fabric_width_inches": 60,
  "reason": "Based on the matching height and waist in the dataset..."
}}
"""
        response_text = self._call_gemini(prompt, "estimate_fabric", business_id, user_id, order_id, system_instruction)
        return json.loads(response_text)
