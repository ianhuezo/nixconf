#!/usr/bin/env bash
# Install boot-restore + crash-recovery for the selected model. HEAD NODE ONLY.
#
#   sudo ~/dspark-recipe/install-model-service.sh
#   sudo ~/dspark-recipe/install-model-service.sh --uninstall
#
# Replaces what `restart: unless-stopped` was doing badly with two units that
# understand the topology:
#
#   spark-model.service          at boot, replay ~/dspark-recipe/.active-model
#                                through model-select.sh (worker-first, ritual)
#   spark-model-watchdog.timer   every 60s, probe /health; after 3 consecutive
#                                failures tear down BOTH ranks and relaunch
#
# Docker's restart policy cannot do either job: it respawns ranks independently,
# leaving the survivor on a rendezvous the new peer can never join.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
UNITS=(spark-model.service spark-model-watchdog.service spark-model-watchdog.timer)

if [[ ${EUID} -ne 0 ]]; then
    echo "ERROR: run with sudo:  sudo $0" >&2
    exit 1
fi
TARGET_USER="${SUDO_USER:-}"
if [[ -z ${TARGET_USER} || ${TARGET_USER} == root ]]; then
    echo "ERROR: run via sudo from your normal account, not a root login." >&2
    exit 1
fi

if [[ ${1:-} == --uninstall ]]; then
    systemctl disable --now spark-model-watchdog.timer 2>/dev/null || true
    systemctl disable spark-model.service 2>/dev/null || true
    for u in "${UNITS[@]}"; do rm -f "/etc/systemd/system/$u"; done
    systemctl daemon-reload
    echo "==> removed. Containers now have NO automatic recovery."
    exit 0
fi

# Refuse on the worker: this orchestrates both ranks over ssh, and on the worker
# it would try to drive the head as its own worker.
HEAD_FABRIC=169.254.34.131
if ! hostname -I 2>/dev/null | tr ' ' '\n' | grep -qxE "192.168.50.157|${HEAD_FABRIC}"; then
    echo "ERROR: this installs on the HEAD node only; this host is not it." >&2
    exit 1
fi

for u in "${UNITS[@]}"; do
    [[ -f ${SCRIPT_DIR}/$u ]] || { echo "ERROR: ${SCRIPT_DIR}/$u missing" >&2; exit 1; }
done
[[ -x ${SCRIPT_DIR}/spark-model-watchdog.sh ]] || { echo "ERROR: watchdog script missing" >&2; exit 1; }

# The units hardcode User=ian and HOME=/home/ian; if this is ever run by another
# account they would silently drive the wrong home directory.
if [[ ${TARGET_USER} != ian ]]; then
    echo "==> rewriting units for user ${TARGET_USER}"
fi
TARGET_HOME="$(getent passwd "${TARGET_USER}" | cut -d: -f6)"

echo "==> installing units"
for u in "${UNITS[@]}"; do
    sed -e "s|^User=.*|User=${TARGET_USER}|" \
        -e "s|^Group=.*|Group=${TARGET_USER}|" \
        -e "s|^Environment=HOME=.*|Environment=HOME=${TARGET_HOME}|" \
        -e "s|/home/ian|${TARGET_HOME}|g" \
        "${SCRIPT_DIR}/$u" > "/etc/systemd/system/$u"
    chmod 0644 "/etc/systemd/system/$u"
done
systemctl daemon-reload

echo "==> enabling"
# spark-model.service is enabled but NOT started: starting it now would relaunch
# the model that is very likely already running, costing a 16-minute reload for
# nothing. It takes effect at the next boot, which is when it is needed.
systemctl enable spark-model.service >/dev/null
systemctl enable --now spark-model-watchdog.timer >/dev/null

echo
echo "==> installed:"
systemctl is-enabled spark-model.service | sed 's/^/    spark-model.service: /'
systemctl is-active spark-model-watchdog.timer | sed 's/^/    watchdog timer:      /'
systemctl list-timers spark-model-watchdog.timer --no-pager 2>/dev/null | sed -n 2p | sed 's/^/    /'
echo
echo "Selected model is recorded in ${TARGET_HOME}/dspark-recipe/.active-model"
echo "  current: $(cat "${TARGET_HOME}/dspark-recipe/.active-model" 2>/dev/null || echo '(none -- run model-select.sh)')"
echo
echo "IMPORTANT: also drop the Docker restart policy on anything already running:"
echo "  docker update --restart=no \$(docker ps -q)"
echo "  ssh 169.254.54.207 'docker update --restart=no \$(docker ps -q)'"
