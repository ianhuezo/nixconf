#!/usr/bin/env bash
# Build the patched GLM-5.3-Flash vLLM runtime for DGX Spark (GB10 / SM121).
#
# Stock vLLM has no glm5_next; the day-0 image from vLLM PR #53906 does, but it
# was cut for B200 and fails five separate ways on GB10. This chains the patch
# stack from tonyd2wild/GLM-5.3-Flash-NVFP4-2x-DGX-Spark onto it.
#
# The stage numbering is Tony's, kept so his DEPLOY-REPORT cross-references
# still line up -- which is also why there is NO v2 here. v2 is his env-gated
# NaN-localizer debug build, a side branch off v1; the production chain is
# v1 -> v3 -> v4 -> v5 -> v6 -> v7 -> v8. (His README's "v1..v7 in order" is
# wrong on this point; the FROM lines in the Dockerfiles are what's authoritative.)
#
# v9 (InstantTensor direct-IO loader) is deliberately NOT built. It loads 15x
# faster and then kills a rank silently ~60-90s later in every multi-node TP2
# boot its author tried, including at KV budgets that are otherwise 100% stable.
#
# v10-v13 are ours; v14 is upstream's DFlash2 overlay (their v11-dflash2),
# restacked on top of v13. Their numbering diverges from ours past v9.
#
#   ./build-glm53-runtime.sh              # build on this node
#   ./build-glm53-runtime.sh --ship       # build, then copy the image to the worker
#   ./build-glm53-runtime.sh --verify     # only re-verify what is already built
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ENV_FILE="${ENV_FILE:-$SCRIPT_DIR/.env.glm53}"

if [[ -f $ENV_FILE ]]; then
    set -a
    # shellcheck disable=SC1090
    source "$ENV_FILE"
    set +a
fi

BASE_IMAGE="${GLM53_BASE_IMAGE:-vllm/vllm-openai:glm53-flash-arm64-cu130}"
FINAL_IMAGE="${GLM53_VLLM_IMAGE:-vllm-glm53-runtime:sm121-v14}"
SHIP=0
VERIFY_ONLY=0

for arg in "$@"; do
    case "$arg" in
        --ship)   SHIP=1 ;;
        --verify) VERIFY_ONLY=1 ;;
        *) echo "usage: $0 [--ship] [--verify]" >&2; exit 2 ;;
    esac
done

# Ordered stage list: "<dockerfile suffix>:<tag suffix>". Each stage is built
# FROM the previous stage's tag, so a failure leaves every earlier stage cached
# and the rebuild resumes from the broken one.
STAGES=(
    "v1-nope-mla:v1"
    "v3-flashinfer:v3"
    "v4-nccl:v4"
    "v5-cutlass:v5"
    "v6-pdl:v6"
    "v7-indexer:v7"
    "v8-fp8-kv:v8"
    "v10-topk-sm-gate:v10"
    "v11-mtp-quant-prefix:v11"
    "v12-b12x-swiglu-clamp:v12"
    "v13-b12x-collapse-vmk:v13"
    "v14-dflash2:v14"
)

TAG_PREFIX="${FINAL_IMAGE%%:*}"

