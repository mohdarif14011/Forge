from fastapi import FastAPI, UploadFile, File, HTTPException
from fastapi.responses import StreamingResponse
from fastapi.middleware.cors import CORSMiddleware
import os
from dotenv import load_dotenv
from pydantic import BaseModel
from typing import List, Optional
from ai_agent import process_raw_json_file, upload_image_to_cloudinary

load_dotenv()

app = FastAPI(title="EdTech AI PDF Extractor")

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
    url = upload_image_to_cloudinary(img_bytes)
    if not url:
        raise HTTPException(status_code=500, detail="Failed to upload image")
    return {"url": url}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)
