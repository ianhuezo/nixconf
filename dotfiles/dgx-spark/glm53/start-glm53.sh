#!/usr/bin/env bash
# Bring up GLM-5.3-Flash NVFP4 across the Spark pair (worker rank 1, then head).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ENV_FILE="${ENV_FILE:-$SCRIPT_DIR/.env.glm53}"
COMPOSE_FILE="${COMPOSE_FILE:-$SCRIPT_DIR/docker-compose.glm53.yml}"
PROJECT="${PROJECT:-glm53}"
WAIT_ATTEMPTS="${WAIT_ATTEMPTS:-120}"
WAIT_SECONDS="${WAIT_SECONDS:-15}"
# Upstream's rule: let the worker finish its rendezvous setup before the head
# arrives. A head that meets a half-initialised worker hangs confusingly.
WORKER_LEAD="${WORKER_LEAD:-25}"

if [ ! -f "$ENV_FILE" ]; then
  echo "Missing $ENV_FILE. Deploy it with dotfiles/dgx-spark/deploy.sh." >&2
  exit 1
fi

set -a
# shellcheck disable=SC1090
source "$ENV_FILE"
set +a

: "${WORKER_HOST:?WORKER_HOST must be set in $ENV_FILE}"
: "${MASTER_ADDR:?MASTER_ADDR must be set in $ENV_FILE}"
: "${NCCL_IB_HCA:?NCCL_IB_HCA must be set in $ENV_FILE}"
: "${NCCL_SOCKET_IFNAME:?NCCL_SOCKET_IFNAME must be set in $ENV_FILE}"
: "${VLLM_HOST_IP:?VLLM_HOST_IP must be set to the head fabric IP in $ENV_FILE}"
: "${WORKER_VLLM_HOST_IP:?WORKER_VLLM_HOST_IP must be set in $ENV_FILE}"

IMAGE="${GLM53_VLLM_IMAGE:-vllm-glm53-runtime:sm121-v14}"
PORT="${VLLM_PORT:-8888}"
# /health, NOT /v1/models: the latter returns 200 even when the engine is dead,
# so readiness polled against it can report success on a corpse.
API_URL="${API_URL:-http://127.0.0.1:${PORT}/health}"
CHAT_URL="${CHAT_URL:-http://127.0.0.1:${PORT}/v1/chat/completions}"

cd "$SCRIPT_DIR"

# Suppress the watchdog for the duration of this launch: a 16-minute weight
# load is indistinguishable from a dead engine from the outside, and without
# this the watchdog would tear down every healthy boot it ever saw.
#
# Owned HERE rather than in model-select.sh because any launch path needs it --
# a direct start-glm53.sh call left the watchdog armed against a live boot.
# trap EXIT (not RETURN) so `set -e` cannot leak it, and the PID goes inside so
# a leaked lock is detectable instead of silently muzzling the watchdog forever.
LOCK_FILE="${LOCK_FILE:-$SCRIPT_DIR/../.switching}"
mkdir -p "$(dirname "$LOCK_FILE")" 2>/dev/null || true
echo $$ > "$LOCK_FILE"
trap 'rm -f "$LOCK_FILE"' EXIT

# Same argument as the image check, for the same reason. The DFlash2 drafter is
# read from each rank's own HF cache, and a rank that cannot find it dies during
# model init -- roughly 15 minutes in, with the surviving rank reporting only a
# rendezvous it can never complete. Cheap to check now, expensive to diagnose later.
if [ "${SPEC_METHOD:-none}" = dflash ]; then
  DRAFT="${DFLASH2_MODEL:-incoai/GLM-5.3-Flash-DFlash2}"
  DRAFT_LEAF="models--$(printf %s "$DRAFT" | sed 's|/|--|g')"
  probe_draft="n=\$(find -L \"\$HOME/.cache/huggingface/hub/$DRAFT_LEAF/snapshots\" -name '*.safetensors' 2>/dev/null | wc -l); echo \${n:-0}"
  echo "==> checking DFlash2 drafter $DRAFT on both ranks"
  head_draft="$(eval "$probe_draft" 2>/dev/null || echo 0)"
  worker_draft="$(ssh "$WORKER_HOST" "$probe_draft" 2>/dev/null || echo 0)"
  if [ "${head_draft:-0}" -lt 1 ] || [ "${worker_draft:-0}" -lt 1 ]; then
    echo "Drafter missing (head: $head_draft shards, worker: $worker_draft shards)." >&2
    echo "Fetch it on both ranks: $SCRIPT_DIR/fetch-glm53-weights.sh draft" >&2
    echo "Or set SPEC_METHOD=none in $ENV_FILE to launch without speculation." >&2
    exit 1
  fi
fi

WORKER_DIR="${WORKER_SCRIPT_DIR:-${WORKER_DIR:-$SCRIPT_DIR}}"
WORKER_HF_CACHE="${WORKER_HF_CACHE:-${HF_CACHE:-}}"
REMOTE_WORKER_DIR="$(printf '%q' "$WORKER_DIR")"
REMOTE_COMPOSE="cd $REMOTE_WORKER_DIR && env -u MASTER_ADDR -u MASTER_PORT -u NODE_RANK -u HEADLESS COMPOSE_DISABLE_ENV_FILE=1"

