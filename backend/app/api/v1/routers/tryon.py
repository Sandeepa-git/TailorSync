from fastapi import APIRouter, Depends, File, Form, HTTPException, UploadFile
from fastapi.concurrency import run_in_threadpool

from app.api.deps import get_current_active_user, rate_limit_ai
from app.models.user import User
from app.services.tryon_service import TryOnError, generate_tryon, get_usage

router = APIRouter()

MAX_UPLOAD_BYTES = 10 * 1024 * 1024


@router.post("/virtual-tryon")
async def virtual_tryon(
    image: UploadFile = File(...),
    dress_description: str = Form(...),
    current_user: User = Depends(rate_limit_ai),
):
    raw = await image.read()
    if not raw:
        raise HTTPException(status_code=422, detail="Photo is empty.")
    if len(raw) > MAX_UPLOAD_BYTES:
        raise HTTPException(status_code=413, detail="Photo is too large (max 10 MB).")
    try:
        image_b64 = await run_in_threadpool(generate_tryon, raw, dress_description)
    except TryOnError as e:
        raise HTTPException(status_code=502, detail=str(e))
    return {"image_base64": image_b64, "mime_type": "image/png", "usage": get_usage()}


@router.get("/virtual-tryon/usage")
def virtual_tryon_usage(current_user: User = Depends(get_current_active_user)):
    """Estimated free try-ons left today (Cloudflare free tier resets 00:00 UTC)."""
    return get_usage()
