import os
from dotenv import load_dotenv

load_dotenv()

from app.services.groq_client import GroqClient
import json

def test_groq():
    client = GroqClient()
    
    print("Testing Groq Measurement Prediction...")
    measurements = {
        "Height Till Knee": "55",
        "Waist": "32"
    }
    
    try:
        result = client.predict_measurements("Long Trouser", measurements)
        print("Success! Raw Response:")
        print(result)
    except Exception as e:
        print(f"Failed: {e}")

if __name__ == "__main__":
    test_groq()
