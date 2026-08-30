#!/usr/bin/env bash
set -euo pipefail

DIR="$(cd "$(dirname "$0")" && pwd)"

NODE1=ian@192.168.50.157
NODE2=ian@192.168.50.179

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
        # Hourly idle-shutdown. Install once per node with
        # sudo ~/dspark-recipe/install-idle-monitor.sh
        scp -q "$DIR/spark-idle-monitor.sh" "$DIR/spark-idle-monitor.service" \
            "$DIR/spark-idle-monitor.timer" "$DIR/install-idle-monitor.sh" \
            "$host:~/dspark-recipe/"
        # GB10 memory ritual. Install once per node with
        # sudo ~/dspark-recipe/install-drop-caches.sh
        scp -q "$DIR/spark-drop-caches" "$DIR/install-drop-caches.sh" \
            "$host:~/dspark-recipe/"
        ssh "$host" 'chmod +x ~/dspark-recipe/patch-runtime.sh ~/dspark-recipe/lock-gpu-clock.sh ~/dspark-recipe/install-gpu-clock-service.sh ~/dspark-recipe/install-idle-monitor.sh ~/dspark-recipe/spark-idle-monitor.sh ~/dspark-recipe/install-drop-caches.sh'

        # GLM-5.3-Flash lives in its own subdirectory so that `docker compose`
        # derives a distinct project name from it. Two compose files sharing a
        # directory would share the project, and then stopping one model would
        # be indistinguishable from stopping the other.
        ssh "$host" 'mkdir -p ~/dspark-recipe/glm53/patches'
        scp -q "$DIR/glm53/env.glm53" "$host:~/dspark-recipe/glm53/.env.glm53"
        scp -q "$DIR/glm53/docker-compose.glm53.yml" \
            "$DIR/glm53/build-glm53-runtime.sh" \
            "$DIR/glm53/fetch-glm53-weights.sh" \
            "$DIR/glm53/start-glm53.sh" "$DIR/glm53/stop-glm53.sh" \
            "$DIR/glm53/bench-glm53.py" "$DIR/glm53/gate-glm53.py" \
            "$DIR/glm53/moe-compare.py" \
            "$DIR"/glm53/Dockerfile.* "$host:~/dspark-recipe/glm53/"
        scp -q "$DIR"/glm53/patches/*.py "$host:~/dspark-recipe/glm53/patches/"
        # DFlash2 overlay: source files, not just patch scripts, so the v14
        # build context is complete on whichever node builds.
        ssh "$host" 'mkdir -p ~/dspark-recipe/glm53/overlay-dflash2/dflash2'
        scp -q "$DIR"/glm53/overlay-dflash2/*.py "$DIR"/glm53/overlay-dflash2/*.md \
            "$host:~/dspark-recipe/glm53/overlay-dflash2/"
        scp -q "$DIR"/glm53/overlay-dflash2/dflash2/*.py \
            "$host:~/dspark-recipe/glm53/overlay-dflash2/dflash2/"
        ssh "$host" 'chmod +x ~/dspark-recipe/glm53/*.sh'
    else
        echo "    (no ~/dspark-recipe yet, skipping .env.dspark)"
    fi
done

echo "==> rewriting worker node-specific values on $NODE2"
ssh "$NODE2" "sed -i 's/^NODE_RANK=0/NODE_RANK=1/; s/^HEADLESS=\$/HEADLESS=1/' \
    ~/dspark-recipe/.env.dspark ~/dspark-recipe/glm53/.env.glm53 2>/dev/null || true"

# The selector orchestrates both ranks over ssh from the head; on the worker it
# would try to drive the head as its own worker.
echo "==> installing model-select + boot/watchdog units on the head ($NODE1)"
scp -q "$DIR/model-select.sh" "$DIR/spark-model-watchdog.sh" \
    "$DIR/spark-model.service" "$DIR/spark-model-watchdog.service" \
    "$DIR/spark-model-watchdog.timer" "$DIR/install-model-service.sh" \
    "$NODE1:~/dspark-recipe/"
ssh "$NODE1" 'chmod +x ~/dspark-recipe/model-select.sh ~/dspark-recipe/spark-model-watchdog.sh ~/dspark-recipe/install-model-service.sh'

# GLM-5.3-Flash EXL3. Head only, and only these three files: the stack itself
# is upstream's (Entrpi/glm-5.3-flash-exl3-2x-spark, cloned to ~ on the head),
# and its install.sh owns the per-box launcher and ~/.glm53-serve.env on BOTH
# boxes. What is ours is the topology .env it reads, and the two wrappers that
# give model-select.sh a both-ranks start/stop it can call.
echo "==> installing GLM-5.3 EXL3 wrappers + .env on the head ($NODE1)"
ssh "$NODE1" 'mkdir -p ~/dspark-recipe/glm53-exl3'
scp -q "$DIR/glm53-exl3/start-glm53-exl3.sh" "$DIR/glm53-exl3/stop-glm53-exl3.sh" \
    "$NODE1:~/dspark-recipe/glm53-exl3/"
ssh "$NODE1" 'chmod +x ~/dspark-recipe/glm53-exl3/*.sh'
if ssh "$NODE1" '[ -d ~/glm-5.3-flash-exl3-2x-spark ]'; then
    scp -q "$DIR/glm53-exl3/env.exl3" "$NODE1:~/glm-5.3-flash-exl3-2x-spark/.env"
else
    echo "    (no ~/glm-5.3-flash-exl3-2x-spark yet; clone it and re-run to place .env)"
fi

echo "==> done"
