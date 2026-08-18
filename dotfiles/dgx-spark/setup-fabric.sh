#!/usr/bin/env bash
#
# Prepare a GX10 node for the dual-Spark DSpark stack:
#   1. MTU 9000 on the CX7 RoCE link (recipes require jumbo frames)
#   2. Add the invoking user to the docker group
#
# Run with:  sudo ./setup-fabric.sh
# Safe to re-run.

set -euo pipefail

NETPLAN_FILE=/etc/netplan/40-cx7.yaml
IFACE=enp1s0f1np1

if [[ ${EUID} -ne 0 ]]; then
    echo "ERROR: run this with sudo:  sudo ./setup-fabric.sh" >&2
    exit 1
fi

TARGET_USER="${SUDO_USER:-}"
if [[ -z ${TARGET_USER} || ${TARGET_USER} == "root" ]]; then
    echo "ERROR: run via sudo from your normal account, not a root login." >&2
    exit 1
fi

# ---------------------------------------------------------------------------
# 1. MTU 9000 on the CX7 ports
#
# Jumbo frames must match on BOTH ends or the link silently blackholes large
# frames, so this script has to run on both nodes before either is useful.
# ---------------------------------------------------------------------------
echo "==> Backing up ${NETPLAN_FILE}"
cp -n "${NETPLAN_FILE}" "${NETPLAN_FILE}.bak.$(date +%Y%m%d%H%M%S)" 2>/dev/null || true

echo "==> Writing ${NETPLAN_FILE} with mtu: 9000"
cat > "${NETPLAN_FILE}" <<'YAML'
network:
  version: 2
  ethernets:
    enp1s0f0np0:
      link-local: [ ipv4 ]
      mtu: 9000
    enp1s0f1np1:
      link-local: [ ipv4 ]
      mtu: 9000
YAML

chmod 600 "${NETPLAN_FILE}"
chown root:root "${NETPLAN_FILE}"

echo "==> Applying netplan (your wifi SSH session is unaffected)"
netplan apply

sleep 3
ACTUAL_MTU=$(cat "/sys/class/net/${IFACE}/mtu")
echo "==> ${IFACE} MTU is now: ${ACTUAL_MTU}"
if [[ ${ACTUAL_MTU} -ne 9000 ]]; then
    echo "WARNING: expected 9000. Check 'sudo netplan status' before launching." >&2
fi

# ---------------------------------------------------------------------------
# 2. docker group
#
# The recipe runs many docker commands; needing sudo for each breaks the
# launcher scripts, which call docker directly.
# ---------------------------------------------------------------------------
if id -nG "${TARGET_USER}" | tr ' ' '\n' | grep -qx docker; then
    echo "==> ${TARGET_USER} already in docker group"
else
    echo "==> Adding ${TARGET_USER} to docker group"
    usermod -aG docker "${TARGET_USER}"
    echo "    NOTE: log out and back in (or run 'newgrp docker') for this to apply."
fi

echo
echo "==> Done. Verify from a NEW shell:"
echo "      ip -br link show ${IFACE}    # should show mtu 9000"
echo "      docker ps                    # should work without sudo"
