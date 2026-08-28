#!/bin/bash
# Sourced by entrypoint.sh before dispatching to a role script.

: "${CLUSTER:=ceph}"

CEPH_CONF="/etc/ceph/${CLUSTER}.conf"
ADMIN_KEYRING="/etc/ceph/${CLUSTER}.client.admin.keyring"

log() {
  echo "$(date '+%F %T')  $*"
}

# All non-mon daemons need the mon up (and the admin keyring it writes to the
# shared /etc/ceph volume) before they can authenticate anything.
wait_for_mon() {
  log "waiting for mon..."
  until ceph --cluster "$CLUSTER" -k "$ADMIN_KEYRING" -n client.admin -s >/dev/null 2>&1; do
    sleep 2
  done
  log "mon is up"
}

# This container's own IP on the compose network - used both as the mon's
# public address and, generically, as "the address this daemon is reachable
# at" since every daemon here lives in its own container/hostname.
own_ip() {
  hostname -i | awk '{print $1}'
}
