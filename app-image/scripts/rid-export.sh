#!/bin/sh

echo "Exporting to RID..."

cd "$WWW_HOME"
python ./manage.py create_zip
