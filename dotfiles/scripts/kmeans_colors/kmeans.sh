#!/usr/bin/env bash

# K-means color extraction wrapper script
# Outputs comma-separated tuples: (#hex,pct),(#hex,pct),...

IMAGE_PATH="$1"
K="${2:-10}"  # Default to 10 colors if not specified

if [ -z "$IMAGE_PATH" ]; then
    echo "Error: No image path provided" >&2
    exit 1
fi

if [ ! -f "$IMAGE_PATH" ]; then
    echo "Error: Image file not found: $IMAGE_PATH" >&2
    exit 1
fi

# Run kmeans_colors with RGB color space to get hex output
# Output format: line 1 = colors (comma-separated), line 2 = percentages (comma-separated)
kmeans_colors -i "$IMAGE_PATH" -k "$K" --print --no-file --pct --sort --rgb 2>/dev/null | \
awk 'BEGIN {FS=","}
NR==1 {for (i=1; i<=NF; i++) colors[i]=$i}
NR==2 {for (i=1; i<=NF; i++) pcts[i]=$i}
END {
    for (i=1; i<=NF; i++) {
        if (i > 1) printf ","
        printf "(#%s,%.2f)", colors[i], pcts[i]*100
    }
    printf "\n"
}'
