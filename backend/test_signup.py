import requests
resp = requests.post("http://127.0.0.1:8001/api/v1/auth/signup", json={"email": "test_auth_restart@example.com", "password": "password", "full_name": "Test Restart", "phone": "12345"})
print(resp.status_code, resp.text)
