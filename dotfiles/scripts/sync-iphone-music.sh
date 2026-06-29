#!/usr/bin/env bash
# Sync ~/Music -> iPhone over USB (ifuse + rsync). Two destinations:
#   1. AFC /Music        -> the standalone file-based music player on the phone
#   2. Spotify sandbox   -> com.spotify.client Documents/"Synced files"
#      (after this, on the phone: Spotify > Settings > enable "Local Files";
#       playback of local files on mobile still requires Spotify Premium)
#
# Requires: ifuse + libimobiledevice (in environment.systemPackages),
#           services.usbmuxd.enable = true, and the iPhone UNLOCKED & trusted.
#           (locked phone => "Could not connect to lockdownd, error code -8")
#
# Usage: sync-iphone-music.sh [all|player|spotify]   (default: all)
set -euo pipefail

TARGET="${1:-all}"
SRC="${HOME}/Music/"
MNT_PLAYER="${HOME}/iphone"
MNT_SPOTIFY="${HOME}/iphone-spotify"
SPOTIFY_BUNDLE="com.spotify.client"

RSYNC_OPTS=(-r --no-perms --no-owner --no-group --omit-dir-times --size-only --info=name)

# Pair (no-op if already paired). iPhone must be unlocked.
idevicepair pair >/dev/null

sync_player() {
  mkdir -p "$MNT_PLAYER"
  mountpoint -q "$MNT_PLAYER" || ifuse "$MNT_PLAYER"
  echo ">> Syncing to file-based player (AFC /Music) ..."
  rsync "${RSYNC_OPTS[@]}" "$SRC" "$MNT_PLAYER/Music/"
  ( cd /tmp && fusermount -uz "$MNT_PLAYER" )
}

sync_spotify() {
  mkdir -p "$MNT_SPOTIFY"
  mountpoint -q "$MNT_SPOTIFY" || ifuse --documents "$SPOTIFY_BUNDLE" "$MNT_SPOTIFY"
  echo ">> Syncing to Spotify sandbox (Synced files) ..."
  rsync "${RSYNC_OPTS[@]}" "$SRC" "$MNT_SPOTIFY/Synced files/"
  ( cd /tmp && fusermount -uz "$MNT_SPOTIFY" )
}

case "$TARGET" in
  player)  sync_player ;;
  spotify) sync_spotify ;;
  all)     sync_player; sync_spotify ;;
  *) echo "usage: $(basename "$0") [all|player|spotify]" >&2; exit 1 ;;
esac

echo "Done. iPhone unmounted."
