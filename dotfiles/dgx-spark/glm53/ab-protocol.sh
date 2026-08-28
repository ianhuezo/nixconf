#!/usr/bin/env bash
# Identical measurement sequence for an A/B of MAX_NUM_BATCHED_TOKENS.
# Order is fixed on purpose: whatever state one phase leaves behind, the other
# config sees the same state at the same point.
set -uo pipefail
cd ~/dspark-recipe/glm53

echo "=== config ==="
grep -hE '^(MAX_NUM_BATCHED_TOKENS|ENFORCE_EAGER|DFLASH2_NUM_TOKENS)=' .env.glm53
docker logs glm53-vllm-glm53-1 2>&1 | tr -d '\r' \
  | grep -oE 'Actual usage is .*CUDAGraph memory|GPU KV cache size: [0-9,]+ tokens, Maximum concurrency[^x]*x' | head -2

echo
echo "=== phase 1: warm (3x small) ==="
for i in 1 2 3; do
  curl -fsS --max-time 300 http://127.0.0.1:8888/v1/chat/completions \
    -H "Content-Type: application/json" \
    -d '{"model":"glm-5.3-flash","messages":[{"role":"user","content":"Count 1 to 60, one per line."}],"max_tokens":400,"temperature":0}' \
    -o /dev/null -w "  warm %{time_total}s\n"
done

echo
echo "=== phase 2: decode on a CLEAN pool (before any big prefill) ==="
./bench-glm53.py -c 1 --runs 5 2>&1 | sed -n '/conc/,/^$/p'
./bench-glm53.py -c 5 --runs 3 2>&1 | sed -n '/conc/,/^$/p'

echo
echo "=== phase 3: prefill scaling ==="
python3 /tmp/prefill-scaling.py 2>&1 | tail -11

echo
echo "=== phase 4: decode AFTER heavy prefill (the dirty-state control) ==="
./bench-glm53.py -c 1 --runs 5 2>&1 | sed -n '/conc/,/^$/p'
./bench-glm53.py -c 5 --runs 3 2>&1 | sed -n '/conc/,/^$/p'