# The image must be byte-identical on both ranks. Upstream lost two boots to a
# silent version skew between them, so this is a hard precondition, not a hint.
echo "==> checking $IMAGE on both ranks"
HEAD_ID="$(docker image inspect "$IMAGE" --format '{{.Id}}' 2>/dev/null || true)"
if [ -z "$HEAD_ID" ]; then
  echo "Head is missing $IMAGE. Build it: $SCRIPT_DIR/build-glm53-runtime.sh --ship" >&2
  exit 1
fi
WORKER_ID="$(ssh "$WORKER_HOST" "docker image inspect '$IMAGE' --format '{{.Id}}' 2>/dev/null" || true)"
if [ "$HEAD_ID" != "$WORKER_ID" ]; then
  echo "Image mismatch between ranks:" >&2
  echo "  head:   ${HEAD_ID:-<missing>}" >&2
  echo "  worker: ${WORKER_ID:-<missing>}" >&2
  echo "Re-ship with: $SCRIPT_DIR/build-glm53-runtime.sh --ship" >&2
  exit 1
fi

# GB10 allocates GPU memory from host DRAM through a driver path that fails
# rather than reclaiming clean page cache, so the KV slab has to be carved out
# of genuinely free pages. Dropping caches first measurably improves the odds.
# Not fatal if sudo needs a password -- it only costs KV headroom.
# Prefers the installed ritual (drop_caches + compact_memory) if
# install-drop-caches.sh has granted a scoped NOPASSWD rule for it; otherwise
# falls back to the inline form, which needs a password and so usually just
# warns. Not fatal either way -- it only costs KV headroom, but the very first
# GLM boot on this pair died 0.74 GiB short precisely because it was skipped.
RITUAL=/usr/local/sbin/spark-drop-caches
drop_caches() {
  local where="$1" cmd
  cmd="if [ -x $RITUAL ]; then sudo -n $RITUAL; else sync && sudo -n sh -c 'echo 3 > /proc/sys/vm/drop_caches'; fi"
  if [ "$where" = local ]; then
    eval "$cmd" 2>/dev/null \
      || echo "    (could not drop caches on head; run: sudo ~/dspark-recipe/install-drop-caches.sh)"
  else
    ssh "$WORKER_HOST" "$cmd" 2>/dev/null \
      || echo "    (could not drop caches on worker; run: sudo ~/dspark-recipe/install-drop-caches.sh)"
  fi
}

echo "==> syncing deployment files to ${WORKER_HOST}:${WORKER_DIR}"
ssh "$WORKER_HOST" "mkdir -p $REMOTE_WORKER_DIR"
scp -q "$COMPOSE_FILE" "${WORKER_HOST}:${REMOTE_WORKER_DIR}/docker-compose.glm53.yml"
scp -q "$ENV_FILE" "${WORKER_HOST}:${REMOTE_WORKER_DIR}/.env.glm53"

echo "==> dropping page cache on both nodes"
drop_caches local
drop_caches worker

echo "==> starting worker (rank 1) on ${WORKER_HOST}"
ssh "$WORKER_HOST" "$REMOTE_COMPOSE NODE_RANK=1 HEADLESS=1 HF_CACHE='$WORKER_HF_CACHE' VLLM_HOST_IP='$WORKER_VLLM_HOST_IP' docker compose -p '$PROJECT' --env-file .env.glm53 -f docker-compose.glm53.yml up -d"

echo "==> waiting ${WORKER_LEAD}s for the worker to settle"
sleep "$WORKER_LEAD"

echo "==> starting head (rank 0)"
COMPOSE_DISABLE_ENV_FILE=1 NODE_RANK=0 HEADLESS='' \
  docker compose -p "$PROJECT" --env-file "$ENV_FILE" -f "$COMPOSE_FILE" up -d

