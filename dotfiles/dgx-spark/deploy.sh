#!/usr/bin/env bash
# Push this directory's configs to both GX10 nodes.
# Repo is the source of truth; the nodes hold copies.
set -euo pipefail

DIR="$(cd "$(dirname "$0")" && pwd)"

NODE1=ian@192.168.50.157   # gx10-64b7, head,   CX7 169.254.34.131
NODE2=ian@192.168.50.179   # gx10-08bb, worker, CX7 169.254.54.207

for host in "$NODE1" "$NODE2"; do
    echo "==> $host"
    scp -q "$DIR/setup-fabric.sh" "$DIR/setup-hf-cli.sh" "$host:~/"
    ssh "$host" 'chmod +x ~/setup-fabric.sh ~/setup-hf-cli.sh'

    if ssh "$host" '[ -d ~/dspark-recipe ]'; then
        scp -q "$DIR/env.dspark" "$host:~/dspark-recipe/.env.dspark"
        scp -q "$DIR/patch-runtime.sh" "$DIR/lock-gpu-clock.sh" \
            "$DIR/install-gpu-clock-service.sh" \
            "$DIR/dgx-spark-gpu-clock.service" "$host:~/dspark-recipe/"
        scp -q "$DIR/patches/0006-reasoning-effort-three-levels.patch" \
            "$host:~/dspark-recipe/patches/"
        ssh "$host" 'chmod +x ~/dspark-recipe/patch-runtime.sh ~/dspark-recipe/lock-gpu-clock.sh ~/dspark-recipe/install-gpu-clock-service.sh'
    else
        echo "    (no ~/dspark-recipe yet, skipping .env.dspark)"
    fi
done

# The worker differs from the head only in these two values.
echo "==> rewriting worker node-specific values on $NODE2"
ssh "$NODE2" "sed -i 's/^NODE_RANK=0/NODE_RANK=1/; s/^HEADLESS=\$/HEADLESS=1/' \
    ~/dspark-recipe/.env.dspark 2>/dev/null || true"

echo "==> done"
