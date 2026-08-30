#!/usr/bin/env bash
# Bring up GLM-5.3-Flash EXL3 + DFlash2 across both ranks. Runs on node1.
#
# This is a thin wrapper around upstream's per-box launcher
# (~/launch-glm53-vllm-tp2.sh, installed by the Entrpi install.sh). It exists
# because model-select.sh needs one command that starts BOTH ranks in the right
# order and does not return until the API is actually serving -- upstream's
# launcher is per-box and returns the moment `docker run -d` accepts.
#
# Everything tunable lives in ~/.glm53-serve.env (written by install.sh from
# dotfiles/dgx-spark/glm53-exl3/env.exl3). Do not add knobs here.
set -euo pipefail

SERVE_ENV="${GLM53_ENV:-$HOME/.glm53-serve.env}"
LAUNCHER="${LAUNCHER:-$HOME/launch-glm53-vllm-tp2.sh}"
# 30s, matching install.sh. The worker has to be listening before the head
# starts, but the gap must also stay well under torch's 600s rendezvous
# timeout, so this is a floor and not a "more is safer" knob.
WORKER_LEAD="${WORKER_LEAD:-30}"
# Weight load + engine init + CUDA-graph capture is ~12-13 min on this pair;
# 30 min leaves room for a cold JIT cache without hanging a boot forever.
API_WAIT="${API_WAIT:-1800}"
NAME="${NAME:-vllm_glm53}"
# At cold boot the worker may still be starting dockerd; 300s covers that
# without hanging a boot forever on a genuinely dead export.
NFS_WAIT="${NFS_WAIT:-300}"

# Profile knobs. These are upstream's own documented values, not tuning: the
# README's "358k, DFlash2 + fp8" row is the stated more-concurrency-headroom
# profile, measured at a 1,275,306-token pool = 3.56 full-length banks. The
# 524288 default gives only 2.74, under the c3 floor we need.
#
# They go on the environment of BOTH launches, which is how the README says to
# set them ("on both launches") -- NOT into ~/.glm53-serve.env, because
# install.sh regenerates that file from .env on every run and would drop them.
#
# CURRENTLY EMPTY = the launcher's shipped defaults (524288 / 4). Four boots
# died at shard 114/120 while these were set to 358400/5, and debugging a
# modified config against upstream's documented behaviour is what made those
# four attempts worthless. Get a clean boot on the shipped values FIRST, then
# reintroduce the 358k profile as a single deliberate change.
MAX_LEN="${MAX_LEN:-}"
# 5 slots for a c3-c5 fan-out. Upstream scales this with the profile (4 at the
# 524k default, 6 at 131k), so 5 sits where 3.56 banks put it. Note the two
# numbers measure different things: MAX_SEQS caps concurrent *sequences*, the
# pool caps concurrent *tokens*. At the 88k prompts this pair actually serves,
# 1,275,306 seats ~14 sessions, so 5 slots is the binding limit, not the pool.
MAX_SEQS="${MAX_SEQS:-}"
# Pass through ONLY what is set, so empty means "launcher default" rather than
# "override with an empty string" -- the launcher uses ${MAX_LEN:-524288}, and
# an exported empty value would still take the default, but MAX_SEQS uses the
# same idiom and relying on that is fragile. Build an explicit prefix instead.
ENVPFX=""
[ -n "$MAX_LEN" ]  && { export MAX_LEN;  ENVPFX="$ENVPFX MAX_LEN='$MAX_LEN'"; }
[ -n "$MAX_SEQS" ] && { export MAX_SEQS; ENVPFX="$ENVPFX MAX_SEQS='$MAX_SEQS'"; }
PROFILE_DESC="MAX_LEN=${MAX_LEN:-<shipped default>} MAX_SEQS=${MAX_SEQS:-<shipped default>}"

# Continuous drop_caches on BOTH ranks, from t=0. This is the single thing that
# makes this checkpoint load on this pair, and it is measured, not guessed.
#
# Both ranks stream the full 163.58 GiB regardless of topology, because TP
# slicing is load-time -- each keeps ~81.5 GiB and discards the rest. On GB10
# the "GPU" allocation IS system RAM, and NVRM's bounded reclaim never evicts
# page cache to satisfy it, so the kernel swaps the MODEL out instead and the
# loader is OOM-killed. Measured on the worker mid-load: an explicit drop took
# it from used 108.2 / avail 13.4 / swap 16.0-of-16 to used 93 / avail 28 /
# swap 2 in seconds. Nothing else moves those numbers.
#
# Cadence matters as much as presence. 15 s was too slow against this pair's
# NVMe -- the Ascent GX10's 1 TB drive fills cache faster than reclaim drains
# it, which is plausibly why upstream (DGX Spark, 4 TB, different controller)
# never had to do this. And it must run from t=0: starting at 44%/62% of load
# on 2026-08-30 was too late, because the swap it had already forced could not
# be recovered.
#
# The head needs it too, despite reading over NFS. Its client pages are worse,
# not better: MemAvailable was measured BELOW Cached there (17.1 vs 19.0), i.e.
# the kernel does not count them as reclaimable at all.
DROP_LOOP="${DROP_LOOP:-1}"
DROP_INTERVAL="${DROP_INTERVAL:-5}"

