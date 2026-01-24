#!/usr/bin/env bash

# Script to repeat an MP3 file a specified number of times using ffmpeg concatenation.
# Usage: ./repeat_mp3.sh x.mp3 [n]
# Default multiplier n = 4

# Get the input file from the first argument
input="$1"
# Get the multiplier from the second argument, default to 4 if not provided
multiplier="${2:-4}"

# Check if input file is provided
if [[ -z "$input" ]]; then
    echo "Error: No input file provided."
    echo "Usage: $0 input.mp3 [multiplier]"
    exit 1
fi

# Resolve the absolute path of the input file
abs_input="$(realpath "$input")"

# Strip the extension and build the output filename
base="${input%.*}"
ext="${input##*.}"
output="${base}_${multiplier}.${ext}"

# Create a temporary file for the concat list
listfile=$(mktemp)

# Generate the concat list by repeating the input file path
for ((i=1; i<=multiplier; i++)); do
    printf "file '%s'\n" "$abs_input" >> "$listfile"
done

# Run ffmpeg to concatenate the files
ffmpeg -hide_banner -loglevel error -f concat -safe 0 -i "$listfile" -c copy "$output"

# Print success message
echo "Created: $output"

# Clean up the temporary file
rm "$listfile"
