#!/bin/bash
set -e

: "${MGR_NAME:=$(hostname)}"

MGR_DATA="/var/lib/ceph/mgr/${CLUSTER}-${MGR_NAME}"
MGR_KEYRING="${MGR_DATA}/keyring"

wait_for_mon
mkdir -p "$MGR_DATA"

if [ ! -f "$MGR_KEYRING" ]; then
  ceph --cluster "$CLUSTER" -k "$ADMIN_KEYRING" -n client.admin \
    auth get-or-create "mgr.${MGR_NAME}" \
    mon 'allow profile mgr' osd 'allow *' mds 'allow *' -o "$MGR_KEYRING"
fi

chown -R ceph:ceph "$MGR_DATA"

log "starting ceph-mgr"
exec ceph-mgr --cluster "$CLUSTER" -i "$MGR_NAME" -f --setuser ceph --setgroup ceph
