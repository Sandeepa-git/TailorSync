import os
import json
import logging
import time
from azure.ai.inference import ChatCompletionsClient
from azure.ai.inference.models import SystemMessage, UserMessage
from app.services.dataset_service import DatasetService

logger = logging.getLogger(__name__)

class FoundryClient:
    def __init__(self):
        self.endpoint = os.environ.get("FOUNDRY_ENDPOINT", "")
        self.api_key = os.environ.get("FOUNDRY_API_KEY", "")
        self.model_name = os.environ.get("FOUNDRY_MODEL_NAME", "gpt-4o")
        
        self.project_endpoint = os.environ.get("FOUNDRY_PROJECT_ENDPOINT", "")
        self.agent_name = os.environ.get("FOUNDRY_AGENT_NAME", "ts-ai-agent")
        self.agent_version = os.environ.get("FOUNDRY_AGENT_VERSION", "")
        self.use_foundry_agent = os.environ.get("USE_FOUNDRY_AGENT", "false").lower() == "true"
        
        if not self.endpoint and not self.use_foundry_agent:
            logger.warning("FOUNDRY_ENDPOINT is not set.")
        if not self.api_key and not self.use_foundry_agent:
            logger.warning("FOUNDRY_API_KEY is not set.")
            
        # Initialize Direct Model Client
        try:
            if self.api_key:
                from azure.core.credentials import AzureKeyCredential
                credential = AzureKeyCredential(self.api_key)
            else:
                from azure.identity import DefaultAzureCredential
                credential = DefaultAzureCredential()

            self.client = ChatCompletionsClient(
                endpoint=self.endpoint,
                credential=credential,
                credential_scopes=["https://cognitiveservices.azure.com/.default"]
            )
        except Exception as e:
            logger.error(f"Failed to initialize FoundryClient (direct model): {e}")
            self.client = None

        # Initialize Agent Client
        self._agent_init_error = None
        try:
            if self.use_foundry_agent and self.project_endpoint:
                from azure.ai.projects import AIProjectClient
                from azure.identity import DefaultAzureCredential
                logger.info(f"Initializing AIProjectClient with endpoint: {self.project_endpoint}")
                self.project_client = AIProjectClient(
                    endpoint=self.project_endpoint, 
                    credential=DefaultAzureCredential()
                )
                logger.info("AIProjectClient created, getting OpenAI client...")
                self.agent_client = self.project_client.get_openai_client()
                logger.info("Agent OpenAI client initialized successfully.")
            else:
                self.project_client = None
                self.agent_client = None
                if self.use_foundry_agent and not self.project_endpoint:
                    self._agent_init_error = "USE_FOUNDRY_AGENT is true but FOUNDRY_PROJECT_ENDPOINT is empty"
                    logger.error(self._agent_init_error)
        except Exception as e:
            self._agent_init_error = f"Failed to initialize AIProjectClient: {e}"
            logger.error(self._agent_init_error, exc_info=True)
            self.project_client = None
            self.agent_client = None

        self._dataset_service = DatasetService()

    def _extract_json(self, content: str, raw_original: str = None) -> str:
        import re
        json_match = re.search(r'```(?:json)?\s*(.*?)\s*```', content, re.DOTALL)
        if json_match:
            extracted = json_match.group(1)
        else:
            start_idx = content.find('{')
            end_idx = content.rfind('}')
            if start_idx != -1 and end_idx != -1 and end_idx > start_idx:
                extracted = content[start_idx:end_idx+1]
            else:
                extracted = content
                
        extracted = extracted.strip()
        
        try:
            json.loads(extracted)
        except json.JSONDecodeError:
            raw = raw_original if raw_original else content
            logger.error(f"Invalid JSON received from AI. Raw response: {raw}")
            raise ValueError(f"The AI did not return valid JSON. Raw response: {raw}")
            
        return extracted

    def _call_foundry_agent(self, prompt: str) -> str:
        agent_ref = {
            "name": self.agent_name,
            "type": "agent_reference"
        }
        if self.agent_version:
            agent_ref["version"] = self.agent_version
            
        start_time = time.time()
        
        # We will use the REST API directly because the SDK sometimes throws 403 
        # on managed identities due to strict workspace-level role checks.
        import requests
        from azure.identity import DefaultAzureCredential
        
        try:
            cred = DefaultAzureCredential()
            token = cred.get_token("https://cognitiveservices.azure.com/.default").token
            
            # The fallback endpoint format
            endpoint = f"{self.project_endpoint}/agents/{self.agent_name}/endpoint/protocols/openai/responses"
            
            headers = {
                "Authorization": f"Bearer {token}",
                "Content-Type": "application/json"
            }
            
            payload = {
                "input": prompt,
                "agent_reference": agent_ref
            }
            
            resp = requests.post(endpoint, json=payload, headers=headers, timeout=90.0)
            
            if resp.status_code != 200:
                raise ValueError(f"Foundry Agent request failed: {resp.status_code} {resp.text}")
                
            elapsed = time.time() - start_time
            logger.info(f"Agent response time (REST API): {elapsed:.2f}s")
            
            raw_text = resp.json().get("output_text", "")
            return self._extract_json(raw_text, raw_original=raw_text)
            
        except Exception as e:
            logger.error(f"Foundry API Agent error: {e}")
            raise ValueError(f"Foundry Agent request failed: {e}")
        except Exception as e:
            logger.error(f"Agent API error: {e}")
            raise ValueError(f"Foundry Agent request failed: {e}")

    def _call_foundry(self, prompt: str, system_instruction: str) -> str:
        if not self.client:
            raise ValueError("Foundry client is not initialized properly. Check credentials and endpoint.")
            
        total_prompt_length = len(prompt) + len(system_instruction)
        logger.info(f"Sending request to Foundry. Total prompt length (characters): {total_prompt_length}")
            
        start_time = time.time()
        try:
            response = self.client.complete(
                messages=[
                    SystemMessage(content=system_instruction),
                    UserMessage(content=prompt),
                ],
                model=self.model_name
            )
            elapsed = time.time() - start_time
            logger.info(f"Direct model response time: {elapsed:.2f}s")
            
            if hasattr(response, 'usage') and response.usage:
                usage = response.usage
                prompt_tokens = getattr(usage, 'prompt_tokens', 'N/A')
                completion_tokens = getattr(usage, 'completion_tokens', 'N/A')
                total_tokens = getattr(usage, 'total_tokens', 'N/A')
                logger.info(f"Foundry Usage - Prompt tokens: {prompt_tokens}, Completion tokens: {completion_tokens}, Total tokens: {total_tokens}")
            
            raw_text = response.choices[0].message.content
            return self._extract_json(raw_text, raw_original=raw_text)
        except Exception as e:
            logger.error(f"Foundry API error: {e}")
            raise ValueError(f"Direct model request failed: {e}")

    def predict_measurements(self, garment_type: str, provided_measurements: dict) -> dict:
        if self.use_foundry_agent:
            prompt = f"""
Task: predict_measurements
Garment Type: {garment_type}
Tailor's Provided Measurements:
{json.dumps(provided_measurements, indent=2)}

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
            response_text = self._call_foundry_agent(prompt)
            return json.loads(response_text)
            
        # Old Direct Model Logic
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
        if self.use_foundry_agent:
            prompt = f"""
Task: recommend_fabric
Garment Type: {garment_type}
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

        # Old Direct Model Logic
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
        if self.use_foundry_agent:
            prompt = f"""
Task: estimate_fabric
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
            response_text = self._call_foundry_agent(prompt)
            return json.loads(response_text)

        # Old Direct Model Logic
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
