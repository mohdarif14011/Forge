import os
import fitz # PyMuPDF
import cloudinary
import cloudinary.uploader
import json
import io
from PIL import Image
import concurrent.futures
from dotenv import load_dotenv
import time
from google import genai
from google.genai import types

load_dotenv(override=True)

# Cloudinary Configuration
cloudinary.config(
    cloud_name=os.getenv("CLOUDINARY_CLOUD_NAME"),
    api_key=os.getenv("CLOUDINARY_API_KEY"),
    api_secret=os.getenv("CLOUDINARY_API_SECRET")
)

# Gemini Client Initialization
gemini_api_keys = [k.strip() for k in os.getenv("GEMINI_API_KEY", "").split(",") if k.strip()]
if not gemini_api_keys:
    print("WARNING: GEMINI_API_KEY is missing from environment variables.")
current_key_idx = 0
client = genai.Client(api_key=gemini_api_keys[0]) if gemini_api_keys else None

import threading

key_lock = threading.Lock()

def generate_with_retry(prompt, images=None, response_mime_type="application/json"):
    global current_key_idx, client
    max_retries = len(gemini_api_keys) * 2 # Allow looping through keys twice
    attempts = 0
    
    contents = []
    if images:
        contents.extend(images)
    contents.append(prompt)
    
    while attempts < max_retries:
        try:
            with key_lock:
                current_client = client

            response = current_client.models.generate_content(
                model='gemini-2.5-flash',
                contents=contents,
                config=types.GenerateContentConfig(
                    response_mime_type=response_mime_type,
                    temperature=0.1
                )
            )
            return response.text.strip(), None
            
        except Exception as e:
            error_msg = str(e)
            if '429' in error_msg or 'RESOURCE_EXHAUSTED' in error_msg:
                attempts += 1
                if attempts < max_retries:
                    with key_lock:
                        # Rotate only if another thread hasn't already rotated it
                        if current_client == client:
                            current_key_idx = (current_key_idx + 1) % len(gemini_api_keys)
                            print(f"Key rate limited. Rotating to key index {current_key_idx}...")
                            client = genai.Client(api_key=gemini_api_keys[current_key_idx])
                    time.sleep(15) # Wait before retrying
                    continue
                else:
                    return None, f"All {len(gemini_api_keys)} API keys exhausted."
            else:
                return None, error_msg
                
    return None, "Max retries exceeded"

def process_raw_json_file(raw_text: str):
    """
    Takes raw JSON text, uses AI to fix syntax errors and extract standardized fields,
    then finds those without a valid explanation to generate step-by-step solutions.
    """
    if not gemini_api_keys:
        yield json.dumps({"status": "error", "message": "GEMINI_API_KEY is not set in environment."}) + "\n"
        return

    yield json.dumps({"status": "progress", "message": "Using AI to analyze, fix, and extract JSON fields..."}) + "\n"
    
    prompt = """
    You are given a raw, potentially malformed JSON text containing exam questions.
    Fix any JSON syntax errors and extract the data into a valid JSON array of objects with the exact following schema:
    - 'text': The question text (extract from 'question', 'questionText', etc.)
    - 'options': A list of exactly 4 strings. If no options exist or it's an integer question, use an empty list `[]`.
    - 'correctAnswer': The correct option string or integer (extract from 'answer', 'correct', 'ans', etc.)
    - 'explanation': The solution or explanation (extract from 'solution', 'exp', etc.). Leave empty `""` if none exists.
    - 'marks': (optional integer)
    - 'negativeMarks': (optional integer)
    
    CRITICAL: Return ONLY a valid JSON array. Do not include markdown blocks like ```json.
    
    Raw text to process:
    """ + raw_text[:30000] # safeguard for token limit

    normalized_text, err = generate_with_retry(prompt, response_mime_type="application/json")
    if err:
        yield json.dumps({"status": "error", "message": f"AI JSON parsing failed: {err}"}) + "\n"
        return
        
    try:
        clean_text = normalized_text
        if clean_text.startswith("```json"):
            clean_text = clean_text[7:]
        elif clean_text.startswith("```"):
            clean_text = clean_text[3:]
        if clean_text.endswith("```"):
            clean_text = clean_text[:-3]
        
        questions = json.loads(clean_text.strip())
        if isinstance(questions, dict) and "questions" in questions:
            questions = questions["questions"]
        if not isinstance(questions, list):
            questions = [questions]
            
    except json.JSONDecodeError:
        yield json.dumps({"status": "error", "message": f"AI failed to return valid JSON. Raw output: {normalized_text}"}) + "\n"
        return
    
    missing_count = sum(1 for q in questions if not q.get("explanation") or len(str(q.get("explanation")).strip()) < 10)
    
    if missing_count > 0:
        yield json.dumps({"status": "progress", "message": f"Found {missing_count} missing solutions. Starting AI generation..."}) + "\n"
    else:
        yield json.dumps({"status": "progress", "message": "All questions have solutions! No AI generation needed."}) + "\n"

    processed = 0
    for i, q in enumerate(questions):
        expl = q.get("explanation", "")
        if not expl or len(str(expl).strip()) < 10:
            processed += 1
            yield json.dumps({"status": "progress", "message": f"Generating missing explanation {processed}/{missing_count} (Question {i+1})..."}) + "\n"
            
            sol_prompt = "Provide a detailed, step-by-step mathematical/scientific solution to this question. Output ONLY the raw explanation text (formatted in LaTeX using $ for math). Question: " + str(q.get("text", ""))
            sol_text, sol_err = generate_with_retry(sol_prompt, response_mime_type="text/plain")
            if sol_text:
                q["explanation"] = sol_text
            else:
                yield json.dumps({"status": "progress", "message": f"Failed to generate for Question {i+1}: {sol_err}"}) + "\n"

    yield json.dumps({"status": "complete", "questions": questions}) + "\n"

def upload_image_to_cloudinary(img_bytes):
    try:
        res = cloudinary.uploader.upload(img_bytes, resource_type="image", folder="edtech_pyqs_manual")
        return res.get("secure_url")
    except Exception as e:
        print(f"Manual cloudinary upload failed: {e}")
        return None
