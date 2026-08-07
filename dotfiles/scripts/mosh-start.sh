#!/usr/bin/env bash

set -e

if [ -z "$1" ]; then
  echo "Usage: $0 [user@]hostname [ssh_port]"
  exit 1
fi

REMOTE="$1"
SSH_PORT="${2:-22}"

# 1. Fetch Mosh credentials by running mosh-server over SSH
echo "Connecting to $REMOTE to initialize mosh-server..."
MOSH_OUT=$(ssh -p "$SSH_PORT" -t "$REMOTE" "mosh-server new" 2>/dev/null)

# Extract IP/Hostname without user prefix
REMOTE_HOST="${REMOTE#*@}"

# Extract Port and Key from mosh-server output
# Expected format: MOSH CONNECT <PORT> <KEY>
MOSH_PORT=$(echo "$MOSH_OUT" | grep "MOSH CONNECT" | awk '{print $3}')
MOSH_KEY=$(echo "$MOSH_OUT" | grep "MOSH CONNECT" | awk '{print $4}')

if [ -z "$MOSH_PORT" ] || [ -z "$MOSH_KEY" ]; then
  echo "Error: Failed to obtain mosh-server credentials."
  echo "Ensure mosh-server is installed on the remote machine."
  exit 1
fi

echo "Mosh server bound to UDP port $MOSH_PORT"
echo "Establishing Mosh session..."

# 2. Hand off connection to mosh-client locally
export MOSH_KEY="$MOSH_KEY"
exec mosh-client "$REMOTE_HOST" "$MOSH_PORT"
