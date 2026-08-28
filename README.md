# ceph-playground

A small multi-container Ceph cluster for poking at the CLI locally: `ceph status`,
`ceph versions`, `ceph osd tree`, CephFS, and an S3-compatible RadosGW - all in
plain `docker compose`, no Kubernetes/cephadm/VM required.

## Image

`image/` is a homemade replacement for the `ceph/daemon` image (that project,
[ceph-container](https://github.com/ceph/ceph-container), was abandoned in
2021 and never got past Ceph 16 "Pacific"). It's built straight from Ceph's
official package repo (`download.ceph.com`) on top of `ubuntu:24.04`, so it
tracks whatever `CEPH_RELEASE` you point it at - defaults to Ceph 20
"Tentacle" in `.env`.

One image, five roles - which daemon a container runs is picked at start time
via `CEPH_DAEMON` (`mon`/`mgr`/`osd`/`mds`/`rgw`/`rgw_user`), dispatched by
`image/entrypoint.sh` to the matching script under `image/scripts/`. Each
daemon bootstraps its own cephx key on first boot straight off the shared
`client.admin` keyring (no separate bootstrap-key dance) and stays running
in the foreground.

This has **not been built or run** - only written. First `docker compose up`
will take a while (apt package install for Ceph is not small) and may need
adjusting - see "If the build fails" below.

## Layout

| service | role                                    |
|---------|-----------------------------------------|
| `mon`   | monitor - cluster map, quorum ("master") |
| `mgr`   | manager - `ceph -s`, dashboard modules   |
| `osd`   | object storage daemon ("worker"), directory-backed, no raw disk needed |
| `mds`   | metadata server, backs a CephFS volume  |
| `rgw`   | RadosGW - S3-compatible HTTP API, published on `localhost:8080` |

All daemons share two named volumes, `ceph_etc` (`/etc/ceph`) and
`ceph_var_lib` (`/var/lib/ceph`), which is how they see the same cluster
config and keyrings - this mirrors how a real bare-metal Ceph deployment
shares `/etc/ceph` across nodes.

## Usage

```sh
docker compose build           # builds image/Dockerfile once (slow first time)
docker compose up -d
docker compose exec mon ceph -s
docker compose exec mon bash   # a shell with the full ceph CLI toolset
```

Give it ~30-60s after `up -d` for the OSD to join and CephFS pools to go
active (`HEALTH_WARN` briefly during that window is normal).

Tear down (and wipe cluster state):

```sh
docker compose down -v
```

### If the build fails

`image/Dockerfile` points at `https://download.ceph.com/debian-${CEPH_RELEASE}/${DISTRO_CODENAME}/`.
If apt can't find packages there:

1. Check what Ceph actually calls the codename/release combo at
   `https://download.ceph.com/debian-tentacle/dists/` (a release this new
   may initially only publish for one Ubuntu codename, or briefly lag behind
   the very latest Ubuntu LTS).
2. Adjust `CEPH_RELEASE` / `DISTRO_CODENAME` in `.env` accordingly (e.g. drop
   back to `DISTRO_CODENAME=jammy` for Ubuntu 22.04), then `docker compose build`.
3. As a fallback, `CEPH_RELEASE=squid` (Ceph 19) is the previous stable and
   more likely to already have full package coverage.

### S3 / RadosGW

```sh
docker compose run --rm -e RGW_USER=testuser rgw   # prints access_key / secret_key
```

Then point any S3 client at `http://localhost:8080` with those keys, e.g.
with the AWS CLI:

```sh
export AWS_ACCESS_KEY_ID=...
export AWS_SECRET_ACCESS_KEY=...
aws --endpoint-url http://localhost:8080 --region us-east-1 s3 mb s3://mybucket
aws --endpoint-url http://localhost:8080 --region us-east-1 s3 cp ./file.txt s3://mybucket/
aws --endpoint-url http://localhost:8080 --region us-east-1 s3 ls s3://mybucket
```

(`--region` just needs to be *some* valid-looking region string; RadosGW
ignores it.)

### CephFS

The `mds` service auto-creates a filesystem named `cephfs` on first boot
(`CEPHFS_CREATE=1` in `docker-compose.yml`). Check it with:

```sh
docker compose exec mon ceph fs status
```

## Notes / gotchas

- This is a **single-OSD** cluster - `mon.sh` sets
  `osd_pool_default_size`/`min_size` to 1 in `ceph.conf` so pools go
  `active+clean` instead of sitting `undersized` forever. Don't expect real
  redundancy semantics out of this playground.
- Every daemon uses `client.admin` directly to mint its own cephx key on
  first boot (simpler than replicating profile-scoped bootstrap keys) - fine
  for a local playground, not a production security model.
- Each container's own IP (`hostname -i`) is used directly as its address,
  so there's no hardcoded subnet to keep in sync with Docker's network.
