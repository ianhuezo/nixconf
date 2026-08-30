#!/usr/bin/env bash
# Choose which model the Spark pair serves. Runs on node1 (the head).
#
#   model-select.sh                 # interactive menu
#   model-select.sh deepseek        # switch to DeepSeek V4 Flash
#   model-select.sh glm53exl3       # switch to GLM-5.3-Flash EXL3 (current)
#   model-select.sh glm53           # switch to GLM-5.3-Flash NVFP4 (superseded)
#   model-select.sh status          # what is up right now
#   model-select.sh stop            # stop everything, serve nothing
#   model-select.sh boot            # start whatever was last selected (systemd)
#
# Only one model is ever resident: each needs ~92-100 GiB per rank out of 121
# GiB of unified memory, so switching is always stop-then-start, never both.
#
# SELECTION IS AN EXPLICIT FILE, not a Docker restart policy. The earlier design
# leaned on `restart: unless-stopped` to bring the selected model back after the
# idle monitor's poweroff, and that was wrong twice over: it made "which model
# is selected" implicit in container state, and -- worse -- Docker cannot
# recover a multi-node mp deployment. It respawns each rank independently, so a
# head failure leaves the worker on a rendezvous it can never complete. Now the
# containers run restart:"no" and spark-model.service replays this file at boot.
set -euo pipefail

RECIPE_DIR="${RECIPE_DIR:-$HOME/dspark-recipe}"
PORT="${PORT:-8888}"
API_URL="http://127.0.0.1:${PORT}/v1/models"
STATE_FILE="${STATE_FILE:-$RECIPE_DIR/.active-model}"
# Suppresses the watchdog while a switch or a 16-minute weight load is in
# flight; without it the watchdog would "recover" a perfectly healthy boot.
LOCK_FILE="${LOCK_FILE:-$RECIPE_DIR/.switching}"
WORKER_WAIT="${WORKER_WAIT:-300}"

# name|label|selector|start script|stop script|served model name
#
# The selector says how to FIND a model's containers, because they are not all
# launched the same way. DeepSeek and the NVFP4 GLM come up through `docker
# compose`, so they carry a project label; the EXL3 GLM comes up through
# upstream's plain `docker run`, which carries no label at all -- only a fixed
# container name. Tagging the row rather than special-casing the lookup keeps
# upstream's launcher unpatched, which matters because install.sh reinstalls it
# from the repo on every run and would clobber any edit.
MODELS=(
  "deepseek|DeepSeek V4 Flash 0731|compose:dspark-recipe|$RECIPE_DIR/start-deepseek-v4-flash-dspark.sh|$RECIPE_DIR/stop-deepseek-v4-flash-dspark.sh|deepseek-v4-flash-dspark"
  "glm53|GLM-5.3-Flash NVFP4|compose:glm53|$RECIPE_DIR/glm53/start-glm53.sh|$RECIPE_DIR/glm53/stop-glm53.sh|glm-5.3-flash"
  "glm53exl3|GLM-5.3-Flash EXL3 4bpw + DFlash2|name:vllm_glm53|$RECIPE_DIR/glm53-exl3/start-glm53-exl3.sh|$RECIPE_DIR/glm53-exl3/stop-glm53-exl3.sh|glm-5.3-flash"
)

field() {
  local name="$1" idx="$2" row
  for row in "${MODELS[@]}"; do
    [ "${row%%|*}" = "$name" ] || continue
    printf '%s\n' "$row" | cut -d'|' -f"$idx"
    return 0
  done
  return 1
}

names()    { local row; for row in "${MODELS[@]}"; do printf '%s\n' "${row%%|*}"; done; }
label()    { field "$1" 2; }
selector() { field "$1" 3; }
starter()  { field "$1" 4; }
stopper()  { field "$1" 5; }
served()   { field "$1" 6; }