[ -x "$LAUNCHER" ] || { echo "launcher missing: $LAUNCHER (run install.sh)" >&2; exit 1; }
[ -f "$SERVE_ENV" ] || { echo "serve config missing: $SERVE_ENV (run install.sh)" >&2; exit 1; }
# shellcheck disable=SC1090
. "$SERVE_ENV"

PORT="${PORT:-8888}"
WORKER_SSH="${WORKER_SSH:-${WORKER_RAIL_IP:-169.254.54.207}}"
# /health, NOT /v1/models: the latter answers 200 while the engine behind it is
# already dead, so it cannot distinguish "loading" from "crashed".
HEALTH_URL="http://127.0.0.1:${PORT}/health"

# Claim the watchdog lock for the whole load. Without it spark-model-watchdog
# sees a not-yet-serving endpoint and "recovers" a perfectly healthy boot.
# The PID matters: a non-numeric lock is treated as stale and cleared.
LOCK_FILE="${LOCK_FILE:-$HOME/dspark-recipe/.switching}"
mkdir -p "$(dirname "$LOCK_FILE")" 2>/dev/null || true
echo $$ > "$LOCK_FILE"
trap 'rm -f "$LOCK_FILE"' EXIT

# In nfs mode the head's weights live behind a service on the OTHER box, and
# the launcher mounts them at container-create time -- so if that service is not
# yet serving, `docker run` fails outright. At cold boot both machines race and
# the head can easily win. This is a dependency `depends_on` cannot express:
# it is cross-host, and Compose orders start rather than readiness anyway.
#
# So probe the real operation. A TCP check on 2049 is not enough -- nfsd can be
# listening before exportfs has published the export, which presents exactly as
# the mount succeeding and the directory being empty.
wait_for_nfs_export() {
  local waited=0 vol=exl3probe
  while :; do
    # The container carries --restart unless-stopped, so this is belt-and-braces
    # for the case where it was stopped by hand rather than crashed.
    ssh -o BatchMode=yes -o ConnectTimeout=5 "$WORKER_SSH" \
      'docker ps --format "{{.Names}}" | grep -qx nfs-exl3 || docker start nfs-exl3 >/dev/null 2>&1' \
      >/dev/null 2>&1 || true

    docker volume rm "$vol" >/dev/null 2>&1 || true
    if docker volume create --driver local --opt type=nfs \
         --opt "o=addr=${WORKER_RAIL_IP},ro,vers=4.2,rsize=1048576,port=${NFS_PORT:-2049}" \
         --opt device=:/ "$vol" >/dev/null 2>&1 \
       && docker run --rm -v "$vol:/m" ubuntu:24.04 test -f /m/config.json >/dev/null 2>&1; then
      docker volume rm "$vol" >/dev/null 2>&1 || true
      echo "==> NFS export ready on ${WORKER_RAIL_IP}:${NFS_PORT:-2049}"
      return 0
    fi
    docker volume rm "$vol" >/dev/null 2>&1 || true

    [ "$waited" -ge "$NFS_WAIT" ] && {
      echo "NFS export not ready after ${NFS_WAIT}s -- check: ssh $WORKER_SSH docker logs nfs-exl3" >&2
      echo "(Up is not success; wait for 'READY AND WAITING FOR NFS CLIENT CONNECTIONS')" >&2
      return 1
    }
    [ "$waited" = 0 ] && echo "==> waiting for the NFS export on the worker"
    sleep 10; waited=$((waited + 10))
  done
}
if [ "${WEIGHTS_MODE:-local}" = nfs ]; then
  wait_for_nfs_export || exit 1
fi

