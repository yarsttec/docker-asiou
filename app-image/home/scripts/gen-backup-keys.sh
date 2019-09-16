#!/bin/sh
set -e

HOME="/srv/backup"
PUB="asiou_backup_public_key.pem"
PRIV="asiou_backup_private_key.pem"

cd "$HOME" || (echo "You should mount the backup directory '$HOME'!" 1>&2; exit 1)

/usr/bin/openssl genpkey \
  -algorithm RSA \
  -out "$PRIV" \
  -pkeyopt rsa_keygen_bits:4096

/usr/bin/openssl rsa \
  -pubout \
  -in "$PRIV" \
  -out "$PUB"

echo "Your files are '$PRIV' and '$PUB'"
