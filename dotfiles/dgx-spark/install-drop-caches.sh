#!/usr/bin/env bash
# Install the GB10 memory ritual so the launcher can run it without a password.
#
#   sudo ~/dspark-recipe/install-drop-caches.sh
#
# Why this exists: start-glm53.sh drops caches before launching, because on GB10
# the KV cache is carved from genuinely free system pages and the NVIDIA driver
# fails rather than reclaiming. Without it, a launch can die needing ~0.7 GiB
# more than is free -- which is exactly how the first GLM boot on this pair died.
#
# The privilege granted is deliberately narrow: a fixed, root-owned script that
# takes no arguments. A NOPASSWD rule on `sh -c` would have been simpler to
# write and equivalent to handing out unrestricted root.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SRC="${SCRIPT_DIR}/spark-drop-caches"
DEST=/usr/local/sbin/spark-drop-caches
SUDOERS=/etc/sudoers.d/spark-drop-caches

if [[ ${EUID} -ne 0 ]]; then
    echo "ERROR: run with sudo:  sudo $0" >&2
    exit 1
fi

TARGET_USER="${SUDO_USER:-}"
if [[ -z ${TARGET_USER} || ${TARGET_USER} == root ]]; then
    echo "ERROR: run via sudo from your normal account, not a root login." >&2
    exit 1
fi

[[ -f ${SRC} ]] || { echo "ERROR: ${SRC} not found" >&2; exit 1; }

echo "==> installing ${DEST}"
install -o root -g root -m 0755 "${SRC}" "${DEST}"

echo "==> granting ${TARGET_USER} NOPASSWD on ${DEST} only"
# Write to a temp file and validate BEFORE moving into sudoers.d: a malformed
# file there can lock everyone out of sudo entirely.
TMP="$(mktemp)"
trap 'rm -f "$TMP"' EXIT
printf '%s ALL=(root) NOPASSWD: %s\n' "${TARGET_USER}" "${DEST}" > "$TMP"
chmod 0440 "$TMP"
if ! visudo -c -f "$TMP" >/dev/null; then
    echo "ERROR: generated sudoers snippet is invalid; not installing" >&2
    exit 1
fi
install -o root -g root -m 0440 "$TMP" "${SUDOERS}"

echo "==> verifying"
if sudo -n -u "${TARGET_USER}" true 2>/dev/null || true; then :; fi
if runuser -u "${TARGET_USER}" -- sudo -n "${DEST}"; then
    echo "==> OK: ${TARGET_USER} can run the ritual without a password"
    echo "    MemFree now: $(awk '/^MemFree:/{printf "%.1f GiB", $2/1048576}' /proc/meminfo)"
else
    echo "ERROR: verification failed -- the launcher will still warn and continue" >&2
    exit 1
fi
