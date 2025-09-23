#!/bin/sh

WALLPAPER_PATH=$1
PROMPT_PATH=$2
API_KEY=$3

python ~/.config/custom_scripts/ai_color_creator/color_generator.py $WALLPAPER_PATH ~/.config/custom_scripts/ai_color_creator/prompt.md $API_KEY --quiet
