import logging
import time
from azure.ai.projects import AIProjectClient
from azure.identity import DefaultAzureCredential
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
        credential = DefaultAzureCredential()
        self._client = AIProjectClient(
            endpoint=settings.AZURE_FOUNDRY_ENDPOINT,
            credential=credential
        )
        agents = self._client.agents.list()
        agent = next((a for a in agents if a.name == settings.AZURE_FOUNDRY_AGENT_NAME), None)
        if not agent:
            raise FoundryUnavailableError(f"Agent '{settings.AZURE_FOUNDRY_AGENT_NAME}' not found.")
        self._agent_id = agent.id

    def invoke_agent(self, prompt: str, operation: str = "",
                     user_id: int = None, business_id: int = None,
                     order_id: int = None) -> str:
        start = time.time()
        try:
            thread = self._client.agents.threads.create()
            self._client.agents.messages.create(
                thread_id=thread.id, role="user", content=prompt
            )
            run = self._client.agents.runs.create_and_process(
                thread_id=thread.id, agent_id=self._agent_id
            )
            if run.status != "completed":
                raise FoundryUnavailableError(f"Run status: {run.status}")

            messages = self._client.agents.messages.list(thread_id=thread.id)
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
