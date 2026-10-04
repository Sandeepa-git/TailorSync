"""Times the 3 AI steps exactly like the app does (run from backend folder after `az login`):
    python benchmark_ai.py
"""
import logging, time
from dotenv import load_dotenv
load_dotenv()
logging.basicConfig(level=logging.WARNING)
from app.services.foundry_client import get_foundry_client

c = get_foundry_client()
print("Agent:", c.agent_name, "| project:", c.project_endpoint or "(not set)", "| reasoning:", c.reasoning_effort)
steps = [
    ("1 predict ", lambda: c.predict_measurements("Long Sleeve Shirt", {"Shoulder": "9.5", "Height": "29", "Chest": "38"})),
    ("2 fabrics ", lambda: c.recommend_fabric("Long Sleeve Shirt", "Office", "Hot", ["Breathable"], "Regular Fit")),
    ("3 estimate", lambda: c.estimate_fabric("Long Sleeve Shirt", "Cotton", {"Shoulder": "9.5", "Height": "29", "Chest": "38", "Long Sleeve Length": "24"})),
]
for name, fn in steps:
    t = time.perf_counter()
    try:
        fn()
        print(f"{name}: {time.perf_counter()-t:5.1f}s total | agent: {getattr(c, 'last_stats', 'n/a')}")
    except Exception as e:
        print(f"{name}: FAILED after {time.perf_counter()-t:.1f}s -> {e}")
print("\nIf 'model=' is gpt-5-mini and 'reasoning=' is large, the model's thinking is the delay.")
