#!/bin/bash

# docker container run -it --rm \
#   -v ${PWD}:/mnt \
#   -v ${PWD}/tmp:/srv/asiou/asiou \
#   yarsttec/asiou:7.7-base /bin/bash
#
# root@:/# rm -rf /srv/asiou/asiou/* && /mnt/debug-build.sh
#

rm -rf /srv/asiou/asiou/*

mkdir -p "${WWW_HOME}"/{asiou,scripts,patches}
cp -r /mnt/home/* ${WWW_HOME}/
cp /mnt/entrypoint.sh /entrypoint.sh
chmod +x "$WWW_HOME/scripts"/*.sh "$WWW_HOME/patches"/*.sh /entrypoint.sh

mkdir -p "$RUN_DIR" "$LOG_DIR" "$TEMP_DIR"
touch "$LOG_DIR/cont_export.log"
chown -R www-data: "$RUN_DIR" "$LOG_DIR" "$TEMP_DIR"
chmod -R g+w "$LOG_DIR"

export ASIOU_VERSION=7.7.0
export CACHE_DISTR_FILE=yes
"$WWW_HOME/scripts/install-asiou.sh"

"$WWW_HOME/patches/00_patch.sh"
