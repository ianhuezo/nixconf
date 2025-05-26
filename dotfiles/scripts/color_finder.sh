#!/bin/sh

# Search for color codes in all files from the current directory
grep -rnI --color=never -E -o \
'rgba?\([^)]*\)|#([A-Fa-f0-9]{6}|[A-Fa-f0-9]{3})' . | \
# Format output as: filename,line_number,color_code
sed -E 's/^([^:]+):([^:]+):/\1,\2,/' | \
# Display in fzf with preview
fzf --delimiter=, \
    --preview 'echo -e "File: {1}\nLine: {2}\nColor: \033[38;5;13m{3}\033[0m"' \
    --preview-window=up:3
