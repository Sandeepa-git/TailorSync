import os
import json
import logging
from azure.ai.inference import ChatCompletionsClient
from azure.ai.inference.models import SystemMessage, UserMessage
from azure.core.credentials import AzureKeyCredential
from app.services.dataset_service import DatasetService

logger = logging.getLogger(__name__)

class FoundryClient:
    def __init__(self):
        self.endpoint = os.environ.get("FOUNDRY_ENDPOINT", "")
        self.api_key = os.environ.get("FOUNDRY_API_KEY", "")
        self.model_name = os.environ.get("FOUNDRY_MODEL_NAME", "gpt-4o")
        
        if not self.endpoint:
            logger.warning("FOUNDRY_ENDPOINT is not set.")
        if not self.api_key:
            logger.warning("FOUNDRY_API_KEY is not set.")
            
        try:
            # Using API Key authentication
            credential = AzureKeyCredential(self.api_key)
            self.client = ChatCompletionsClient(
                endpoint=self.endpoint,
                credential=credential,
            )
        except Exception as e:
            logger.error(f"Failed to initialize FoundryClient with Entra ID: {e}")
            self.client = None

        self._dataset_service = DatasetService()

    def _call_foundry(self, prompt: str, system_instruction: str) -> str:
        if not self.client:
            raise ValueError("Foundry client is not initialized properly. Check credentials and endpoint.")
            
        try:
            response = self.client.complete(
                messages=[
                    SystemMessage(content=system_instruction),
                    UserMessage(content=prompt),
                ],
                model=self.model_name
            )
            content = response.choices[0].message.content
            # Basic cleanup in case it returns markdown JSON
            if content.startswith("```json"):
                content = content.replace("```json", "").replace("```", "").strip()
            elif content.startswith("```"):
                content = content.replace("```", "").strip()
            return content
        except Exception as e:
            logger.error(f"Foundry API error: {e}")
            raise e

    def predict_measurements(self, garment_type: str, provided_measurements: dict) -> dict:
        exact_match = self._dataset_service.get_exact_match(garment_type, provided_measurements)
        context = self._dataset_service.get_dataset_context(garment_type)
        
        system_instruction = f"""
You are the AI intelligence engine for TailorSync.
Role: Predict missing measurements for a garment.
Rules:
1. Analyze the provided dataset context.
2. If an EXACT MATCH is provided, use its values as the primary recommendation.
3. Look for variation in similar records to provide alternatives.
4. Output strict JSON exactly matching the requested format.

Dataset Context:
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
      "recommended": "Value as string",
      "alternatives": ["Alternative 1", "Alternative 2"],
      "reason": "Brief explanation"
    }}
  ]
}}
"""
        response_text = self._call_foundry(prompt, system_instruction)
        return json.loads(response_text)

    def recommend_fabric(self, garment_type: str, occasion: str, weather: str, fabric_preferences: list, fit: str) -> dict:
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
        response_text = self._call_foundry(prompt, system_instruction)
        return json.loads(response_text)

    def estimate_fabric(self, garment_type: str, fabric: str, measurements: dict) -> dict:
        context = self._dataset_service.get_dataset_context(garment_type)
        system_instruction = f"""
You are the AI fabric estimator for TailorSync.
Rules:
1. Estimate fabric in meters based on the dataset.
2. For short trousers, use 'Fabric estimation_short in meter'.
3. For long trousers, use 'Fabric estimation_long in meter'.
4. Note that shirt datasets are based on 45-inch width, and trousers on 60-inch width.
5. Return strict JSON.

Dataset Context:
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
        response_text = self._call_foundry(prompt, system_instruction)
        return json.loads(response_text)
