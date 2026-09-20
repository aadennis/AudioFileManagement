#! /usr/bin/env bash
#  Convert a windows path to a unix path - a substantial improvement over the 
#  wslpath command, which does not handle unmounted drives.
#  It does not actually mount unmounted drives. For that, in wsl, use the command pair:
#  ---  sudo mkdir -p /mnt/h && sudo mount -t drvfs H: /mnt/h ---
#  ... replacing H: and h with the drive letter you want to mount. 
#  Then you can use this script to convert the path.

#!/usr/bin/env bash

path="$1"

drive=$(printf '%s' "${path:0:1}" | tr '[:upper:]' '[:lower:]')
echo "drive is character 0 for 1 character: [$drive]"

rest=${path:2}
echo "the rest to grab is characters 2 and beyond (zero-indexed)..."
echo ", which leaves out the DOS drive letter: [$rest]"

rest=${rest//\\//}
echo "rest after replacing backslashes with forward slashes: $rest"

printf '/mnt/%s/%s\n' "$drive" "$rest"

