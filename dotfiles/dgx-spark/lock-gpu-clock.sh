#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ENV_FILE="${ENV_FILE:-$SCRIPT_DIR/.env.dspark}"
if [[ -f $ENV_FILE ]]; then
    set -a
    source "$ENV_FILE"
    set +a
fi

IMAGE="${DSPARK_VLLM_IMAGE:-vllm-dspark-runtime:dspark-nvfp4-stage-c}"
CLOCK_MHZ="${CLOCK_MHZ:-3003}"

case "${1:-lock}" in
    lock)
        args=(-lgc "$CLOCK_MHZ")
        ;;
    reset)
        args=(-rgc)
        ;;
    *)
        echo "Usage: $0 [lock|reset]" >&2
        exit 2
        ;;
esac

docker image inspect "$IMAGE" >/dev/null
docker run --rm --privileged --gpus all --entrypoint nvidia-smi \
    "$IMAGE" "${args[@]}"
echo "Clock operation complete. Verify symmetry under load with:"
echo "  nvidia-smi --query-gpu=clocks.sm,power.draw --format=csv,noheader"
