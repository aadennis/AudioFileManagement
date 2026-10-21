#!/usr/bin/env bash

set -euo pipefail

get_input_folder() {

    local folder

    if [[ -n "${SOUND_RECORDER_DEFAULT:-}" ]]; then
        folder="$SOUND_RECORDER_DEFAULT"
    elif [[ -n "${WSL_DISTRO_NAME:-}" ]]; then
        folder=$(cmd.exe /c echo %SOUND_RECORDER_DEFAULT% | tr -d '\r')
    else
        echo "ERROR: SOUND_RECORDER_DEFAULT not defined" >&2
        exit 1
    fi

    if [[ -n "${WSL_DISTRO_NAME:-}" ]]; then
        folder=$(wslpath "$folder")
    fi

    printf '%s\n' "$folder"
}

process_file() {
    local input_file="$1"
    local output_dir="$2"
    local gain_db="$3"
    local datestamp="$4"

    local filename
    filename=$(basename "$input_file")

    local stem="${filename%.*}"

    local gain_tag
    gain_tag=$(printf '%+g' "$gain_db")

    local output_file
    output_file="${output_dir}/${stem}_${gain_tag}dB_${datestamp}.mp3"

    echo "Processing: $filename"

    printf 'Input file: <%s>\n' "$input_file"

    ffmpeg \
        -nostdin \
        -hide_banner \
        -loglevel warning \
        -i "$input_file" \
        -af "volume=${gain_db}dB,alimiter=limit=0.95" \
        -y \
        "$output_file"
}

usage() {
    cat <<EOF
    Usage:
        $0 <dB adjustment>
        $0

    Examples:
        $0 
        $0 3
        $0 6
        $0 -3
EOF

}

main() {
    local gain_db="6" # default gain adjustment in dB

    case $# in
        0)
            echo "No gain adjustment specified, using default: $gain_db dB"
            ;;
        1)
            gain_db="$1"

            [[ $gain_db =~ ^[-+]?[0-9]+([.][0-9]+)?$ ]] || {
                echo "Invalid dB value: $gain_db"
                exit 1
            }

            echo "Using gain adjustment: $gain_db dB"
            ;;
        *)
            usage
            exit 1
            ;;
    esac

    local input_dir
    input_dir=$(get_input_folder)

    local output_dir="${input_dir}/updated_volume"
    echo "output_dir: $output_dir"

    mkdir -p "$output_dir"

    local datestamp
    datestamp=$(date +%Y%m%d)

    find "$input_dir" \
        -type f \
        -iname "*.mp3" \
        ! -path "*/updated_volume/*" |
    while IFS= read -r file
    do
        process_file \
            "$file" \
            "$output_dir" \
            "$gain_db" \
            "$datestamp"
    done

    echo
    echo "Completed."
    echo "Output folder:"
    echo "  $output_dir"
}

main "$@"