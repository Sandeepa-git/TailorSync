import asyncio
from app.services.dataset_service import DatasetService
from app.services.gemini_client import GeminiClient

def test_flow():
    print("--- E2E Flow Test ---")
    
    service = DatasetService()
    
    # 1. Exact Match Test for Trouser
    measurements = {"Height Till Knee": "20 1/2", "Waist": "32"}
    match = service.get_exact_match("Long Trouser", measurements)
    print(f"Trouser Exact Match (Height 20.5, Waist 32):")
    print(f"  Round Knee expected: 20, got: {match.get('Round Knee')}")
    print(f"  Round End expected: 14, got: {match.get('Round End')}")
    print(f"  Fabric est_long expected: 1.5, got: {match.get('Fabric estimation_long in meter')}")

    # 2. Exact Match Test for Shirt
    measurements = {"Shoulder Length": "10", "Short Sleeve Length": "20"}
    match2 = service.get_exact_match("Short Sleeve Shirt", measurements)
    print(f"\nShirt Exact Match (Shoulder 10, Sleeve 20):")
    print(f"  Height expected: 27, got: {match2.get('Height')}")
    print(f"  Chest expected: 40, got: {match2.get('Chest')}")
    
    print("\n--- Testing Complete ---")
    
if __name__ == "__main__":
    test_flow()
