#!/usr/bin/env bash
# Fetch the two DeepSeek-V4.1-Flash-1017 Engram shards as resumable parallel HTTP ranges; hf refuses files this large without xet.
set -euo pipefail

DIR="${1:-$HOME/models/DeepSeek-V4.1-Flash-1017-EXL3-2.75bpw-DGX-Spark}"
REPO=deepseek-ai/DeepSeek-V4.1-Flash-1017
SEGS="${SEGS:-24}"
MAX_TRIES="${MAX_TRIES:-500}"
STALL_BPS="${STALL_BPS:-262144}"
FILES=(model-00047-of-00048.safetensors model-00048-of-00048.safetensors)
AUTH=()
[ -f "$HOME/.cache/huggingface/token" ] && AUTH=(-H "Authorization: Bearer $(cat "$HOME/.cache/huggingface/token")")

segment() {
  local url=$1 part=$2 start=$3 end=$4 want=$(( $4 - $3 + 1 )) have tries=0
  while :; do
    have=$(stat -c %s "$part" 2>/dev/null || echo 0)
    [ "$have" -lt "$want" ] || return 0
    (( ++tries <= MAX_TRIES )) || { echo "giving up on $part after $MAX_TRIES tries" >&2; return 1; }
    curl -sSL --fail "${AUTH[@]}" --connect-timeout 20 --speed-limit "$STALL_BPS" --speed-time 60 \
      -r "$((start + have))-$end" "$url" >> "$part" || sleep 5
  done
}

bounds() {
  local i=$1 size=$2 chunk=$3 start end
  start=$(( i * chunk )); end=$(( start + chunk - 1 ))
  [ "$end" -lt "$size" ] || end=$(( size - 1 ))
  echo "$start $end"
}

fetch() {
  local name=$1 url="https://huggingface.co/$REPO/resolve/main/$1" hdr size sha chunk i start end joined pids=()
  local out="$DIR/$name" tmp="$DIR/$name.joining" work="$DIR/.engram-parts/$name"
  hdr=$(curl -sSI "${AUTH[@]}" "$url")
  size=$(grep -i '^x-linked-size:' <<<"$hdr" | tr -dc 0-9)
  sha=$(grep -i '^x-linked-etag:' <<<"$hdr" | grep -o '[0-9a-f]\{64\}')
  [ -n "$size" ] && [ -n "$sha" ] || { echo "$name: no size/sha in headers" >&2; return 1; }

  if [ ! -f "$out" ] || [ "$(stat -c %s "$out")" != "$size" ]; then
    mkdir -p "$work"; touch "$tmp"
    chunk=$(( (size + SEGS - 1) / SEGS ))
    joined=$(stat -c %s "$tmp")
    for ((i = 0; i < SEGS; i++)); do
      read -r start end < <(bounds "$i" "$size" "$chunk")
      [ "$joined" -gt "$end" ] && continue
      segment "$url" "$work/$i" "$start" "$end" & pids+=($!)
    done
    for p in "${pids[@]}"; do wait "$p"; done
    for ((i = 0; i < SEGS; i++)); do
      read -r start end < <(bounds "$i" "$size" "$chunk")
      if [ "$(stat -c %s "$tmp")" -gt "$end" ]; then rm -f "$work/$i"; continue; fi
      truncate -s "$start" "$tmp"
      cat "$work/$i" >> "$tmp"
      rm "$work/$i"
    done
    [ "$(stat -c %s "$tmp")" = "$size" ] || { echo "$name: joined size $(stat -c %s "$tmp") != $size" >&2; return 1; }
    mv "$tmp" "$out"
    rmdir "$work" 2>/dev/null || true
  fi

  if [ "$(cat "$out.sha256-ok" 2>/dev/null)" != "$sha" ]; then
    [ "$(sha256sum "$out" | cut -d' ' -f1)" = "$sha" ] || { echo "$name: sha256 mismatch (want $sha)" >&2; return 1; }
    echo "$sha" > "$out.sha256-ok"
  fi
  echo "$name ok ($size bytes, sha256 $sha)"
}

mkdir -p "$DIR"
pids=()
for f in "${FILES[@]}"; do fetch "$f" & pids+=($!); done
rc=0
for p in "${pids[@]}"; do wait "$p" || rc=1; done
rmdir "$DIR/.engram-parts" 2>/dev/null || true
exit $rc
