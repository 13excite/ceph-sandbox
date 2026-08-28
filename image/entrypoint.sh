#!/bin/bash
set -e

: "${CLUSTER:=ceph}"
export CLUSTER

ROLE="${CEPH_DAEMON:-$1}"
ROLE="$(echo "$ROLE" | tr '[:upper:]' '[:lower:]')"

mkdir -p /var/run/ceph /etc/ceph

# shellcheck source=scripts/common.sh
source /opt/ceph-entrypoint/common.sh

case "$ROLE" in
  mon)      exec /opt/ceph-entrypoint/mon.sh ;;
  mgr)      exec /opt/ceph-entrypoint/mgr.sh ;;
  osd)      exec /opt/ceph-entrypoint/osd.sh ;;
  mds)      exec /opt/ceph-entrypoint/mds.sh ;;
  rgw)      exec /opt/ceph-entrypoint/rgw.sh ;;
  rgw_user) exec /opt/ceph-entrypoint/rgw_user.sh ;;
  bash|sh|shell) exec /bin/bash ;;
  *)
    echo "ERROR: unknown CEPH_DAEMON '${ROLE}' (expected one of: mon mgr osd mds rgw rgw_user)" >&2
    exit 1
    ;;
esac
