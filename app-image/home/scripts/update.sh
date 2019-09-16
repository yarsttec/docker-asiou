#!/bin/sh

echo "Running database update..."

cd "$WWW_HOME"
python -W ignore ./manage.py migrate "$@"
