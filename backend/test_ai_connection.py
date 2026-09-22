"""Test Azure AI Foundry connection using Device Code login."""
import os
import sys
import time
from dotenv import load_dotenv

load_dotenv()

print("=" * 60)
print("  TailorSync - AI Agent Connection Test")
print("=" * 60)

endpoint = os.getenv("AZURE_FOUNDRY_ENDPOINT", "")
agent_name = os.getenv("AZURE_FOUNDRY_AGENT_NAME", "TailorSync-Agent")
tenant_id = os.getenv("AZURE_TENANT_ID", "")

print(f"\n  Endpoint:   {endpoint}")
print(f"  Agent Name: {agent_name}")

# Step 1: Authenticate
print("\n[1/4] Authenticating via Device Code...")
print("  >>> A code will appear below. Open the URL and enter the code <<<\n")

from azure.identity import DeviceCodeCredential

def device_code_callback(verification_uri, user_code, expires_on):
    print("  " + "=" * 56)
    print(f"  Go to:  {verification_uri}")
    print(f"  Enter code:  {user_code}")
    print("  " + "=" * 56)
    print("\n  Waiting for you to complete sign-in...\n")

credential = DeviceCodeCredential(
    tenant_id=tenant_id,
    prompt_callback=device_code_callback
)

try:
    token = credential.get_token("https://cognitiveservices.azure.com/.default")
    print("  ✅ Authenticated successfully!")
except Exception as e:
    print(f"  ❌ Auth error: {type(e).__name__}: {e}")
    sys.exit(1)

# Step 2: Connect client
print("\n[2/4] Connecting to Azure AI Project Client...")
from azure.ai.projects import AIProjectClient

try:
    client = AIProjectClient(
        endpoint=endpoint,
        credential=credential
    )
    print("  ✅ Client created")
except Exception as e:
    print(f"  ❌ Client error: {e}")
    sys.exit(1)

# Step 3: Find agent
print(f"\n[3/4] Looking for agent '{agent_name}'...")
try:
    agents_list = client.agents.list_agents()
    found_agent = None
    count = 0
    for a in agents_list:
        count += 1
        print(f"    - {a.name} (id: {a.id})")
        if a.name and a.name.lower() == agent_name.lower():
            found_agent = a

    if count == 0:
        print("  ⚠️  No agents found")

    if found_agent:
        print(f"\n  ✅ Agent '{found_agent.name}' FOUND! (id: {found_agent.id})")
    else:
        print(f"\n  ❌ Agent '{agent_name}' not found among {count} agents")
        sys.exit(1)
except Exception as e:
    print(f"  ❌ Error: {type(e).__name__}: {e}")
    sys.exit(1)

# Step 4: Test invocation via thread + run
print("\n[4/4] Sending test prompt to agent...")
try:
    from azure.ai.agents.models import ThreadMessageOptions, AgentThreadCreationOptions

    thread_options = AgentThreadCreationOptions(
        messages=[
            ThreadMessageOptions(
                role="user",
                content='Reply with exactly: {"status": "connected"}'
            )
        ]
    )

    run = client.agents.create_thread_and_process_run(
        agent_id=found_agent.id,
        thread=thread_options
    )

    if run.status == "completed":
        print(f"  ✅ Run completed! (id: {run.id}, thread: {run.thread_id})")

        # Get the response message
        messages = client.agents.messages.list(thread_id=run.thread_id)
        for msg in messages:
            if msg.role == "assistant":
                print(f"  ✅ Agent responded: {msg.content[0].text.value[:200]}")
                break
    else:
        print(f"  ❌ Run status: {run.status}")
        if hasattr(run, 'last_error') and run.last_error:
            print(f"  Error: {run.last_error}")
        sys.exit(1)
except Exception as e:
    print(f"  ❌ Error: {type(e).__name__}: {e}")
    import traceback
    traceback.print_exc()
    sys.exit(1)

print("\n" + "=" * 60)
print("  ✅ ALL CHECKS PASSED - Backend <-> AI Agent connected!")
print("=" * 60)
