#!/usr/bin/env bash
# Convert all .wav files in the named folder to .mp3 files in a sub-folder named 'mp3'
# Uses ffmpeg
# Configurable quality via constants below.
# Usage:
#   chmod +x convert_wav_to_mp3.sh
#   ./convert_wav_to_mp3.sh /path/to/folder
# Optional env/CLI overrides:
#   -b|--bitrate <bitrate>    — set bitrate (e.g. 320k). Only used when USE_VBR=false
#   --vbr                     — use libmp3lame VBR best-quality mode (-q:a 0)
#   -r|--recursive            — search subdirectories for .wav files
#   -h|--help                 — show this message

# -------------------------------
# Configurable constants (edit those if you like)
# -------------------------------
# If true, we use VBR quality mode best quality (libmp3lame -q:a 0).
# If false, we use constant MP3_BITRATE as a CBR using -b:a.
USE_VBR=true
# When not using VBR, change this to the desired bitrate e.g. "320k" or "192k"
MP3_BITRATE="320k"
# -------------------------------

set -euo pipefail
IFS=$'\n\t'

show_help() {
  sed -n '1,120p' "$0" | sed -n '1,60p'
}

# parse CLI
RECURSIVE=false
BITRATE='' 

# accept flags
POSITIONAL=()
while [[ $# -gt 0 ]]; do
  case $1 in
    -r|--recursive)
      RECURSIVE=true
      shift
      ;;
    -b|--bitrate)
      BITRATE="$2"
      shift
      shift
      ;;
    --vbr)
      USE_VBR=true
      shift
      ;;
    --no-vbr)
      USE_VBR=false
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
      echo "Unknown option $1"
      exit 1
      ;;
    *)
      POSITIONAL+=("$1")
      shift
      ;;
  esac
done

# restore positional
set -- "${POSITIONAL[@]}"

if [ $# -lt 1 ]; then
  echo "Usage: $0 <directory> [--recursive] [--vbr] [--no-vbr] [-b|--bitrate BITRATE]"
  exit 1
fi

TARGET_DIR="$1"

if [ ! -d "$TARGET_DIR" ]; then
  echo "Error: directory '$TARGET_DIR' not found."
  exit 2
fi

# Apply CLI bitrate override if passed
if [ -n "$BITRATE" ]; then
  MP3_BITRATE="$BITRATE"
fi

MP3_DIR="$TARGET_DIR/mp3"
mkdir -p -- "$MP3_DIR"

echo "Searching for .wav files in: $TARGET_DIR"
if [ "$RECURSIVE" = true ]; then
  echo "Recursive search: enabled"
  SEARCH_CMD=(find "$TARGET_DIR" -type f -iname '*.wav')
else
  SEARCH_CMD=(find "$TARGET_DIR" -maxdepth 1 -type f -iname '*.wav')
fi

# Build ffmpeg args for MP3 conversion
## Build ffmpeg args as an array to avoid splitting/quoting issues
declare -a FFMPEG_ARGS
if [ "$USE_VBR" = true ]; then
  FFMPEG_ARGS=( -codec:a libmp3lame -q:a 0 )
else
  FFMPEG_ARGS=( -codec:a libmp3lame -b:a "$MP3_BITRATE" )
fi

# Verify ffmpeg supports libmp3lame (otherwise building MP3 won't work)
if ! ffmpeg -hide_banner -encoders 2>/dev/null | grep -qE "libmp3lame|mp3\_?lame"; then
  echo "Error: the ffmpeg build doesn't support libmp3lame / LAME mp3 encoder."
  echo "Install ffmpeg with mp3 encoder support or use a build that includes libmp3lame (e.g., apt install ffmpeg on Debian/Ubuntu or use a static build)."
  exit 3
fi

# Convert
count=0
# Use process substitution to handle files safely
while IFS= read -r -d $'\0' src; do
  # Avoid converting files already under mp3 dir
  # (e.g. if the specified folder is itself mp3 or to avoid double-work)
  if [[ "$src" == "$MP3_DIR"* ]]; then
    continue
  fi

  filename="$(basename "$src")"
  base="${filename%.*}"
  out="$MP3_DIR/${base}.mp3"

  echo "Converting: $src -> $out"
  # Try the command; if it fails with 'At least one output file must be specified', print the full command for debug
  if ! ffmpeg -y -hide_banner -loglevel info -i "$src" "${FFMPEG_ARGS[@]}" "$out"; then
    echo "\n--- ERROR: ffmpeg failed while converting $src" >&2
    echo "Command: ffmpeg -y -i '$src' ${FFMPEG_ARGS[*]} '$out'" >&2
    echo "Check the ffmpeg output above for clues (missing encoder, invalid flags)." >&2
    continue
  fi
  count=$((count + 1))

done < <("${SEARCH_CMD[@]}" -print0)

if [ "$count" -eq 0 ]; then
  echo "No .wav files found in $TARGET_DIR"
else
  echo "✅ Converted $count file(s). Output in $MP3_DIR"
fi

exit 0
