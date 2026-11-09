#!/usr/bin/env bash
# Bring up DeepSeek-V4.1-Flash-1017 EXL3 2.75bpw (HeNryous/deepseek-v41-1017-dgx-spark) across both ranks. Runs on node1.
set -euo pipefail

UPSTREAM="${UPSTREAM:-$HOME/deepseek-v41-1017-dgx-spark}"
export RECIPE="${RECIPE:-$HOME/dgx-spark-deepseek-v41}"
export HEAD="${HEAD:-169.254.34.131}"
export WORKER="${WORKER:-169.254.54.207}"
export FAB_IF="${FAB_IF:-enp1s0f1np1}"
export FAB_HCA="${FAB_HCA:-rocep1s0f1}"
export PORT="${PORT:-8888}"
NAME=dsv41-serve
API_WAIT="${API_WAIT:-1800}"
DROP_INTERVAL="${DROP_INTERVAL:-5}"
KV_OFFLOAD_CAP_GB="${KV_OFFLOAD_CAP_GB:-40}"
HEALTH_URL="http://127.0.0.1:${PORT}/health"
LOCK_FILE="${LOCK_FILE:-$HOME/dspark-recipe/.switching}"
SERVE="$(mktemp /tmp/dsv41-serve.XXXXXX.sh)"
DROP_STOP="$(mktemp -u /tmp/dsv41-dropstop.XXXXXX)"
DROP_PID=""

[ -f "$UPSTREAM/serve/serve_example.sh" ] || { echo "missing $UPSTREAM (git clone HeNryous/deepseek-v41-1017-dgx-spark)" >&2; exit 1; }
[ -x "$RECIPE/scripts/launch/dsv41_tp2.sh" ] || { echo "missing $RECIPE launcher (git clone sudoingX/dgx-spark-deepseek-v41 && checkout cc59c36)" >&2; exit 1; }
ssh -o BatchMode=yes -o ConnectTimeout=5 "$HEAD" true || { echo "node1 cannot ssh to itself at $HEAD; the launcher needs it" >&2; exit 1; }

mkdir -p "$(dirname "$LOCK_FILE")"
echo $$ > "$LOCK_FILE"

release() {
  [ "$(cat "$LOCK_FILE" 2>/dev/null || true)" = "$$" ] && rm -f "$LOCK_FILE"
  : > "$DROP_STOP" 2>/dev/null || true
  [ -n "$DROP_PID" ] && kill "$DROP_PID" 2>/dev/null
  rm -f "$DROP_STOP" "$SERVE"
  return 0
}
trap release EXIT

sed "s/rocep1s0f0,roceP2p1s0f0/${FAB_HCA}/g" "$UPSTREAM/serve/serve_example.sh" > "$SERVE"
if grep -q 'roceP2p1s0f0' "$SERVE" || ! grep -q "NCCL_IB_HCA=${FAB_HCA} EXL3_RDMA_DEVICES=${FAB_HCA} " "$SERVE"; then
  echo "serve_example.sh HCA list did not rewrite to ${FAB_HCA}; upstream changed, update this script" >&2
  exit 1
fi

clean_script() {
  cat <<EOF
rm -f /dev/shm/vllm_offload_*.mmap
d=/c/kv_offload
[ -d "\$d" ] || exit 0
find "\$d" -type f -mmin +1440 -delete
find "\$d" -type f -printf '%T@ %s %p\n' | sort -rn \
  | awk -v cap=$((KV_OFFLOAD_CAP_GB * 1024 * 1024 * 1024)) '{ t += \$2; if (t > cap) { sub(/^[^ ]+ [^ ]+ /, ""); print } }' \
  | xargs -r -d '\n' rm -f
find "\$d" -mindepth 1 -type d -empty -delete
EOF
}
PREP='docker rm -f dsv41-serve >/dev/null 2>&1 || true
mkdir -p "$HOME/.cache/dsv41-serve"
docker run --rm -i -v /dev/shm:/dev/shm -v "$HOME/.cache/dsv41-serve:/c" ubuntu:24.04 sh -s
sudo -n /usr/local/sbin/spark-drop-caches >/dev/null 2>&1 || true'
clean_script | bash -c "$PREP"
clean_script | ssh -o BatchMode=yes -o ConnectTimeout=10 "$WORKER" "$PREP"

(
  while [ ! -e "$DROP_STOP" ]; do
    sudo -n /usr/local/sbin/spark-drop-caches >/dev/null 2>&1 || true
    ssh -o BatchMode=yes -o ConnectTimeout=4 "$WORKER" \
      'sudo -n /usr/local/sbin/spark-drop-caches >/dev/null 2>&1 || true' >/dev/null 2>&1 || true
    sleep "$DROP_INTERVAL"
  done
) &
DROP_PID=$!

echo "==> starting DeepSeek-V4.1-Flash-1017 (head $HEAD, worker $WORKER, $FAB_IF/$FAB_HCA, :$PORT)"
timeout "$API_WAIT" bash "$SERVE" || { echo "launcher failed or exceeded ${API_WAIT}s" >&2; exit 1; }

until curl -fsS --max-time 5 "$HEALTH_URL" >/dev/null 2>&1; do
  docker ps --format '{{.Names}}' | grep -qx "$NAME" || { docker logs --tail 40 "$NAME" >&2 2>&1; exit 1; }
  sleep 5
done

echo "DeepSeek-V4.1-Flash-1017 serving on :${PORT}"
