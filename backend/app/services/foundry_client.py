import logging
import time
from azure.ai.projects import AIProjectClient
from azure.identity import InteractiveBrowserCredential, DefaultAzureCredential
import os
from app.core.config import settings

logger = logging.getLogger(__name__)

class FoundryUnavailableError(Exception):
    pass

class FoundryClient:
    _instance = None
    _project_client = None
    _openai_client = None

    @classmethod
    def get_instance(cls):
        if cls._instance is None:
            inst = cls()
            try:
                inst._initialize()
                cls._instance = inst
            except Exception:
                cls._instance = None
                raise
        return cls._instance

    def _initialize(self):
        if os.environ.get("WEBSITE_SITE_NAME"):
            logger.info("Running in Azure App Service, using DefaultAzureCredential")
            credential = DefaultAzureCredential()
        else:
            logger.info("Running locally, using InteractiveBrowserCredential")
            credential = InteractiveBrowserCredential(tenant_id=settings.AZURE_TENANT_ID)
            
        self._project_client = AIProjectClient(
            endpoint=settings.AZURE_FOUNDRY_ENDPOINT,
            credential=credential
        )
        self._openai_client = self._project_client.get_openai_client()
        logger.info(f"AI OpenAI client connected to {settings.AZURE_FOUNDRY_ENDPOINT}")

    def invoke_agent(self, prompt: str, operation: str = "",
                     user_id: int = None, business_id: int = None,
                     order_id: int = None) -> str:
        start = time.time()
        try:
            # Use the new agent_reference approach from Azure AI Projects >=2.1.0
            my_agent = settings.AZURE_FOUNDRY_AGENT_NAME
            # In the user's snippet, version was '3', if not provided via env, we default to "3".
            # Using 'latest' or skipping version might be allowed, but we'll stick to '3' as requested.
            my_version = "3"
            
            response = self._openai_client.responses.create(
                input=[{"role": "user", "content": prompt}],
                extra_body={"agent_reference": {"name": my_agent, "version": my_version, "type": "agent_reference"}},
            )
            
            elapsed = time.time() - start
            logger.info(f"AI [{operation}] ok business={business_id} "
                       f"user={user_id} order={order_id} "
                       f"time={elapsed:.2f}s")
                       
            return response.output_text
            
        except Exception as e:
            elapsed = time.time() - start
            logger.error(f"AI [{operation}] FAIL business={business_id} "
                        f"user={user_id} order={order_id} "
                        f"time={elapsed:.2f}s error={type(e).__name__}: {e}")
            raise FoundryUnavailableError(str(e))
