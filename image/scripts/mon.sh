#!/bin/bash
set -e

: "${MON_NAME:=$(hostname)}"

MON_DATA="/var/lib/ceph/mon/${CLUSTER}-${MON_NAME}"
MON_KEYRING="/etc/ceph/${CLUSTER}.mon.keyring"
MONMAP="/etc/ceph/monmap"

mkdir -p "$MON_DATA"

MON_IP="$(own_ip)"

if [ ! -f "$CEPH_CONF" ]; then
  FSID="$(uuidgen)"
  log "bootstrapping new cluster, fsid=${FSID}"
  cat > "$CEPH_CONF" <<EOF
[global]
fsid = ${FSID}
mon initial members = ${MON_NAME}
mon host = ${MON_IP}
osd pool default size = 1
osd pool default min size = 1
osd crush chooseleaf type = 0
mon warn on pool no redundancy = false
auth allow insecure global id reclaim = false
EOF
fi

if [ ! -f "$ADMIN_KEYRING" ]; then
  ceph-authtool "$ADMIN_KEYRING" --create-keyring -n client.admin --gen-key \
    --cap mon 'allow *' --cap osd 'allow *' --cap mds 'allow *' --cap mgr 'allow *'
fi

if [ ! -f "$MON_KEYRING" ]; then
  ceph-authtool "$MON_KEYRING" --create-keyring --gen-key -n mon. --cap mon 'allow *'
  ceph-authtool "$MON_KEYRING" --import-keyring "$ADMIN_KEYRING"
fi

if [ ! -e "$MON_DATA/keyring" ]; then
  FSID="$(grep '^fsid' "$CEPH_CONF" | awk '{print $NF}')"
  monmaptool --create --add "$MON_NAME" "$MON_IP" --fsid "$FSID" "$MONMAP"
  ceph-mon --cluster "$CLUSTER" --mkfs -i "$MON_NAME" \
    --monmap "$MONMAP" --keyring "$MON_KEYRING" --mon-data "$MON_DATA"
  rm -f "$MONMAP"
fi

chown -R ceph:ceph "$MON_DATA" /var/run/ceph
chown ceph:ceph "$CEPH_CONF" "$ADMIN_KEYRING" "$MON_KEYRING"

log "starting ceph-mon"
exec ceph-mon --cluster "$CLUSTER" -i "$MON_NAME" --mon-data "$MON_DATA" \
  --public-addr "$MON_IP" -f --setuser ceph --setgroup ceph
