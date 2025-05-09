#!/bin/sh
# Disable output buffering with `stdbuf -oL`
stdbuf -oL cava -p ~/.config/cava_conf/cava.conf | while read -r line; do
  echo "$line" # Stream raw values (space-separated)
done