# The head needs > 16 GiB of swap to survive weight load, and without it the
# boot dies at shard 114/120 every single time.
#
# Measured 2026-08-30 across six identical failures: peak head footprint is
# anon 32.6 (the EXL3 loader's transient dequant/TP-slice working set) + gpu
# 79.4 + shmem 2.4 = 114.4 GiB against 1.4 GiB available -- about 3 GiB short
# of the ~83.6 GiB it needs resident to finish. The peak is transient: the
# worker's anon collapses 25.7 -> 1.0 GiB the instant loading completes,
# settling near 85 GiB. So this is a spike to absorb, not a budget to cut --
# which is why no KV/GMU/MAX_LEN change ever moved the failure shard.
#
# /etc/fstab carries the entry (sw,nofail) so this is normally a no-op; the
# check exists because a head that boots without it fails in a way that looks
# like a config problem and costs hours to re-diagnose. swapon needs root and
# there is no passwordless sudo for it, but swap is a global kernel resource
# rather than a namespaced one, so a privileged container can do it.
# BOTH ranks. The head is where weight load dies, but the worker hits the same
# squeeze later, during KV carve and CUDA-graph capture -- observed at 7 GiB
# available on 2026-08-30 while still carrying only the stock 16 GiB.
SWAP_SETUP='
  set -e
  if [ ! -f /host/swapfile2 ]; then
    fallocate -l 64G /host/swapfile2
    chmod 600 /host/swapfile2
    mkswap /host/swapfile2 >/dev/null
  fi
  swapon /host/swapfile2 2>/dev/null || true
  # Persist, so a reboot does not silently reintroduce the failure.
  grep -q "^/swapfile2" /host/etc/fstab || \
    printf "%s\n" "/swapfile2	none	swap	sw,nofail	0	0" >> /host/etc/fstab
'
swap_gib() { awk '/^SwapTotal:/{printf "%d", $2/1048576}' /proc/meminfo; }

ensure_swap() {
  local want="${SWAP_MIN_GIB:-40}" have
  # --- head ---
  have=$(swap_gib)
  if [ "${have:-0}" -lt "$want" ]; then
    echo "==> head swap ${have}GiB (< ${want}GiB); enabling /swapfile2"
    docker run --rm --privileged -v /:/host ubuntu:24.04 sh -c "$SWAP_SETUP" >/dev/null 2>&1 || true
    have=$(swap_gib)
    [ "${have:-0}" -lt "$want" ] && {
      echo "WARNING: head swap is still ${have}GiB -- expect an OOM kill at" >&2
      echo "         ~shard 114/120 during weight load." >&2
    }
  fi
  # --- worker ---
  local whave
  whave=$(ssh -o BatchMode=yes -o ConnectTimeout=5 "$WORKER_SSH" \
    "awk '/^SwapTotal:/{printf \"%d\", \$2/1048576}' /proc/meminfo" 2>/dev/null)
  if [ "${whave:-0}" -lt "$want" ]; then
    echo "==> worker swap ${whave}GiB (< ${want}GiB); enabling /swapfile2"
    ssh -o BatchMode=yes -o ConnectTimeout=10 "$WORKER_SSH" \
      "docker run --rm --privileged -v /:/host ubuntu:24.04 sh -c '$SWAP_SETUP'" >/dev/null 2>&1 || true
  fi
  echo "==> swap: head $(swap_gib)GiB, worker $(ssh -o BatchMode=yes -o ConnectTimeout=5 "$WORKER_SSH" \
    "awk '/^SwapTotal:/{printf \"%d\", \$2/1048576}' /proc/meminfo" 2>/dev/null)GiB"
}
ensure_swap

# Head first, and before the worker starts. A fresh worker rendezvouses with
# whatever TCP store it finds; if the old head is still up it will attach to
# that one and then die of connection-reset the instant it is replaced, leaving
# the new head waiting on a worker that is already gone.
# Start the ritual BEFORE either rank launches -- see the DROP_LOOP note.
# Starting it partway through is too late: swap already forced by then is
# not recoverable.
DROP_STOP="$(mktemp -u /tmp/glm53-dropstop.XXXXXX)"
DROP_PID=""
if [ "$DROP_LOOP" != 0 ]; then
  (
    while [ ! -e "$DROP_STOP" ]; do
      sudo -n /usr/local/sbin/spark-drop-caches >/dev/null 2>&1 || true
      ssh -o BatchMode=yes -o ConnectTimeout=4 "$WORKER_SSH" \
        'sudo -n /usr/local/sbin/spark-drop-caches >/dev/null 2>&1 || true' >/dev/null 2>&1 || true
      sleep "$DROP_INTERVAL"
    done
  ) &
  DROP_PID=$!
fi

# Per-rank memory trace for the whole boot. Four OOM deaths were debugged
# without ever capturing the head's GPU allocation, which is the one number
# that says whether the head's footprint differs from the worker's or whether
# it is host overhead. Cheap, and it makes the next failure diagnosable.
TRACE="${TRACE:-$HOME/exl3-memtrace.csv}"
echo "ts,host,mem_used_gib,mem_avail_gib,cache_gib,swap_used_gib,gpu_mib" > "$TRACE"
(
  while [ ! -e "$DROP_STOP" ]; do
    for h in 127.0.0.1 "$WORKER_SSH"; do
      ssh -o BatchMode=yes -o ConnectTimeout=5 "$h" \
        'read u a c s <<<"$(awk "/^MemTotal/{t=\$2}/^MemAvailable/{a=\$2}/^Cached:/{c=\$2}/^SwapTotal/{st=\$2}/^SwapFree/{sf=\$2}END{printf \"%.1f %.1f %.1f %.1f\", (t-a)/1048576, a/1048576, c/1048576, (st-sf)/1048576}" /proc/meminfo)"
         g=$(nvidia-smi --query-compute-apps=used_memory --format=csv,noheader,nounits 2>/dev/null | paste -sd+ - | bc 2>/dev/null)
         echo "$(date +%s),$(hostname),$u,$a,$c,$s,${g:-0}"' 2>/dev/null >> "$TRACE" || true
    done
    sleep 10
  done
) &
TRACE_PID=$!

