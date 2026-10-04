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

        # Foundry AGENT settings (preferred). When FOUNDRY_PROJECT_ENDPOINT is set,
        # requests go to the configured agent (its own instructions + files);
        # the plain model deployment above is only used as a fallback.
        self.project_endpoint = os.environ.get("FOUNDRY_PROJECT_ENDPOINT", "").strip()
        self.agent_name = os.environ.get("FOUNDRY_AGENT_NAME", "tailorsync-ai-agent").strip()
        self.agent_version = os.environ.get("FOUNDRY_AGENT_VERSION", "").strip()
        self._agent_client = None
        
        if not self.endpoint:
            logger.warning("FOUNDRY_ENDPOINT is not set.")
        if not self.api_key:
            logger.warning("FOUNDRY_API_KEY is not set.")
            
        try:
            if self.api_key:
                # Local dev: Using API Key authentication
                from azure.core.credentials import AzureKeyCredential
                credential = AzureKeyCredential(self.api_key)
            else:
                # Production: Using Managed Identity
                from azure.identity import DefaultAzureCredential
                credential = DefaultAzureCredential()

            self.client = ChatCompletionsClient(
                endpoint=self.endpoint,
                credential=credential,
                credential_scopes=["https://cognitiveservices.azure.com/.default"]
            )
        except Exception as e:
            logger.error(f"Failed to initialize FoundryClient: {e}")
            self.client = None

        self._dataset_service = DatasetService()

    # ------------------------------------------------------------------ agent
    def _get_agent_client(self):
        """OpenAI-compatible client bound to the Foundry project (Entra ID auth)."""
        if self._agent_client is None:
            from azure.ai.projects import AIProjectClient
            from azure.identity import DefaultAzureCredential

            project = AIProjectClient(endpoint=self.project_endpoint, credential=DefaultAzureCredential())
            self._agent_client = project.get_openai_client()
        return self._agent_client

    def _call_agent(self, prompt: str, task_context: str) -> str:
        agent_ref = {"name": self.agent_name, "type": "agent_reference"}
        if self.agent_version:
            agent_ref["version"] = self.agent_version
        # The agent keeps its own instructions/files; we only add the task details.
        message = f"{task_context.strip()}\n\n{prompt.strip()}"
        response = self._get_agent_client().responses.create(
            input=[{"role": "user", "content": message}],
            extra_body={"agent_reference": agent_ref},
        )
        logger.info(f"Foundry agent '{self.agent_name}' answered")
        return response.output_text

    def _call_model(self, prompt: str, system_instruction: str) -> str:
        if not self.client:
            raise ValueError("Foundry client is not initialized properly. Check credentials and endpoint.")
        response = self.client.complete(
            messages=[
                SystemMessage(content=system_instruction),
                UserMessage(content=prompt),
            ],
            model=self.model_name
        )
        logger.info(f"Foundry model '{self.model_name}' answered (fallback / no agent configured)")
        return response.choices[0].message.content

    def _call_foundry(self, prompt: str, system_instruction: str) -> str:
        try:
            content = None
            if self.project_endpoint:
                try:
                    content = self._call_agent(prompt, system_instruction)
                except Exception as agent_err:
                    logger.error(f"Foundry agent call failed, falling back to model: {agent_err}")
            if content is None:
                content = self._call_model(prompt, system_instruction)
            
            # Robust JSON extraction: Find content between ```json and ``` or first { and last }
            import re
            json_match = re.search(r'```(?:json)?\s*(.*?)\s*```', content, re.DOTALL)
            if json_match:
                content = json_match.group(1)
            else:
                # Fallback to finding outermost brackets
                start_idx = content.find('{')
                end_idx = content.rfind('}')
                if start_idx != -1 and end_idx != -1 and end_idx > start_idx:
                    content = content[start_idx:end_idx+1]
                    
            content = content.strip()
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
5. IMPORTANT: Never return empty strings for measurements. You MUST provide a concrete numerical prediction for every missing measurement.

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
        response_text = self._call_foundry(prompt, system_instruction)
        result = json.loads(response_text)
        
        # Sanitize the output to guarantee no empty measurements
        if "predictions" in result:
            for p in result["predictions"]:
                if not p.get("recommended") or p.get("recommended").strip() == "":
                    p["recommended"] = "0" # Safe fallback
        
        return result

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
