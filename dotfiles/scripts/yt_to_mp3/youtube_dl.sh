#!/bin/sh

RESOLUTION=$1
URL=$2
python ~/.config/custom_scripts/yt_to_mp3/youtube_dl_preview.py $RESOLUTION $URL
