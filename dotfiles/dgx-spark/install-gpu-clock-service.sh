#!/usr/bin/env bash
# Install the boot-time 3003 MHz GPU clock lock on one DGX Spark node.
# Run once per node with sudo. Safe to re-run.
set -euo pipefail

UNIT=dgx-spark-gpu-clock.service
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SOURCE="$SCRIPT_DIR/$UNIT"
DEST="/etc/systemd/system/$UNIT"
ACTION="${1:-install}"

if [[ $EUID -ne 0 ]]; then
    echo "ERROR: run with sudo: sudo $0 [$ACTION]" >&2
    exit 1
fi

case "$ACTION" in
    install)
        [[ -f $SOURCE ]] || { echo "Missing $SOURCE" >&2; exit 1; }
        install -o root -g root -m 0644 "$SOURCE" "$DEST"
        systemctl daemon-reload
        systemctl enable "$UNIT"
        # Starting/restarting this unit only changes the clock setting. It does
        # not restart Docker or the running vLLM containers.
        systemctl restart "$UNIT"
        systemctl is-enabled --quiet "$UNIT"
        systemctl is-active --quiet "$UNIT"
        echo "Installed and active: $UNIT"
        nvidia-smi --query-gpu=clocks.max.gr,clocks.gr,pstate,power.draw \
            --format=csv,noheader
        ;;
    uninstall)
        systemctl disable --now "$UNIT" 2>/dev/null || true
        rm -f "$DEST"
        systemctl daemon-reload
        echo "Removed $UNIT and reset the GPU clock policy."
        ;;
    status)
        systemctl --no-pager --full status "$UNIT"
        nvidia-smi --query-gpu=clocks.max.gr,clocks.gr,pstate,power.draw \
            --format=csv,noheader
        ;;
    *)
        echo "Usage: sudo $0 [install|uninstall|status]" >&2
        exit 2
        ;;
esac
