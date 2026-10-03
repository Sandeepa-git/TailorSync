import os
import io
import logging
import requests
import base64
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

PROMPT_TEMPLATE = """Edit the uploaded photo by changing only the person's clothing.
Dress the person in {description}, naturally fitted to their existing body and pose.
{details}
Preserve the person exactly as they appear in the original photo: same face, facial
features, identity, hairstyle, hairline, skin tone, expression, body shape, body
proportions, shoulder width, torso length, arm length, hands, pose, posture, and overall
appearance. Do not manipulate, regenerate, beautify, slim, widen, reshape, or alter the
face or body in any way.
Keep the original camera angle, framing, perspective, background, lighting, shadows, and
image quality unchanged.
Change only the {target}. Keep all other clothing and everything else in the photograph
unchanged."""

EDIT_PROMPT_TEMPLATE = """{image_context}
Edit the current photo by applying only this clothing change requested by the user:
\"{instruction}\".
Only change the person's clothing (for example colour, fabric, pattern, sleeve length,
garment length, collar, fit). If the request asks for anything else, such as changing
the face, body, age, background, or adding people or objects, ignore that part and leave
it unchanged.
Preserve the person exactly as they appear: same face, facial features, identity,
hairstyle, hairline, skin tone, expression, body shape, body proportions, shoulder width,
torso length, arm length, hands, pose, posture, and overall appearance. Do not
manipulate, regenerate, beautify, slim, widen, reshape, or alter the face or body in any
way.
Keep the original camera angle, framing, perspective, background, lighting, shadows, and
image quality unchanged.
Keep the clothing modest and appropriate. Do not remove clothing or make the person
revealingly dressed. Keep all other clothing that was not mentioned unchanged."""

@router.get("/styles")
def get_styles():
    garments = [
        {"id": k, "label": v["label"], "needs_full_body": v["needs_full_body"]}
        for k, v in GARMENTS.items()
    ]
    colors = [{"id": k, "label": v} for k, v in COLORS.items()]
    return {"garments": garments, "colors": colors}

def process_image(contents: bytes) -> Image.Image:
    if len(contents) > 8 * 1024 * 1024:
        raise HTTPException(status_code=413, detail="File too large. Max 8 MB.")
    try:
        img = Image.open(io.BytesIO(contents))
        if img.format not in ["JPEG", "PNG", "WEBP"]:
            raise ValueError("Only JPEG or PNG photos are allowed.")
        img = img.convert("RGB")
        max_size = 1280
        if max(img.width, img.height) > max_size:
            ratio = max_size / max(img.width, img.height)
            new_size = (int(img.width * ratio), int(img.height * ratio))
            img = img.resize(new_size, Image.LANCZOS)
        return img
    except Exception as e:
        logger.error(f"Image processing error: {e}")
        raise HTTPException(status_code=400, detail="Invalid image file.")

def call_gemini_blocking(images: list[Image.Image], prompt: str):
    api_key = os.environ.get("GEMINI_API_KEY")
    model_name = "gemini-3.8-flash"
    if not api_key:
        raise ValueError("GEMINI_API_KEY is missing")
    
    parts = [{"text": prompt}]
    for img in images:
        img_byte_arr = io.BytesIO()
        img.save(img_byte_arr, format='JPEG')
        b64_img = base64.b64encode(img_byte_arr.getvalue()).decode('utf-8')
        parts.append({
            "inline_data": {
                "mime_type": "image/jpeg",
                "data": b64_img
            }
        })
    
    url = f"https://generativelanguage.googleapis.com/v1beta/models/{model_name}:generateContent?key={api_key}"
    
    payload = {
        "contents": [{"parts": parts}],
        "generationConfig": {
             "responseModalities": ["IMAGE"]
        }
    }
    
    response = requests.post(url, json=payload, timeout=90)
    if response.status_code == 429:
        raise HTTPException(status_code=429, detail="The preview service is busy. Please try again in a minute.")
    
    response.raise_for_status()
    data = response.json()
    
    try:
        candidate = data.get("candidates", [])[0]
        parts = candidate.get("content", {}).get("parts", [])
        
        # Check for image
        for part in parts:
            if "inlineData" in part:
                return base64.b64decode(part["inlineData"]["data"])
            elif "image" in part:
                return base64.b64decode(part["image"]["imageBytes"])
        
        # If no image found, log details
        finish_reason = candidate.get("finishReason", "UNKNOWN")
        safety_ratings = candidate.get("safetyRatings", [])
        text_parts = [p.get("text", "") for p in parts if "text" in p]
        
        logger.error(f"No image returned. Finish Reason: {finish_reason}, Safety: {safety_ratings}, Text: {text_parts}")
        
        is_debug = os.environ.get("DEBUG_STYLE_PREVIEW", "false").lower() == "true"
        debug_msg = f" (Reason: {finish_reason}, Text: {' '.join(text_parts)})" if is_debug else ""
        
        if finish_reason in ["SAFETY", "BLOCKLIST", "PROHIBITED_CONTENT"]:
            raise HTTPException(status_code=502, detail=f"The photo could not be processed. Try a clearer, well-lit photo of the person.{debug_msg}")
        else:
            raise HTTPException(status_code=502, detail=f"The preview could not be generated. Please try again.{debug_msg}")
            
    except (KeyError, IndexError) as e:
        logger.error(f"Failed to parse Gemini response: {e}, Response: {data}")
        raise HTTPException(status_code=502, detail="The preview could not be generated. Please try again.")

def call_gemini_with_retry(images: list[Image.Image], prompt: str):
    try:
        return call_gemini_blocking(images, prompt)
    except HTTPException as e:
        if e.status_code == 502:
            logger.info("Retrying Gemini call...")
            return call_gemini_blocking(images, prompt)
        raise e

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

    img = process_image(await photo.read())
    garment = GARMENTS[garment_id]
    color_label = COLORS[color_id]
    description = garment["description"].format(color=color_label)
    
    prompt = PROMPT_TEMPLATE.format(
        description=description,
        details=garment['details'],
        target=garment['target']
    )

    image_bytes = await run_in_threadpool(call_gemini_with_retry, [img], prompt)
    return Response(content=image_bytes, media_type="image/jpeg")

@router.post("/edit")
async def generate_style_edit(
    image: UploadFile = File(...),
    original: Optional[UploadFile] = File(None),
    instruction: str = Form(...)
):
    if not instruction or len(instruction.strip()) == 0 or len(instruction) > 300:
        raise HTTPException(status_code=400, detail="Instruction must be between 1 and 300 characters.")
        
    edit_img = process_image(await image.read())
    images = []
    
    if original:
        orig_img = process_image(await original.read())
        images.append(orig_img)
        images.append(edit_img)
        image_context = "Image 1 is the original photo of the person (identity reference). Image 2 is the current edited photo."
    else:
        images.append(edit_img)
        image_context = ""
        
    prompt = EDIT_PROMPT_TEMPLATE.format(
        image_context=image_context,
        instruction=instruction.strip()
    ).strip()
    
    image_bytes = await run_in_threadpool(call_gemini_with_retry, images, prompt)
    return Response(content=image_bytes, media_type="image/jpeg")
