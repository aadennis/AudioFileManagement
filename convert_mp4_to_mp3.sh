#!/bin/bash
# Given an input file path to a file of mp4 type,
# creates an output with the same base name, 
# but with the extension of .mp3.
# requirements:
# ffmpeg is installed. 
# usage:
# chmod +x convert_mp4_to_mp3.sh
# ./convert_mp4_to_mp3.sh yourfile.mp4
# If on Windows/WSL2, easiest is to copy the mp4 into say
# /mnt/c/temp, and work from that.
# export PS1='\u@\h:\w\$ '
# export PS1='\u@\h:$ '
# source ~/.bashrc



if [ -z "$1" ]; then
    echo "Usage: $0 <input-file>"
    exit 1
fi

basename=$(basename "$1" .mp4)
output="$basename.mp3"

ffmpeg -i "$1" -vn -ar 44100 -ac 2 -b:a 192k "$output"
