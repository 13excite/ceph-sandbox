#!/bin/bash
set -e

: "${RGW_NAME:=$(hostname)}"
: "${RGW_PORT:=8080}"

RGW_DATA="/var/lib/ceph/radosgw/${CLUSTER}-rgw.${RGW_NAME}"
RGW_KEYRING="${RGW_DATA}/keyring"

wait_for_mon
mkdir -p "$RGW_DATA"

if [ ! -f "$RGW_KEYRING" ]; then
  ceph --cluster "$CLUSTER" -k "$ADMIN_KEYRING" -n client.admin \
    auth get-or-create "client.rgw.${RGW_NAME}" \
    osd 'allow rwx' mon 'allow rw' -o "$RGW_KEYRING"
fi
chown -R ceph:ceph "$RGW_DATA"

log "starting radosgw on port ${RGW_PORT}"
exec radosgw --cluster "$CLUSTER" -n "client.rgw.${RGW_NAME}" -k "$RGW_KEYRING" \
  --rgw-frontends="beast port=${RGW_PORT}" -f --setuser ceph --setgroup ceph
