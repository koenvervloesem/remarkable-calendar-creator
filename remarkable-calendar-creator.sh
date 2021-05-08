#!/usr/bin/env bash
#
# Copyright (c) 2021 Koen Vervloesem
# SPDX-License-Identifier: MIT
#
### remarkable-calendar-creator - Create a calendar for use on the reMarkable
###
### Usage:
###   remarkable-calendar-creator <file> [pcal options]
###
### Options:
###   file                     Output file to write the calendar to. Can be a png or pdf file.
###   pcal options (optional)  Extra options to use for pcal. Consult pcal's man page for the supported pcal options.
###   -h                       Show this message.
help() {
    sed -rn 's/^### ?//;T;p' "$0"
}

# Check arguments
if [ "$#" -eq 0 ] || [ "$1" = "-h" ]; then
    help
    exit 1
fi

# Set default options if environment variables are unset or null
PCAL_OPTS=${PCAL_OPTS:-"-F Monday -f calendar -n/10 -S"}
GS_OPTIONS=${GS_OPTIONS:-"-q -dSAFER -dNOPAUSE -r226"}

# Get filename for output file
output_file=$1
filename=$(basename "$output_file")
extension="${filename##*.}"

# Check extension and set the correct options for GhostScript output
if [ "$extension" = "png" ]; then
    read -r -d '' format_options <<'EOF'
-dAlignToPixels=0 -dGridFitTT=2 -sDEVICE=png16m -dTextAlphaBits=4 -dGraphicsAlphaBits=4
EOF
elif [ "$extension" = "pdf" ]; then
    read -r -d '' format_options <<'EOF'
-sDEVICE=pdfwrite
EOF
else
    echo "Unsupported filename extension $extension. Please use png or pdf."
    exit 2
fi

# Get extra options for pcal
shift
pcal_extra_options=$*

# Export environment variables that are automatically used:
#   PCAL_OPTS by pcal
#   GS_OPTIONS by gs
export PCAL_OPTS
export GS_OPTIONS

# Call pcal and pipe output to GhostScript
# shellcheck disable=SC2086 # The options can't be quoted
pcal $pcal_extra_options | gs $format_options -sOutputFile="$output_file" -
