#!/usr/bin/env bash

# Usage: ./repeat_mp3.sh x.mp3 [n]
# Default multiplier n = 4

input="$1"
multiplier="${2:-4}"

if [[ -z "$input" ]]; then
    echo "Error: No input file provided."
    echo "Usage: $0 input.mp3 [multiplier]"
    exit 1
fi

# Resolve absolute path
abs_input="$(realpath "$input")"

# Strip extension and build output filename
base="${input%.*}"
ext="${input##*.}"
output="${base}_${multiplier}.${ext}"

# Create temporary concat list
listfile=$(mktemp)

for ((i=1; i<=multiplier; i++)); do
    printf "file '%s'\n" "$abs_input" >> "$listfile"
done

# Run ffmpeg concat
ffmpeg -hide_banner -loglevel error -f concat -safe 0 -i "$listfile" -c copy "$output"

echo "Created: $output"

rm "$listfile"
