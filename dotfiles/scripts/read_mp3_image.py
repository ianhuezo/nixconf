import eyed3
from io import BytesIO
from PIL import Image  # Requires Pillow library
import sys

art_location = sys.argv[0]
tmp_cached_location = sys.argv[1]

def extract_album_art(mp3_path):
    # Load the MP3 file
    audio = eyed3.load(mp3_path)
    if not audio or not audio.tag:
        raise ValueError("No ID3 tag found in the MP3 file.")

    # Get all embedded images (album art)
    images = audio.tag.images
    if not images:
        raise ValueError("No album art found in the MP3 file.")

    # Find the front cover image (or use the first image)
    front_cover = None
    for img in images:
        if img.picture_type == eyed3.id3.frames.ImageFrame.FRONT_COVER:
            front_cover = img
            break
    if not front_cover:
        front_cover = images[0]  # Fallback to first image

    # Load image data into a buffer (BytesIO)
    buffer = BytesIO(front_cover.image_data)
    buffer.seek(0)  # Reset buffer position to the start

    # Optional: Render with Pillow (for display/processing)
    # Or: img.save("output.jpg") to save it
    img.save(f"{tmp_cached_location}"


extract_album_art(f"{art_location}")
