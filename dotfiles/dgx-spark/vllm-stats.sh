#!/usr/bin/env bash
# Snapshot vLLM performance, or diff against an earlier snapshot.
#
#   vllm-stats.sh                 # print current cumulative stats
#   vllm-stats.sh save base.txt   # write a snapshot for later comparison
#   vllm-stats.sh diff base.txt   # stats for traffic served SINCE that snapshot
#
# The diff form is the useful one. Every vLLM counter here is cumulative since
# engine start, so a bare reading is an average over all history and hides any
# recent change. Subtracting two snapshots gives the numbers for just the window
# between them, which is what you want after changing a setting.
set -uo pipefail

HOST="${VLLM_HOST:-192.168.50.157}"
PORT="${VLLM_PORT:-8888}"
KEYS='generation_tokens_total|prompt_tokens_total|prompt_tokens_cached_total|request_decode_time_seconds_sum|request_prefill_time_seconds_sum|request_prompt_tokens_sum|request_generation_tokens_sum|request_prompt_tokens_count|inter_token_latency_seconds_sum|inter_token_latency_seconds_count|spec_decode_num_draft_tokens_total|spec_decode_num_accepted_tokens_total'

scrape() {
    curl -fsS --max-time 10 "http://${HOST}:${PORT}/metrics" 2>/dev/null \
        | grep -E "^vllm:(${KEYS})\{" \
        | sed -E 's/\{[^}]*\}//' \
        || { echo "cannot reach vLLM at ${HOST}:${PORT}" >&2; exit 1; }
}

# Renders one set of totals. Called with deltas for the diff form, which is why
# it takes values on stdin rather than scraping itself.
report() {
    awk '
    { v[$1] = $2 }
    END {
        n      = v["vllm:request_prompt_tokens_count"]
        gen    = v["vllm:request_generation_tokens_sum"]
        dec    = v["vllm:request_decode_time_seconds_sum"]
        pre    = v["vllm:request_prefill_time_seconds_sum"]
        prompt = v["vllm:request_prompt_tokens_sum"]
        cached = v["vllm:prompt_tokens_cached_total"]
        ptot   = v["vllm:prompt_tokens_total"]
        steps  = v["vllm:inter_token_latency_seconds_count"]
        itl    = v["vllm:inter_token_latency_seconds_sum"]
        draft  = v["vllm:spec_decode_num_draft_tokens_total"]
        acc    = v["vllm:spec_decode_num_accepted_tokens_total"]

        if (n <= 0) { print "no completed requests in this window"; exit }

        printf "requests            : %d\n", n
        printf "avg prompt tokens   : %.0f\n", prompt/n
        printf "avg output tokens   : %.0f\n", gen/n
        printf "prompt:output ratio : %.1f : 1\n", (gen>0 ? prompt/gen : 0)
        print  ""
        printf "decode rate         : %.1f tok/s\n", (dec>0 ? gen/dec : 0)
        printf "mean engine step    : %.1f ms\n",    (steps>0 ? itl/steps*1000 : 0)
        printf "tokens per step     : %.2f\n",       (steps>0 ? gen/steps : 0)
        print  ""
        # Only uncached prompt tokens cost real compute; the apparent rate that
        # includes cache hits can overstate prefill by an order of magnitude.
        fresh = ptot - cached
        printf "prefix cache hit    : %.1f%%\n", (ptot>0 ? cached/ptot*100 : 0)
        printf "fresh prefill rate  : %.0f tok/s\n", (pre>0 ? fresh/pre : 0)
        print  ""
        printf "MTP acceptance      : %.1f%%\n", (draft>0 ? acc/draft*100 : 0)
        printf "accepted per draft  : %.2f\n",   (draft>0 ? acc/(draft/5) : 0)
    }'
}

case "${1:-show}" in
    show) scrape | report ;;
    save)
        [[ -n ${2:-} ]] || { echo "usage: $0 save <file>" >&2; exit 2; }
        scrape > "$2" && echo "saved snapshot: $2"
        ;;
    diff)
        [[ -f ${2:-} ]] || { echo "usage: $0 diff <snapshot-file>" >&2; exit 2; }
        # join pairs each metric with its old value; counters only ever grow, so
        # a negative result means the engine restarted and the window is invalid.
        join <(sort "$2") <(scrape | sort) \
            | awk '{ d = $3 - $2; if (d < 0) { print "counter went backwards ("$1") -- vLLM restarted since the snapshot" > "/dev/stderr"; exit 1 } print $1, d }' \
            | report
        ;;
    *) echo "usage: $0 [show|save <file>|diff <file>]" >&2; exit 2 ;;
esac
