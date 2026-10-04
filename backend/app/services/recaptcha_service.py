"""Google reCAPTCHA v2 ("I'm not a robot") verification for login / signup.

Env vars (Azure App Service + backend/.env):
  RECAPTCHA_SITE_KEY    public key (shown in the widget)
  RECAPTCHA_SECRET_KEY  secret key (used here to verify tokens)

If the keys are not set, Google's official TEST keys are used: the real
Google widget loads and works on any domain (it shows a small "for testing
only" note and always passes). Set your own keys for real protection, or
RECAPTCHA_ENABLED=false to turn reCAPTCHA off (app falls back to "slide to verify").
"""
import logging
import os

import requests
from fastapi import HTTPException, Request

logger = logging.getLogger(__name__)

VERIFY_URL = "https://www.google.com/recaptcha/api/siteverify"
HEADER_NAME = "X-Captcha-Token"

# Google's public test keys: https://developers.google.com/recaptcha/docs/faq
TEST_SITE_KEY = "6LeIxAcTAAAAAJcZVRqyHh71UMIEGNQ_MXjiZKhI"
TEST_SECRET_KEY = "6LeIxAcTAAAAAGG-vFI1TnRWxMZNFuojJ4WifJWe"


def site_key() -> str:
    return os.getenv("RECAPTCHA_SITE_KEY", "").strip() or TEST_SITE_KEY


def secret_key() -> str:
    return os.getenv("RECAPTCHA_SECRET_KEY", "").strip() or TEST_SECRET_KEY


def is_enabled() -> bool:
    return os.getenv("RECAPTCHA_ENABLED", "true").strip().lower() not in ("false", "0", "no", "off")


def verify_request(request: Request) -> None:
    """Raise unless the request carries a valid reCAPTCHA token (when enabled)."""
    if not is_enabled():
        return
    token = request.headers.get(HEADER_NAME)
    if not token:
        raise HTTPException(status_code=400, detail="Please tick \"I'm not a robot\" first.")

    data = {"secret": secret_key(), "response": token}
    if request.client and request.client.host:
        data["remoteip"] = request.client.host
    try:
        result = requests.post(VERIFY_URL, data=data, timeout=10).json()
    except Exception as e:
        logger.error("reCAPTCHA verify failed: %s", e)
        raise HTTPException(status_code=503, detail="Security check is unavailable. Please try again.")

    if not result.get("success"):
        logger.warning("reCAPTCHA rejected token: %s", result.get("error-codes"))
        raise HTTPException(status_code=400, detail="Security check failed or expired. Please verify again.")
