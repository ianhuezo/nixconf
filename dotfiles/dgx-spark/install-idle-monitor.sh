#!/usr/bin/env bash
# Install the hourly idle-shutdown timer on this node. Run on BOTH nodes.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BIN=/usr/local/bin/spark-idle-monitor.sh
UNIT=spark-idle-monitor.service
TIMER=spark-idle-monitor.timer
STATE_DIR=/var/lib/spark-idle
ACTION="${1:-install}"

if [[ $EUID -ne 0 ]]; then
    echo "ERROR: run with sudo: sudo $0 [$ACTION]" >&2
    exit 1
fi

case "$ACTION" in
    install)
        for f in spark-idle-monitor.sh "$UNIT" "$TIMER"; do
            [[ -f "$SCRIPT_DIR/$f" ]] || { echo "Missing $SCRIPT_DIR/$f" >&2; exit 1; }
        done
        install -o root -g root -m 0755 "$SCRIPT_DIR/spark-idle-monitor.sh" "$BIN"
        install -o root -g root -m 0644 "$SCRIPT_DIR/$UNIT"  "/etc/systemd/system/$UNIT"
        install -o root -g root -m 0644 "$SCRIPT_DIR/$TIMER" "/etc/systemd/system/$TIMER"
        mkdir -p "$STATE_DIR"
        systemctl daemon-reload
        systemctl enable --now "$TIMER"
        echo "Installed. Next run:"
        systemctl list-timers --no-pager "$TIMER" | sed -n '1,2p'
        ;;
    uninstall)
        systemctl disable --now "$TIMER" 2>/dev/null || true
        rm -f "/etc/systemd/system/$TIMER" "/etc/systemd/system/$UNIT" "$BIN"
        systemctl daemon-reload
        echo "Removed the idle monitor. Machines will stay powered on."
        ;;
    status)
        systemctl list-timers --no-pager "$TIMER" | sed -n '1,2p' || true
        echo "--- last run ---"
        journalctl -u "$UNIT" -n 20 --no-pager 2>/dev/null || true
        echo "--- state ---"
        echo "last-tokens: $(cat "$STATE_DIR/last-tokens" 2>/dev/null || echo '(none)')"
        [[ -e "$STATE_DIR/inhibit" ]] && echo "INHIBITED (shutdown disabled)" || echo "inhibit: off"
        ;;
    dry-run)
        # Full decision path, no poweroff and no state write.
        echo "--- what the monitor would decide right now ---"
        DRY_RUN=1 "$SCRIPT_DIR/spark-idle-monitor.sh"
        ;;
    inhibit)   mkdir -p "$STATE_DIR"; touch "$STATE_DIR/inhibit"; echo "Idle shutdown disabled until you run: sudo $0 allow" ;;
    allow)     rm -f "$STATE_DIR/inhibit"; echo "Idle shutdown re-enabled." ;;
    *)
        echo "Usage: sudo $0 [install|uninstall|status|dry-run|inhibit|allow]" >&2
        exit 2
        ;;
esac
