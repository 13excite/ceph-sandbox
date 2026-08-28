#!/bin/bash
# Quick overview of the playground cluster.
set -euo pipefail
cd "$(dirname "$0")/.."

echo "### ceph -s"
docker compose exec mon ceph -s
echo
echo "### ceph versions"
docker compose exec mon ceph versions
echo
echo "### ceph osd tree"
docker compose exec mon ceph osd tree
echo
echo "### ceph fs status"
docker compose exec mon ceph fs status || true