# Turn a table selector into a `docker ps --filter` expression. Bare values are
# read as compose projects so an un-migrated selector still behaves.
# name= is a regex match, hence the anchors: without them `name=vllm_glm53`
# would also match a stray `vllm_glm53_old`.
filter_of() {
  case "$1" in
    name:*)    printf 'name=^%s$' "${1#name:}" ;;
    compose:*) printf 'label=com.docker.compose.project=%s' "${1#compose:}" ;;
    *)         printf 'label=com.docker.compose.project=%s' "$1" ;;
  esac
}

containers_of() {
  docker ps -aq --filter "$(filter_of "$1")" 2>/dev/null
}

selected_model() { [ -f "$STATE_FILE" ] && cat "$STATE_FILE" || true; }

# What is physically up, which can differ from what is selected (e.g. mid-boot,
# or after a crash). Both are reported by `status` on purpose.
running_model() {
  local name
  for name in $(names); do
    if [ -n "$(containers_of "$(selector "$name")")" ]; then
      printf '%s\n' "$name"; return 0
    fi
  done
  return 1
}

serving_name() {
  curl -fsS --max-time 3 "$API_URL" 2>/dev/null \
    | grep -o '"id":"[^"]*"' | head -1 | cut -d'"' -f4
}

# /v1/models answers 200 even when the engine behind it is dead, so a name
# coming back is not evidence the thing can serve. /health is the liveness probe.
engine_healthy() {
  curl -fsS --max-time 3 "http://127.0.0.1:${PORT}/health" >/dev/null 2>&1
}

# Normalise the restart policy on whatever is actually running. The DeepSeek
# compose file is vendored from upstream and still says unless-stopped; rather
# than fork it, neutralise the policy after the fact on both ranks.
disarm_restart() {
  local sel="$1" ids filter
  filter="$(filter_of "$sel")"
  ids="$(containers_of "$sel")"
  [ -n "$ids" ] && docker update --restart=no $ids >/dev/null 2>&1 || true
  ssh "${WORKER_SSH:-169.254.54.207}" \
    "ids=\$(docker ps -aq --filter '$filter' 2>/dev/null); \
     [ -n \"\$ids\" ] && docker update --restart=no \$ids >/dev/null 2>&1 || true" 2>/dev/null || true
}

status() {
  local sel run up
  sel="$(selected_model)"; run="$(running_model || true)"
  echo "Spark pair -- ${RECIPE_DIR}"
  echo
  local name mark
  for name in $(names); do
    mark="  "; [ "$name" = "${sel:-}" ] && mark="=>"
    printf '%s %-10s %s\n' "$mark" "$name" "$(label "$name")"
  done
  echo
  echo "selected : ${sel:-none}${sel:+ ($(label "$sel"))}"
  if [ -z "${run:-}" ]; then
    echo "running  : nothing"
  else
    printf 'running  : %s -- ' "$run"
    docker ps -a --filter "$(filter_of "$(selector "$run")")" \
      --format '{{.Names}} [{{.Status}}]' | paste -sd', ' -
  fi
  [ -e "$LOCK_FILE" ] && echo "         (a switch/load is in progress)"
  up="$(serving_name || true)"
  if [ -n "$up" ]; then
    if engine_healthy; then
      echo "endpoint : http://127.0.0.1:${PORT}/v1  serving '$up'  [healthy]"
    else
      echo "endpoint : answering as '$up' but /health FAILS -- engine is dead"
    fi
  else
    echo "endpoint : not answering on :${PORT} (down, or still loading)"
  fi
}

stop_all() {
  local name script
  for name in $(names); do
    [ -n "$(containers_of "$(selector "$name")")" ] || continue
    script="$(stopper "$name")"
    echo "==> stopping $name"
    if [ -x "$script" ]; then
      "$script"
    else
      echo "    $script missing; falling back to a direct container stop" >&2
      # Word splitting is the point: containers_of returns one id per line.
      # shellcheck disable=SC2046
      docker rm -f $(containers_of "$(selector "$name")") >/dev/null 2>&1 || true
    fi
  done
}

wait_for_worker() {
  local waited=0
  until ssh -o ConnectTimeout=5 -o BatchMode=yes "${WORKER_SSH:-169.254.54.207}" true 2>/dev/null; do
    (( waited >= WORKER_WAIT )) && { echo "worker unreachable after ${WORKER_WAIT}s" >&2; return 1; }
    sleep 10; waited=$((waited + 10))
  done
}

