#!/usr/bin/env bash
# Get the GLM-5.3-Flash NVFP4 weights onto BOTH nodes: download once on the
# head, then mirror to the worker across the RoCE fabric.
#
# Both nodes need their own local copy -- NFS is not an option here. NFS client
# memory resists kernel reclaim harder than local page cache, and on GB10,
# where every GPU allocation comes out of host DRAM, the NFS-mounted rank is
# reliably the one that dies when the KV slab is carved.
#
# But that is an argument for two copies, not for two downloads. The fabric
# link is 200 Gb/s; the internet is not. Pulling ~186 GiB twice from HuggingFace
# costs twice the WAN bytes and, because the two downloads compete for the same
# uplink, more than twice the wall clock. Downloading once and copying over the
# wire is bounded by NVMe and ssh crypto instead -- minutes, not hours.
#
#   ./fetch-glm53-weights.sh            # download, then mirror. Detached.
#   ./fetch-glm53-weights.sh --watch    # same, then follow the log
#   ./fetch-glm53-weights.sh download   # head download only
#   ./fetch-glm53-weights.sh mirror     # fabric copy only (download must be done)
#   ./fetch-glm53-weights.sh verify     # compare both sides
#   ./fetch-glm53-weights.sh --status   # where things stand
#   ./fetch-glm53-weights.sh draft      # DFlash2 drafter, both nodes (2.3 GiB)
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ENV_FILE="${ENV_FILE:-$SCRIPT_DIR/.env.glm53}"

if [ -f "$ENV_FILE" ]; then
  set -a
  # shellcheck disable=SC1090
  source "$ENV_FILE"
  set +a
fi

: "${WORKER_HOST:?WORKER_HOST must be set in $ENV_FILE}"
MODEL="${GLM53_MODEL:-local-inference-lab/GLM-5.3-Flash-NVFP4}"
CACHE="${HF_CACHE:-$HOME/.cache/huggingface}"
REPO_LEAF="models--${MODEL//\//--}"
REPO_DIR="$CACHE/hub/$REPO_LEAF"
LOG="${GLM53_FETCH_LOG:-$HOME/glm53-fetch.log}"
NEEDED_GIB=190

# `hf` lands in ~/.local/bin via pipx, which a non-interactive ssh shell lacks.
export PATH="$HOME/.local/bin:$PATH"
export HF_HUB_DISABLE_XET="${HF_HUB_DISABLE_XET:-1}"

worker_home() { ssh "$WORKER_HOST" 'echo $HOME'; }

check_disk() {
  local label="$1" avail
  if [ "$label" = head ]; then
    avail=$(df -BG --output=avail "$HOME" | tail -1 | tr -dc 0-9)
  else
    avail=$(ssh "$WORKER_HOST" 'df -BG --output=avail "$HOME" | tail -1' | tr -dc 0-9)
  fi
  if [ -z "$avail" ] || [ "$avail" -lt "$NEEDED_GIB" ]; then
    echo "ERROR: $label needs ${NEEDED_GIB}G free, has ${avail:-unknown}G" >&2
    return 1
  fi
  echo "  $label disk: ${avail}G free"
}

do_download() {
  echo "==> downloading $MODEL on the head (~186 GiB)"
  check_disk head
  # hf download is resumable and skips blobs it already has, so re-running
  # after an interrupted transfer is the intended recovery path.
  hf download "$MODEL"
  echo "==> download complete"
}

do_mirror() {
  echo "==> mirroring to $WORKER_HOST over the fabric"
  [ -d "$REPO_DIR" ] || { echo "ERROR: $REPO_DIR not present; download first" >&2; return 1; }
  check_disk worker

  local whome dest
  whome="$(worker_home)"
  dest="$whome/.cache/huggingface/hub"
  ssh "$WORKER_HOST" "mkdir -p '$dest'"

  # -a keeps the snapshots/ symlinks AS symlinks. They point at
  # ../../blobs/<sha> -- relative, and the whole tree moves together, so they
  # resolve on the far side. Copying them dereferenced would double the bytes
  # and break the layout hf expects.
  # -W skips the delta algorithm (pointless on a fresh copy over a fast link)
  # and --no-compress skips CPU work on already-compressed weights, so the
  # transfer is bounded by NVMe and the ssh cipher rather than by rsync.
  # .no_exist is a negative-cache marker, sometimes root-owned; not worth
  # failing a 200 GB transfer over.
  rsync -aHW --partial --no-compress --exclude='.no_exist' \
    --info=progress2 \
    -e 'ssh -o Compression=no -c aes128-gcm@openssh.com' \
    "$REPO_DIR/" "$WORKER_HOST:$dest/$REPO_LEAF/"

  echo "==> mirror complete"
  do_verify
}

