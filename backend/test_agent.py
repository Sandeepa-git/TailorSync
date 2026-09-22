import os
from azure.ai.projects import AIProjectClient
from azure.identity import InteractiveBrowserCredential
from dotenv import load_dotenv
import traceback

load_dotenv()

# We will use the interactive browser credential to authenticate as YOU
credential = InteractiveBrowserCredential(tenant_id=os.environ.get("AZURE_TENANT_ID"))
endpoint = os.environ.get("AZURE_FOUNDRY_ENDPOINT")

print(f"Connecting to {endpoint}...")
project_client = AIProjectClient(
    endpoint=endpoint,
    credential=credential
)

openai_client = project_client.get_openai_client()

agent_name = "tailorsync-ai-agent"
print(f"Testing agent '{agent_name}'...")

versions_to_try = ["latest", "3", "1"]

for version in versions_to_try:
    print(f"\n--- Trying version '{version}' ---")
    try:
        response = openai_client.responses.create(
            input=[{"role": "user", "content": "Hello, testing!"}],
            extra_body={"agent_reference": {"name": agent_name, "version": version, "type": "agent_reference"}},
        )
        print("✅ SUCCESS!")
        print(response.output_text)
        break
    except Exception as e:
        print(f"❌ Failed: {e}")
