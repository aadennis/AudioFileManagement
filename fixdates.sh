#!/bin/bash
# Use PowerShell to read Modified time and write it to Created time
# Usage: ./fixdates.sh "*.jpg"

pattern="$1"
dir='/mnt/c/temp/downloads/roland_wav/mp3'

cd $dir
for f in $pattern; do
    # Skip if no match
    [ -e "$f" ] || continue

    powershell.exe -NoLogo -NoProfile -Command \
      "(Get-Item \"$(wslpath -w "$f")\").CreationTime = (Get-Item \"$(wslpath -w "$f")\").LastWriteTime"
    
    echo "Updated: $f"
done