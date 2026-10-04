import requests

BASE_URL = 'https://tailorsync-api-prod-gxgvdaawe5a6bffn.centralus-01.azurewebsites.net/api/v1'

def test_prediction():
    login_data = {
        'email': 'agsvwimalasiri@gmail.com',
        'password': 'Password123!'
    }
    r_login = requests.post(f"{BASE_URL}/auth/login", json=login_data)
    token = r_login.json()['access_token']
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
    r_pred = requests.post(f"{BASE_URL}/ai/foundry-predict", json=payload, headers=headers)
    print(f"Prediction status: {r_pred.status_code}")
    print(f"Prediction response: {r_pred.text}")

if __name__ == '__main__':
    test_prediction()
