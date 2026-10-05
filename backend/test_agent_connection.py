"""
TailorSync - Foundry agent / AI prediction connection test.

Two checks:
  1) agent : calls the Foundry agent DIRECTLY with the same code the backend uses
             (app/services/foundry_client.py). Needs the FOUNDRY_* settings in
             backend/.env and an Azure login on this PC (`az login`).
  2) api   : calls the LIVE backend on Azure exactly like the app does
             (login -> /ai/foundry-predict and /ai/predict-measurements) and
             prints status codes + timings, so you can see where a 502 comes from.

Usage (from the backend folder, with your venv active):
    python test_agent_connection.py agent
    python test_agent_connection.py api
    python test_agent_connection.py all
"""
import getpass
import json
import os
import sys
import time

API = os.environ.get(
    "TAILORSYNC_API",
    "https://tailorsync-api-prod-gxgvdaawe5a6bffn.centralus-01.azurewebsites.net/api/v1",
)
SAMPLE = {"Shoulder": "18", "Height": "30", "Chest": "40"}  # inches, shirt


def line(title):
    print("\n" + "=" * 70 + f"\n{title}\n" + "=" * 70)


def test_agent():
    line("1) Foundry agent - direct call (same code as the backend)")
    try:
        from dotenv import load_dotenv
        load_dotenv(os.path.join(os.path.dirname(__file__), ".env"))
    except ImportError:
        print("python-dotenv not installed - using existing environment variables only")

    for k in ["FOUNDRY_PROJECT_ENDPOINT", "FOUNDRY_AGENT_NAME", "FOUNDRY_AGENT_VERSION",
              "FOUNDRY_ENDPOINT", "FOUNDRY_MODEL_NAME"]:
        v = os.environ.get(k, "")
        print(f"  {k:26} = {v if v else '(not set)'}")
    print(f"  {'FOUNDRY_API_KEY':26} = {'(set)' if os.environ.get('FOUNDRY_API_KEY') else '(not set)'}")

    sys.path.insert(0, os.path.dirname(__file__))
    from app.services.foundry_client import FoundryClient

    fc = FoundryClient()

    if fc.project_endpoint:
        print("\n[a] Agent only (no fallback):")
        t0 = time.perf_counter()
        try:
            msg = json.dumps({"task": "predict_missing_measurements", "garment_type": "Long Sleeve Shirt",
                              "provided_measurements": SAMPLE,
                              "reply_format": {"predictions": [{"measurement": "name", "recommended": "number",
                                                                "alternatives": ["number", "number"]}]},
                              "rules": "JSON only."})
            out = fc._call_agent(msg)
            print(f"  OK in {time.perf_counter() - t0:.1f}s | {fc.last_stats if hasattr(fc, 'last_stats') else ''}")
            print("  reply:", out[:400])
        except Exception as e:
            print(f"  FAILED after {time.perf_counter() - t0:.1f}s -> {type(e).__name__}: {e}")
            print("  Tip: run `az login` (DefaultAzureCredential) and check the agent name/version in Foundry.")
    else:
        print("\n[a] FOUNDRY_PROJECT_ENDPOINT not set - agent is not used, backend goes straight to the model.")

    print("\n[b] Full predict_measurements (agent, then model fallback):")
    t0 = time.perf_counter()
    try:
        res = fc.predict_measurements("Long Sleeve Shirt", SAMPLE)
        n = len(res.get("predictions", []))
        print(f"  OK in {time.perf_counter() - t0:.1f}s - {n} predictions")
        print("  first:", json.dumps(res.get("predictions", [])[:3]))
    except Exception as e:
        print(f"  FAILED after {time.perf_counter() - t0:.1f}s -> {type(e).__name__}: {e}")


def test_api():
    line(f"2) Live backend - {API}")
    import requests

    t0 = time.perf_counter()
    try:
        r = requests.get(API.replace("/api/v1", "") + "/health", timeout=60)
        print(f"  /health -> {r.status_code} in {time.perf_counter() - t0:.1f}s  {r.text[:80]}")
    except Exception as e:
        print(f"  /health FAILED -> {e}")
        return

    token = os.environ.get("TAILORSYNC_TOKEN", "").strip()
    if token:
        print("  using TAILORSYNC_TOKEN from the environment")
        return _call_ai(token)

    email = input("\n  App login email: ").strip()
    password = getpass.getpass("  App password (not shown): ")
    r = requests.post(f"{API}/auth/login", json={"email": email, "password": password}, timeout=60)
    if r.status_code != 200:
        # some versions use form login
        r = requests.post(f"{API}/auth/login", data={"username": email, "password": password}, timeout=60)
    if r.status_code != 200:
        print(f"  login FAILED -> {r.status_code} {r.text[:200]}")
        if "robot" in r.text or "Security check" in r.text:
            print("  reCAPTCHA is enabled, so scripted login is blocked. Set TAILORSYNC_TOKEN to an")
            print("  access token instead (e.g. from /docs -> Authorize, or the app's secure storage).")
        return
    token = r.json().get("access_token")
    print("  login OK")
    _call_ai(token)


def _call_ai(token):
    import requests
    h = {"Authorization": f"Bearer {token}"}

    calls = [
        ("Foundry agent  /ai/foundry-predict",
         f"{API}/ai/foundry-predict",
         {"garment_type": "Long Sleeve Shirt", "measurements": SAMPLE}),
        ("Custom ML      /ai/predict-measurements",
         f"{API}/ai/predict-measurements",
         {"garment_type": "shirt", "shoulder": 18.0, "height": 30.0, "chest": 40.0}),
    ]
    for name, url, body in calls:
        t0 = time.perf_counter()
        try:
            r = requests.post(url, json=body, headers=h, timeout=240)
            dt = time.perf_counter() - t0
            print(f"\n  {name}: {r.status_code} in {dt:.1f}s")
            print("   ", r.text[:400])
            if r.status_code == 502:
                print("    -> 502 = Azure got no answer from the app (restart/deploy in progress, or the "
                      "worker crashed). Check App Service > Log stream at this exact time.")
            elif r.status_code == 503:
                print("    -> 503 = backend caught an AI error (detail above) - usually agent auth/config.")
            elif dt > 90:
                print("    -> slower than the app's 90 s timeout: the phone would show 'took too long'.")
        except Exception as e:
            print(f"\n  {name}: FAILED after {time.perf_counter() - t0:.1f}s -> {e}")


if __name__ == "__main__":
    mode = (sys.argv[1] if len(sys.argv) > 1 else "all").lower()
    if mode in ("agent", "all"):
        test_agent()
    if mode in ("api", "all"):
        test_api()
