#!/usr/bin/env bash
# Split a single .mp3 file into n equal-sized parts (approx.) using ffmpeg.
# - Default parts: 4
# - Default output folder: 'split' (created next to the input file)
# - Outputs named: <basename>-1.mp3, <basename>-2.mp3, etc.
# - Preserves mp3 format using stream copy (-c copy)
# Usage:
#   chmod +x split_mp3_file.sh
#   ./split_mp3_file.sh x.mp3
#   ./split_mp3_file.sh x.mp3 -n 6
#   ./split_mp3_file.sh x.mp3 --parts 6 --outdir splits

set -euo pipefail
IFS=$'\n\t'

show_help() {
  cat <<'EOF'
Usage: split_mp3_file.sh <input.mp3> [options]

Splits input.mp3 into N parts (default 4) and writes them to a folder named 'split' in the same directory.

Options:
  -n | --parts N       : number of parts (default 4)
  --outdir <name>     : output folder name (default 'split')
  --no-force           : do not overwrite existing files
  -h | --help          : show help
EOF
}

# defaults
PARTS=4
OUT_DIR_NAME="split"
FORCE_OVERWRITE=true

# parse cli
POSITIONAL=()
while [[ $# -gt 0 ]]; do
  case $1 in
    -n|--parts)
      PARTS="$2"
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
  echo "Usage: $0 <input.mp3> [-n | --parts N] [--outdir name] [--no-force]"
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

# Validate PARTS is a positive integer
if ! [[ "$PARTS" =~ ^[0-9]+$ ]] || [ "$PARTS" -le 0 ]; then
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
part_duration=$(echo "scale=3; $duration / $PARTS" | bc)

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
