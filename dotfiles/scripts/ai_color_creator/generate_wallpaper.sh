#!/bin/sh

WALLPAPER_PATH=$1
PROMPT_PATH=$2
API_KEY=$3

python color_generator.py $WALLPAPER_PATH $PROMPT_PATH $API_KEY --quiet
