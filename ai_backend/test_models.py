import os
import traceback
from google import genai
from dotenv import load_dotenv

load_dotenv()

with open('models.txt', 'w') as f:
    try:
        client = genai.Client(api_key=os.getenv('GEMINI_API_KEY'))
        models = client.models.list()
        for m in models:
            f.write(f"{m.name}\n")
        f.write("Success")
    except Exception as e:
        f.write(traceback.format_exc())
