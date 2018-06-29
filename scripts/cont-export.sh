#!/bin/sh

echo "Exporting to the Contingent (full) ..."

cd "$WWW_HOME"
python ./asiou/manage.py cont_export
