!/bin/sh

magick "$1" -coalesce -define webp:lossless=true "$2"
