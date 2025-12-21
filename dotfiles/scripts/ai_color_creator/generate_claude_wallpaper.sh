#!/bin/sh

# Debug log file
LOG_FILE="/tmp/claude_wallpaper_debug.log"

echo "=== Claude Wallpaper Generation Debug ===" >>"$LOG_FILE"
echo "Timestamp: $(date)" >>"$LOG_FILE"
echo "Raw WALLPAPER_PATH argument: $1" >>"$LOG_FILE"
echo "Current shell: $SHELL" >>"$LOG_FILE"
echo "PATH: $PATH" >>"$LOG_FILE"
echo "USER: $USER" >>"$LOG_FILE"
echo "HOME: $HOME" >>"$LOG_FILE"
echo "PWD: $PWD" >>"$LOG_FILE"
echo "Claude location: $(which claude)" >>"$LOG_FILE"

WALLPAPER_PATH=$1
KMEANS_COLORS=$2

# Strip file:// prefix if present
WALLPAPER_PATH=${WALLPAPER_PATH#file://}

echo "Cleaned WALLPAPER_PATH: $WALLPAPER_PATH" >>"$LOG_FILE"
echo "Kmeans colors: $KMEANS_COLORS" >>"$LOG_FILE"

# Get the directory containing the wallpaper for --add-dir
WALLPAPER_DIR=$(dirname "$WALLPAPER_PATH")

echo "WALLPAPER_DIR: $WALLPAPER_DIR" >>"$LOG_FILE"
echo "Prompt file exists: $(test -f ~/.config/custom_scripts/ai_color_creator/prompt.md && echo yes || echo no)" >>"$LOG_FILE"
echo "Wallpaper file exists: $(test -f "$WALLPAPER_PATH" && echo yes || echo no)" >>"$LOG_FILE"

# Load and process prompt
PROMPT_CONTENT=$(cat ~/.config/custom_scripts/ai_color_creator/prompt.md 2>&1)
PROMPT_LENGTH=${#PROMPT_CONTENT}
echo "Prompt content length: $PROMPT_LENGTH characters" >>"$LOG_FILE"
if [ $PROMPT_LENGTH -eq 0 ]; then
  echo "ERROR: Prompt file is empty or could not be read" >>"$LOG_FILE"
fi

# Function to convert hex to HSL
hex_to_hsl() {
  local hex=$1
  # Remove # prefix
  hex=${hex#\#}

  # Convert hex to RGB (0-255)
  r=$((16#${hex:0:2}))
  g=$((16#${hex:2:2}))
  b=$((16#${hex:4:2}))

  # Use Python for accurate HSL conversion
  python3 -c "
import colorsys
r, g, b = $r/255.0, $g/255.0, $b/255.0
h, l, s = colorsys.rgb_to_hls(r, g, b)
h = int(h * 360)
s = int(s * 100)
l = int(l * 100)
print(f'hsl({h}, {s}%, {l}%)')
"
}

# Inject kmeans colors into prompt
if [ -n "$KMEANS_COLORS" ]; then
  # Format: #hex%pct,#hex%pct,... -> readable list with HSL values
  KMEANS_FORMATTED=$(echo "$KMEANS_COLORS" | awk -F',' '{
    for (i=1; i<=NF; i++) {
      split($i, a, "%")
      printf "%s|%s\n", a[1], a[2]
    }
  }' | while IFS='|' read -r hex pct; do
    hsl=$(hex_to_hsl "$hex")
    printf "- %s = %s (%s%%)\n" "$hex" "$hsl" "$pct"
  done)

  # Use awk to replace placeholder, avoiding sed's pattern matching issues
  TEMP_FORMATTED=$(mktemp)
  printf '%s' "$KMEANS_FORMATTED" > "$TEMP_FORMATTED"
  PROMPT_CONTENT=$(awk -v replacement="$KMEANS_FORMATTED" '
    /\*\*KMEANS_COLORS_PLACEHOLDER\*\*/ {
      print replacement
      next
    }
    { print }
  ' <<< "$PROMPT_CONTENT")
  rm -f "$TEMP_FORMATTED"
  echo "Injected kmeans colors into prompt (with HSL)" >>"$LOG_FILE"
else
  # Remove placeholder if no kmeans colors
  PROMPT_CONTENT=$(echo "$PROMPT_CONTENT" | sed '/\*\*3\. K-Means Color Reference/,/^---$/d')
  echo "No kmeans colors provided, removed section from prompt" >>"$LOG_FILE"
fi

echo "Starting Claude Code execution..." >>"$LOG_FILE"
echo "Start time: $(date +%s)" >>"$LOG_FILE"

# Capture both stdout and stderr separately
STDOUT_FILE="/tmp/claude_stdout_$$.txt"
STDERR_FILE="/tmp/claude_stderr_$$.txt"

# Run Claude Code with the image and hardcoded prompt path (same as Gemini script)
# Use defaultMode with explicit Read allow list for the directories
# Redirect stdin from /dev/null and set TERM=dumb to prevent hanging when called from QuickShell
# Expand the wallpaper dir path in the permissions
# For absolute paths, prepend / with // (so /home becomes //home)
WALLPAPER_DIR_PATTERN="/${WALLPAPER_DIR#/}"
WALLPAPER_PATH_PATTERN="/${WALLPAPER_PATH#/}"
SETTINGS_JSON="{\"defaultMode\":\"acceptEdits\",\"permissions\":{\"allow\":[\"Read(/$WALLPAPER_DIR_PATTERN/**)\",\"Read(~/.config/custom_scripts/ai_color_creator/**)\",\"Read(/$WALLPAPER_PATH_PATTERN)\"]}}"
echo "Settings JSON: $SETTINGS_JSON" >>"$LOG_FILE"
TERM=dumb claude -p --add-dir "$WALLPAPER_DIR" --settings "$SETTINGS_JSON" --print --output-format json "Read $WALLPAPER_PATH $PROMPT_CONTENT" </dev/null >"$STDOUT_FILE" 2>"$STDERR_FILE" &

# Get the PID of the background process
CLAUDE_PID=$!
echo "Claude PID: $CLAUDE_PID" >>"$LOG_FILE"

# Wait for the process with a timeout (180 seconds / 3 minutes)
TIMEOUT=180
COUNT=0
while kill -0 "$CLAUDE_PID" 2>/dev/null; do
  if [ $COUNT -ge $TIMEOUT ]; then
    echo "ERROR: Claude timed out after ${TIMEOUT}s, killing process" >>"$LOG_FILE"
    kill -9 "$CLAUDE_PID" 2>/dev/null
    echo '{"error": "Claude process timed out"}' >"$STDOUT_FILE"
    EXIT_CODE=124
    break
  fi
  sleep 1
  COUNT=$((COUNT + 1))
done

# Get exit code if process finished normally
if [ $COUNT -lt $TIMEOUT ]; then
  wait "$CLAUDE_PID"
  EXIT_CODE=$?
fi

echo "End time: $(date +%s)" >>"$LOG_FILE"
echo "Claude Code exit code: $EXIT_CODE" >>"$LOG_FILE"
echo "STDOUT length: $(wc -c <"$STDOUT_FILE") bytes" >>"$LOG_FILE"
echo "STDERR length: $(wc -c <"$STDERR_FILE") bytes" >>"$LOG_FILE"

# Output stdout to console (for QML to capture)
cat "$STDOUT_FILE"

# Log stderr for debugging
if [ -s "$STDERR_FILE" ]; then
  echo "STDERR content:" >>"$LOG_FILE"
  cat "$STDERR_FILE" >>"$LOG_FILE"
fi

# Cleanup temp files
rm -f "$STDOUT_FILE" "$STDERR_FILE"
echo "=== End Debug ===" >>"$LOG_FILE"
echo "" >>"$LOG_FILE"

exit $EXIT_CODE
