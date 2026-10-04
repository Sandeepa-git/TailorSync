import requests

BASE_URL = 'https://tailorsync-api-prod-gxgvdaawe5a6bffn.centralus-01.azurewebsites.net/api/v1'

def test_prediction():
    # Login as admin to get token
    login_data = {
        'username': 'agsvwimalasiri@gmail.com',
        'password': 'Password123!'
    }
    print("1. Logging in...")
    # Fix: Use data instead of json, and send as x-www-form-urlencoded
    r_login = requests.post(f"{BASE_URL}/auth/login", data=login_data)
    
    if r_login.status_code != 200:
        print(f"Login failed: {r_login.status_code} {r_login.text}")
        return
        
    token = r_login.json()['access_token']
    headers = {'Authorization': f'Bearer {token}'}
    
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
