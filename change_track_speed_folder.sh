#!/usr/bin/env bash

# change_track_speed_folder.sh
# Usage:
#   ./change_track_speed_folder.sh <folder> [speed]
#
# Processes all .mp3 files in <folder>, changes playback speed (default 1.5),
# and writes outputs to a new random subfolder under <folder>.

set -euo pipefail

usage() {
    echo "Usage: $0 <folder> [speed]"
    exit 1
}

if [ $# -lt 1 ]; then
    usage
fi

INPUT_DIR="$1"
SPEED="${2:-1.5}"

if [ ! -d "$INPUT_DIR" ]; then
    echo "Error: '$INPUT_DIR' is not a directory."
    exit 1
fi

# Format speed nicely (remove unnecessary trailing zeros)
SPEED_FMT=$(printf '%g' "$SPEED")

# Create a random output directory under the input directory
OUT_DIR="$INPUT_DIR/processed-$(date +%s%N)-$RANDOM"
mkdir -p "$OUT_DIR"

shopt -s nullglob
count=0

# Build atempo chain for ffmpeg (supports speeds outside 0.5-2.0)
build_atempo_chain() {
    local target="$1"
    # Use bc for float comparisons
    if command -v bc >/dev/null 2>&1; then
        if (( $(echo "$target >= 0.5 && $target <= 2.0" | bc -l) )); then
            printf "atempo=%s" "$target"
            return
        fi

        local remaining="$target"
        local chain=""
        while (( $(echo "$remaining < 0.5 || $remaining > 2.0" | bc -l) )); do
            if (( $(echo "$remaining < 0.5" | bc -l) )); then
                chain="${chain}atempo=0.5,"
                remaining=$(echo "$remaining / 0.5" | bc -l)
            else
                chain="${chain}atempo=2.0,"
                remaining=$(echo "$remaining / 2.0" | bc -l)
            fi
        done
        chain="${chain}atempo=${remaining}"
        printf "%s" "$chain"
    else
        # If bc not available, rely on single atempo (works for typical defaults like 1.5)
        printf "atempo=%s" "$target"
    fi
}

ATEMPO_CHAIN=$(build_atempo_chain "$SPEED_FMT")

for f in "$INPUT_DIR"/*.mp3; do
    [ -e "$f" ] || continue
    base=$(basename "$f" .mp3)
    out="$OUT_DIR/${base}-${SPEED_FMT}.mp3"
    echo "Processing: '$f' -> '$out' (speed=${SPEED_FMT})"
    ffmpeg -y -i "$f" -filter:a "$ATEMPO_CHAIN" -vn -c:a libmp3lame -qscale:a 2 "$out"
    count=$((count+1))
done

if [ "$count" -eq 0 ]; then
    echo "No .mp3 files found in '$INPUT_DIR'."
else
    echo "Converted $count file(s). Output directory: $OUT_DIR"
fi

exit 0
