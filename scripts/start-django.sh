#!/bin/sh
set -e

PATH="$WWW_HOME/asiou"
PID="$RUN_DIR/django-asiou.pid"
SOCKET="$RUN_DIR/django-fcgi-asiou.sock"

METHOD=prefork
MIN_SPARCE=3
MAX_SPARCE=5
MAX_REQUESTS=100
MAX_CHILDREN=25

DEBUG=true

OUT_LOG="$LOG_DIR/asiou.log"
ERR_LOG="$LOG_DIR/asiou.errlog"

exec /usr/bin/python -W ignore "$PATH/manage.py" runfcgi \
        daemonize=false \
        method="$METHOD" \
        workdir="$PATH" \
        socket="$SOCKET" \
        pidfile="$PID" \
        debug="$DEBUG" \
        minspare="$MIN_SPARCE" \
        maxspare="$MAX_SPARCE" \
        maxrequests="$MAX_REQUESTS" \
        maxchildren="$MAX_CHILDREN" \
        outlog="$OUT_LOG" \
        errlog="$ERR_LOG"
