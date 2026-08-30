#!/usr/bin/env bash
# Tear down BOTH EXL3 ranks. Always both: a rank left alive will happily
# rendezvous with the next launch and hang it.
set -euo pipefail

SERVE_ENV="${GLM53_ENV:-$HOME/.glm53-serve.env}"
NAME="${NAME:-vllm_glm53}"

if [ -f "$SERVE_ENV" ]; then
  # shellcheck disable=SC1090
  . "$SERVE_ENV"
fi
WORKER_SSH="${WORKER_SSH:-${WORKER_RAIL_IP:-169.254.54.207}}"

echo "Stopping EXL3 head..."
docker rm -f "$NAME" >/dev/null 2>&1 || true

echo "Stopping EXL3 worker on ${WORKER_SSH}..."
ssh -o BatchMode=yes -o ConnectTimeout=10 "$WORKER_SSH" \
  "docker rm -f '$NAME' >/dev/null 2>&1 || true" || true

echo "GLM-5.3-Flash EXL3 stopped."
