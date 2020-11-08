#!/bin/bash

# docker container run -it --rm \
#   -v ${PWD}:/mnt \
#   -v ${PWD}/tmp:/srv/asiou/asiou \
#   yarsttec/asiou:7.6-base /bin/bash

# rm -rf /srv/asiou/asiou/*

mkdir -p ${WWW_HOME}/{asiou,scripts,patches}
cp -r /mnt/home/* ${WWW_HOME}/
chmod +x $WWW_HOME/scripts/*.sh $WWW_HOME/patches/*.sh

export ASIOU_VERSION=7.6.2
export CACHE_DISTR_FILE=yes
$WWW_HOME/scripts/install-asiou.sh

$WWW_HOME/patches/00_patch.sh
