#!/usr/bin/env bash

# Color extraction using quantette (Wu's algorithm)
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

# Extract colors using quantette Wu's algorithm (optimal color quantization)
# Note: quantette outputs space-separated hex values without # prefix
QUANTETTE_COLORS=$(quantette-cli "$IMAGE_PATH" -k "$TOTAL_COLORS" quantette 2>/dev/null | \
tr ' ' '\n' | \
grep -v '^$' | \
awk '{if (length($0) == 6) print toupper($0)}')

# Calculate even percentage distribution
PERCENTAGE=$(awk "BEGIN {printf \"%.2f\", 100.0/$TOTAL_COLORS}")

# Format output as comma-separated tuples with even percentage distribution
echo "$QUANTETTE_COLORS" | awk -v pct="$PERCENTAGE" 'BEGIN {ORS=""}
{
    if (NR > 1) printf ","
    printf "(#%s,%s)", $0, pct
}
END {printf "\n"}'
