# arm64 NFS export for the EXL3 head

`install.sh --nfs` is the recipe's fix for the head OOM-ing during weight load.
On GB10 it silently does nothing, for three stacked reasons — all fixed by
`build-nfs-server-arm64.sh` plus one runtime change.

| # | Symptom | Cause |
|---|---|---|
| 1 | `exec format error`, restart loop | `erichough/nfs-server` is amd64-only |
| 2 | `capsh: command not found`, then `missing CAP_SYS_ADMIN` | `libcap` absent; then libcap >=2.43 prints `Current: =ep`, which upstream's regex cannot parse |
| 3 | `2: Unsupported version`, `rpc.nfsd failed` | upstream hardcodes `--no-nfs-version 2`; kernels without NFSv2 reject disabling it |

**Runtime change: `--network host`, not `-p 12049:2049`.** Kernel `nfsd` only
creates sockets in the init network namespace. Under bridge networking
`rpc.nfsd` fails with `writing fd to kernel failed: errno 111` and
`/proc/fs/nfsd/portlist` stays empty — while `docker ps` still shows the
container Up and the host still shows 12049 listening (docker-proxy forwarding
to nothing). Consequence: the export is on **2049**, so `NFS_PORT=2049`.

## Bring-up (worker)

```bash
./build-nfs-server-arm64.sh
docker rm -f nfs-exl3
docker run -d --name nfs-exl3 --restart unless-stopped --privileged --network host \
  -v "$HOME/models/glm53-exl3:/export/glm53-exl3:ro" \
  -v /lib/modules:/lib/modules:ro \
  -e NFS_EXPORT_0="/export/glm53-exl3 *(ro,no_subtree_check,fsid=0,insecure)" \
  erichough/nfs-server
```

Wait for `READY AND WAITING FOR NFS CLIENT CONNECTIONS`. `Up` alone is not
success — check the log.

`install.sh --nfs` skips its own `docker run` when a container named
`nfs-exl3` is already running, so start this first and the recipe is unmodified.

## Verify from the head

```bash
docker volume create --driver local --opt type=nfs \
  --opt o=addr=169.254.54.207,ro,vers=4.2,rsize=1048576,port=2049 \
  --opt device=:/ exl3test
docker run --rm -v exl3test:/m ubuntu:24.04 ls /m | head
```

Expect 120 `.safetensors` plus `config.json`.
