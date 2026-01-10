#!/usr/bin/env bash

# change_track_speed.sh
# Usage:
#   ./change_track_speed.sh input.mp3 [speed] [output.mp3]
#
# Example:
#   ./change_track_speed.sh track.mp3 0.7 slowed.mp3

set -e

if [ -z "$1" ]; then
    echo "Error: No input file provided."
    echo "Usage: $0 input.mp3 [speed] [output.mp3]"
    exit 1
fi

INPUT="$1"
SPEED="${2:-0.7}"

# Auto-generate output filename if not provided
if [ -z "$3" ]; then
    BASENAME="${INPUT%.*}"
    OUTPUT="${BASENAME}_${SPEED}x.mp3"
else
    OUTPUT="$3"
fi

# Validate speed is numeric
if ! [[ "$SPEED" =~ ^[0-9]*\.?[0-9]+$ ]]; then
    echo "Error: Speed must be a numeric value (e.g., 0.7, 1.25)."
    exit 1
fi

echo "Processing:"
echo "  Input : $INPUT"
echo "  Speed : $SPEED"
echo "  Output: $OUTPUT"
echo

# ffmpeg atempo supports 0.5–2.0 per filter; chain if needed
build_atempo_chain() {
    local target=$1
    local chain=""

    # If within range, just use it
    if (( $(echo "$target >= 0.5 && $target <= 2.0" | bc -l) )); then
        echo "atempo=$target"
        return
    fi

    # Otherwise break into multiple 0.5–2.0 steps
    local remaining=$target
    while (( $(echo "$remaining < 0.5 || $remaining > 2.0" | bc -l) )); do
        if (( $(echo "$remaining < 0.5" | bc -l) )); then
            chain="${chain}atempo=0.5,"
            remaining=$(echo "$remaining / 0.5" | bc -l)
        else
            chain="${chain}atempo=2.0,"
            remaining=$(echo "$remaining / 2.0" | bc -l)
        fi
    done

    chain="${chain}atempo=$remaining"
    echo "$chain"
}

ATEMPO_CHAIN=$(build_atempo_chain "$SPEED")

ffmpeg -i "$INPUT" -filter:a "$ATEMPO_CHAIN" -c:a libmp3lame -q:a 2 "$OUTPUT"

echo "Done. Output written to $OUTPUT"

