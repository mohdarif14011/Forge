import os
import json
import fitz  # PyMuPDF
from huggingface_hub import hf_hub_download
from llama_cpp import Llama

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------
PDF_PATH = "temp_PYQ.pdf"  # Path to your PDF file
OUTPUT_JSON = "extracted_questions.json"

# We use a 4-bit quantized version of Llama-3-8B to fit perfectly in a free 16GB GPU (like Colab T4)
MODEL_REPO = "QuantFactory/Meta-Llama-3-8B-Instruct-GGUF"
MODEL_FILE = "Meta-Llama-3-8B-Instruct.Q4_K_M.gguf"
MODEL_DIR = "./models"

# ---------------------------------------------------------------------------
# Step 1: Download the Model (Only happens once)
# ---------------------------------------------------------------------------
def download_model():
    os.makedirs(MODEL_DIR, exist_ok=True)
    model_path = os.path.join(MODEL_DIR, MODEL_FILE)
    
    if not os.path.exists(model_path):
        print(f"Downloading model {MODEL_FILE}... This might take a few minutes (approx 4.7GB).")
        hf_hub_download(
            repo_id=MODEL_REPO,
            filename=MODEL_FILE,
            local_dir=MODEL_DIR
        )
        print("Download complete!")
    else:
        print("Model already exists locally.")
    return model_path

# ---------------------------------------------------------------------------
# Step 2: Initialize LLM
# ---------------------------------------------------------------------------
def initialize_llm(model_path):
    print("Loading model into GPU...")
    # n_gpu_layers=-1 offloads all layers to the GPU
    # n_ctx=4096 gives it enough context window to read a full page at a time
    llm = Llama(
        model_path=model_path,
        n_gpu_layers=-1, 
        n_ctx=4096,      
        verbose=False    
    )
    return llm

# ---------------------------------------------------------------------------
# Step 3: Extract Questions
# ---------------------------------------------------------------------------
def extract_questions_from_text(llm, text, page_num):
    print(f"Processing Page {page_num}...")
    
    # Prompt engineering to ensure JSON output
    prompt = f"""<|begin_of_text|><|start_header_id|>system<|end_header_id|>

You are an expert at extracting examination questions from raw text.
Extract all the questions from the provided text.
Ignore syllabus information, headers, page numbers, or irrelevant context.
Return ONLY a valid JSON list of strings containing the questions.
Example Output: ["What is the capital of France?", "Explain Newton's second law."]
If there are no questions in the text, return an empty list: []
<|eot_id|><|start_header_id|>user<|end_header_id|>

Here is the text from Page {page_num}:
{text}
<|eot_id|><|start_header_id|>assistant<|end_header_id|>
"""
    
    # Generate response
    response = llm(
        prompt,
        max_tokens=1024,
        stop=["<|eot_id|>"],
        temperature=0.1 # Low temperature for more deterministic/factual output
    )
    
    output_text = response['choices'][0]['text'].strip()
    
    # Clean up the output to ensure it's valid JSON
    # Sometimes models wrap output in ```json ... ``` blocks
    if output_text.startswith("```json"):
        output_text = output_text[7:]
    if output_text.startswith("```"):
        output_text = output_text[3:]
    if output_text.endswith("```"):
        output_text = output_text[:-3]
    
    output_text = output_text.strip()
    
    try:
        questions = json.loads(output_text)
        if isinstance(questions, list):
            return questions
        else:
            print(f"Warning: Model didn't return a list on page {page_num}. Raw output: {output_text}")
            return []
    except json.JSONDecodeError:
        print(f"Failed to parse JSON on page {page_num}. Raw output: {output_text}")
        return []

# ---------------------------------------------------------------------------
# Main Execution
# ---------------------------------------------------------------------------
def main():
    if not os.path.exists(PDF_PATH):
        print(f"Error: PDF file '{PDF_PATH}' not found.")
        return

    # 1. Download Model
    model_path = download_model()
    
    # 2. Load Model
    llm = initialize_llm(model_path)
    
    # 3. Read PDF
    print(f"Opening {PDF_PATH}...")
    doc = fitz.open(PDF_PATH)
    total_pages = len(doc)
    print(f"PDF has {total_pages} pages.")
    
    all_extracted_questions = []
    
    # 4. Process Page by Page
    for page_num in range(total_pages):
        page = doc.load_page(page_num)
        text = page.get_text("text").strip()
        
        # Skip empty pages
        if len(text) < 20: 
            print(f"Skipping Page {page_num + 1} (not enough text).")
            continue
            
        questions = extract_questions_from_text(llm, text, page_num + 1)
        
        if questions:
            print(f"-> Extracted {len(questions)} questions from Page {page_num + 1}")
            all_extracted_questions.extend(questions)
        else:
            print(f"-> No questions found on Page {page_num + 1}")
            
    # 5. Save Output
    print(f"\nExtraction complete! Found {len(all_extracted_questions)} questions in total.")
    with open(OUTPUT_JSON, "w", encoding="utf-8") as f:
        json.dump(all_extracted_questions, f, indent=4, ensure_ascii=False)
        
    print(f"Saved all questions to {OUTPUT_JSON}")

if __name__ == "__main__":
    main()
