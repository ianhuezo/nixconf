#!/usr/bin/env bash
set -euo pipefail

NAME=dsv41-serve
WORKER="${WORKER:-169.254.54.207}"

echo "Stopping DeepSeek-V4.1 head..."
docker rm -f "$NAME" >/dev/null 2>&1 || true

echo "Stopping DeepSeek-V4.1 worker on ${WORKER}..."
ssh -o BatchMode=yes -o ConnectTimeout=10 "$WORKER" \
  "docker rm -f '$NAME' >/dev/null 2>&1 || true" || true

echo "DeepSeek-V4.1-Flash-1017 stopped."
