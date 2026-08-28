#!/bin/bash
# One-shot helper: `docker compose run --rm -e RGW_USER=alice rgw` style usage
# to create (or show) an S3 user and print its keys.
set -e

: "${RGW_USER:?RGW_USER must be set, e.g. -e RGW_USER=testuser}"

wait_for_mon

radosgw-admin --cluster "$CLUSTER" user info --uid="$RGW_USER" 2>/dev/null \
  || radosgw-admin --cluster "$CLUSTER" user create --uid="$RGW_USER" --display-name="$RGW_USER"
