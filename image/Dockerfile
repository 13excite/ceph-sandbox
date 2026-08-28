# Minimal, homemade replacement for the (abandoned since 2021) ceph/daemon
# image, built straight from Ceph's own official package repo so we get a
# current release - Ceph 20 "Tentacle" - instead of being stuck on Pacific.
#
# One image, five roles: which daemon it runs is picked at "docker run" time
# via $CEPH_DAEMON (mon|mgr|osd|mds|rgw|rgw_user), see entrypoint.sh.

FROM ubuntu:24.04

ARG CEPH_RELEASE=tentacle
ARG DISTRO_CODENAME=noble

RUN apt-get update && apt-get install -y --no-install-recommends \
        ca-certificates curl gnupg lsb-release uuid-runtime python3 iproute2 \
    && curl -fsSL "https://download.ceph.com/keys/release.asc" -o /usr/share/keyrings/ceph.asc \
    && echo "deb [signed-by=/usr/share/keyrings/ceph.asc] https://download.ceph.com/debian-${CEPH_RELEASE}/ ${DISTRO_CODENAME} main" \
        > /etc/apt/sources.list.d/ceph.list \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
        ceph-mon ceph-mgr ceph-osd ceph-mds radosgw ceph-common \
    && apt-get purge -y --auto-remove curl gnupg \
    && rm -rf /var/lib/apt/lists/*

COPY entrypoint.sh /usr/local/bin/entrypoint.sh
COPY scripts/ /opt/ceph-entrypoint/
RUN chmod +x /usr/local/bin/entrypoint.sh /opt/ceph-entrypoint/*.sh

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
