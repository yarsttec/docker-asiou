#!/bin/sh

echo "Running database update..."

cd "$WWW_HOME"
find . -name "*.pyc" -type f -delete
python ./asiou/manage.py updatedb --line-by-line
