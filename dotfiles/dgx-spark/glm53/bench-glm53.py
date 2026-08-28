#!/usr/bin/env python3
"""Measure TTFT and decode throughput at one or more concurrency levels.

Methodology deliberately matches jack6464's forum numbers so the results are
comparable rather than merely plausible: ~161 prompt tokens, 256 forced output
tokens (ignore_eos, so EOS cannot cut a run short and skew the rate),
temperature 0.

Two knobs of his that are worth being explicit about:

  --no-thinking   His benchmarks and Tony's both ran with thinking disabled.
                  This deployment serves thinking ON, because with it off GLM
                  emits untagged reasoning into content and breaks omp. So the
                  default here measures what you will actually experience, and
                  --no-thinking reproduces his condition. Expect them to differ.

  --concurrency   His headline 60.68 tok/s is a c5 AGGREGATE across five
                  saturated streams, not a per-stream figure. Both are reported
                  below, because only the per-stream number is what a single
                  agent feels.

Stdlib only -- this runs on the Spark nodes, which have a bare python3.

  ./bench-glm53.py                      # c1 and c4 (omp's maxConcurrency)
  ./bench-glm53.py -c 1 4 5 --runs 3
  ./bench-glm53.py --no-thinking        # reproduce the published condition
  ./bench-glm53.py --host 192.168.50.157
"""

import argparse
import json
import statistics
import sys
import threading
import time
import urllib.request

# ~161 tokens, chosen to sit in the same prompt-length regime as the published
# runs. The actual count is read back from usage and reported, so a tokenizer
# difference shows up rather than hiding.
PROMPT = (
    "You are reviewing a distributed inference deployment. Two nodes serve a "
    "mixture-of-experts model with tensor parallelism across a high-speed "
    "fabric. The key-value cache is quantised to eight bits, speculative "
    "decoding is enabled with a multi-token prediction head, and the scheduler "
    "uses chunked prefill with a small batch cap to bound activation memory. "
    "Explain, in careful detail, how the interaction between speculative "
    "decoding and request batching changes as concurrency rises from one "
    "request to five, why the benefit of speculation is largest when the batch "
    "is small, and what this implies for choosing between a throughput-oriented "
    "configuration and a latency-oriented one. Discuss the memory cost of the "
    "draft head and how it trades against key-value cache capacity."
)


def one_request(host, port, model, max_tokens, thinking, out, idx):
    """Run a single streaming completion; record timings into out[idx]."""
    body = {
        "model": model,
        "messages": [{"role": "user", "content": PROMPT}],
        "max_tokens": max_tokens,
        "temperature": 0.0,
        # Force the full token budget so a short answer cannot flatter the rate.
        "ignore_eos": True,
        "stream": True,
        "stream_options": {"include_usage": True},
        "chat_template_kwargs": {"enable_thinking": thinking},
    }
    req = urllib.request.Request(
        f"http://{host}:{port}/v1/chat/completions",
        data=json.dumps(body).encode(),
        headers={"Content-Type": "application/json"},
    )

    start = time.perf_counter()
    ttft = None
    completion_tokens = prompt_tokens = 0
    try:
        with urllib.request.urlopen(req, timeout=900) as resp:
            for raw in resp:
                line = raw.decode("utf-8", "replace").strip()
                if not line.startswith("data: "):
                    continue
                payload = line[6:]
                if payload == "[DONE]":
                    break
                chunk = json.loads(payload)
                if chunk.get("usage"):
                    completion_tokens = chunk["usage"].get("completion_tokens", 0)
                    prompt_tokens = chunk["usage"].get("prompt_tokens", 0)
                for choice in chunk.get("choices", []):
                    delta = choice.get("delta") or {}
                    # Thinking-on responses stream reasoning FIRST, and that is
                    # the first token a user actually waits for, so it counts
                    # for TTFT. This build emits it as "reasoning";
                    # "reasoning_content" is the other spelling in the wild.
                    # Check all three -- missing the right key silently yields
                    # no TTFT at all, which is how this was first found.
                    if ttft is None and any(
                        delta.get(k) for k in ("content", "reasoning", "reasoning_content")
                    ):
                        ttft = time.perf_counter() - start
    except Exception as exc:  # noqa: BLE001 - report, do not abort the sweep
        out[idx] = {"error": str(exc)}
        return

    total = time.perf_counter() - start
    out[idx] = {
        "ttft": ttft,
        "total": total,
        "completion_tokens": completion_tokens,
        "prompt_tokens": prompt_tokens,
        # Decode rate excludes prefill: the first token is not decoded at the
        # steady-state rate, so counting it inflates short runs.
        "decode": (completion_tokens - 1) / (total - ttft)
        if ttft and total > ttft and completion_tokens > 1
        else 0.0,
    }


