#!/bin/bash
set -e

print_message() {
  echo "[$(date --rfc-3339=seconds)] $1"
}

print_message "Running '$DATABASE_NAME' database backup"

HOME="/srv/backup"
PUB="asiou_backup_public_key.pem"

cd "$HOME" || (echo "You should mount backup directory '$HOME'!" 1>&2; exit 1)

info_file="info.txt"
file_prefix="backup_asiou_db"
archive_file="${file_prefix}_$(date -u +'%Y%m%d_%H%M%S').tar"

backup_file_key="${file_prefix}.key"
backup_file_key_enc="${backup_file_key}.enc"
backup_file_data_enc="${file_prefix}.sql.bz2.enc"


# Generate a random password.
print_message "Generating a random password..."
/usr/bin/openssl rand -base64 -out "$backup_file_key" 256
rm ".rnd" || :

export MYSQL_PWD="$DATABASE_PASSWORD"
( \
  /usr/bin/openssl version; \
  echo "db: aes-256-cbc"; \
  echo "key: rsa"; \
)> "$info_file"

# Make dump, compress and encode it.
print_message "Making the database dump..."
/usr/bin/mysqldump \
    --routines \
    -h "$DATABASE_HOST" -P "$DATABASE_PORT" -u "$DATABASE_USER" \
    "$DATABASE_NAME" | \
  bzip2 -c | \
  /usr/bin/openssl enc -e \
    -aes-256-cbc \
    -salt \
    -out "$backup_file_data_enc" \
    -pass file:"$backup_file_key"

# Verify archive.
# printf "\x01" | dd of="$backup_file_data_enc" bs=1 seek=100 count=1 conv=notrunc
# echo "123" >> "$backup_file_data_enc"
# truncate -s 10000000 "$backup_file_data_enc"
print_message "Verifying an archive..."
res=$( (openssl enc -d \
        -aes-256-cbc \
        -in "$backup_file_data_enc" \
        -pass file:"$backup_file_key" 2>&3 | \
    bzip2 -t) 3>&1)
if [ ! -z "$res" ]; then
  echo "$res" 1>&2
  echo "Failed to verify the archive!" 1>&2
  exit 1
fi

# Encrypt the password.
print_message "Encrypting the password..."
/usr/bin/openssl rsautl \
  -encrypt \
  -inkey "$PUB" \
  -pubin \
  -in "$backup_file_key" \
  -out "$backup_file_key_enc"

# Remove the plain password.
rm -f "$backup_file_key"

# Generate digest.
print_message "Generating digests..."
sha256sum "$backup_file_key_enc" "$backup_file_data_enc" > "${file_prefix}.sha256"
md5sum    "$backup_file_key_enc" "$backup_file_data_enc" > "${file_prefix}.md5"

# Pack everything in a single container.
print_message "Packing everything into one file..."
tar -c -f "$archive_file" \
  "$info_file" \
  "$backup_file_key_enc" \
  "$backup_file_data_enc" \
  "${file_prefix}.sha256" \
  "${file_prefix}.md5"

# Remove intermediate files.
print_message "Cleaning up..."
rm "$info_file"\
   "$backup_file_key_enc" \
   "$backup_file_data_enc" \
   "${file_prefix}.sha256" \
   "${file_prefix}.md5"

print_message "The backup is done, your file has name '$archive_file'"
