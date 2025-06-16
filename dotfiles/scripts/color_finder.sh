#!/bin/sh

# Function to convert RGB to hex
rgb_to_hex() {
  local rgb_str="$1"
  local values=$(echo "$rgb_str" | sed -E 's/rgba?\(([^)]+)\).*/\1/' | tr -d ' ')
  local r=$(echo "$values" | cut -d, -f1)
  local g=$(echo "$values" | cut -d, -f2)
  local b=$(echo "$values" | cut -d, -f3)

  # Handle potential floating point values
  r=$(printf "%.0f" "$r" 2>/dev/null || echo "$r")
  g=$(printf "%.0f" "$g" 2>/dev/null || echo "$g")
  b=$(printf "%.0f" "$b" 2>/dev/null || echo "$b")

  printf "#%02X%02X%02X" "$r" "$g" "$b" 2>/dev/null || echo "$rgb_str"
}

# Function to expand 3-digit hex to 6-digit
expand_hex() {
  local hex="$1"
  if [ ${#hex} -eq 4 ]; then
    local c1=$(echo "$hex" | cut -c2)
    local c2=$(echo "$hex" | cut -c3)
    local c3=$(echo "$hex" | cut -c4)
    echo "#${c1}${c1}${c2}${c2}${c3}${c3}"
  else
    echo "$hex"
  fi
}

# Function to create colored box
create_colored_box() {
  local hex="$1"
  if [ -n "$hex" ] && echo "$hex" | grep -q "^#[A-Fa-f0-9]\{6\}$"; then
    local r=$((0x$(echo $hex | cut -c2-3)))
    local g=$((0x$(echo $hex | cut -c4-5)))
    local b=$((0x$(echo $hex | cut -c6-7)))
    printf "\033[48;2;%d;%d;%dm  \033[0m" "$r" "$g" "$b"
  else
    printf "error"
  fi
}

# Search and process colors
{
  grep -rnI --color=never -E -o 'rgba?\([^)]*\)|#([A-Fa-f0-9]{6}|[A-Fa-f0-9]{3})' . |
    sed -E 's/^([^:]+):([^:]+):/\1,\2,/' |
    while IFS=, read -r file line color; do
      if echo "$color" | grep -q '^rgb'; then
        hex_color=$(rgb_to_hex "$color")
      else
        hex_color=$(expand_hex "$(echo "$color" | tr '[:lower:]' '[:upper:]')")
      fi

      # Create colored box representation
      colored_box=$(create_colored_box "$hex_color")
      printf "%s,%s,[%s],'%s'\n" "$file" "$line" "$colored_box" "$hex_color"
    done
}
