import sys
import os
import requests
import json

# Add current directory to python path
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from app.database.session import SessionLocal
from app.models.user import User
from app.core.jwt import create_access_token

def test_prediction():
    print("1. Getting user from DB...")
    db = SessionLocal()
    user = db.query(User).filter(User.email == 'agsvwimalasiri@gmail.com').first()
    if not user:
        user = db.query(User).first()
    
    if not user:
        print("No user found!")
        return
        
    role_value = user.role.value if hasattr(user.role, 'value') else str(user.role)
    token = create_access_token(str(user.id), {"role": role_value})
    db.close()
    
    print("2. Calling prediction endpoint...")
    headers = {'Authorization': f'Bearer {token}'}
    payload = {
        "garment_type": "trouser",
        "measurements": {
            "length": 40,
            "waist": 32,
            "hips": 38,
            "inside_leg": 30
        }
    }
    
    BASE_URL = 'https://tailorsync-api-prod-gxgvdaawe5a6bffn.centralus-01.azurewebsites.net/api/v1'
    r_pred = requests.post(f"{BASE_URL}/ai/foundry-predict", json=payload, headers=headers)
    print(f"Prediction status: {r_pred.status_code}")
    print(f"Prediction response: {json.dumps(r_pred.json(), indent=2) if r_pred.status_code == 200 else r_pred.text}")

if __name__ == '__main__':
    test_prediction()
