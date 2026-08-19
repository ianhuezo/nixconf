#!/usr/bin/env bash
set -euo pipefail

if [[ ${EUID} -eq 0 ]]; then
    TARGET_USER="${SUDO_USER:-}"
    if [[ -z ${TARGET_USER} || ${TARGET_USER} == "root" ]]; then
        echo "ERROR: run this via 'sudo ./setup-hf-cli.sh' from your normal" >&2
        echo "       account, not as a root login. Installing the HF CLI and" >&2
        echo "       token into /root is not what you want." >&2
        exit 1
    fi
    SUDO=()
    AS_USER=(sudo -u "${TARGET_USER}" -H)
else
    TARGET_USER="${USER}"
    SUDO=(sudo)
    AS_USER=()
fi

echo "==> Installing HuggingFace CLI for user: ${TARGET_USER}"

if command -v pipx >/dev/null 2>&1; then
    echo "==> pipx already present, skipping apt"
else
    echo "==> Installing pipx"
    "${SUDO[@]}" apt-get update -qq
    "${SUDO[@]}" apt-get install -y pipx
fi

echo "==> Installing huggingface_hub[cli]"
if "${AS_USER[@]}" pipx list 2>/dev/null | grep -q huggingface-hub; then
    "${AS_USER[@]}" pipx upgrade huggingface_hub
else
    "${AS_USER[@]}" pipx install "huggingface_hub[cli]"
fi

"${AS_USER[@]}" pipx ensurepath >/dev/null 2>&1 || true

TARGET_HOME="$(getent passwd "${TARGET_USER}" | cut -d: -f6)"
HF_BIN="${TARGET_HOME}/.local/bin/hf"

echo
if [[ -x ${HF_BIN} ]]; then
    echo "==> Installed: $("${AS_USER[@]}" "${HF_BIN}" version 2>/dev/null || echo "${HF_BIN}")"
    echo
    echo "Next, as ${TARGET_USER} (NOT with sudo):"
    echo
    echo "    exec \$SHELL -l"
    echo "    hf auth login"
    echo
    echo "The token is written to ~/.cache/huggingface/token with 600 perms."
    echo "Bind-mounting ~/.cache/huggingface into the vLLM container carries"
    echo "both the token and the downloaded weights in one go."
else
    echo "ERROR: expected ${HF_BIN} but it is missing." >&2
    exit 1
fi
