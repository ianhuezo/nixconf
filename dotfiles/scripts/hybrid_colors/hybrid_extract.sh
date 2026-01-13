#!/usr/bin/env bash

# Hybrid color extraction using both kmeans and quantette
# Outputs: (#hex,pct),(#hex,pct),...

IMAGE_PATH="$1"
TOTAL_COLORS="${2:-32}"  # Total colors to extract

if [ -z "$IMAGE_PATH" ]; then
    echo "Error: No image path provided" >&2
    exit 1
fi

if [ ! -f "$IMAGE_PATH" ]; then
    echo "Error: Image file not found: $IMAGE_PATH" >&2
    exit 1
fi

# Extract 16 colors using kmeans (good for dominant colors with LAB color space)
KMEANS_COLORS=$(kmeans_colors -i "$IMAGE_PATH" -k 16 --print --no-file --pct --sort 2>/dev/null | \
awk 'BEGIN {FS=","}
NR==1 {for (i=1; i<=NF; i++) colors[i]=$i}
NR==2 {for (i=1; i<=NF; i++) pcts[i]=$i}
END {
    for (i=1; i<=NF; i++) {
        printf "#%s|%.2f\n", colors[i], pcts[i]*100
    }
}')

# Extract 16 colors using quantette Wu's algorithm (better for diversity)
# Note: quantette outputs space-separated hex values without # prefix
QUANTETTE_COLORS=$(quantette-cli "$IMAGE_PATH" -k 16 quantette 2>/dev/null | \
tr ' ' '\n' | \
grep -v '^$' | \
awk '{if (length($0) == 6) printf "#%s|0.00\n", toupper($0)}')

# Combine and deduplicate colors by hex value
# Keep the percentage from kmeans if duplicate, otherwise use 0.00 from quantette
ALL_COLORS=$(printf "%s\n%s\n" "$KMEANS_COLORS" "$QUANTETTE_COLORS" | \
awk -F'|' '
{
    hex = tolower($1)
    if (!seen[hex]++) {
        colors[hex] = $2
        order[++count] = hex
    }
}
END {
    for (i=1; i<=count && i<='"$TOTAL_COLORS"'; i++) {
        hex = order[i]
        print hex "|" colors[hex]
    }
}')

# Format output as comma-separated tuples
echo "$ALL_COLORS" | awk -F'|' 'BEGIN {ORS=""}
{
    if (NR > 1) printf ","
    # Remove # prefix for output, as format expects it in tuple
    printf "(%s,%s)", $1, $2
}
END {printf "\n"}'
