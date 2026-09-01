#!/bin/sh
# Line-buffered so quickshell's SplitParser sees each frame as it's produced.
# exec drops the relay shell: cava becomes the direct child of the Process.
exec stdbuf -oL cava -p "$HOME/.config/cava_conf/cava.conf"