launch() {
  local target="$1" script
  script="$(starter "$target")"
  if [ ! -x "$script" ]; then
    echo "cannot start $target: $script is missing or not executable" >&2
    echo "deploy it with dotfiles/dgx-spark/deploy.sh from the workstation" >&2
    return 1
  fi
  # Write our PID, not an empty file: the watchdog treats a non-numeric lock as
  # stale and clears it, so an empty placeholder here opens a race where the
  # watchdog could act between this line and start-glm53.sh claiming the lock.
  mkdir -p "$(dirname "$LOCK_FILE")"; echo $$ > "$LOCK_FILE"
  # The lock must come off even if the launcher dies, or the watchdog stays
  # muzzled forever and a real crash goes unrecovered.
  trap 'rm -f "$LOCK_FILE"' RETURN
  echo "==> starting $target ($(label "$target"))"
  "$script"
  disarm_restart "$(selector "$target")"
}

switch_to() {
  local target="$1"
  if ! names | grep -qx "$target"; then
    echo "unknown model: $target (choose from: $(names | paste -sd' ' -))" >&2
    exit 2
  fi
  # Check the launcher exists BEFORE tearing anything down, so a typo or a
  # missing deploy cannot leave the pair serving nothing.
  [ -x "$(starter "$target")" ] || { launch "$target"; return $?; }

  # Skip the no-op restart only when NOT forced. A config-only change (say
  # MTP_NUM_TOKENS) leaves the same model "selected and serving" while the
  # running engine still has the old settings, so `restart` has to exist --
  # otherwise the only way to apply it is a manual stop/start pair.
  if [ "${FORCE_RESTART:-0}" != 1 ] \
     && [ "$(running_model || true)" = "$target" ] \
     && [ "$(serving_name || true)" = "$(served "$target")" ] && engine_healthy; then
    echo "$target is already selected and serving. Nothing to do."
    echo "(config changed? use: $0 restart)"
    printf '%s\n' "$target" > "$STATE_FILE"
    return 0
  fi

  stop_all
  printf '%s\n' "$target" > "$STATE_FILE"
  launch "$target"
  echo
  status
}

case "${1:-menu}" in
  status) status ;;
  restart)
    sel="$(selected_model)"
    [ -n "$sel" ] || { echo "nothing selected" >&2; exit 2; }
    echo "==> restarting $sel to pick up config changes"
    FORCE_RESTART=1 switch_to "$sel"
    ;;
  stop)   stop_all; rm -f "$STATE_FILE"; echo; status ;;
  boot)
    # Invoked by spark-model.service after a poweroff/reboot. No selection
    # means the user deliberately stopped everything; do not resurrect it.
    sel="$(selected_model)"
    [ -n "$sel" ] || { echo "no model selected; nothing to start"; exit 0; }
    echo "==> boot: restoring $sel"
    wait_for_worker || exit 1
    stop_all           # clear anything half-alive from the previous power cycle
    launch "$sel"
    ;;
  menu)
    status; echo; echo "Select a model:"
    i=0; opts=()
    for name in $(names); do
      i=$((i + 1)); opts+=("$name")
      printf '  %d) %-10s %s\n' "$i" "$name" "$(label "$name")"
    done
    printf '  %d) %-10s %s\n' "$((i + 1))" "stop" "stop everything"
    printf '  q) quit\n\n'
    read -rp "choice: " choice
    case "$choice" in
      q|Q|"") echo "no change" ;;
      $((i + 1))) stop_all; rm -f "$STATE_FILE"; echo; status ;;
      *)
        if [ "$choice" -ge 1 ] 2>/dev/null && [ "$choice" -le "$i" ]; then
          switch_to "${opts[$((choice - 1))]}"
        else
          echo "invalid choice" >&2; exit 2
        fi
        ;;
    esac
    ;;
  *) switch_to "$1" ;;
esac
