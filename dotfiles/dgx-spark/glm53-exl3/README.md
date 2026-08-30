# GLM-5.3-Flash EXL3 4bpw + DFlash2 on the Spark pair

Serves [brandonmusic/GLM-5.3-Flash-tr3-4bpw](https://huggingface.co/brandonmusic/GLM-5.3-Flash-tr3-4bpw)
(EXL3/TR3 4bpw of zai-org/GLM-5.3-Flash, 320B/A18B) with the DFlash2 block-diffusion
drafter, across both GX10 nodes at TP2 on `:8888`. Replaces the NVFP4 stack in
`../glm53/`, which stays on disk as the rollback.

Upstream recipe: [Entrpi/glm-5.3-flash-exl3-2x-spark](https://github.com/Entrpi/glm-5.3-flash-exl3-2x-spark).
The engine is upstream's image (`ghcr.io/entrpi/...:v1-dflash2`, digest
`sha256:284142c58…`, vllm_commit `90104cfe4`) — unmodified, verified against
their BUILD.md.

## What is ours, and why

Everything here exists because the recipe does not run unmodified on **ASUS
Ascent GX10** hardware. Upstream validated on NVIDIA DGX Spark. Same GB10
silicon, same 128 GB unified memory; different NVMe, and — decisively — a
different default swap size.

| File | Why |
|---|---|
| `env.exl3` | topology (`.env` for upstream's install.sh) |
| `start-glm53-exl3.sh` / `stop-glm53-exl3.sh` | both-ranks start/stop for `model-select.sh`; upstream's launcher is per-box and returns before the API is up |
| `nfs-arm64/` | rebuilds upstream's NFS server for arm64 — see its README |
| `BASELINE-nvfp4.md` | the outgoing stack's real-traffic metrics, for comparison |

## The failure that cost seven boots: swap

Six consecutive boots were OOM-killed at **exactly shard 114/120**. That
determinism was the clue and it was missed for a long time — a memory *race*
scatters (108, 117, 112); a fixed shard means a hard ceiling at the top of an
allocation curve.

Measured at the peak (`nvidia-smi` + `/proc/meminfo`, 10 s sampling, both ranks):

```
peak head footprint = anon 32.6 + gpu 79.4 + shmem 2.4 = 114.4 GiB
available at peak   = 1.4 GiB
needs               = ~83.6 GiB gpu resident to finish   -> ~3 GiB short
```

Both ranks stream the **full 163.58 GiB** regardless of topology, because TP
slicing is load-time — each keeps ~81.5 GiB and discards the rest. The `anon`
is the EXL3 loader's transient dequant/TP-slice working set, and it is
**transient**: the worker's collapses 25.7 -> 1.0 GiB the instant loading
completes, settling near 85 GiB. So this is a spike to absorb, not a budget to
cut.

Stock swap was Ubuntu's installer default, **16 GiB**, and it hit 15/15 full on
every failed run — the kernel was already using the right strategy and simply
ran out of room. Fix: a 64 GiB swapfile on both nodes (`ensure_swap` in the
start script, `sw,nofail` in each `/etc/fstab`). First boot with it succeeded.

Swap is safe here because the model's memory is **not swappable** — the ~83 GiB
slice is NVRM/driver allocation the kernel cannot page out. Only the loader's
cold anonymous pages move, they are written once and never read back, and swap
returns to ~3 GiB and stays flat while serving.

### Things that were tried and are NOT the cause

Recorded so nobody re-runs them: local vs NFS weights, `drop_caches` cadence
(from 15 s down to 4 s, one rank and both), `MAX_LEN` 358400 vs 524288,
`MAX_SEQS` 4 vs 5, `GMU`, image skew (IDs match across ranks), wrong image
(digest matches upstream). None moved the failure shard, because none of them
touch the loader's anonymous working set.

## Two real bugs found on the way

**`spark-model-watchdog` killed healthy boots.** `start-glm53-exl3.sh` released
the lock unconditionally on EXIT, so two overlapping launchers would have the
older one delete the younger one's lock; the watchdog then read a 12-minute
weight load as a dead engine and relaunched — forever. Now released only if the
PID still matches.

**`install.sh --nfs` silently does nothing on arm64** and still exits `rc=0`.
See `nfs-arm64/README.md`. `rc=0` is not evidence the export works — check
`docker logs nfs-exl3` for `READY AND WAITING FOR NFS CLIENT CONNECTIONS`.

## Bring-up

```bash
model-select.sh glm53exl3      # both ranks, ~13 min to API
model-select.sh status
```

The start script probes the NFS export before launching either rank (a
cross-host dependency `depends_on` cannot express), ensures swap on both nodes,
and waits on `/health` — not `/v1/models`, which answers 200 while the engine
behind it is dead.

## Configuration notes

**`MAX_LEN` is 524288 (upstream's shipped default) and should stay there even
though omp is capped at 358400.** Concurrency is `pool / actual request size`,
and the pool grows with the declared length: 524288 gives a 1,435,070-token
pool = **4.00x** at omp's 358k cap, whereas declaring 358400 gives only
1,275,306 = 3.56x. Declaring long and capping client-side is strictly better.

`MAX_SEQS` is 4 (shipped) against omp's `maxConcurrency: 5`, so a 5th
concurrent request queues rather than failing. Check
`vllm:request_queue_time_seconds` before changing it.

**Memory floor:** upstream measures 5.25 GiB free under saturation at this KV
budget; this pair rests at 3.0-3.7 GiB, and upstream notes floors degrade
1.5-2 GiB per day of workload. If swap starts climbing during serving,
`KV_CACHE_MEMORY` is the lever — at the cost of pool, hence concurrency.
