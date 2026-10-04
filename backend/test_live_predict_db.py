import sys
import os
import requests

# Add current directory to path
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from app.database.session import SessionLocal
from app.models.user import User
from app.core.security import create_access_token

def test_prediction():
    print("1. Generating token from DB...")
    db = SessionLocal()
    try:
        user = db.query(User).first()
        if not user:
            print("No users found.")
            return
        token = create_access_token(user.id)
    finally:
        db.close()
        
    headers = {'Authorization': f'Bearer {token}'}
    
    BASE_URL = 'https://tailorsync-api-prod-gxgvdaawe5a6bffn.centralus-01.azurewebsites.net/api/v1'
    print("2. Calling prediction endpoint...")
    payload = {
        "dataset_type": "trouser",
        "customer_id": 1,
        "input_measurements": {
            "length": 40,
            "waist": 32,
            "hips": 38,
            "inside_leg": 30
        }
    }
    r_pred = requests.post(f"{BASE_URL}/ai/foundry-predict", json=payload, headers=headers)
    print(f"Prediction status: {r_pred.status_code}")
    print(f"Prediction response: {r_pred.text}")

if __name__ == '__main__':
    test_prediction()
