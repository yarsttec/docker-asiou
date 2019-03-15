#!/bin/sh

echo "Exporting to the Contingent (diff) ..."

cd "$WWW_HOME"
python ./manage.py cont_export diff
