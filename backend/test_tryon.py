"""Quick check of the Cloudflare virtual try-on (run from the backend folder).

    python test_tryon.py path\\to\\photo.jpg "red silk saree with gold border"

Saves the result as tryon_result.png next to this script.
"""
import base64, sys, time
from dotenv import load_dotenv
load_dotenv()
from app.services.tryon_service import generate_tryon

if len(sys.argv) < 2:
    sys.exit('Usage: python test_tryon.py <photo> ["dress description"]')
photo = sys.argv[1]
dress = sys.argv[2] if len(sys.argv) > 2 else "an elegant royal blue silk saree with a gold zari border"
t = time.time()
b64 = generate_tryon(open(photo, "rb").read(), dress)
open("tryon_result.png", "wb").write(base64.b64decode(b64))
print(f"OK in {time.time() - t:.1f}s -> tryon_result.png")
