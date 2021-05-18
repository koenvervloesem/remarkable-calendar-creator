#!/usr/bin/env bash
#
# Copyright (c) 2021 Koen Vervloesem
# SPDX-License-Identifier: MIT
#
### remarkable-calendar-downloader - Download events from an iCal calendar for use with remarkable-calendar-creator
###
### Usage:
###   remarkable-calendar-downloader <url> <file>
###
### Options:
###   url                      Url of the ics file with your events.
###   file                     Output file to write the pcal events to.
###   -h                       Show this message.
help() {
    sed -rn 's/^### ?//;T;p' "$0"
}

# Check arguments
if [ "$#" -ne 2 ] || [ "$1" = "-h" ]; then
    help
    exit 1
fi
url=$1
output_file=$2

# Find ical2pcal
if [ -f "ical2pcal.sh" ]; then
    ICAL2PCAL=./ical2pcal.sh
else
    ICAL2PCAL=/opt/bin/ical2pcal
fi

# Download file and convert it to pcal format
wget "$url" --output-document "$output_file".ics
# shellcheck disable=SC2086 # Don't quote the -E option
$ICAL2PCAL $ICAL2PCAL_OPTS -o "$output_file" "$output_file".ics
