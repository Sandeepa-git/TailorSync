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
        self.use_foundry_agent = True
        self.project_endpoint = "https://tailorsync-ai-resource.services.ai.azure.com/api/projects/tailorsync-ai"
        self.agent_name = "ts-ai-agent"
        self.agent_version = "3"
        
        try:
            from azure.identity import DefaultAzureCredential
            from azure.ai.projects import AIProjectClient
            
            project_client = AIProjectClient(
                endpoint=self.project_endpoint,
                credential=DefaultAzureCredential(),
            )
            self.openai_client = project_client.get_openai_client()
        except Exception as e:
            logger.error(f"Failed to initialize AIProjectClient: {e}")
            self.openai_client = None

        self._dataset_service = DatasetService()

    def _call_foundry_agent(self, prompt: str) -> str:
        if not self.openai_client:
            raise ValueError("Foundry agent client is not initialized.")
        
        response = self.openai_client.responses.create(
            input=[{"role": "user", "content": prompt}],
            extra_body={
                "agent_reference": {
                    "name": self.agent_name, 
                    "version": self.agent_version, 
                    "type": "agent_reference"
                }
            },
        )
        content = response.output_text
        
        import re
        json_match = re.search(r'```(?:json)?\s*(.*?)\s*```', content, re.DOTALL)
        if json_match:
            content = json_match.group(1)
        else:
            start_idx = content.find('{')
            end_idx = content.rfind('}')
            if start_idx != -1 and end_idx != -1 and end_idx > start_idx:
                content = content[start_idx:end_idx+1]
                
        return content.strip()
    def predict_measurements(self, garment_type: str, provided_measurements: dict) -> dict:
        exact_match = self._dataset_service.get_exact_match(garment_type, provided_measurements)
        context = self._dataset_service.get_dataset_context(garment_type)
        
        exact_match_str = ""
        if exact_match:
            exact_match_str = f"Found an exact match in the dataset: {json.dumps(exact_match)}\nUse these values as the primary 'recommended' predictions where possible."

        prompt = f"""
Task: predict_measurements
Garment Type: {garment_type}
Tailor's Provided Measurements:
{json.dumps(provided_measurements, indent=2)}

Dataset Context:
{context}
{exact_match_str}

Predict ALL the missing measurements appropriate for a {garment_type} based on the dataset.
Ensure NO measurement is left empty.
Return ONLY a JSON object with this exact structure:
{{
  "predictions": [
    {{
      "measurement": "Name of missing measurement",
      "recommended": "Value as string (e.g. '32')",
      "alternatives": ["Alternative 1", "Alternative 2"],
      "reason": "Brief explanation"
    }}
  ]
}}
"""
        response_text = self._call_foundry_agent(prompt)
        result = json.loads(response_text)
        
        if "predictions" in result:
            for p in result["predictions"]:
                if not p.get("recommended") or p.get("recommended").strip() == "":
                    p["recommended"] = "0" 
        
        return result

    def recommend_fabric(self, garment_type: str, occasion: str, weather: str, fabric_preferences: list, fit: str) -> dict:
        prompt = f"""
Task: recommend_fabric
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
        response_text = self._call_foundry_agent(prompt)
        return json.loads(response_text)

    def estimate_fabric(self, garment_type: str, fabric: str, measurements: dict) -> dict:
        context = self._dataset_service.get_dataset_context(garment_type)
        
        prompt = f"""
Task: estimate_fabric
Garment Type: {garment_type}
Selected Fabric: {fabric}
Confirmed Measurements:
{json.dumps(measurements, indent=2)}

Dataset Context:
{context}

Estimate the required fabric quantity in meters based on the dataset.
Note that shirt datasets are based on 45-inch width, and trousers on 60-inch width.
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
        response_text = self._call_foundry_agent(prompt)
        return json.loads(response_text)
