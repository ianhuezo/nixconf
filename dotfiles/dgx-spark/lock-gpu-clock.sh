#!/usr/bin/env bash
# Lock the GB10 graphics clock to its supported 3003 MHz ceiling.
# The driver setting is reset by reboot. install-gpu-clock-service.sh installs
# the systemd unit that reapplies it automatically. Docker --privileged lets
# this manual helper work without sudo; docker membership is root-equivalent.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ENV_FILE="${ENV_FILE:-$SCRIPT_DIR/.env.dspark}"
if [[ -f $ENV_FILE ]]; then
    set -a
    # shellcheck disable=SC1090
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
