#!/bin/bash
# Split an audio file into equal parts using ffmpeg
# usage:
# ./split_audio_file.sh ../test_artifacts/pitch01.mp3
# mymp3='/mnt/c/temp/fresco/Lesson of 2025-05-07.mp3' 



# Check for input
if [ $# -lt 1 ]; then
  echo "Usage: $0 <input_file> [number_of_parts]"
  exit 1
fi

input_file="$1"
number_of_parts="${2:-4}"  # Default to 4 parts if not provided

# Validate input file
if [ ! -f "$input_file" ]; then
  echo "Error: File '$input_file' not found."
  exit 1
fi

# Extract the base name without extension
extension="${input_file##*.}"
filename="${input_file##*/}"
base_name="${filename%.*}"

# Get total duration in seconds (supports decimals)
duration=$(ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$input_file")

if [ -z "$duration" ]; then
  echo "Error: Could not determine duration of '$input_file'."
  exit 1
fi

# Calculate part duration with 2 decimal places
part_duration=$(echo "scale=2; $duration / $number_of_parts" | bc)

# Loop through and split
i=0
while [ $i -lt "$number_of_parts" ]; do
  start_time=$(echo "$i * $part_duration" | bc)
  part_num=$(printf "%02d" $(($i + 1)))
  output_dir=$(dirname "$input_file")
  output_file="${output_dir}/${base_name}_${part_num}.${extension}"


  echo "Creating part $part_num: start=$start_time, duration=$part_duration..."
  ffmpeg -y -i "$input_file" -ss "$start_time" -t "$part_duration" -c copy "$output_file"

  i=$((i + 1))
done

echo "✅ Splitting complete!"
