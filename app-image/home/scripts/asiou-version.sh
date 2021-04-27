#!/bin/sh
set -e

/bin/ls "$WWW_HOME"/asiou/*/migrations/* \
  | grep -oE '[0-9]{8}_[0-9]{4}\.py$' \
  | cut -d'.' -f1 | sort -r | head -1
