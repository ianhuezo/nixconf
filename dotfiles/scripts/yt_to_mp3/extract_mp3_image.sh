#!/bin/sh
MP3_FOLDER="$1"
MP3_NAME="$2"
rm /tmp/FRONT_COVER* 2>/dev/null #first remove any front covers that could interfere
cd "$MP3_FOLDER"
eyeD3 \
  --write-images=/tmp/ \
  "$MP3_NAME" |
  grep "Writing /tmp/FRONT_COVER" |
  cut -d' ' -f2 |
  sed 's/\.\.\.$//'
