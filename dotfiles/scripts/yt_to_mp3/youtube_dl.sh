#!/bin/bash
#Example script that runs
if [ "$#" -lt 2 ]; then
    echo "Usage: $0 <resolution> <youtube-url>"
    exit 1
fi

RESOLUTION=$1
URL=$2

python youtube_dl_preview.py $RESOLUTION $URL
