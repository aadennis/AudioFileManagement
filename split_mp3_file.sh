#!/usr/bin/env bash
# Split a single .mp3 file into equal-sized parts or fixed-duration chunks using ffmpeg.
# - Default parts: 4
# - Default output folder: 'split' (created next to the input file)
# - Outputs named: <basename>-1.mp3, <basename>-2.mp3, etc.
# - Preserves mp3 format using stream copy (-c copy)
# Usage:
#   chmod +x split_mp3_file.sh
#   ./split_mp3_file.sh x.mp3
#   ./split_mp3_file.sh x.mp3 -n 6
#   ./split_mp3_file.sh x.mp3 --duration 10m
#   ./split_mp3_file.sh x.mp3 --parts 6 --outdir splits

set -euo pipefail
IFS=$'\n\t'

show_help() {
  cat <<'EOF'
Usage: split_mp3_file.sh <input.mp3> [options]

Splits input.mp3 into N parts (default 4), or into fixed-duration chunks, and writes them to a folder named 'split' in the same directory.

Options:
  -n | --parts N       : number of parts (default 4)
  --duration TIME      : target duration per part (e.g. 600, 10m, 00:10:00); final part may be shorter
  --outdir <name>     : output folder name (default 'split') !!! this is just the leaf name, not a path.  
  --no-force           : do not overwrite existing files
  -h | --help          : show help
EOF
}

# defaults
PARTS=4
PARTS_SET=false
CHUNK_DURATION=""
OUT_DIR_NAME="split"
FORCE_OVERWRITE=true

# parse cli
POSITIONAL=()
while [[ $# -gt 0 ]]; do
  case $1 in
    -n|--parts)
      PARTS="$2"
      PARTS_SET=true
      shift
      shift
      ;;
    --duration)
      CHUNK_DURATION="$2"
      shift
      shift
      ;;
    --outdir)
      OUT_DIR_NAME="$2"
      shift
      shift
      ;;
    --no-force)
      FORCE_OVERWRITE=false
      shift
      ;;
    -h|--help)
      show_help
      exit 0
      ;;
    --)
      shift
      break
      ;;
    -*|--*)
      echo "Unknown option: $1"
      exit 1
      ;;
    *)
      POSITIONAL+=("$1")
      shift
      ;;
  esac
done
set -- "${POSITIONAL[@]}"

if [ $# -lt 1 ]; then
  echo "Usage: $0 <input.mp3> [-n | --parts N | --duration TIME] [--outdir name] [--no-force]"
  exit 1
fi

INPUT_FILE="$1"

if [ ! -f "$INPUT_FILE" ]; then
  echo "Error: '$INPUT_FILE' not found"
  exit 2
fi

# Basic extension check
ext="${INPUT_FILE##*.}"
if [[ "${ext,,}" != "mp3" ]]; then
  echo "Warning: input extension is not .mp3. Proceeding anyway but the script expects mp3."
fi

# Validate the selected split mode.
if [ -n "$CHUNK_DURATION" ] && [ "$PARTS_SET" = true ]; then
  echo "Error: use either --parts or --duration, not both"
  exit 3
fi
if [ -z "$CHUNK_DURATION" ] && { ! [[ "$PARTS" =~ ^[0-9]+$ ]] || [ "$PARTS" -le 0 ]; }; then
  echo "Error: parts must be a positive integer (>0). Provided: $PARTS"
  exit 3
fi

# Check ffmpeg exists
if ! command -v ffmpeg >/dev/null 2>&1; then
  echo "Error: ffmpeg not found. Install ffmpeg to use this script."
  exit 4
fi

# Create output directory: same dir as input file
input_dir="$(dirname "$INPUT_FILE")"
filename="$(basename "$INPUT_FILE")"
base="${filename%.*}"
OUTPUT_DIR="$input_dir/$OUT_DIR_NAME"
mkdir -p -- "$OUTPUT_DIR"

# Get duration in seconds (may contain decimals)
duration=$(ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$INPUT_FILE")
if [ -z "$duration" ]; then
  echo "Error: could not determine duration of input file"
  exit 5
fi

# Calculate part duration with 3 decimal places
if [ -n "$CHUNK_DURATION" ]; then
  case "$CHUNK_DURATION" in
    *:*)
      if ! [[ "$CHUNK_DURATION" =~ ^([0-9]+):([0-9]{2})(:([0-9]{2})(\.[0-9]+)?)?$ ]]; then
        echo "Error: duration must be seconds, Nm, Nh, or HH:MM:SS. Provided: $CHUNK_DURATION"
        exit 6
      fi
      if [[ "$CHUNK_DURATION" == *:*:* ]]; then
        chunk_seconds=$(awk -F: '{ print ($1 * 3600) + ($2 * 60) + $3 }' <<< "$CHUNK_DURATION")
      else
        chunk_seconds=$(awk -F: '{ print ($1 * 60) + $2 }' <<< "$CHUNK_DURATION")
      fi
      ;;
    *m)
      chunk_seconds=$(awk '{ sub(/m$/, ""); print $1 * 60 }' <<< "$CHUNK_DURATION")
      ;;
    *h)
      chunk_seconds=$(awk '{ sub(/h$/, ""); print $1 * 3600 }' <<< "$CHUNK_DURATION")
      ;;
    *s|*[!0-9.]*|"")
      echo "Error: duration must be seconds, Nm, Nh, or HH:MM:SS. Provided: $CHUNK_DURATION"
      exit 6
      ;;
    *)
      chunk_seconds="$CHUNK_DURATION"
      ;;
  esac

  if ! awk -v value="$chunk_seconds" 'BEGIN { exit !(value > 0) }'; then
    echo "Error: duration must be greater than zero. Provided: $CHUNK_DURATION"
    exit 6
  fi
  PARTS=$(awk -v total="$duration" -v chunk="$chunk_seconds" 'BEGIN {
    whole = int(total / chunk)
    if (total - (whole * chunk) > 0.000001) whole++
    print whole
  }')
  part_duration="$chunk_seconds"
else
  part_duration=$(echo "scale=3; $duration / $PARTS" | bc)
fi

# Loop and create parts
i=0
while [ $i -lt "$PARTS" ]; do
  start_time=$(echo "scale=3; $i * $part_duration" | bc)
  part_num=$((i + 1))
  output_file="$OUTPUT_DIR/${base}-$part_num.mp3"

  # compute length for last part: make sure we don't exceed duration
  if [ $i -eq $((PARTS - 1)) ]; then
    # last part runs to end; calculate remaining time to be safe
    tval=$(echo "scale=3; $duration - $start_time" | bc)
  else
    tval="$part_duration"
  fi

  echo "Creating part $part_num: start=$start_time duration=$tval -> $output_file"

  # Skip if output newer than source
  if [ -f "$output_file" ] && [ "$output_file" -nt "$INPUT_FILE" ]; then
    echo "Skipping (up-to-date): $output_file"
    i=$((i + 1))
    continue
  fi

  # Build ffmpeg command and run
  ffmpeg_cmd=( -hide_banner -loglevel info -nostdin -i "$INPUT_FILE" -ss "$start_time" -t "$tval" -c copy )

  # Add overwrite flag
  if [ "$FORCE_OVERWRITE" = true ]; then
    ffmpeg_cmd+=(-y)
  fi

  # Append output file
  ffmpeg_cmd+=("$output_file")

  # Run
  if ! ffmpeg "${ffmpeg_cmd[@]}"; then
    echo "Error: ffmpeg failed for part $part_num"
  fi

  i=$((i + 1))
done

echo "✅ Split complete: output in $OUTPUT_DIR"
exit 0
