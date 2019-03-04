#!/bin/sh

docker build \
    -t yarsttec/asiou:7.6-base \
    -f Dockerfile \
    --build-arg BUILD_DATE=$(date -u +"%Y-%m-%dT%H:%M:%SZ") \
    $* .
