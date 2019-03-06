#!/bin/bash
set -ex

# Compile source code
python -W ignore -m compileall -f -qq $WWW_HOME/asiou

# Prepare compressed static files
find $WWW_HOME/static \
    -type f \
    -regextype posix-extended \
    -iregex '.*\.(css|js|html?|ttf)' \
    -exec gzip -9 -k -q '{}' \;

# Optimize images
find $WWW_HOME/static \
    -type f \
    -regextype posix-extended \
    -iregex '.*\.(png|gif)' \
    -exec optipng -o3 -q '{}' \;
