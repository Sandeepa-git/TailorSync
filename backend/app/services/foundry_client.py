import logging
import time
from azure.ai.projects import AIProjectClient
from azure.identity import InteractiveBrowserCredential, DefaultAzureCredential
import os
from azure.ai.agents.models import AgentThreadCreationOptions, ThreadMessageOptions
from app.core.config import settings

logger = logging.getLogger(__name__)

class FoundryUnavailableError(Exception):
    pass

class FoundryClient:
    _instance = None
    _client = None
    _agent_id = None

    @classmethod
    def get_instance(cls):
        if cls._instance is None:
            cls._instance = cls()
            cls._instance._initialize()
        return cls._instance

    def _initialize(self):
        if os.environ.get("WEBSITE_SITE_NAME"):
            logger.info("Running in Azure App Service, using DefaultAzureCredential")
            credential = DefaultAzureCredential()
        else:
            logger.info("Running locally, using InteractiveBrowserCredential")
            credential = InteractiveBrowserCredential(tenant_id=settings.AZURE_TENANT_ID)
        self._client = AIProjectClient(
            endpoint=settings.AZURE_FOUNDRY_ENDPOINT,
            credential=credential
        )
        agents = self._client.agents.list_agents()
        agent = next((a for a in agents if a.name.lower() == settings.AZURE_FOUNDRY_AGENT_NAME.lower()), None)
        if not agent:
            raise FoundryUnavailableError(f"Agent '{settings.AZURE_FOUNDRY_AGENT_NAME}' not found.")
        self._agent_id = agent.id
        logger.info(f"AI agent '{agent.name}' connected (id: {agent.id})")

    def invoke_agent(self, prompt: str, operation: str = "",
                     user_id: int = None, business_id: int = None,
                     order_id: int = None) -> str:
        start = time.time()
        try:
            thread_options = AgentThreadCreationOptions(
                messages=[
                    ThreadMessageOptions(role="user", content=prompt)
                ]
            )
            run = self._client.agents.create_thread_and_process_run(
                assistant_id=self._agent_id,
                thread=thread_options
            )

            if run.status != "completed":
                raise FoundryUnavailableError(f"Run status: {run.status}")

            messages = self._client.agents.messages.list(thread_id=run.thread_id)
            for msg in messages:
                if msg.role == "assistant":
                    elapsed = time.time() - start
                    logger.info(f"AI [{operation}] ok business={business_id} "
                               f"user={user_id} order={order_id} "
                               f"time={elapsed:.2f}s")
                    return msg.content[0].text.value

            raise FoundryUnavailableError("No assistant response")
        except FoundryUnavailableError:
            raise
        except Exception as e:
            elapsed = time.time() - start
            logger.error(f"AI [{operation}] FAIL business={business_id} "
                        f"user={user_id} order={order_id} "
                        f"time={elapsed:.2f}s error={type(e).__name__}: {e}")
            raise FoundryUnavailableError(str(e))
