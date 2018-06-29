#!/bin/sh
#set -e

HOME="/srv/backup"
PRIV="asiou_backup_private_key.pem"

restore_file=$1

print_error() {
    echo "$1" 1>&2
    exit 1
}

cd "$HOME" || print_error "You should mount restore directory '$HOME'!"

[! -f "$PRIV"] && print_error "Private key '$PRIV' not found!"
[! -f "$restore_file"] && print_error "Backup file '$restore_file' not found!"

file_prefix="backup_asiou_db"

restore_file_key="${file_prefix}.key"
restore_file_key_enc="${restore_file_key}.enc"
restore_file_data="${file_prefix}.sql"
restore_file_data_enc="${file_prefix}.sql.bz2.enc"

# Extract from single.
echo "Extracting tar container..."
tar -x -f "$restore_file" || print_error "Cannot extract tar container!"

# Verify digest.
echo "Verifying data..."
sha256sum -c "${file_prefix}.sha256" || print_error "Cannot verify archive!"
md5sum    -c "${file_prefix}.md5"    || print_error "Cannot verify archive!"

# Restore the random password.
echo "Restoring encryption key..."
openssl rsautl \
    -decrypt \
    -inkey "$PRIV" \
    -in "$restore_file_key_enc" \
    -out "$restore_file_key"

# Decrypt data.
echo "Decrypting data..."
openssl enc -d \
        -aes-256-cbc \
        -in "$restore_file_data_enc" \
        -pass file:"$restore_file_key" | \
    bzip2 -dc > "$restore_file_data" || \
        print_error "Cannot decrypt data!"

rm -f "$restore_file_key_enc" \
      "$restore_file_key" \
      "$restore_file_data_enc" \
      "${file_prefix}.sha256" \
      "${file_prefix}.md5"

# Restore data to MySQL.
echo "Restoring database '$DATABASE_NAME'..."
/usr/bin/mysql \
    -h "$DATABASE_HOST" -P "$DATABASE_PORT" \
    -u "$DATABASE_USER" -p"$DATABASE_PASSWORD" \
    "$DATABASE_NAME" < "$restore_file_data" || \
        print_error "Cannot restore database!"

# Remove the plain password.
rm -f "$restore_file_data"

echo "Successful!"
