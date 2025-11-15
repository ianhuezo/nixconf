#!/usr/bin/env python

import sys
import os
import requests
import mimetypes
import json
from pathlib import Path
import re

# Configuration
BASE_URL = "https://generativelanguage.googleapis.com"

def get_mime_type(file_path):
    """Determine the MIME type of the image file."""
    mime_type, _ = mimetypes.guess_type(file_path)
    if mime_type and mime_type.startswith('image/'):
        return mime_type
    return 'image/jpeg'

def upload_file(file_path, api_key, quiet=False):
    """Upload the wallpaper file to Gemini API and return the file URI."""
    if not os.path.exists(file_path):
        raise FileNotFoundError(f"File not found: {file_path}")
    
    file_name = Path(file_path).name
    mime_type = get_mime_type(file_path)
    file_size = os.path.getsize(file_path)
    
    if not quiet:
        print(f"Uploading {file_name} ({file_size:,} bytes)...", file=sys.stderr)
    
    # ... rest of upload logic stays the same ...
    boundary = "foo_bar_baz"
    
    with open(file_path, 'rb') as f:
        file_data = f.read()
    
    body_parts = []
    metadata = {
        "file": {
            "display_name": f"wallpaper_{file_name}"
        }
    }
    body_parts.append(f"--{boundary}")
    body_parts.append("Content-Type: application/json")
    body_parts.append("")
    body_parts.append(json.dumps(metadata))
    
    body_parts.append(f"--{boundary}")
    body_parts.append(f"Content-Type: {mime_type}")
    body_parts.append("")
    
    body_text = "\r\n".join(body_parts) + "\r\n"
    body_end = f"\r\n--{boundary}--"
    body = body_text.encode('utf-8') + file_data + body_end.encode('utf-8')
    
    headers = {
        "X-Goog-Upload-Protocol": "multipart",
        "X-Goog-Upload-Command": "upload, finalize",
        "X-Goog-Upload-Header-Content-Length": str(file_size),
        "Content-Type": f"multipart/related; boundary={boundary}",
    }
    
    url = f"{BASE_URL}/upload/v1beta/files?key={api_key}"
    
    try:
        response = requests.post(url, headers=headers, data=body)
        response.raise_for_status()
        
        result = response.json()
        file_uri = result['file']['uri']
        if not quiet:
            print(f"Upload successful! File URI: {file_uri}", file=sys.stderr)
        return file_uri
        
    except requests.exceptions.RequestException as e:
        if not quiet:
            print(f"Upload failed: {e}", file=sys.stderr)
            if hasattr(e.response, 'text'):
                print(f"Error response: {e.response.text}", file=sys.stderr)
        raise

def read_prompt_file(prompt_path, quiet=False):
    """Read the custom prompt from a markdown file."""
    if not os.path.exists(prompt_path):
        raise FileNotFoundError(f"Prompt file not found: {prompt_path}")
    
    try:
        with open(prompt_path, 'r', encoding='utf-8') as f:
            prompt = f.read().strip()
        
        if not prompt:
            raise ValueError("Prompt file is empty")
            
        if not quiet:
            print(f"Loaded prompt from: {prompt_path}", file=sys.stderr)
        return prompt
        
    except Exception as e:
        raise Exception(f"Error reading prompt file: {e}")

def extract_json_from_text(text):
    """Extract JSON content from text that may contain markdown or other formatting."""
    # ... same as original ...
    json_block_pattern = r'```(?:json)?\s*(\{.*?\})\s*```'
    match = re.search(json_block_pattern, text, re.DOTALL | re.IGNORECASE)
    if match:
        try:
            return json.loads(match.group(1))
        except json.JSONDecodeError:
            pass
    
    json_pattern = r'\{[^{}]*(?:\{[^{}]*\}[^{}]*)*\}'
    matches = re.findall(json_pattern, text, re.DOTALL)
    
    for match in matches:
        try:
            parsed = json.loads(match)
            return parsed
        except json.JSONDecodeError:
            continue
    
    array_pattern = r'\[[^\[\]]*(?:\[[^\[\]]*\][^\[\]]*)*\]'
    matches = re.findall(array_pattern, text, re.DOTALL)
    
    for match in matches:
        try:
            parsed = json.loads(match)
            return parsed
        except json.JSONDecodeError:
            continue
    
    return None

def analyze_wallpaper(file_uri, file_path, prompt, api_key, quiet=False):
    """Send the uploaded file to Gemini for analysis."""
    mime_type = get_mime_type(file_path)

    payload = {
        "contents": [{
            "parts": [
                {"text": prompt},
                {
                    "file_data": {
                        "mime_type": mime_type,
                        "file_uri": file_uri
                    }
                }
            ]
        }],
        "generationConfig": {
              "temperature": 1.0,
              "topK": 64,
              "topP": 0.95,
              "maxOutputTokens": 8192
        }
    }
    
    url = f"{BASE_URL}/v1beta/models/gemini-2.5-pro:generateContent?key={api_key}"
    headers = {"Content-Type": "application/json"}
    
    if not quiet:
        print("Analyzing wallpaper...", file=sys.stderr)
    
    try:
        response = requests.post(url, headers=headers, json=payload)
        response.raise_for_status()
        
        result = response.json()
        
        if 'candidates' in result and len(result['candidates']) > 0:
            content = result['candidates'][0]['content']['parts'][0]['text']
            return content
        else:
            return "No analysis generated."
            
    except requests.exceptions.RequestException as e:
        if not quiet:
            print(f"Analysis failed: {e}", file=sys.stderr)
            if hasattr(e.response, 'text'):
                print(f"Error response: {e.response.text}", file=sys.stderr)
        raise

def cleanup_file(file_uri, api_key, quiet=False):
    """Optional: Delete the uploaded file from Gemini storage."""
    try:
        file_id = file_uri.split('/')[-1]
        url = f"{BASE_URL}/v1beta/files/{file_id}?key={api_key}"
        
        response = requests.delete(url)
        if response.status_code == 200 and not quiet:
            print("Uploaded file cleaned up successfully.", file=sys.stderr)
    except Exception as e:
        if not quiet:
            print(f"Warning: Could not clean up uploaded file: {e}", file=sys.stderr)

def main():
    # Check for quiet flag
    quiet = "--quiet" in sys.argv
    if quiet:
        sys.argv.remove("--quiet")
    
    if len(sys.argv) != 4:
        print("Usage: python wallpaper_analyzer.py <path_to_image> <path_to_prompt_file> <api_key> [--quiet]")
        print("Example: python wallpaper_analyzer.py ~/Downloads/wallpaper.jpg prompts/analyze.md AIzaSyC... --quiet")
        print("\nUse --quiet to suppress status messages (useful for piping)")
        print("Get your API key from: https://makersuite.google.com/app/apikey")
        sys.exit(1)
    
    file_path = sys.argv[1]
    prompt_path = sys.argv[2]
    api_key = sys.argv[3]
    
    try:
        prompt = read_prompt_file(prompt_path, quiet)
        file_uri = upload_file(file_path, api_key, quiet)
        analysis = analyze_wallpaper(file_uri, file_path, prompt, api_key, quiet)
        
        # Extract and output JSON
        output = extract_json_from_text(analysis)
        if output:
            print(json.dumps(output, indent=2))  # Pretty JSON to stdout
        else:
            print(analysis)  # Fallback to raw text
        
        cleanup_file(file_uri, api_key, quiet)
        return output
        
    except Exception as e:
        print(f"Error: {e}", file=sys.stderr)
        sys.exit(1)

if __name__ == "__main__":
    main()
