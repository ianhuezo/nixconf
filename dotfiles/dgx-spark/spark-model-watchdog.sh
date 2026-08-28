#!/usr/bin/env bash
# Recover the Spark pair when the engine dies. Runs on the head from
# spark-model-watchdog.timer.
#
# vLLM v1 has no engine-restart path, and a Docker restart policy actively makes
# things worse on a multi-node mp deployment: it respawns each rank
# independently, so the survivor sits on a TCPStore rendezvous the new peer can
# never join. Recovery has to tear down BOTH ranks and relaunch in order, which
# is what model-select.sh already does.
#
# Probes /health, NOT /v1/models -- the latter returns 200 with a dead engine,
# so a naive probe reports a corpse as healthy. /health returns 503 on
# EngineDeadError.
set -uo pipefail

RECIPE_DIR="${RECIPE_DIR:-$HOME/dspark-recipe}"
PORT="${PORT:-8888}"
HEALTH_URL="http://127.0.0.1:${PORT}/health"
STATE_FILE="$RECIPE_DIR/.active-model"
LOCK_FILE="$RECIPE_DIR/.switching"
FAIL_FILE="$RECIPE_DIR/.health-fails"
FAIL_THRESHOLD="${FAIL_THRESHOLD:-3}"

say() { echo "[watchdog] $*"; }          # journald captures stdout

# Nothing selected means the pair is deliberately idle. Do not resurrect it --
# that would fight the user and the idle monitor at the same time.
sel="$(cat "$STATE_FILE" 2>/dev/null || true)"
[ -n "$sel" ] || { say "no model selected; standing down"; exit 0; }

# A 16-minute weight load looks exactly like a dead engine from here. The lock
# is what distinguishes "still loading" from "died", and without it the watchdog
# would kill every boot it ever saw.
if [ -e "$LOCK_FILE" ]; then
    # A lock whose writer has died is stale, and honouring it forever means the
    # watchdog never guards anything again -- silently. That happened: a
    # launcher aborted under set -e before its cleanup ran, and the resulting
    # lock muzzled the watchdog indefinitely with a reassuring log line.
    lock_pid="$(cat "$LOCK_FILE" 2>/dev/null || true)"
    if [[ $lock_pid =~ ^[0-9]+$ ]] && kill -0 "$lock_pid" 2>/dev/null; then
        say "switch/load in progress (pid $lock_pid); not probing"
        exit 0
    fi
    say "clearing stale lock (writer ${lock_pid:-unknown} is gone)"
    rm -f "$LOCK_FILE"
fi

if curl -fsS --max-time 10 "$HEALTH_URL" >/dev/null 2>&1; then
    fails=$(cat "$FAIL_FILE" 2>/dev/null || echo 0)
    [ "$fails" != 0 ] && say "healthy again after $fails failure(s)"
    rm -f "$FAIL_FILE"
    exit 0
fi

fails=$(cat "$FAIL_FILE" 2>/dev/null || echo 0)
[[ $fails =~ ^[0-9]+$ ]] || fails=0
fails=$((fails + 1))
echo "$fails" > "$FAIL_FILE"
say "health probe failed ($fails/$FAIL_THRESHOLD)"

if (( fails < FAIL_THRESHOLD )); then
    exit 0
fi

say "=== RECOVERY: $FAIL_THRESHOLD consecutive failures, relaunching $sel ==="
rm -f "$FAIL_FILE"
# model-select.sh handles the whole ritual: stop BOTH ranks, drop caches and
# compact on both, start worker first, wait for the API.
if "$RECIPE_DIR/model-select.sh" "$sel"; then
    say "=== RECOVERY COMPLETE ==="
else
    say "=== RECOVERY FAILED -- will retry on the next tick ==="
    exit 1
fi
