#!/usr/bin/env bash
set -euo pipefail

RECIPE_DIR="${RECIPE_DIR:-$(cd "$(dirname "$0")" && pwd)}"
ENV_FILE="${ENV_FILE:-$RECIPE_DIR/.env.dspark}"

if [[ -f $ENV_FILE ]]; then
    set -a
    source "$ENV_FILE"
    set +a
fi

IMAGE="${DSPARK_VLLM_IMAGE:-vllm-dspark-runtime:dspark-nvfp4-stage-c}"
PATCH5_FILE="$RECIPE_DIR/patches/0005-suppress-stops-in-reasoning.patch"
PATCH6_FILE="$RECIPE_DIR/patches/0006-reasoning-effort-three-levels.patch"
SITE_PACKAGES=/opt/env/lib/python3.12/site-packages
TMP_IMAGE="${IMAGE}-local-patches-build"
TMP_DIR=$(mktemp -d)
CID=

cleanup() {
    [[ -z $CID ]] || docker rm -f "$CID" >/dev/null 2>&1 || true
    rm -rf "$TMP_DIR"
}
trap cleanup EXIT

verify_image() {
    docker run --rm --entrypoint /opt/env/bin/python "$1" -c '
from hashlib import sha256
from pathlib import Path
root = Path("/opt/env/lib/python3.12/site-packages/vllm")
dspark = root / "v1/spec_decode/dspark.py"
detok = root / "v1/engine/detokenizer.py"
tokenizer = root / "tokenizers/deepseek_v4.py"
encoding = root / "tokenizers/deepseek_v4_encoding.py"
assert "shared_experts.gate_up_proj" in dspark.read_text(), "Patch 4 missing"
assert "_reasoning_stop_guard" in detok.read_text(), "Patch 5 missing"
assert sha256(tokenizer.read_bytes()).hexdigest() == "4469bce68c0d85ca1b283ef05a9cba662888af21ac3cd4e5764e800cfd579500"
assert sha256(encoding.read_bytes()).hexdigest() == "19e895a82ba3b1da9a23cef5ae579562aee9245d050500a14591a9ebaa7a0cc4"
print("verified: Patch 4 + Patch 5 + PR #24 reasoning effort")
'
}

for file in "$PATCH5_FILE" "$PATCH6_FILE"; do
    [[ -f $file ]] || { echo "Missing $file" >&2; exit 1; }
done
docker image inspect "$IMAGE" >/dev/null

mkdir -p "$TMP_DIR/vllm/v1/engine" "$TMP_DIR/vllm/tokenizers"
CID=$(docker create "$IMAGE")
docker cp "$CID:$SITE_PACKAGES/vllm/v1/engine/detokenizer.py" \
    "$TMP_DIR/vllm/v1/engine/detokenizer.py"
docker cp "$CID:$SITE_PACKAGES/vllm/tokenizers/deepseek_v4.py" \
    "$TMP_DIR/vllm/tokenizers/deepseek_v4.py"
docker cp "$CID:$SITE_PACKAGES/vllm/tokenizers/deepseek_v4_encoding.py" \
    "$TMP_DIR/vllm/tokenizers/deepseek_v4_encoding.py"
docker rm "$CID" >/dev/null
CID=

if grep -q '_reasoning_stop_guard' "$TMP_DIR/vllm/v1/engine/detokenizer.py" \
    && grep -q 'REASONING_EFFORT_PROMPTS' "$TMP_DIR/vllm/tokenizers/deepseek_v4_encoding.py"; then
    echo "All local runtime patches are already present in $IMAGE"
    verify_image "$IMAGE"
    exit 0
fi

if ! grep -q '_reasoning_stop_guard' "$TMP_DIR/vllm/v1/engine/detokenizer.py"; then
    patch --batch --forward -d "$TMP_DIR" -p1 < "$PATCH5_FILE"
fi
if ! grep -q 'REASONING_EFFORT_PROMPTS' "$TMP_DIR/vllm/tokenizers/deepseek_v4_encoding.py"; then
    patch --batch --forward -d "$TMP_DIR" -p1 < "$PATCH6_FILE"
fi

printf '%s  %s\n' \
    4469bce68c0d85ca1b283ef05a9cba662888af21ac3cd4e5764e800cfd579500 \
    "$TMP_DIR/vllm/tokenizers/deepseek_v4.py" \
    19e895a82ba3b1da9a23cef5ae579562aee9245d050500a14591a9ebaa7a0cc4 \
    "$TMP_DIR/vllm/tokenizers/deepseek_v4_encoding.py" \
    | sha256sum --check --status

cat > "$TMP_DIR/Dockerfile" <<'EOF'
ARG BASE_IMAGE=vllm-dspark-runtime:dspark-nvfp4-stage-c
FROM ${BASE_IMAGE}
LABEL org.local.dspark.patch5="suppress-stops-in-reasoning" \
      org.local.dspark.patch6="reasoning-effort-pr24-8bceae3"
COPY vllm/v1/engine/detokenizer.py /opt/env/lib/python3.12/site-packages/vllm/v1/engine/detokenizer.py
COPY vllm/tokenizers/deepseek_v4.py /opt/env/lib/python3.12/site-packages/vllm/tokenizers/deepseek_v4.py
COPY vllm/tokenizers/deepseek_v4_encoding.py /opt/env/lib/python3.12/site-packages/vllm/tokenizers/deepseek_v4_encoding.py
RUN /opt/env/bin/python -m py_compile \
    /opt/env/lib/python3.12/site-packages/vllm/v1/engine/detokenizer.py \
    /opt/env/lib/python3.12/site-packages/vllm/tokenizers/deepseek_v4.py \
    /opt/env/lib/python3.12/site-packages/vllm/tokenizers/deepseek_v4_encoding.py
EOF

docker build --build-arg "BASE_IMAGE=$IMAGE" -t "$TMP_IMAGE" -f "$TMP_DIR/Dockerfile" "$TMP_DIR"
verify_image "$TMP_IMAGE"

docker tag "$TMP_IMAGE" "$IMAGE"
docker image rm "$TMP_IMAGE" >/dev/null

echo "Patched runtime ready: $IMAGE"
