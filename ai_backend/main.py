from fastapi import FastAPI, UploadFile, File, HTTPException, Body
from fastapi.responses import StreamingResponse
from fastapi.middleware.cors import CORSMiddleware
import os
from dotenv import load_dotenv
from pydantic import BaseModel
from typing import List, Optional
from ai_agent import process_raw_json_file, upload_image_to_cloudinary, generate_with_retry

load_dotenv()
# Trigger reload after env update
app = FastAPI(title="EdTech AI PDF Extractor")

class FixSolutionRequest(BaseModel):
    question: str
    options: List[str]
    correctAnswer: str
    currentExplanation: str
    hint: str

# Allow requests from the React Admin Panel
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"], # In production, restrict this to your frontend URL
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.get("/")
def read_root():
    return {"status": "AI Backend is running"}

@app.post("/api/generate-missing-solutions")
async def generate_missing_solutions(file: UploadFile = File(...)):
    raw_bytes = await file.read()
    raw_text = raw_bytes.decode('utf-8')
    def stream_response():
        for chunk in process_raw_json_file(raw_text):
            yield chunk
            
    return StreamingResponse(stream_response(), media_type="application/x-ndjson")

@app.post("/api/upload-image")
async def upload_image(file: UploadFile = File(...)):
    img_bytes = await file.read()
    url, error = upload_image_to_cloudinary(img_bytes)
    if not url:
        raise HTTPException(status_code=500, detail=f"Failed to upload image: {error}")
    return {"url": url}

@app.post("/api/fix-solution")
async def fix_solution(req: FixSolutionRequest):
    prompt = f"""Act as an expert math/science tutor.
The previous solution generated for this question is incorrect or needs modification based on the following feedback: "{req.hint}"

Provide a highly detailed, complete, step-by-step solution to this question that addresses the feedback.
Do not skip any steps. Clearly explain the logic and formulas used.
Output ONLY the raw explanation text (formatted in LaTeX using $ for inline math and $$ for block math). Do not include any other markdown formatting.

Question: {req.question}
Options: {req.options}
Correct Answer: {req.correctAnswer}
Previous Incorrect Solution: {req.currentExplanation}"""
    
    sol_text, sol_err = generate_with_retry(prompt, response_mime_type="text/plain")
    if sol_err:
        raise HTTPException(status_code=500, detail=sol_err)
    return {"solution": sol_text}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)
