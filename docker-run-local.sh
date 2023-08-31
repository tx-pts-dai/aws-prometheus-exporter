#!/bin/bash
# Requirements:
# - Set these variables here or in the env
# AWS_ACCESS_KEY_ID=
# AWS_SECRET_ACCESS_KEY=
# AWS_SESSION_TOKEN=
IMAGE_NAME="aws-prometheus-exporter"
EXPORTER_PORT="9877"
HOST_PORT="9877"

docker run \
   -e AWS_ACCESS_KEY_ID="$AWS_ACCESS_KEY_ID" \
   -e AWS_SECRET_ACCESS_KEY="$AWS_SECRET_ACCESS_KEY" \
   -e AWS_SESSION_TOKEN="$AWS_SESSION_TOKEN" \
   -p $HOST_PORT:$EXPORTER_PORT \
   $IMAGE_NAME
