import os
import io
import logging
from fastapi import APIRouter, UploadFile, File, Form, HTTPException, Response
from typing import Optional
from starlette.concurrency import run_in_threadpool
from PIL import Image

logger = logging.getLogger(__name__)

router = APIRouter()

GARMENTS = {
    "long_sleeve_shirt": {
        "label": "Long sleeve shirt",
        "target": "shirt",
        "description": "a clean, plain {color} long-sleeve shirt",
        "details": "The shirt should have a realistic collar, long sleeves reaching the wrists, natural fabric folds, stitching, shadows, and wrinkles.",
        "needs_full_body": False
    },
    "short_sleeve_shirt": {
        "label": "Short sleeve shirt",
        "target": "shirt",
        "description": "a clean, plain {color} short-sleeve shirt",
        "details": "The shirt should have a realistic collar, short sleeves ending above the elbow, natural fabric folds, stitching, shadows, and wrinkles.",
        "needs_full_body": False
    },
    "long_trousers": {
        "label": "Long trousers",
        "target": "trousers",
        "description": "clean, plain {color} tailored long trousers",
        "details": "The trousers should have a realistic waistband, long legs reaching the ankles, natural fabric folds, creases, stitching, shadows, and wrinkles.",
        "needs_full_body": True
    },
    "short_trousers": {
        "label": "Short trousers",
        "target": "trousers",
        "description": "clean, plain {color} tailored short trousers",
        "details": "The trousers should have a realistic waistband, legs ending just above the knee, natural fabric folds, creases, stitching, shadows, and wrinkles.",
        "needs_full_body": True
    }
}

COLORS = {
    "white": "white",
    "black": "black",
    "navy_blue": "navy blue",
    "light_blue": "light blue",
    "grey": "grey",
    "beige": "beige"
}

@router.get("/styles")
def get_styles():
    garments = [
        {"id": k, "label": v["label"], "needs_full_body": v["needs_full_body"]}
        for k, v in GARMENTS.items()
    ]
    colors = [{"id": k, "label": v} for k, v in COLORS.items()]
    return {"garments": garments, "colors": colors}

import requests
import base64

def call_gemini_blocking(img: Image.Image, prompt: str):
    api_key = os.environ.get("GEMINI_API_KEY")
    model_name = os.environ.get("GEMINI_IMAGE_MODEL", "gemini-3.1-flash-lite-image")
    if not api_key:
        raise ValueError("GEMINI_API_KEY is missing")
    
    img_byte_arr = io.BytesIO()
    img.save(img_byte_arr, format='JPEG')
    b64_img = base64.b64encode(img_byte_arr.getvalue()).decode('utf-8')
    
    url = f"https://generativelanguage.googleapis.com/v1beta/models/{model_name}:predict"
    # Note: Depending on the specific image editing API format. 
    # For a general fallback to standard generateContent:
    url = f"https://generativelanguage.googleapis.com/v1beta/models/{model_name}:generateContent?key={api_key}"
    
    payload = {
        "contents": [
            {
                "parts": [
                    {"text": prompt},
                    {
                        "inline_data": {
                            "mime_type": "image/jpeg",
                            "data": b64_img
                        }
                    }
                ]
            }
        ],
        "generationConfig": {
             # No specific config, defaults are usually fine.
        }
    }
    
    response = requests.post(url, json=payload, timeout=90)
    response.raise_for_status()
    data = response.json()
    
    try:
        parts = data["candidates"][0]["content"]["parts"]
        for part in parts:
            if "inlineData" in part:
                return base64.b64decode(part["inlineData"]["data"])
            elif "image" in part:
                return base64.b64decode(part["image"]["imageBytes"])
    except (KeyError, IndexError) as e:
        logger.error(f"Failed to parse Gemini response: {e}, Response: {data}")
        
    raise ValueError("No image returned from model.")

@router.post("/")
async def generate_style_preview(
    photo: UploadFile = File(...),
    garment_id: str = Form(...),
    color_id: str = Form("white")
):
    if garment_id not in GARMENTS:
        raise HTTPException(status_code=400, detail="Unknown garment_id")
    if color_id not in COLORS:
        raise HTTPException(status_code=400, detail="Unknown color_id")

    # Read image
    contents = await photo.read()
    if len(contents) > 8 * 1024 * 1024:
        raise HTTPException(status_code=413, detail="File too large. Max 8 MB.")
    
    try:
        img = Image.open(io.BytesIO(contents))
        
        # Validate format
        if img.format not in ["JPEG", "PNG", "WEBP"]:
            raise ValueError("Only JPEG or PNG photos are allowed.")
            
        img = img.convert("RGB")
        
        # Resize if > 1280
        max_size = 1280
        if max(img.width, img.height) > max_size:
            ratio = max_size / max(img.width, img.height)
            new_size = (int(img.width * ratio), int(img.height * ratio))
            img = img.resize(new_size, Image.LANCZOS)
    except Exception as e:
        logger.error(f"Image processing error: {e}")
        raise HTTPException(status_code=400, detail="Invalid image file.")

    garment = GARMENTS[garment_id]
    color_label = COLORS[color_id]
    description = garment["description"].format(color=color_label)
    
    prompt = f"""Edit the uploaded photo by changing only the person's clothing.
Dress the person in {description}, naturally fitted to their existing body and pose.
{garment['details']}
Preserve the person exactly as they appear in the original photo: same face, facial
features, identity, hairstyle, hairline, skin tone, expression, body shape, body
proportions, shoulder width, torso length, arm length, hands, pose, posture, and overall
appearance. Do not manipulate, regenerate, beautify, slim, widen, reshape, or alter the
face or body in any way.
Keep the original camera angle, framing, perspective, background, lighting, shadows, and
image quality unchanged.
Change only the {garment['target']}. Keep all other clothing and everything else in the photograph
unchanged."""

    try:
        image_bytes = await run_in_threadpool(call_gemini_blocking, img, prompt)
    except Exception as e:
        logger.error(f"Error calling Gemini: {e}")
        raise HTTPException(status_code=502, detail="Model generation failed. Try a different photo.")
        
    if not image_bytes:
        raise HTTPException(status_code=502, detail="No image returned by the model.")

    return Response(content=image_bytes, media_type="image/jpeg")
