#!/bin/sh
ALBUM_NAME="$1"
ALBUM_ARTIST="$2"
ALBUM_ART_PATH="$3"
ALBUM_MP3_PATH="$4"
ALBUM_MP3_OUT_PATH="$5"

# Debug output for eyeD3 command
echo "DEBUG: Starting eyeD3 metadata tagging..."
echo "DEBUG: ALBUM_NAME='$ALBUM_NAME'"
echo "DEBUG: ALBUM_ARTIST='$ALBUM_ARTIST'"
echo "DEBUG: ALBUM_ART_PATH='$ALBUM_ART_PATH'"
echo "DEBUG: ALBUM_MP3_PATH='$ALBUM_MP3_PATH'"

eyeD3 \
  --title "$ALBUM_NAME" \
  --artist "$ALBUM_ARTIST" \
  --add-image "$ALBUM_ART_PATH:FRONT_COVER" \
  --track "01" \
  "$ALBUM_MP3_PATH"

# Debug output for cp command
echo "DEBUG: Starting file copy operation..."
echo "DEBUG: ALBUM_MP3_OUT_PATH='$ALBUM_MP3_OUT_PATH'"
echo "DEBUG: Source file: '$ALBUM_MP3_PATH'"
echo "DEBUG: Destination directory: '$ALBUM_MP3_OUT_PATH'"
echo "DEBUG: Final destination: '$ALBUM_MP3_OUT_PATH/$ALBUM_NAME.mp3'"
echo "DEBUG: Current working directory before cd: $(pwd)"

cd ~ && echo "DEBUG: Changed to directory: $(pwd)" && cp "$ALBUM_MP3_PATH" "$ALBUM_MP3_OUT_PATH/$ALBUM_NAME.mp3"

# Check if copy was successful
if [ $? -eq 0 ]; then
    echo "DEBUG: File copy completed successfully"
else
    echo "DEBUG: File copy failed with exit code: $?"
fi

echo "DEBUG: Script execution completed"
