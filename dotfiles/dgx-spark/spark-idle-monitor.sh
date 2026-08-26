#!/usr/bin/env bash
# Power off the DSpark cluster when no inference has happened for an hour.
#
# Runs hourly on BOTH nodes from spark-idle-monitor.timer. Each node decides
# independently from the same signal: vllm:generation_tokens_total, a monotonic
# counter scraped from the head's metrics endpoint. Unchanged between two
# consecutive hourly checks means nothing ran, so both nodes power themselves
# off. Effective idle window is therefore 1-2 hours, not exactly one.
#
# Deliberately NOT `set -e`: every failure path below is handled explicitly,
# because the dangerous mistake here is treating an error as "idle".
set -uo pipefail

# Role detection uses the LAN address; reaching the head uses the RoCE fabric.
# That split is deliberate. The worker's LAN address has been observed to drop
# while the node is perfectly healthy and still serving as a TP peer over RoCE.
# Scraping the head over the LAN would then fail, and a naive "head unreachable
# -> power off" rule would kill a working worker. The fabric is the link the
# cluster actually depends on: if it is down, the cluster is genuinely broken.
HEAD_IP=192.168.50.157          # head, LAN
HEAD_FABRIC=169.254.34.131      # head, RoCE (MASTER_ADDR in env.dspark)
STATE_DIR=/var/lib/spark-idle
STATE_FILE="$STATE_DIR/last-tokens"
INHIBIT_FILE="$STATE_DIR/inhibit"
# The head waits so the worker powers off first. Both hold the NCCL
# communicator; dropping the worker first avoids the head tearing down a live
# tensor-parallel group.
HEAD_DELAY=60

# DRY_RUN=1 exercises every decision path but never powers off and never
# writes state, so `install-idle-monitor.sh dry-run` is safe on a live box.
DRY_RUN="${DRY_RUN:-0}"
poweroff_now() {
    if [[ $DRY_RUN == 1 ]]; then
        say "DRY RUN: would power off now"
        exit 0
    fi
    # Checked here rather than at the top of the script on purpose: inhibit
    # suppresses the shutdown, not the monitoring. Installing the timer with
    # the inhibit file in place gives a supervised trial -- every hourly
    # decision lands in the journal, nothing ever powers off.
    if [[ -e $INHIBIT_FILE ]]; then
        say "INHIBITED: would have powered off, but $INHIBIT_FILE exists"
        exit 0
    fi
    systemctl poweroff
}

[[ $DRY_RUN == 1 ]] || mkdir -p "$STATE_DIR"

IS_HEAD=false
hostname -I 2>/dev/null | tr ' ' '\n' | grep -qxE "$HEAD_IP|$HEAD_FABRIC" && IS_HEAD=true
ROLE=$([[ $IS_HEAD == true ]] && echo head || echo worker)

# Head scrapes itself; worker goes over the fabric, never the LAN.
if [[ $IS_HEAD == true ]]; then
    METRICS_URL="${METRICS_URL:-http://127.0.0.1:8888/metrics}"
else
    METRICS_URL="${METRICS_URL:-http://${HEAD_FABRIC}:8888/metrics}"
fi

say() { echo "[$ROLE] $*"; }          # journald captures stdout

# --- scrape -------------------------------------------------------------
# An unreachable endpoint is NOT idleness. After a manual power-on vLLM needs
# ~200s to load; a naive script would read that silence as "nothing running"
# and shut the machine straight back down.
if ! metrics=$(curl -fsS --max-time 10 "$METRICS_URL" 2>/dev/null); then
    if [[ $IS_HEAD == false ]] \
       && ! ping -c2 -W2 "$HEAD_FABRIC" >/dev/null 2>&1 \
       && ! ping -c2 -W2 "$HEAD_IP" >/dev/null 2>&1; then
        # Head is gone on BOTH paths. Requiring both is the point: either one
        # alone can drop while the cluster is fine. A worker with no head
        # serves nothing, so don't sit there burning ~25W.
        say "head unreachable on fabric AND lan -> lone worker is useless, powering off"
        poweroff_now
        exit 0
    fi
    say "metrics unreachable but host is up -> no action (vLLM may be loading)"
    exit 0
fi

# Sum across engine labels. The `{` anchors the match so that
# num_requests_waiting does not also swallow num_requests_waiting_by_reason.
sum_metric() {
    printf '%s\n' "$metrics" | grep -E "^${1}\{" | awk '{s+=$NF} END{printf "%.0f", s+0}'
}

tokens=$(sum_metric "vllm:generation_tokens_total")
running=$(sum_metric "vllm:num_requests_running")
waiting=$(sum_metric "vllm:num_requests_waiting")

save_and_exit() { [[ $DRY_RUN == 1 ]] || echo "$tokens" > "$STATE_FILE"; say "$1"; exit 0; }

# --- guards -------------------------------------------------------------
(( running > 0 || waiting > 0 )) && \
    save_and_exit "requests in flight (running=$running waiting=$waiting) -> no action"

if who 2>/dev/null | grep -q .; then
    save_and_exit "interactive session present -> no action"
fi

[[ -f $STATE_FILE ]] || save_and_exit "first run, baseline=$tokens"

last=$(cat "$STATE_FILE" 2>/dev/null)
[[ $last =~ ^[0-9]+$ ]] || save_and_exit "unreadable state, re-baselining at $tokens"

# A decrease means the counter reset, i.e. vLLM restarted -- which is activity,
# not idleness.
(( tokens < last )) && save_and_exit "counter reset ($last -> $tokens) -> no action"
(( tokens > last )) && save_and_exit "activity: +$(( tokens - last )) tokens -> no action"

# --- idle ---------------------------------------------------------------
say "idle: generation_tokens_total unchanged at $tokens -> powering off"
if [[ $IS_HEAD == true ]]; then
    say "head delays ${HEAD_DELAY}s so the worker drops out of the TP group first"
    [[ $DRY_RUN == 1 ]] || sleep "$HEAD_DELAY"
fi
poweroff_now
