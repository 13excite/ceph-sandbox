#!/bin/bash
set -e

: "${MDS_NAME:=$(hostname)}"
: "${CEPHFS_CREATE:=0}"
: "${CEPHFS_NAME:=cephfs}"
: "${CEPHFS_DATA_POOL_PG:=8}"
: "${CEPHFS_METADATA_POOL_PG:=8}"

MDS_DATA="/var/lib/ceph/mds/${CLUSTER}-${MDS_NAME}"
MDS_KEYRING="${MDS_DATA}/keyring"

wait_for_mon
mkdir -p "$MDS_DATA"

if [ ! -f "$MDS_KEYRING" ]; then
  ceph --cluster "$CLUSTER" -k "$ADMIN_KEYRING" -n client.admin \
    auth get-or-create "mds.${MDS_NAME}" \
    osd 'allow rwx' mds 'allow' mon 'allow profile mds' -o "$MDS_KEYRING"
fi
chown -R ceph:ceph "$MDS_DATA"

if [ "$CEPHFS_CREATE" = "1" ]; then
  if ! ceph --cluster "$CLUSTER" -k "$ADMIN_KEYRING" -n client.admin fs ls | grep -q "name: ${CEPHFS_NAME},"; then
    DATA_POOL="${CEPHFS_NAME}_data"
    META_POOL="${CEPHFS_NAME}_metadata"
    ceph --cluster "$CLUSTER" -k "$ADMIN_KEYRING" -n client.admin osd pool create "$DATA_POOL" "$CEPHFS_DATA_POOL_PG"
    ceph --cluster "$CLUSTER" -k "$ADMIN_KEYRING" -n client.admin osd pool create "$META_POOL" "$CEPHFS_METADATA_POOL_PG"
    ceph --cluster "$CLUSTER" -k "$ADMIN_KEYRING" -n client.admin fs new "$CEPHFS_NAME" "$META_POOL" "$DATA_POOL"
    log "created cephfs '${CEPHFS_NAME}'"
  fi
fi

log "starting ceph-mds"
exec ceph-mds --cluster "$CLUSTER" -i "$MDS_NAME" -f --setuser ceph --setgroup ceph
