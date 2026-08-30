#!/usr/bin/env bash
# Build erichough/nfs-server for arm64, with the two fixes GB10 needs.
# Run ON THE WORKER. Idempotent.
#
# WHY THIS EXISTS
# upstream install.sh --nfs runs erichough/nfs-server, which publishes amd64
# only -- on GB10 it restart-loops on "exec format error" while install.sh
# still exits rc=0, so the breakage is silent. The image's *source* is
# arch-independent (alpine + nfs-utils), so we build it locally and tag it with
# the name install.sh invokes. install.sh then finds a local arm64 image,
# never pulls, and its --nfs path runs unmodified.
#
# The two patches are upstream bugs against a current userland/kernel, not
# arm64 issues -- both reproduce on amd64 with the same versions.
set -euo pipefail

SRC="${SRC:-$HOME/docker-nfs-server}"
[ -d "$SRC/.git" ] || git clone https://github.com/ehough/docker-nfs-server "$SRC"
cd "$SRC"
git checkout -q -- . 2>/dev/null || true

# (1) capsh is in libcap, which alpine does not pull in transitively. Without
#     it the capability assertion dies on "capsh: command not found".
grep -q 'nfs-utils libcap' Dockerfile || \
  sed -i 's/apk --update --no-cache add bash nfs-utils/apk --update --no-cache add bash nfs-utils libcap/' Dockerfile

# (2) libcap >= 2.43 prints the compact "Current: =ep" instead of a
#     comma-separated capability list. Upstream's regex only matches the old
#     form, so a --privileged container reads as having no capabilities.
python3 - <<'PY'
p = "entrypoint.sh"; s = open(p).read()
old = '  if capsh --print | grep -Eq "^Current: = .*,?${1}(,|$)"; then'
new = (old + "\n    return 0\n  fi\n\n"
       '  # libcap >=2.43 compact form.\n'
       '  if capsh --print | grep -Eq "^Current: =[a-z]*ep[a-z]*$"; then')
if 'compact form' not in s:
    assert old in s, "capability check not found -- upstream changed"
    s = s.replace(old, new, 1); open(p, "w").write(s)
PY

# (3) Upstream hardcodes --no-nfs-version 2. Kernels that removed NFSv2 reject
#     being asked to disable it ("2: Unsupported version") and rpc.nfsd exits.
python3 - <<'PY'
p = "entrypoint.sh"; s = open(p).read()
old = """  local flags=('--nfs-version' "$requested_version" '--no-nfs-version' 2)"""
new = """  local flags=('--nfs-version' "$requested_version")"""
if old in s:
    s = s.replace(old, new, 1); open(p, "w").write(s)
PY

docker build -q -t erichough/nfs-server:latest .
echo "built erichough/nfs-server:latest ($(docker image inspect erichough/nfs-server:latest --format '{{.Architecture}}'))"
