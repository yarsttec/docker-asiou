#!/bin/sh
set -e

ASIOU_VERSION=7.7.0
ASIOU_FILE="www${ASIOU_VERSION}.zip"
URL="http://asiou.coikko.ru/static/upd_vers/x32/${ASIOU_FILE}"

# TMPFILE="asiou.zip"
TMPFILE="$(mktemp)"

echo "Downloading ${ASIOU_FILE}..."
meta="$(wget -qSO"$TMPFILE" "$URL" 2>&1)"
modified="$(echo "$meta" | grep 'Last-Modified')"

version="$(unzip -Z1 "$TMPFILE" | grep -oE '[0-9]{8}_[0-9]{4}\.py$' | cut -d'.' -f1 | sort -r | head -1)"

echo "-- info --"
echo $modified
echo "Version: ${version}"

rm -f "$TMPFILE"
