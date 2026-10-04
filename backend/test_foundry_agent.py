"""Check that the backend reaches your Foundry AGENT (not the plain model).

Run from the backend folder after `az login`:
    python test_foundry_agent.py
"""
import logging
from dotenv import load_dotenv

load_dotenv()
logging.basicConfig(level=logging.INFO, format="%(levelname)s %(message)s")

from app.services.foundry_client import FoundryClient

c = FoundryClient()
print("Project endpoint:", c.project_endpoint or "(NOT SET)")
print("Agent:", c.agent_name, "version:", c.agent_version or "(latest)")
try:
    print("\nAgent reply:\n", c._call_agent('Reply with JSON only: {"status": "ok", "who": "<your agent name>"}', "Connection test."))
    print("\n✅ The agent is connected.")
except Exception as e:
    print("\n❌ Agent call failed:", type(e).__name__, e)
