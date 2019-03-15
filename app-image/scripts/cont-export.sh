#!/bin/sh

echo "Exporting to the Contingent (full) ..."

cd "$WWW_HOME"
python ./manage.py cont_export
