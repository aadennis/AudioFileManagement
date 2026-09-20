#!/usr/bin/env bash

DEBUG=1

debug()
{
    [ "$DEBUG" = "1" ] && echo "DEBUG: $*" >&2
}

path="$1"

drive="${path%%:*}"
drive=$(printf '%s' "$drive" | tr '[:upper:]' '[:lower:]')

rest="${path#*:}"
rest=${rest//\\//}

debug "path='$path'"
debug "drive='$drive'"
debug "rest='$rest'"

echo "/mnt/$drive$rest"
