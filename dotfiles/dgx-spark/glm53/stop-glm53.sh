#!/usr/bin/env bash
# Tear down BOTH GLM ranks. Always both: a rank left alive will happily
# rendezvous with the next launch and hang it.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ENV_FILE="${ENV_FILE:-$SCRIPT_DIR/.env.glm53}"
COMPOSE_FILE="${COMPOSE_FILE:-$SCRIPT_DIR/docker-compose.glm53.yml}"
PROJECT="${PROJECT:-glm53}"

if [ -f "$ENV_FILE" ]; then
  set -a
  # shellcheck disable=SC1090
  source "$ENV_FILE"
  set +a
fi

: "${WORKER_HOST:?WORKER_HOST must be set in $ENV_FILE or environment}"

cd "$SCRIPT_DIR"

WORKER_DIR="${WORKER_SCRIPT_DIR:-${WORKER_DIR:-$SCRIPT_DIR}}"
WORKER_HF_CACHE="${WORKER_HF_CACHE:-${HF_CACHE:-}}"

echo "Stopping GLM head..."
COMPOSE_DISABLE_ENV_FILE=1 docker compose -p "$PROJECT" --env-file "$ENV_FILE" -f "$COMPOSE_FILE" down || true

echo "Stopping GLM worker on ${WORKER_HOST}..."
ssh "$WORKER_HOST" "cd '$WORKER_DIR' && env -u MASTER_ADDR -u MASTER_PORT -u NODE_RANK -u HEADLESS COMPOSE_DISABLE_ENV_FILE=1 HF_CACHE='$WORKER_HF_CACHE' VLLM_HOST_IP='${WORKER_VLLM_HOST_IP:-}' docker compose -p '$PROJECT' --env-file .env.glm53 -f docker-compose.glm53.yml down" || true

echo "GLM-5.3-Flash stopped."
