#!/bin/sh
set -e

echo "Running database backup..."

HOME="/srv/backup"
PUB="asiou_backup_public_key.pem"

cd "$HOME" || (echo "You should mount backup directory '$HOME'!" 1>&2; exit 1)

file_prefix="backup_asiou_db"
archive_file="${file_prefix}_$(date -u +'%Y%m%d_%H%M%S').tar"

backup_file_key="${file_prefix}.key"
backup_file_key_enc="${backup_file_key}.enc"
backup_file_data_enc="${file_prefix}.sql.bz2.enc"


# Generate a random password.
echo "Generating a random password..."
/usr/bin/openssl rand -base64 256 -out "$backup_file_key"
rm ".rnd" || :

# Make dump, compress and encode it.
echo "Making database dump..."
/usr/bin/mysqldump \
        --routines \
        -h "$DATABASE_HOST" -P "$DATABASE_PORT" \
        -u "$DATABASE_USER" -p"$DATABASE_PASSWORD" \
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
echo "Verifying archive..."
res=$( (openssl enc -d \
        -aes-256-cbc \
        -in "$backup_file_data_enc" \
        -pass file:"$backup_file_key" 2>&3 | \
    bzip2 -t) 3>&1)
if [ ! -z "$res" ]; then
    echo "$res" 1>&2
    echo "Failed to verify archive!" 1>&2
    exit 1
fi

# Encrypt the password.
echo "Encrypting the password..."
/usr/bin/openssl rsautl \
    -encrypt \
    -inkey "$PUB" \
    -pubin \
    -in "$backup_file_key" \
    -out "$backup_file_key_enc"

# Remove the plain password.
rm -f "$backup_file_key"

# Generate digest.
echo "Generating digests..."
sha256sum "$backup_file_key_enc" "$backup_file_data_enc" > "${file_prefix}.sha256"
md5sum    "$backup_file_key_enc" "$backup_file_data_enc" > "${file_prefix}.md5"

# Pack everything in a single container.
echo "Packing everything into one file..."
tar -c -f "$archive_file" \
    "$backup_file_key_enc" \
    "$backup_file_data_enc" \
    "${file_prefix}.sha256" \
    "${file_prefix}.md5"

# Remove intermediate files.
echo "Cleaning up..."
rm "$backup_file_key_enc" \
   "$backup_file_data_enc" \
   "${file_prefix}.sha256" \
   "${file_prefix}.md5"

echo "Backup is done, your file is '$archive_file'"
