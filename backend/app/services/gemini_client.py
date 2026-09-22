import os
import time
import json
import logging
import google.generativeai as genai
from app.core.config import settings

logger = logging.getLogger(__name__)

# Try to configure Gemini
api_key = os.environ.get("GEMINI_API_KEY", "")
if api_key:
    genai.configure(api_key=api_key)
else:
    logger.warning("GEMINI_API_KEY is not set. Gemini AI will not work.")

# The master instructions given by the user
MASTER_INSTRUCTIONS = """
# TailorSync AI — Master Agent Instructions

## 1. ROLE
You are the AI intelligence engine for **TailorSync**, a tailoring management application.
Your responsibilities are:
1. Predict missing garment/body measurements from measurements supplied by the tailor.
2. Recommend suitable fabrics based on garment type and customer preferences.
3. Estimate the required fabric quantity for the selected garment and fabric width.
4. Use the TailorSync datasets provided below as the primary evidence for numerical predictions and fabric calculations.
5. Use your general tailoring, garment-construction, fabric, and measurement knowledge to reason about the retrieved data and produce sensible recommendations.
Your outputs are recommendations and estimates, not guaranteed physical measurements.

## 2. KNOWLEDGE AND DATA USAGE
Below, you are provided with TailorSync tailoring measurement datasets in CSV format.
Whenever a request requires information that can be obtained from the datasets:
Always retrieve and inspect the relevant data before producing the answer.
The provided datasets are the primary source for measurement relationships, missing-measurement prediction, fabric quantity estimation, garment-specific fabric usage, and fabric-width-specific estimates.

## 3. MULTIPLE POSSIBILITIES FOR MISSING MEASUREMENTS
Because human body proportions vary, do not assume that one measurement has only one possible value.
For each missing measurement, provide:
- `recommended`: primary suggested value
- `alternatives`: 1–2 other plausible values when meaningful
- `reason`: short explanation based on the retrieved data and body-proportion reasoning

## 4. FABRIC RECOMMENDATION
Return exactly three fabric recommendations. Rank them from highest suitability to lowest suitability.
Each recommendation must contain:
1. `fabric_name`: Fabric name
2. `suitability_percentage`: e.g. 91%
3. `reason`: Short reason

## 5. RESPONSE FORMAT
You must respond with ONLY raw, valid JSON. Do not include markdown formatting like ```json.
The structure of your JSON response must strictly match what the application requests.
"""

def get_datasets_context() -> str:
    """Reads all CSV files from the data directory and formats them into a prompt string."""
    data_dir = os.path.join(os.path.dirname(os.path.dirname(os.path.dirname(__file__))), 'data')
    if not os.path.exists(data_dir):
        return "No datasets available."
    
    context = "=== TAILORSYNC DATASETS ===\n\n"
    for filename in os.listdir(data_dir):
        if filename.endswith(".csv"):
            garment_name = filename.replace("_dataset.csv", "").replace("_", " ").title()
            context += f"--- {garment_name} Dataset ---\n"
            try:
                with open(os.path.join(data_dir, filename), 'r') as f:
                    context += f.read() + "\n\n"
            except Exception as e:
                logger.error(f"Error reading dataset {filename}: {e}")
    return context

class GeminiClient:
    def __init__(self):
        self._model = genai.GenerativeModel(
            model_name="gemini-1.5-flash",
            system_instruction=MASTER_INSTRUCTIONS + "\n\n" + get_datasets_context()
        )

    def _call_gemini(self, prompt: str, operation: str, business_id: int, user_id: int, order_id: int) -> str:
        """Helper to invoke Gemini 1.5 Flash."""
        start = time.time()
        try:
            response = self._model.generate_content(
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
        
        prompt = f"""
I have the following reference measurements for a {garment_type}:
{json.dumps(provided_measurements, indent=2)}

Please predict the missing measurements appropriate for a {garment_type} using the provided datasets.
Return ONLY a JSON object with this exact structure:
{{
  "predictions": [
    {{
      "measurement": "Name of missing measurement",
      "recommended": 12.5,
      "alternatives": [12.0, 13.0],
      "reason": "Explanation here"
    }}
  ]
}}
"""
        response_text = self._call_gemini(prompt, "predict_measurements", business_id, user_id, order_id)
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
      "suitability_percentage": "91%",
      "reason": "Highly suitable for hot weather..."
    }}
  ]
}}
"""
        response_text = self._call_gemini(prompt, "recommend_fabric", business_id, user_id, order_id)
        return json.loads(response_text)

    def estimate_fabric(self, 
                        garment_type: str, 
                        fabric: str, 
                        measurements: dict, 
                        business_id: int, 
                        user_id: int, 
                        order_id: int) -> dict:
        
        prompt = f"""
Estimate fabric quantity in meters for a {garment_type} made of {fabric}.
Measurements:
{json.dumps(measurements, indent=2)}

Return ONLY a JSON object in this structure:
{{
  "recommended_meters": 2.10,
  "fabric_width_inches": 60,
  "range": "2.00-2.25",
  "reason": "Based on the dataset..."
}}
"""
        response_text = self._call_gemini(prompt, "estimate_fabric", business_id, user_id, order_id)
        return json.loads(response_text)