echo "==> clearing any live head"
docker rm -f "$NAME" >/dev/null 2>&1 || true

echo "==> starting worker (rank 1) on ${WORKER_SSH}  [$PROFILE_DESC]"
ssh -o BatchMode=yes -o ConnectTimeout=10 "$WORKER_SSH" \
  "${ENVPFX} \$HOME/launch-glm53-vllm-tp2.sh 1"

echo "==> waiting ${WORKER_LEAD}s for the worker to settle"
sleep "$WORKER_LEAD"

echo "==> starting head (rank 0)"
"$LAUNCHER" 0

# The GB10 memory ritual, run CONTINUOUSLY rather than once.
#
# spark-drop-caches explains why: NVRM allocates GPU-visible memory out of
# system RAM with __GFP_RETRY_MAYFAIL -- bounded reclaim that never forces
# page-cache eviction. Buffered-I/O loading of a 164 GiB checkpoint lets the
# page cache take the balance, the kernel starts swapping anonymous pages to
# compensate, and the loader is OOM-killed near the end of shard load. Measured
# here on the first attempt: head OOMKilled at 114/120 with swap 15.5/16 GiB.
#
# The launcher's single pre-launch drop cannot help, because the cache refills
# during the ~5 minutes of loading. Upstream's answer is --nfs (a paced read);
# that image is amd64-only and cannot run on GB10, so we pace by evicting
# instead. Cost is nil: shard pages are read exactly once, so there is nothing
# worth caching. Both ranks, since both load ~82 GiB.
# Release the lock ONLY if we still own it. An unconditional `rm` here is a
# self-sustaining outage: two launchers overlap (the watchdog starts one while
# an operator's is still running), the older one exits and deletes the YOUNGER
# one's lock, the watchdog then sees an unlocked 12-minute weight load, calls it
# a dead engine, and relaunches -- forever. Observed doing exactly that on
# 2026-08-30; it killed a healthy NFS boot twice before being caught.
#
# The drop loop must also die on every exit path, or it outlives a failed boot
# and keeps dropping caches against whatever runs next.
release() {
  [ "$(cat "$LOCK_FILE" 2>/dev/null || true)" = "$$" ] && rm -f "$LOCK_FILE"
  : > "$DROP_STOP" 2>/dev/null || true
  [ -n "${DROP_PID:-}" ] && kill "$DROP_PID" 2>/dev/null
  [ -n "${TRACE_PID:-}" ] && kill "$TRACE_PID" 2>/dev/null
  rm -f "$DROP_STOP" 2>/dev/null || true
  return 0
}
trap release EXIT

echo "==> waiting for the API (weight load alone is ~10 min; dropping caches every 15s)"
t0=$(date +%s)
until curl -fsS --max-time 5 "$HEALTH_URL" >/dev/null 2>&1; do
  sleep 15
  # A dead container never becomes healthy, so fail fast rather than burn the
  # full 30 minutes waiting for something that already exited.
  if ! docker ps --format '{{.Names}}' | grep -qx "$NAME"; then
    echo "head container exited during boot; last 40 lines:" >&2
    docker logs "$NAME" 2>&1 | tail -40 >&2
    echo >&2
    echo "if it wedged into swap at ~90% of shard load, re-run install.sh --nfs" >&2
    exit 1
  fi
  if [ $(( $(date +%s) - t0 )) -gt "$API_WAIT" ]; then
    echo "API not up after ${API_WAIT}s -- docker logs $NAME" >&2
    exit 1
  fi
done
echo "==> API up after $(( $(date +%s) - t0 ))s"

# Upstream's JIT shape warmup: without it the first real request pays ~7s of
# lazy compilation. Non-fatal -- serving is already live at this point.
if [ -x "$HOME/glm53-warmup.sh" ]; then
  echo "==> warming JIT shapes"
  API_BASE="http://127.0.0.1:${PORT}" bash "$HOME/glm53-warmup.sh" || \
    echo "    warmup reported failures; serving continues" >&2
fi

echo "GLM-5.3-Flash EXL3 serving on :${PORT}"
