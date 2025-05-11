#!/bin/sh

# Try multiple methods to find the process
if pgrep -x ".quickshell-wra"; then
  pkill quickshell
else
  quickshell -p ~/.config/quickshell/bar/shell.qml
fi