# Hold page cache down THROUGH the load, not just before it.
#
# The pre-launch ritual only fixes the reservation at construction time. During
# the ~12-minute shard read, buffered I/O parks essentially everything in page
# cache: measured on this pair, MemFree sat at 0.7-2.3 GiB while MemAvailable
# read ~19 GiB. That gap matters because the NVIDIA driver allocates with
# bounded reclaim (__GFP_RETRY_MAYFAIL) and will NOT evict cache to satisfy a
# request -- so MemAvailable is not spendable, MemFree is. Any allocation made
# after loading (the KV pool, or b12x's scale-factor conversion) then faces
# ~1 GiB of genuinely free memory regardless of how much gpu-memory-utilization
# left behind. Running the flusher lifted MemFree 0.7 -> 14.5 GiB immediately.
#
# Dropping cache mid-load is safe: shards are read once, sequentially, and the
# data is already copied into the model's tensors. Upstream reached the same
# conclusion (cache_flusher.sh) after a KV-allocation hunt.
start_cache_flusher() {
  local dur="${FLUSH_MINUTES:-25}" thresh="${FLUSH_THRESHOLD_GIB:-12}"
  local body="for i in \$(seq 1 \$(( ${dur} * 4 ))); do
    F=\$(awk '/^MemFree:/{printf \"%.0f\", \$2/1048576}' /proc/meminfo)
    [ \"\$F\" -lt ${thresh} ] && sudo -n ${RITUAL} >/dev/null 2>&1
    sleep 15
  done"
  # Best-effort on both ranks; a missing NOPASSWD rule just makes it a no-op.
  nohup bash -c "$body" >/dev/null 2>&1 &
  disown 2>/dev/null || true
  ssh "$WORKER_HOST" "nohup bash -c $(printf '%q' "$body") >/dev/null 2>&1 & disown" 2>/dev/null || true
  echo "    (holding page cache below ${thresh} GiB for ${dur} min on both ranks)"
}
echo "==> starting cache flusher"
start_cache_flusher

echo "==> waiting for the API (weight load alone is ~10 min)"
for _ in $(seq 1 "$WAIT_ATTEMPTS"); do
  if curl -fsS --max-time 5 "$API_URL" >/dev/null 2>&1; then
    echo "GLM-5.3-Flash is serving: $API_URL"
    COMPOSE_DISABLE_ENV_FILE=1 docker compose -p "$PROJECT" --env-file "$ENV_FILE" -f "$COMPOSE_FILE" ps
    echo "==> smoke test"
    curl -fsS --max-time 120 "$CHAT_URL" \
      -H "Content-Type: application/json" \
      -d '{"model":"'"${SERVED_MODEL_NAME:-glm-5.3-flash}"'","messages":[{"role":"user","content":"Reply with OK."}],"max_tokens":512,"temperature":0.0}' >/dev/null
    echo "Smoke test passed."

    # The KV pool is the number every other tuning decision hangs off, and it
    # is only knowable after a boot. Surface it here rather than making anyone
    # go spelunking in the logs for it.
    # A miswired drafter does NOT crash -- shapes stay valid, the drafter
    # consumes garbage features, and the only symptom is acceptance collapsing
    # while decode still "works". These two log lines are the wiring proof:
    # the aux layer ids must be (6,15,25,34,43) -- the runner's +1 over the
    # drafter config's [5,14,24,33,42] -- and the sampler must warm up at
    # num_spec=7. Anything else means the capture or the block size is wrong.
    if [ "${SPEC_METHOD:-none}" = dflash ]; then
      echo
      echo "==> DFlash2 wiring (expect aux layers (6, 15, 25, 34, 43) and num_spec=7)"
      COMPOSE_DISABLE_ENV_FILE=1 docker compose -p "$PROJECT" --env-file "$ENV_FILE" \
        -f "$COMPOSE_FILE" logs 2>/dev/null \
        | grep -Ei 'auxiliary layers|num_spec=|drafter path' \
        | tail -5 | sed 's/^/    /' \
        || echo "    (not found in logs -- check that the drafter actually loaded)"
    fi

    echo
    echo "==> KV pool (concurrency = pool / max-model-len = ${MAX_MODEL_LEN:-200000})"
    COMPOSE_DISABLE_ENV_FILE=1 docker compose -p "$PROJECT" --env-file "$ENV_FILE" \
      -f "$COMPOSE_FILE" logs 2>/dev/null \
      | grep -Ei 'KV cache size|Maximum concurrency|kv_cache_memory|Available KV cache' \
      | tail -5 | sed 's/^/    /' \
      || echo "    (not found in logs; check manually)"
    exit 0
  fi
  # A rank that dies during load leaves the API endpoint silent forever;
  # noticing at 3 minutes beats noticing at 30. Compose failing to answer is
  # not the same as the container being gone, so only a clean empty result
  # counts as death.
  running_ids="$(COMPOSE_DISABLE_ENV_FILE=1 docker compose -p "$PROJECT" --env-file "$ENV_FILE" \
    -f "$COMPOSE_FILE" ps -q --status running 2>/dev/null)" || running_ids="skip"
  if [ -z "$running_ids" ]; then
    echo "Head container is no longer running. Capture logs BEFORE tearing down:" >&2
    echo "  docker compose -p $PROJECT --env-file $ENV_FILE -f $COMPOSE_FILE logs --tail=200" >&2
    exit 1
  fi
  sleep "$WAIT_SECONDS"
done

echo "Timed out waiting for the GLM API. Head logs:" >&2
COMPOSE_DISABLE_ENV_FILE=1 docker compose -p "$PROJECT" --env-file "$ENV_FILE" -f "$COMPOSE_FILE" logs --tail=150 >&2 || true
echo "Worker logs:" >&2
ssh "$WORKER_HOST" "$REMOTE_COMPOSE docker compose -p '$PROJECT' --env-file .env.glm53 -f docker-compose.glm53.yml logs --tail=150" >&2 || true
exit 1
