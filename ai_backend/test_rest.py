import os
import requests
import json
from dotenv import load_dotenv

load_dotenv()

api_key = os.getenv('GEMINI_API_KEY')
url = f"https://generativelanguage.googleapis.com/v1beta/models?key={api_key}"

with open('rest_models.txt', 'w') as f:
    try:
        response = requests.get(url)
        if response.status_code == 200:
            data = response.json()
            models = [m['name'] for m in data.get('models', [])]
            for m in models:
                f.write(f"{m}\n")
        else:
            f.write(f"Error {response.status_code}: {response.text}")
    except Exception as e:
        f.write(str(e))
