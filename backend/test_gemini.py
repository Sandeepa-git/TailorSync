"""Quick test to verify Gemini API image generation works."""
import os
import requests
import base64
import json
from dotenv import load_dotenv

load_dotenv()

api_key = os.environ.get("GEMINI_API_KEY")
model_name = os.environ.get("GEMINI_IMAGE_MODEL", "gemini-3.1-flash-image")

print(f"API Key: {api_key[:10]}...{api_key[-5:]}" if api_key else "API Key: NOT SET")
print(f"Model: {model_name}")
print()

if not api_key:
    print("ERROR: GEMINI_API_KEY is not set!")
    exit(1)

# Step 1: Check if model exists by listing models
print("=" * 50)
print("Step 1: Checking if model exists...")
list_url = f"https://generativelanguage.googleapis.com/v1beta/models/{model_name}?key={api_key}"
resp = requests.get(list_url, timeout=15)
print(f"  Status: {resp.status_code}")
if resp.status_code == 200:
    model_info = resp.json()
    print(f"  Model found: {model_info.get('displayName', 'N/A')}")
    print(f"  Supported methods: {model_info.get('supportedGenerationMethods', [])}")
else:
    print(f"  ERROR: {resp.text[:300]}")
    print()
    print("Trying to list available models with 'image' in the name...")
    list_all_url = f"https://generativelanguage.googleapis.com/v1beta/models?key={api_key}"
    resp2 = requests.get(list_all_url, timeout=15)
    if resp2.status_code == 200:
        models = resp2.json().get("models", [])
        image_models = [m for m in models if "image" in m.get("name", "").lower() or "image" in str(m.get("supportedGenerationMethods", [])).lower()]
        print(f"  Found {len(image_models)} image-related models:")
        for m in image_models:
            print(f"    - {m['name']} ({m.get('displayName', 'N/A')})")
        if not image_models:
            print("  No image-specific models found. Listing all models:")
            for m in models[:15]:
                print(f"    - {m['name']} ({m.get('displayName', 'N/A')})")
            if len(models) > 15:
                print(f"    ... and {len(models) - 15} more")
    else:
        print(f"  Failed to list models: {resp2.status_code} - {resp2.text[:200]}")

# Step 2: Try a simple image generation request
print()
print("=" * 50)
print("Step 2: Testing image generation...")
url = f"https://generativelanguage.googleapis.com/v1beta/models/{model_name}:generateContent?key={api_key}"

payload = {
    "contents": [{"parts": [{"text": "Generate a simple image of a plain white shirt on a white background."}]}],
    "generationConfig": {
        "responseModalities": ["IMAGE"]
    }
}

try:
    resp = requests.post(url, json=payload, timeout=60)
    print(f"  Status: {resp.status_code}")
    
    if resp.status_code == 200:
        data = resp.json()
        candidates = data.get("candidates", [])
        if candidates:
            parts = candidates[0].get("content", {}).get("parts", [])
            for part in parts:
                if "inlineData" in part:
                    img_data = part["inlineData"]["data"]
                    img_bytes = base64.b64decode(img_data)
                    print(f"  SUCCESS! Image generated ({len(img_bytes)} bytes)")
                    # Save test image
                    with open("test_output.jpg", "wb") as f:
                        f.write(img_bytes)
                    print(f"  Saved to test_output.jpg")
                    break
                elif "text" in part:
                    print(f"  Text response: {part['text'][:200]}")
            else:
                print(f"  No image in response. Parts: {json.dumps(parts)[:300]}")
                finish_reason = candidates[0].get("finishReason", "UNKNOWN")
                print(f"  Finish reason: {finish_reason}")
        else:
            print(f"  No candidates in response: {json.dumps(data)[:300]}")
    else:
        print(f"  ERROR: {resp.text[:500]}")
except requests.exceptions.Timeout:
    print("  TIMEOUT after 60s")
except Exception as e:
    print(f"  EXCEPTION: {e}")

print()
print("=" * 50)
print("Test complete.")