# Every patch in the stack is guarded on an exact source match and dies loudly
# if the base image moved, so a build that succeeds has already proved most of
# this. What it does NOT prove is that a later pip layer clobbered an earlier
# pin -- which is exactly the failure that cost the upstream author two boots.
verify_image() {
    local img="$1"
    echo "==> verifying $img"
    docker run --rm -i --entrypoint python3 "$img" - <<'PYCHECK'
import sys
from pathlib import Path

base = Path("/usr/local/lib/python3.12/dist-packages")
checks = []

def has(path, needle, label):
    try:
        checks.append((label, needle in (base / path).read_text()))
    except OSError:
        checks.append((label, False))

has("vllm/platforms/cuda.py",
    "AttentionBackendEnum.FLASHINFER_MLA_SPARSE_SM90", "v1 sm90 backend offered on cap-12")
has("vllm/v1/attention/backends/mla/flashinfer_mla_sparse_sm90.py",
    "capability.major in (9, 12)", "v1 sm90 capability gate")
has("vllm/v1/attention/backends/mla/flashinfer_mla_sparse_sm90.py",
    "else \"fa2\"", "v1 fa2 selected off-Hopper")
has("vllm/platforms/cuda.py", "return major in (9, 10)", "v6 PDL gated off SM12x")
has("vllm/model_executor/layers/sparse_attn_indexer_kpool.py",
    "torch.full(", "v7 indexer topk init to -1")
has("vllm/models/glm5next/nvidia/ops/kpool_compress.py",
    "(pid >= 0) & (pid < pool_len)", "v7 pool-id clamp")
has("flashinfer/data/include/flashinfer/attention/mla.cuh",
    "CTA_TILE_KV < 32u", "v8 fp8 smem tile capped")
has("flashinfer/mla/_core.py", "major not in (9, 12)", "v8 fp8 gate accepts SM12x")
has("vllm/model_executor/layers/sparse_attn_indexer_kpool.py",
    "multi_processor_count >= 78", "v10 persistent_topk gated off small-SM parts")
has("vllm/model_executor/layers/quantization/modelopt.py",
    'prefix.startswith("model.layers.")', "v11 MTP draft quant-prefix mapping")
has("flashinfer/fused_moe/cute_dsl/blackwell_sm12x/moe_activation.py",
    'activation == "silu"', "v12 b12x clamp covers silu")
has("vllm/model_executor/layers/fused_moe/experts/flashinfer_b12x_moe.py",
    "swiglu_limit=self.moe_config.swiglu_limit", "v12 swiglu_limit plumbed to b12x")
has("vllm/model_executor/layers/fused_moe/oracle/nvfp4.py",
    "NvFp4MoeBackend.FLASHINFER_B12X,\n        NvFp4MoeBackend.FLASHINFER_TRTLLM",
    "v12 oracle allows b12x with clamp")
has("flashinfer/fused_moe/cute_dsl/blackwell_sm12x/_moe_dynamic/generic.py",
    "def _collapse_to_vmk", "v13 collapse_to_vmk delegated (generic)")
has("flashinfer/fused_moe/cute_dsl/blackwell_sm12x/_moe_dynamic/gated.py",
    "def _collapse_to_vmk", "v13 collapse_to_vmk delegated (gated)")
has("vllm/model_executor/models/registry.py",
    '"DFlash2DraftModel": ("qwen3_dflash2", "DFlash2Qwen3ForCausalLM")',
    "v14 DFlash2 drafter registered")
has("vllm/v1/core/kv_cache_utils.py",
    "DFLASH2-DRAFTER-GROUP", "v14 GLM5Next KV fast path knows the drafter")
has("vllm/models/glm5next/nvidia/model.py",
    "DFLASH2-AUX-CAPTURE", "v14 GLM5Next aux hidden-state capture")
has("vllm/config/vllm.py", "_is_dflash2_draft", "v14 DFlash2 forces the V2 runner")
checks.append((
    "v14 DFlash2 speculator importable",
    (base / "vllm/v1/worker/gpu/spec_decode/dflash2/speculator.py").is_file()
    and (base / "vllm/model_executor/models/qwen3_dflash2.py").is_file(),
))

import flashinfer
checks.append(("v3 flashinfer 0.6.18", flashinfer.__version__.startswith("0.6.18")))

from importlib.metadata import version
checks.append(("v4 nccl 2.30.7", version("nvidia-nccl-cu13") == "2.30.7"))
checks.append(("v5 cutlass-dsl 4.6.2", version("nvidia-cutlass-dsl") == "4.6.2"))

try:
    __import__("flashinfer_jit_cache")
    checks.append(("v3 stale 0.6.17 AOT cache removed", False))
except ImportError:
    checks.append(("v3 stale 0.6.17 AOT cache removed", True))

bad = 0
for label, ok in checks:
    print("  [%-4s] %s" % ("ok" if ok else "FAIL", label))
    bad += not ok
sys.exit(1 if bad else 0)
PYCHECK
}

if [[ $VERIFY_ONLY == 1 ]]; then
    verify_image "$FINAL_IMAGE"
    exit 0
fi

echo "==> base image: $BASE_IMAGE"
docker pull "$BASE_IMAGE"

prev="$BASE_IMAGE"
for stage in "${STAGES[@]}"; do
    suffix="${stage%%:*}"
    tag="${TAG_PREFIX}:sm121-${stage##*:}"
    echo
    echo "==> building $tag  (FROM $prev)"
    docker build \
        --build-arg "BASE_IMAGE=$prev" \
        -t "$tag" \
        -f "$SCRIPT_DIR/Dockerfile.$suffix" \
        "$SCRIPT_DIR"
    prev="$tag"
done

if [[ $prev != "$FINAL_IMAGE" ]]; then
    # FINAL_IMAGE is meant to be an alias for the last stage. If it names an
    # EARLIER stage instead -- which happens when .env.glm53 still points at the
    # previous image and this script sources it -- the tag below would silently
    # repoint that stage at the final one. Losing the real v13 tag that way cost
    # a confusing five minutes; refuse instead.
    for stage in "${STAGES[@]}"; do
        if [[ $FINAL_IMAGE == "${TAG_PREFIX}:sm121-${stage##*:}" ]]; then
            echo "Refusing to retag: GLM53_VLLM_IMAGE=$FINAL_IMAGE names build stage" \
                 "${stage##*:}, not the final stage (${prev##*:})." >&2
            echo "Update GLM53_VLLM_IMAGE in $ENV_FILE to $prev and re-run." >&2
            exit 1
        fi
    done
    docker tag "$prev" "$FINAL_IMAGE"
fi

verify_image "$FINAL_IMAGE"
echo
echo "==> built and verified: $FINAL_IMAGE"

if [[ $SHIP == 1 ]]; then
    : "${WORKER_HOST:?WORKER_HOST must be set in $ENV_FILE to use --ship}"
    HEAD_ID="$(docker image inspect "$FINAL_IMAGE" --format '{{.Id}}')"
    echo "==> shipping $FINAL_IMAGE to $WORKER_HOST (~23 GB over the fabric)"
    docker save "$FINAL_IMAGE" | ssh "$WORKER_HOST" docker load
    # Tony's operational rule #2: two of his "mystery garbage" boots were a
    # silent image mismatch between ranks. Prove they match rather than assume.
    WORKER_ID="$(ssh "$WORKER_HOST" "docker image inspect '$FINAL_IMAGE' --format '{{.Id}}'")"
    if [[ $HEAD_ID != "$WORKER_ID" ]]; then
        echo "MISMATCH: head $HEAD_ID != worker $WORKER_ID" >&2
        exit 1
    fi
    echo "==> both ranks on $FINAL_IMAGE ($HEAD_ID)"
fi
