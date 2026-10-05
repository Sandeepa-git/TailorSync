"""
Standalone Foundry agent + live API test - no venv, no backend imports.
Reads FOUNDRY_* values from backend/.env by itself.

Run:  double-click test_agent.bat   (or: py agent_test_standalone.py)
"""
import getpass, json, os, sys, time

HERE = os.path.dirname(os.path.abspath(__file__))
API = os.environ.get("TAILORSYNC_API",
                     "https://tailorsync-api-prod-gxgvdaawe5a6bffn.centralus-01.azurewebsites.net/api/v1")
SAMPLE = {"Shoulder": "18", "Height": "30", "Chest": "40"}


def load_env():
    path = os.path.join(HERE, ".env")
    if not os.path.exists(path):
        print("  (no backend/.env found - using system environment only)")
        return
    for raw in open(path, encoding="utf-8", errors="ignore"):
        line = raw.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        k, v = line.split("=", 1)
        os.environ.setdefault(k.strip(), v.strip().strip('"').strip("'"))


def hr(t):
    print("\n" + "=" * 68 + "\n" + t + "\n" + "=" * 68)


def test_agent():
    hr("1) Foundry AGENT - direct call")
    load_env()
    ep = os.environ.get("FOUNDRY_PROJECT_ENDPOINT", "").strip()
    name = os.environ.get("FOUNDRY_AGENT_NAME", "tailorsync-ai-agent").strip()
    ver = os.environ.get("FOUNDRY_AGENT_VERSION", "").strip()
    print(f"  project endpoint : {ep or '(NOT SET)'}")
    print(f"  agent name       : {name}")
    print(f"  agent version    : {ver or '(latest)'}")
    if not ep:
        print("  -> FOUNDRY_PROJECT_ENDPOINT missing in backend/.env; the agent can't be called.")
        return
    try:
        from azure.ai.projects import AIProjectClient
        from azure.identity import DefaultAzureCredential
    except ImportError:
        print("  -> azure packages missing. Run test_agent.bat (it installs them).")
        return

    msg = json.dumps({
        "task": "predict_missing_measurements",
        "garment_type": "Long Sleeve Shirt",
        "provided_measurements": SAMPLE,
        "reply_format": {"predictions": [{"measurement": "name", "recommended": "number",
                                          "alternatives": ["number", "number"]}]},
        "rules": "Predict every missing measurement. JSON only.",
    })
    ref = {"name": name, "type": "agent_reference"}
    if ver:
        ref["version"] = ver
    t0 = time.perf_counter()
    try:
        project = AIProjectClient(endpoint=ep, credential=DefaultAzureCredential())
        client = project.get_openai_client().with_options(timeout=120.0, max_retries=0)
        resp = client.responses.create(input=[{"role": "user", "content": msg}],
                                       extra_body={"agent_reference": ref})
        dt = time.perf_counter() - t0
        u = getattr(resp, "usage", None)
        print(f"  OK in {dt:.1f}s | model={getattr(resp, 'model', '?')} "
              f"tokens in={getattr(u, 'input_tokens', '?')} out={getattr(u, 'output_tokens', '?')}")
        print("  reply:", (resp.output_text or "")[:500])
    except Exception as e:
        dt = time.perf_counter() - t0
        print(f"  FAILED after {dt:.1f}s -> {type(e).__name__}: {e}")
        txt = str(e).lower()
        if "credential" in txt or "login" in txt or "token" in txt:
            print("  -> Azure sign-in problem: run `az login` (Azure CLI) and try again.")
        elif "not found" in txt or "404" in txt:
            print("  -> Agent name/version or project endpoint is wrong. Check them in the Foundry portal.")
        elif "403" in txt or "permission" in txt or "authoriz" in txt:
            print("  -> Your account / the App Service identity lacks 'Azure AI User' on the Foundry project.")


def test_api():
    hr("2) LIVE backend - " + API)
    import requests
    t0 = time.perf_counter()
    try:
        r = requests.get(API.replace("/api/v1", "") + "/health", timeout=60)
        print(f"  /health -> {r.status_code} in {time.perf_counter() - t0:.1f}s  {r.text[:80]}")
    except Exception as e:
        print(f"  /health FAILED -> {e}")
        return

    token = os.environ.get("TAILORSYNC_TOKEN", "").strip()
    if not token:
        email = input("\n  App login email (Enter to skip): ").strip()
        if not email:
            return
        pw = getpass.getpass("  App password (hidden): ")
        r = requests.post(f"{API}/auth/login", json={"email": email, "password": pw}, timeout=60)
        if r.status_code != 200:
            print(f"  login FAILED -> {r.status_code} {r.text[:200]}")
            if "robot" in r.text or "Security check" in r.text:
                print("  reCAPTCHA blocks script login. Set TAILORSYNC_TOKEN=<access token> and rerun.")
            return
        token = r.json().get("access_token")
        print("  login OK")
    h = {"Authorization": f"Bearer {token}"}

    for label, path, body in [
        ("Foundry  /ai/foundry-predict", "/ai/foundry-predict",
         {"garment_type": "Long Sleeve Shirt", "measurements": SAMPLE}),
        ("CustomML /ai/predict-measurements", "/ai/predict-measurements",
         {"garment_type": "shirt", "shoulder": 18.0, "height": 30.0, "chest": 40.0}),
    ]:
        t0 = time.perf_counter()
        try:
            r = requests.post(API + path, json=body, headers=h, timeout=240)
            dt = time.perf_counter() - t0
            print(f"\n  {label}: {r.status_code} in {dt:.1f}s\n    {r.text[:400]}")
            if r.status_code == 502:
                print("    -> 502: Azure got no answer from the app (restarting/deploying or crashed).")
            elif r.status_code == 503:
                print("    -> 503: backend caught an AI error - see detail above.")
            elif dt > 90:
                print("    -> over 90 s: the phone app would time out before this finishes.")
        except Exception as e:
            print(f"\n  {label}: FAILED after {time.perf_counter() - t0:.1f}s -> {e}")


if __name__ == "__main__":
    mode = (sys.argv[1] if len(sys.argv) > 1 else "all").lower()
    if mode in ("agent", "all"):
        test_agent()
    if mode in ("api", "all"):
        test_api()
    print()
