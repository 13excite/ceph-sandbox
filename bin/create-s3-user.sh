#!/bin/bash
# Create (or show, if it already exists) an S3 user on the radosgw and print
# its access/secret key pair.
#
# Usage: bin/create-s3-user.sh [uid]
set -euo pipefail
cd "$(dirname "$0")/.."

RGW_USER_NAME="${1:-testuser}"

docker compose run --rm -e CEPH_DAEMON=RGW_USER -e RGW_USER="$RGW_USER_NAME" rgw
