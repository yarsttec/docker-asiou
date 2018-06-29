#!/bin/sh

echo "Exporting to RID..."

cd "$WWW_HOME"
python ./asiou/manage.py create_zip
