#!/bin/sh

# Debug log file
LOG_FILE="/tmp/claude_wallpaper_debug.log"

echo "=== Claude Wallpaper Generation Debug ===" >> "$LOG_FILE"
echo "Timestamp: $(date)" >> "$LOG_FILE"
echo "Raw WALLPAPER_PATH argument: $1" >> "$LOG_FILE"
echo "Current shell: $SHELL" >> "$LOG_FILE"
echo "PATH: $PATH" >> "$LOG_FILE"
echo "USER: $USER" >> "$LOG_FILE"
echo "HOME: $HOME" >> "$LOG_FILE"
echo "PWD: $PWD" >> "$LOG_FILE"
echo "Claude location: $(which claude)" >> "$LOG_FILE"

WALLPAPER_PATH=$1

# Strip file:// prefix if present
WALLPAPER_PATH=${WALLPAPER_PATH#file://}

echo "Cleaned WALLPAPER_PATH: $WALLPAPER_PATH" >> "$LOG_FILE"

# Get the directory containing the wallpaper for --add-dir
WALLPAPER_DIR=$(dirname "$WALLPAPER_PATH")

echo "WALLPAPER_DIR: $WALLPAPER_DIR" >> "$LOG_FILE"
echo "Prompt file exists: $(test -f ~/.config/custom_scripts/ai_color_creator/prompt.md && echo yes || echo no)" >> "$LOG_FILE"
echo "Wallpaper file exists: $(test -f "$WALLPAPER_PATH" && echo yes || echo no)" >> "$LOG_FILE"

# Check prompt content length
PROMPT_CONTENT=$(cat ~/.config/custom_scripts/ai_color_creator/prompt.md 2>&1)
PROMPT_LENGTH=${#PROMPT_CONTENT}
echo "Prompt content length: $PROMPT_LENGTH characters" >> "$LOG_FILE"
if [ $PROMPT_LENGTH -eq 0 ]; then
    echo "ERROR: Prompt file is empty or could not be read" >> "$LOG_FILE"
fi

echo "Starting Claude Code execution..." >> "$LOG_FILE"
echo "Start time: $(date +%s)" >> "$LOG_FILE"

# Build the command for logging
CMD="claude --add-dir \"$WALLPAPER_DIR\" --settings '{\"defaultMode\":\"acceptEdits\",\"permissions\":{\"allow\":[\"Read($WALLPAPER_DIR/**)\",\"Read(~/.config/custom_scripts/ai_color_creator/**)\"]}}'  --print --output-format json \"Read $WALLPAPER_PATH \$(cat ~/.config/custom_scripts/ai_color_creator/prompt.md)\""
echo "Command to execute: $CMD" >> "$LOG_FILE"

# Capture both stdout and stderr separately
STDOUT_FILE="/tmp/claude_stdout_$$.txt"
STDERR_FILE="/tmp/claude_stderr_$$.txt"

# Run Claude Code with the image and hardcoded prompt path (same as Gemini script)
# Use defaultMode with explicit Read allow list for the directories
# Redirect stdin from /dev/null to prevent hanging when called from QuickShell
claude --add-dir "$WALLPAPER_DIR" --settings "{\"defaultMode\":\"acceptEdits\",\"permissions\":{\"allow\":[\"Read($WALLPAPER_DIR/**)\",\"Read(~/.config/custom_scripts/ai_color_creator/**)\"]}}" --print --output-format json "Read $WALLPAPER_PATH $(cat ~/.config/custom_scripts/ai_color_creator/prompt.md)" < /dev/null > "$STDOUT_FILE" 2> "$STDERR_FILE"

EXIT_CODE=$?
echo "End time: $(date +%s)" >> "$LOG_FILE"
echo "Claude Code exit code: $EXIT_CODE" >> "$LOG_FILE"
echo "STDOUT length: $(wc -c < "$STDOUT_FILE") bytes" >> "$LOG_FILE"
echo "STDERR length: $(wc -c < "$STDERR_FILE") bytes" >> "$LOG_FILE"

# Output stdout to console (for QML to capture)
cat "$STDOUT_FILE"

# Log stderr for debugging
if [ -s "$STDERR_FILE" ]; then
    echo "STDERR content:" >> "$LOG_FILE"
    cat "$STDERR_FILE" >> "$LOG_FILE"
fi

# Cleanup temp files
rm -f "$STDOUT_FILE" "$STDERR_FILE"
echo "=== End Debug ===" >> "$LOG_FILE"
echo "" >> "$LOG_FILE"

exit $EXIT_CODE
