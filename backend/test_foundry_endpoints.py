import os
from dotenv import load_dotenv

# Load environment variables before importing the app modules
load_dotenv()

from app.services.foundry_client import FoundryClient

def run_tests():
    print("Initializing FoundryClient...")
    try:
        client = FoundryClient()
        print(f"USE_FOUNDRY_AGENT: {client.use_foundry_agent}")
        if client.use_foundry_agent:
            print(f"Agent Name: {client.agent_name}")
    except Exception as e:
        print(f"Failed to initialize client: {e}")
        return

    print("\n--- 1. Testing Predict Measurements ---")
    try:
        res = client.predict_measurements("Shirt", {"Neck": "15", "Chest": "38"})
        print("Result:", res)
    except Exception as e:
        print("Error:", e)

    print("\n--- 2. Testing Recommend Fabric ---")
    try:
        res = client.recommend_fabric("Shirt", "Formal", "Hot", ["Breathable", "Soft"], "Slim")
        print("Result:", res)
    except Exception as e:
        print("Error:", e)

    print("\n--- 3. Testing Estimate Fabric ---")
    try:
        res = client.estimate_fabric("Long Trousers", "Cotton", {"Waist": "32", "Length": "40"})
        print("Result:", res)
    except Exception as e:
        print("Error:", e)

if __name__ == "__main__":
    run_tests()
