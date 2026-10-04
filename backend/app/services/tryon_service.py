"""Virtual try-on: re-dress a customer photo using Cloudflare Workers AI (FLUX.2 klein).

Free tier: 10,000 neurons/day (no card). One try-on ~110-150 neurons.
"""
import base64
import io
import json
import logging
import math
import os
import threading
from datetime import datetime, timedelta, timezone

import requests
from PIL import Image, ImageOps

logger = logging.getLogger(__name__)

MODEL = "@cf/black-forest-labs/flux-2-klein-4b"
INPUT_MAX_SIDE = 512      # input tiles are 512x512 -> keep cost low
OUTPUT_LONG_SIDE = 1024   # output long side


class TryOnError(Exception):
    pass


# ---------------------------------------------------------------------------
# Daily usage tracking (Cloudflare free tier = 10,000 neurons/day, resets 00:00 UTC)
# ---------------------------------------------------------------------------
DAILY_FREE_NEURONS = 10_000
# Published FLUX.2 klein-4b rates (developers.cloudflare.com/workers-ai/platform/pricing)
NEURONS_PER_INPUT_TILE = 5.37
NEURONS_PER_OUTPUT_TILE = 26.05

_usage_lock = threading.Lock()


def _usage_file() -> str:
    custom = os.getenv("TRYON_USAGE_FILE")
    if custom:
        return custom
    if os.getenv("WEBSITE_SITE_NAME"):  # Azure App Service: /home survives restarts/deploys
        return "/home/data/tryon_usage.json"
    return os.path.join(os.path.dirname(__file__), "..", "..", "data", "tryon_usage.json")


def _today_utc() -> str:
    return datetime.now(timezone.utc).strftime("%Y-%m-%d")


def _read_usage() -> dict:
    try:
        with open(_usage_file(), "r", encoding="utf-8") as f:
            data = json.load(f)
        if data.get("date") == _today_utc():
            return data
    except (OSError, ValueError):
        pass
    return {"date": _today_utc(), "used_neurons": 0.0, "generations": 0, "exhausted": False}


def _write_usage(data: dict) -> None:
    path = _usage_file()
    try:
        os.makedirs(os.path.dirname(os.path.abspath(path)), exist_ok=True)
        tmp = path + ".tmp"
        with open(tmp, "w", encoding="utf-8") as f:
            json.dump(data, f)
        os.replace(tmp, path)
    except OSError as e:
        logger.warning("Could not save try-on usage: %s", e)


def estimate_neurons(out_w: int, out_h: int, in_w: int = 512, in_h: int = 512) -> float:
    in_tiles = math.ceil(in_w / 512) * math.ceil(in_h / 512)
    out_tiles = math.ceil(out_w / 512) * math.ceil(out_h / 512)
    return in_tiles * NEURONS_PER_INPUT_TILE + out_tiles * NEURONS_PER_OUTPUT_TILE


TYPICAL_NEURONS_PER_TRYON = estimate_neurons(768, 1024)


def _record_usage(neurons: float = 0.0, exhausted: bool = False) -> None:
    with _usage_lock:
        data = _read_usage()
        if neurons:
            data["used_neurons"] = round(data["used_neurons"] + neurons, 2)
            data["generations"] += 1
        if exhausted:
            data["exhausted"] = True
        _write_usage(data)


def get_usage() -> dict:
    with _usage_lock:
        data = _read_usage()
    used = data["used_neurons"]
    remaining_neurons = 0.0 if data.get("exhausted") else max(0.0, DAILY_FREE_NEURONS - used)
    now = datetime.now(timezone.utc)
    resets_at = (now + timedelta(days=1)).replace(hour=0, minute=0, second=0, microsecond=0)
    return {
        "date": data["date"],
        "generations_today": data["generations"],
        "used_neurons": round(used, 1),
        "daily_free_neurons": DAILY_FREE_NEURONS,
        "remaining_neurons": round(remaining_neurons, 1),
        "remaining_generations": int(remaining_neurons // TYPICAL_NEURONS_PER_TRYON),
        "max_generations_per_day": int(DAILY_FREE_NEURONS // TYPICAL_NEURONS_PER_TRYON),
        "resets_at": resets_at.isoformat(),
        "is_estimate": True,
    }


def _round16(v: float) -> int:
    return max(256, int(round(v / 16)) * 16)


def _prepare_image(raw: bytes):
    """Fix EXIF rotation, shrink to <=512px, return (png_bytes, out_w, out_h)."""
    try:
        img = Image.open(io.BytesIO(raw))
        img = ImageOps.exif_transpose(img).convert("RGB")
    except Exception as e:
        raise TryOnError(f"Invalid image: {e}")

    w, h = img.size
    scale = OUTPUT_LONG_SIDE / max(w, h)
    out_w, out_h = _round16(w * scale), _round16(h * scale)

    img.thumbnail((INPUT_MAX_SIDE, INPUT_MAX_SIDE))
    buf = io.BytesIO()
    img.save(buf, format="PNG")
    return buf.getvalue(), out_w, out_h


def build_prompt(dress_description: str) -> str:
    return (
        "Edit this photo. Change ONLY the person's clothing: dress them in "
        f"{dress_description.strip()}. "
        "Keep the person's face, identity, hairstyle, skin tone, body shape, pose, "
        "camera angle and background exactly the same. "
        "Photorealistic, realistic fabric texture, natural folds, natural lighting, high detail."
    )


def generate_tryon(image_bytes: bytes, dress_description: str) -> str:
    """Returns the generated image as a base64 string."""
    account_id = os.getenv("CF_ACCOUNT_ID", "").strip()
    token = os.getenv("CF_API_TOKEN", "").strip()
    if not account_id or not token:
        raise TryOnError("Virtual try-on is not configured (CF_ACCOUNT_ID / CF_API_TOKEN missing).")
    if not dress_description or not dress_description.strip():
        raise TryOnError("Please describe the dress.")

    if get_usage()["remaining_generations"] <= 0:
        raise TryOnError("Today's free image limit is used up. It resets at 5:30 AM (Sri Lanka time).")

    png, out_w, out_h = _prepare_image(image_bytes)
    url = f"https://api.cloudflare.com/client/v4/accounts/{account_id}/ai/run/{MODEL}"
    files = {
        "prompt": (None, build_prompt(dress_description)),
        "input_image_0": ("person.png", png, "image/png"),
        "width": (None, str(out_w)),
        "height": (None, str(out_h)),
    }
    try:
        r = requests.post(url, files=files, headers={"Authorization": f"Bearer {token}"}, timeout=90)
    except requests.RequestException as e:
        raise TryOnError(f"Could not reach image service: {e}")

    try:
        data = r.json()
    except ValueError:
        raise TryOnError(f"Image service error ({r.status_code}): {r.text[:300]}")

    if r.status_code != 200 or not data.get("success", False):
        errors = data.get("errors") or data
        logger.error("Cloudflare try-on failed %s: %s", r.status_code, errors)
        err_text = str(errors).lower()
        if r.status_code == 429 or "neuron" in err_text or "quota" in err_text:
            _record_usage(exhausted=True)
            raise TryOnError("Today's free image limit is used up. It resets at 5:30 AM (Sri Lanka time).")
        raise TryOnError(f"Image generation failed ({r.status_code}): {str(errors)[:300]}")

    image_b64 = (data.get("result") or {}).get("image")
    if not image_b64:
        raise TryOnError("Image service returned no image.")
    _record_usage(neurons=estimate_neurons(out_w, out_h))
    return image_b64
