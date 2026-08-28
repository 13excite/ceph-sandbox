#!/bin/bash
set -e

OSD_ROOT="/var/lib/ceph/osd"
mkdir -p "$OSD_ROOT"

wait_for_mon

EXISTING="$(find "$OSD_ROOT" -maxdepth 1 -mindepth 1 -name "${CLUSTER}-*" | head -n1 || true)"

if [ -z "$EXISTING" ]; then
  log "no existing OSD found, creating one (directory-backed, single OSD)"
  UUID="$(uuidgen)"
  OSD_SECRET="$(ceph-authtool --gen-print-key)"
  OSD_ID="$(echo "{\"cephx_secret\": \"${OSD_SECRET}\"}" \
    | ceph --cluster "$CLUSTER" -k "$ADMIN_KEYRING" -n client.admin osd new "$UUID" -i -)"
  OSD_PATH="${OSD_ROOT}/${CLUSTER}-${OSD_ID}"

  mkdir -p "$OSD_PATH"
  ceph-authtool --create-keyring "${OSD_PATH}/keyring" --name "osd.${OSD_ID}" --add-key "$OSD_SECRET"
  chown -R ceph:ceph "$OSD_PATH"

  ceph-osd --cluster "$CLUSTER" -i "$OSD_ID" --mkfs --osd-uuid "$UUID" --setuser ceph --setgroup ceph
  chown -R ceph:ceph "$OSD_PATH"
  log "OSD ${OSD_ID} created"
else
  OSD_PATH="$EXISTING"
  OSD_ID="$(basename "$OSD_PATH" | sed "s/^${CLUSTER}-//")"
  log "reusing existing OSD ${OSD_ID}"
fi

chown -R ceph:ceph "$OSD_PATH"

log "starting ceph-osd ${OSD_ID}"
exec ceph-osd --cluster "$CLUSTER" -i "$OSD_ID" -f --setuser ceph --setgroup ceph
