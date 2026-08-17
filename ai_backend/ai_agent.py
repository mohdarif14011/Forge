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
from pydantic import BaseModel, Field
from typing import List, Optional

class QuestionSchema(BaseModel):
    text: str = Field(description="The question text (extract from 'question', 'questionText', etc.)")
    options: List[str] = Field(description="A list of exactly 4 strings. If no options exist or it's an integer question, use an empty list []")
    correctAnswer: str = Field(description="The correct option string or integer (extract from 'answer', 'correct', 'ans', etc.)")
    explanation: Optional[str] = Field(default="", description="The solution or explanation. Leave empty if none exists.")
    marks: Optional[int] = Field(default=None, description="The positive marks for the question")
    negativeMarks: Optional[int] = Field(default=None, description="The negative marks for the question")
    year: Optional[str] = Field(default=None, description="The exam year (e.g., '2023')")
    date: Optional[str] = Field(default=None, description="The exam date (e.g., '24 Jan 2023')")
    shift: Optional[str] = Field(default=None, description="The exam shift (e.g., 'Morning Shift')")

class QuestionListSchema(BaseModel):
    questions: List[QuestionSchema]


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

def generate_with_retry(prompt, images=None, response_mime_type="application/json", response_schema=None):
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

            config_args = {
                "response_mime_type": response_mime_type,
                "temperature": 0.1,
                "max_output_tokens": 8192
            }
            if response_schema:
                config_args["response_schema"] = response_schema

            response = current_client.models.generate_content(
                model='gemini-2.5-flash',
                contents=contents,
                config=types.GenerateContentConfig(**config_args)
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
    Takes raw JSON text, tries to parse it natively, and falls back to AI to fix syntax errors.
    Then finds those without a valid explanation to generate step-by-step solutions.
    """
    if not gemini_api_keys:
        yield json.dumps({"status": "error", "message": "GEMINI_API_KEY is not set in environment."}) + "\n"
        return

    questions = None
    native_parse_success = False

    def find_questions_list(d):
        if isinstance(d, list):
            return d
        if isinstance(d, dict):
            for k in ["questions", "data", "results", "Sheet1"]:
                if k in d and isinstance(d[k], list):
                    return d[k]
            for v in d.values():
                if isinstance(v, list) and len(v) > 0 and isinstance(v[0], dict):
                    return v
        return [d] if isinstance(d, dict) else d

    try:
        # Try native python JSON decoding first
        try:
            data = json.loads(raw_text.strip())
        except json.JSONDecodeError:
            import ast
            import re
            text_eval = raw_text.strip().replace('\n', ' ').replace('\r', '')
            text_eval = re.sub(r'\btrue\b', 'True', text_eval)
            text_eval = re.sub(r'\bfalse\b', 'False', text_eval)
            text_eval = re.sub(r'\bnull\b', 'None', text_eval)
            data = ast.literal_eval(text_eval)
            
        raw_questions = find_questions_list(data)
        if not isinstance(raw_questions, list):
            raw_questions = [raw_questions]
            
        # Normalize keys in Python
        questions = []
        for q in raw_questions:
            if not isinstance(q, dict):
                continue
            # Extract text
            text = q.get("text") or q.get("question") or q.get("questionText") or q.get("question_text") or q.get("Question") or ""
            # Extract options
            options = q.get("options") or q.get("choices") or q.get("Options") or q.get("Choices")
            if options is None:
                options = []
            elif isinstance(options, dict):
                options = list(options.values())
            elif not isinstance(options, list):
                options = [str(options)]
            
            # Extract correctAnswer
            correct_answer = q.get("correctAnswer")
            if correct_answer is None:
                correct_answer = q.get("correct_option") or q.get("answer") or q.get("correct") or q.get("ans") or q.get("Answer") or q.get("correct_answer") or ""
            
            # Extract explanation
            explanation = q.get("explanation")
            if explanation is None:
                explanation = q.get("solution") or q.get("exp") or q.get("Explanation") or q.get("Solution") or ""
                
            if not text and not options and not correct_answer:
                continue
                
            questions.append({
                "text": str(text),
                "options": [str(o) for o in options],
                "correctAnswer": str(correct_answer),
                "explanation": str(explanation),
                "marks": q.get("marks") or q.get("Marks"),
                "negativeMarks": q.get("negativeMarks") or q.get("NegativeMarks"),
                "year": q.get("year") or q.get("Year"),
                "date": q.get("date") or q.get("Date"),
                "shift": q.get("shift") or q.get("Shift")
            })
            
        if not questions:
            raise ValueError("No valid questions found")
            
        native_parse_success = True
        yield json.dumps({"status": "progress", "message": f"Successfully parsed {len(questions)} questions natively..."}) + "\n"
    except Exception as e:
        yield json.dumps({"status": "progress", "message": f"Native JSON parse failed ({str(e)}). Falling back to AI to fix syntax errors..."}) + "\n"

    if not native_parse_success:
        prompt = """
        You are given a raw, potentially malformed JSON text containing exam questions.
        Fix any JSON syntax errors and extract the data into a valid JSON array of objects with the exact following schema:
        - 'text': The question text (extract from 'question', 'questionText', etc.)
        - 'options': A list of exactly 4 strings. If no options exist or it's an integer question, use an empty list `[]`.
        - 'correctAnswer': The correct option string or integer (extract from 'answer', 'correct', 'ans', etc.)
        - 'explanation': The solution or explanation (extract from 'solution', 'exp', etc.). Leave empty `""` if none exists.
        - 'marks': (optional integer)
        - 'negativeMarks': (optional integer)
        - 'year': (optional string)
        - 'date': (optional string)
        - 'shift': (optional string)
        
        CRITICAL: Return ONLY a valid JSON array. Do not include markdown blocks like ```json.
        CRITICAL: Ensure ALL backslashes in LaTeX or math formulas are double-escaped (e.g., \\\\sin instead of \\sin) so the output is strictly valid JSON.
        CRITICAL: DO NOT include literal newlines inside JSON strings. Use \\n for line breaks.
        
        Raw text to process:
        """ + raw_text[:500000] # safeguard for token limit

        normalized_text, err = generate_with_retry(
            prompt,
            response_mime_type="application/json",
            response_schema=QuestionListSchema
        )
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
            
            clean_text = clean_text.strip()
            try:
                data = json.loads(clean_text, strict=False)
            except json.JSONDecodeError as jde:
                # Fallback: Python's ast.literal_eval is much more forgiving with invalid escapes (like \c, \s) than json.loads
                import ast
                import re
                
                # Replace literal newlines to avoid string literal EOL errors
                text_eval = clean_text.replace('\n', ' ').replace('\r', '')
                # Map JSON keywords to Python keywords
                text_eval = re.sub(r'\btrue\b', 'True', text_eval)
                text_eval = re.sub(r'\bfalse\b', 'False', text_eval)
                text_eval = re.sub(r'\bnull\b', 'None', text_eval)
                
                try:
                    data = ast.literal_eval(text_eval)
                except Exception as e2:
                    yield json.dumps({"status": "error", "message": f"AI failed to return valid JSON. JSON error: {str(jde)}. Raw output: {normalized_text}"}) + "\n"
                    return

            raw_questions = find_questions_list(data)
            questions = raw_questions if isinstance(raw_questions, list) else [raw_questions]
                
        except Exception as e:
            yield json.dumps({"status": "error", "message": f"AI failed to return valid JSON. Error: {str(e)}. Raw output: {normalized_text}"}) + "\n"
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
            
            sol_prompt = f"""Act as an expert math/science tutor.
Provide a highly detailed, complete, step-by-step solution to this question. 
Do not skip any steps. Clearly explain the logic and formulas used.
Output ONLY the raw explanation text (formatted in LaTeX using $ for inline math and $$ for block math). Do not include any other markdown formatting.

Question: {q.get('text', '')}
Options: {q.get('options', [])}
Correct Answer: {q.get('correctAnswer', '')}"""
            sol_text, sol_err = generate_with_retry(sol_prompt, response_mime_type="text/plain")
            if sol_text:
                q["explanation"] = sol_text
            else:
                yield json.dumps({"status": "progress", "message": f"Failed to generate for Question {i+1}: {sol_err}"}) + "\n"

    yield json.dumps({"status": "complete", "questions": questions}) + "\n"

def upload_image_to_cloudinary(img_bytes):
    # Dynamically load env and configure Cloudinary to ensure latest credentials are used
    load_dotenv(override=True)
    cloudinary.config(
        cloud_name=os.getenv("CLOUDINARY_CLOUD_NAME"),
        api_key=os.getenv("CLOUDINARY_API_KEY"),
        api_secret=os.getenv("CLOUDINARY_API_SECRET")
    )
    try:
        res = cloudinary.uploader.upload(io.BytesIO(img_bytes), resource_type="image", folder="edtech_pyqs_manual")
        return res.get("secure_url"), None
    except Exception as e:
        print(f"Manual cloudinary upload failed: {e}")
        return None, str(e)

