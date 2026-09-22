"""Create TailorSync-Agent in Azure AI Foundry."""
import os
import sys
from dotenv import load_dotenv

load_dotenv()

print("=" * 60)
print("  TailorSync - Create AI Agent")
print("=" * 60)

endpoint = os.getenv("AZURE_FOUNDRY_ENDPOINT", "")
agent_name = os.getenv("AZURE_FOUNDRY_AGENT_NAME", "TailorSync-Agent")
tenant_id = os.getenv("AZURE_TENANT_ID", "")

print(f"\n  Endpoint:   {endpoint}")
print(f"  Agent Name: {agent_name}")

# Step 1: Authenticate
print("\n[1/3] Authenticating via Device Code...")
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
print("\n[2/3] Connecting to Azure AI Project Client...")
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

# Step 3: Create the agent
print(f"\n[3/3] Creating agent '{agent_name}'...")

# First check if agent already exists
try:
    agents_list = client.agents.list_agents()
    for a in agents_list:
        if a.name and a.name.lower() == agent_name.lower():
            print(f"\n  ⚠️  Agent '{a.name}' already exists (id: {a.id})")
            print("  Skipping creation.")
            sys.exit(0)
except Exception as e:
    print(f"  ⚠️  Could not list agents: {e}")
    print("  Proceeding with creation anyway...\n")

# System prompt for TailorSync
system_prompt = """You are TailorSync AI Assistant — a professional tailoring and fashion expert.
You help tailors and their customers with:

1. **Measurements**: Guide users on how to take body measurements accurately.
   Provide tips for chest, waist, hip, shoulder, sleeve length, inseam, etc.

2. **Fabric Recommendations**: Suggest fabrics based on garment type, occasion,
   season, budget, and style preference. Consider comfort, durability, and drape.

3. **Style Advice**: Recommend garment styles, cuts, and designs based on body type,
   occasion, and current fashion trends.

4. **Order Management**: Help summarize order details, suggest timelines,
   and provide status updates when asked.

5. **Pricing Guidance**: Provide rough cost estimates based on garment type,
   fabric choice, and complexity of tailoring.

Always be professional, friendly, and concise. Use metric (cm) for measurements.
If you're unsure about something, say so rather than guessing.
Respond in clear, structured formats when listing recommendations."""

try:
    # Try creating with gpt-5-mini first, fall back to gpt-4o, then gpt-4o-mini
    model_names = ["gpt-5-mini", "gpt-4o", "gpt-4o-mini", "gpt-35-turbo", "gpt-4"]
    agent = None

    for model in model_names:
        try:
            print(f"  Trying model: {model}...")
            agent = client.agents.create_agent(
                model=model,
                name=agent_name,
                instructions=system_prompt,
            )
            print(f"  ✅ Agent created with model: {model}")
            break
        except Exception as model_err:
            print(f"    ⚠️  {model} not available: {model_err}")
            continue

    if agent:
        print(f"\n  ✅ Agent '{agent.name}' created successfully!")
        print(f"     ID:    {agent.id}")
        print(f"     Model: {agent.model}")
    else:
        print("\n  ❌ No model deployment found. Please deploy a model in Azure AI Foundry first.")
        print("     Go to: https://ai.azure.com → Your project → Deployments → Deploy a model")
        sys.exit(1)

except Exception as e:
    print(f"  ❌ Error creating agent: {type(e).__name__}: {e}")
    import traceback
    traceback.print_exc()
    sys.exit(1)

print("\n" + "=" * 60)
print("  ✅ Agent created! You can now run test_ai_connection.py")
print("=" * 60)