do_verify() {
  echo "==> verifying both copies"
  local whome dest hb hs wb ws broken
  whome="$(worker_home)"
  dest="$whome/.cache/huggingface/hub/$REPO_LEAF"

  hb=$(find "$REPO_DIR/blobs" -type f | wc -l)
  hs=$(du -sb "$REPO_DIR" | cut -f1)
  wb=$(ssh "$WORKER_HOST" "find '$dest/blobs' -type f | wc -l")
  ws=$(ssh "$WORKER_HOST" "du -sb '$dest' | cut -f1")

  printf '  head  : %s blobs, %s bytes\n' "$hb" "$hs"
  printf '  worker: %s blobs, %s bytes\n' "$wb" "$ws"

  # A symlink that survived the copy but points at a blob that did not is the
  # failure mode that matters here, and it is silent until vLLM tries to load.
  broken=$(ssh "$WORKER_HOST" "find -L '$dest/snapshots' -type l 2>/dev/null | wc -l")
  if [ "$broken" != 0 ]; then
    echo "  FAIL: $broken broken symlinks on the worker" >&2
    return 1
  fi
  if [ "$hb" != "$wb" ] || [ "$hs" != "$ws" ]; then
    echo "  FAIL: copies differ; re-run '$0 mirror' (rsync will fill the gaps)" >&2
    return 1
  fi
  echo "  ok: identical, no broken symlinks"
}

# The DFlash2 drafter is 2.34 GiB, not 186. The single-download-then-mirror
# argument above is about WAN bytes and uplink contention at 186 GiB scale; at
# 2.3 GiB it does not apply, and two direct pulls avoid needing the rsync
# symlink dance twice.
do_draft() {
  local draft="${DFLASH2_MODEL:-incoai/GLM-5.3-Flash-DFlash2}"
  echo "==> fetching drafter $draft on both nodes (~2.3 GiB each)"
  hf download "$draft" &
  local head_pid=$!
  ssh "$WORKER_HOST" "PATH=\$HOME/.local/bin:\$PATH HF_HUB_DISABLE_XET=1 hf download '$draft'" &
  local worker_pid=$!
  wait "$head_pid" || { echo "ERROR: head download failed" >&2; return 1; }
  wait "$worker_pid" || { echo "ERROR: worker download failed" >&2; return 1; }

  # A drafter present on only one rank is a rank-1 crash ~15 minutes into a
  # boot, with the head reporting nothing useful. Prove both sides resolve.
  local leaf="models--${draft//\//--}"
  local ok=1
  for where in head worker; do
    local n
    if [ "$where" = head ]; then
      n=$(find -L "$CACHE/hub/$leaf/snapshots" -name '*.safetensors' 2>/dev/null | wc -l)
    else
      n=$(ssh "$WORKER_HOST" "find -L \"\$HOME/.cache/huggingface/hub/$leaf/snapshots\" -name '*.safetensors' 2>/dev/null | wc -l")
    fi
    printf '  %-6s: %s resolved safetensors\n' "$where" "$n"
    [ "${n:-0}" -ge 1 ] || ok=0
  done
  [ "$ok" = 1 ] || { echo "  FAIL: drafter missing on a rank" >&2; return 1; }
  echo "  ok: drafter present on both ranks"
}

do_status() {
  local whome dest
  whome="$(worker_home)"
  dest="$whome/.cache/huggingface/hub/$REPO_LEAF"
  if pgrep -f "hf download $MODEL" >/dev/null; then
    echo "  phase : downloading on head"
  elif pgrep -f "rsync.*$REPO_LEAF" >/dev/null; then
    echo "  phase : mirroring to worker"
  else
    echo "  phase : idle"
  fi
  printf '  head  : %s\n' "$(du -sh "$REPO_DIR" 2>/dev/null | cut -f1 || echo 'nothing yet')"
  printf '  worker: %s\n' "$(ssh "$WORKER_HOST" "du -sh '$dest' 2>/dev/null | cut -f1" || echo 'nothing yet')"
  echo "  log   : $LOG"
}

case "${1:-all}" in
  download) do_download ;;
  mirror)   do_mirror ;;
  verify)   do_verify ;;
  draft)    do_draft ;;
  --status) do_status ;;
  all|--watch)
    if pgrep -f "hf download $MODEL" >/dev/null; then
      echo "a download is already running; not starting another"
    else
      # One detached job so the mirror follows the download without needing a
      # second visit. Both phases land in the same log.
      nohup bash -c "'$0' download && '$0' mirror" > "$LOG" 2>&1 &
      echo "started (download then mirror); log: $LOG"
    fi
    echo "  progress: $0 --status"
    if [ "${1:-}" = "--watch" ]; then
      sleep 2
      tail -f "$LOG"
    fi
    ;;
  *)
    echo "usage: $0 [all|--watch|download|mirror|verify|draft|--status]" >&2
    exit 2
    ;;
esac
