import yt_dlp
import sys
import json
import os
from yt_dlp.utils import sanitize_filename
import re
from datetime import datetime
import hashlib
import re
import glob

current_time = datetime.now().strftime("%Y%m%d%H%M%S")
hash_input = current_time.encode()
sha_hash = hashlib.sha256(hash_input).hexdigest()[:6]

# Configure UTF-8 output
sys.stdout.reconfigure(encoding='utf-8')

status = {
    "percentage": 0,
    "title": "",
    "uploader": "",
    "audio_path": "",
    "thumbnail_path": "",
    "display_id": "",
    "error": ""
}

def parse_arguments():
    """Parse and validate arguments with enhanced error handling"""
    try:
        if len(sys.argv) not in [3, 5]:
            raise ValueError("Invalid argument count")
            
        if len(sys.argv) == 5:
            start, end, quality, url = sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4]
            try:
                start = float(start) if start else None
                end = float(end) if end else None
            except ValueError:
                raise ValueError("Invalid start/end time format")
        else:
            start, end = None, None
            quality, url = sys.argv[1], sys.argv[2]

        return start, end, quality, url

    except Exception as e:
        status["error"] = f"Argument error: {str(e)}"
        print(json.dumps(status, ensure_ascii=False))
        sys.exit(1)

def sanitize_path(path):
    """Handle filesystem-safe names with proper encoding"""
    try:
        return os.path.normpath(path)
    except Exception as e:
        status["error"] = f"Path error: {str(e)}"
        print(json.dumps(status, ensure_ascii=False))
        sys.exit(1)

def extract_metadata(url):
    """Extract metadata with proper Unicode handling"""
    try:
        with yt_dlp.YoutubeDL({"quiet": True}) as ydl:
            meta = ydl.extract_info(url, download=False)
            status["title"] = meta.get("title", "")
            status["uploader"] = meta.get("uploader", "")
            status["id"] = meta.get("display_id", "")
    except Exception as e:
        status["error"] = f"Metadata error: {str(e)}"
        print(json.dumps(status, ensure_ascii=False))
        sys.exit(1)

def progress_hook(d):
    """Improved progress callback with regex and path pre-generation"""
    try:
        if d["status"] == "downloading":
            # Regex pattern to handle various percentage formats
            percent_str = d.get("_percent_str", "0%")
            match = re.search(r"(\d+[\.,]?\d*)%?", percent_str)
            
            if match:
                percent_value = match.group(1).replace(',', '.')
                status["percentage"] = min(100, max(0, round(float(percent_value))))
            else:
                status["percentage"] = 0

        elif d["status"] == "finished":
            status["percentage"] = 100
        print(json.dumps(status, ensure_ascii=False))
        sys.stdout.flush()

    except Exception as e:
        status["error"] = f"Progress error: {str(e)}"
        print(json.dumps(status, ensure_ascii=False))
        sys.exit(1)

def main():
    start, end, quality, url = parse_arguments()
    extract_metadata(url)
    
    # Pre-sanitize the title for the output template
    raw_title = status["title"]  # Get the title from extract_metadata
    sanitized_title = sanitize_filename(raw_title.lstrip())
    
    # Replace problematic characters that yt-dlp converts to Unicode equivalents
    char_replacements = {
        "/": " ",   # Forward slash
        "⧸": " ",   # Division slash (Unicode replacement for /)
        "|": " ",   # Pipe
        "｜": " ",  # Fullwidth pipe (Unicode replacement for |)
        "?": " ",   # Question mark  
        "？": " ",  # Fullwidth question mark (Unicode replacement for ?)
        "*": " ",   # Asterisk
        "＊": " ",  # Fullwidth asterisk (Unicode replacement for *)
        "<": " ",   # Less than
        "＜": " ",  # Fullwidth less than (Unicode replacement for <)
        ">": " ",   # Greater than
        "＞": " ",  # Fullwidth greater than (Unicode replacement for >)
        ":": " ",   # Colon
        "：": " ",  # Fullwidth colon (Unicode replacement for :)
        '"': " ",   # Quote
        "＂": " ",  # Fullwidth quote (Unicode replacement for ")
        "\\": " ",  # Backslash
        "＼": " ",  # Fullwidth backslash (Unicode replacement for \)
    }
    
    # Apply all character replacements
    for old_char, new_char in char_replacements.items():
        sanitized_title = sanitized_title.replace(old_char, new_char)
    
    # Collapse multiple spaces
    sanitized_title = re.sub(r'\s+', ' ', sanitized_title).strip()
    
    # Configure sanitized output templates using the pre-sanitized title
    ydl_opts = {
        "format": "bestaudio/best",
        "postprocessors": [
            {
                "key": "FFmpegThumbnailsConvertor",
                "format": "png",
                "when": "before_dl"
            },
            {
                "key": "FFmpegExtractAudio",
                "preferredcodec": "mp3",
                "preferredquality": quality,
            }
        ],
        "writethumbnail": True,
        "outtmpl": {
            "default": f"/tmp/{sanitized_title}_{sha_hash}.%(ext)s",
            "thumbnail": f"/tmp/{sanitized_title}_{sha_hash}.%(ext)s"
        },
        "progress_hooks": [progress_hook],
        "quiet": True,
        "restrictfilenames": False,  # Allow Unicode in sanitized names
        "windowsfilenames": False
    }
    # Add time restrictions if specified
    if start is not None or end is not None:
        ydl_opts["postprocessor_args"] = [
            f"-ss {start}" if start else "",
            f"-to {end}" if end else ""
        ]
    try:
        with yt_dlp.YoutubeDL(ydl_opts) as ydl:
            info = ydl.extract_info(url, download=True)
            
            # The files should now be created with the sanitized filename
            audio_path = f"/tmp/{sanitized_title}_{sha_hash}.mp3"
            thumbnail_path = f"/tmp/{sanitized_title}_{sha_hash}.png"
            
            # Fallback: scan the /tmp directory for files with the hash if direct path doesn't work
            if not os.path.exists(audio_path):
                # Look for any mp3 file with our hash
                mp3_files = glob.glob(f"/tmp/*_{sha_hash}.mp3")
                audio_path = mp3_files[0] if mp3_files else ""
            
            if not os.path.exists(thumbnail_path):
                # Look for any png file with our hash
                png_files = glob.glob(f"/tmp/*_{sha_hash}.png")
                thumbnail_path = png_files[0] if png_files else ""
            
            # Update status with verified paths
            status.update({
                "audio_path": audio_path if os.path.exists(audio_path) else "",
                "thumbnail_path": thumbnail_path if os.path.exists(thumbnail_path) else ""
            })
            
            print(json.dumps(status, ensure_ascii=False))
            
    except Exception as e:
        status["error"] = f"Processing error: {str(e)}"
        print(json.dumps(status, ensure_ascii=False))
        sys.exit(1)
        
if __name__ == "__main__":
    main()