def run_level(host, port, model, max_tokens, thinking, concurrency):
    out = [None] * concurrency
    threads = [
        threading.Thread(
            target=one_request,
            args=(host, port, model, max_tokens, thinking, out, i),
        )
        for i in range(concurrency)
    ]
    wall_start = time.perf_counter()
    for t in threads:
        t.start()
    for t in threads:
        t.join()
    wall = time.perf_counter() - wall_start

    errors = [r["error"] for r in out if r and "error" in r]
    good = [r for r in out if r and "error" not in r]
    if not good:
        return {"errors": errors, "ok": 0}

    total_tokens = sum(r["completion_tokens"] for r in good)
    ttfts = [r["ttft"] for r in good if r["ttft"]]
    return {
        "ok": len(good),
        "errors": errors,
        # 0.0 rather than an exception: a TTFT-detection miss should degrade the
        # report, not destroy a benchmark run that otherwise succeeded.
        "ttft": statistics.median(ttfts) if ttfts else 0.0,
        "per_stream": statistics.median(r["decode"] for r in good),
        # Aggregate is total tokens over the WALL clock of the whole batch, not
        # the sum of per-stream rates -- streams do not start and end together.
        "aggregate": total_tokens / wall,
        "prompt_tokens": good[0]["prompt_tokens"],
        "wall": wall,
    }


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--host", default="127.0.0.1")
    ap.add_argument("--port", type=int, default=8888)
    ap.add_argument("--model", default="glm-5.3-flash")
    ap.add_argument("-c", "--concurrency", type=int, nargs="+", default=[1, 4])
    ap.add_argument("--runs", type=int, default=3, help="repeats per level; median reported")
    ap.add_argument("--max-tokens", type=int, default=256)
    ap.add_argument(
        "--no-thinking",
        action="store_true",
        help="disable thinking, reproducing the published benchmark condition",
    )
    args = ap.parse_args()
    thinking = not args.no_thinking

    print(f"model      : {args.model} @ {args.host}:{args.port}")
    print(f"thinking   : {'on (as served)' if thinking else 'off (published condition)'}")
    print(f"output     : {args.max_tokens} forced tokens, temp 0, {args.runs} run(s) per level")
    print()

    rows = []
    for c in args.concurrency:
        results = []
        for r in range(args.runs):
            res = run_level(
                args.host, args.port, args.model, args.max_tokens, thinking, c
            )
            if res.get("ok"):
                results.append(res)
            else:
                print(f"  c{c} run {r + 1} failed: {res.get('errors')}", file=sys.stderr)
        if not results:
            continue
        rows.append(
            (
                c,
                statistics.median(x["ttft"] for x in results),
                statistics.median(x["per_stream"] for x in results),
                statistics.median(x["aggregate"] for x in results),
                results[0]["prompt_tokens"],
                sum(len(x["errors"]) for x in results),
            )
        )

    if not rows:
        print("no successful runs", file=sys.stderr)
        return 1

    print(f"{'conc':>5}  {'TTFT':>8}  {'per-stream':>12}  {'aggregate':>11}  {'prompt':>7}  {'err':>4}")
    print(f"{'-' * 5}  {'-' * 8}  {'-' * 12}  {'-' * 11}  {'-' * 7}  {'-' * 4}")
    for c, ttft, per, agg, ptok, errs in rows:
        print(f"{c:>5}  {ttft:>7.3f}s  {per:>8.2f} tok/s  {agg:>6.2f} tok/s  {ptok:>7}  {errs:>4}")

    print()
    print("Reference (jack6464, native SM12x + Marlin + MTP=5, thinking off):")
    print("     1    0.439s     23.08 tok/s   23.08 tok/s      161")
    print("     5        -           -        60.68 tok/s      161")
    return 0


if __name__ == "__main__":
    sys.exit(main())
