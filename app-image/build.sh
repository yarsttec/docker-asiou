#!/bin/sh

DOCKER_BUILDKIT=0 \
docker build \
  -t "yarsttec/asiou" \
  -f Dockerfile \
  --build-arg "BUILD_DATE=$(date -u +"%Y-%m-%dT%H:%M:%SZ")" \
  $* .
