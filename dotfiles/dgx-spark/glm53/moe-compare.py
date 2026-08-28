#!/usr/bin/env python3
"""Greedy output comparison across MoE backends -- a correctness gate, not a benchmark.

The failure mode this exists to catch is specific and nasty: on SM12x, a wrong
FP4 MoE kernel does not crash. It returns fluent, well-formed, *wrong* text.
Upstream lost a day to exactly that ("syntactically valid but corrupted output,
despite isolated kernel tests passing"), and a throughput benchmark would have
cheerfully reported the broken backend as faster.

So: capture greedy (temperature 0) completions on a known-good backend, switch
backends, replay the identical prompts, and diff token-for-token. Same weights +
same prompt + greedy decoding should agree almost exactly. Divergence into
plausible-but-different prose is the corruption signature.

  ./moe-compare.py save marlin.json      # on the reference backend
  ./moe-compare.py diff marlin.json      # after switching backends

Exit status is 0 only if every prompt matches, so it can gate a rollout.
"""

import argparse
import difflib
import json
import sys
import urllib.request

# Deliberately varied: MoE routing is input-dependent, so a single prompt could
# exercise a narrow slice of experts and miss corruption elsewhere. These span
# prose, code, structured output, arithmetic and long-form reasoning.
PROMPTS = [
    "Write a Python function that merges two sorted lists. Code only.",
    "Explain in three sentences why B-trees suit disk-backed indexes.",
    "Return strict JSON: {\"city\":\"Paris\",\"country\":?} - fill in country.",
    "What is 8347 * 291? Show the multiplication steps.",
    "List the first 10 prime numbers, comma separated, nothing else.",
    "Translate to French: 'The weather is cold today and it may snow.'",
    "Write a QML Rectangle with a radial gradient. Code only.",
    "Summarise the tradeoff between speculative decoding and batch throughput.",
]


def complete(host, port, model, prompt, max_tokens):
    body = {
        "model": model,
        "messages": [{"role": "user", "content": prompt}],
        "max_tokens": max_tokens,
        # Greedy. Any sampling randomness would make the diff meaningless.
        "temperature": 0.0,
        "top_p": 1.0,
        "seed": 42,
    }
    req = urllib.request.Request(
        f"http://{host}:{port}/v1/chat/completions",
        data=json.dumps(body).encode(),
        headers={"Content-Type": "application/json"},
    )
    with urllib.request.urlopen(req, timeout=600) as r:
        out = json.loads(r.read().decode())
    msg = out["choices"][0]["message"]
    # Reasoning is part of the model's output and just as susceptible to
    # corruption, so it belongs in the comparison.
    return {
        "content": msg.get("content") or "",
        "reasoning": msg.get("reasoning") or msg.get("reasoning_content") or "",
        "completion_tokens": out.get("usage", {}).get("completion_tokens", 0),
    }


def collect(args):
    results = []
    for i, p in enumerate(PROMPTS, 1):
        print(f"  [{i}/{len(PROMPTS)}] {p[:58]}...", flush=True)
        try:
            results.append({"prompt": p, **complete(
                args.host, args.port, args.model, p, args.max_tokens)})
        except Exception as exc:
            results.append({"prompt": p, "error": f"{type(exc).__name__}: {exc}"})
    return results


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("action", choices=["save", "diff"])
    ap.add_argument("file")
    ap.add_argument("--host", default="127.0.0.1")
    ap.add_argument("--port", type=int, default=8888)
    ap.add_argument("--model", default="glm-5.3-flash")
    ap.add_argument("--max-tokens", type=int, default=400)
    args = ap.parse_args()

    if args.action == "save":
        res = collect(args)
        json.dump(res, open(args.file, "w"), indent=1)
        bad = sum(1 for r in res if "error" in r)
        print(f"\nsaved {len(res)} completions to {args.file} ({bad} errors)")
        return 1 if bad else 0

    ref = json.load(open(args.file))
    cur = collect(args)
    print()

    mismatched = 0
    for a, b in zip(ref, cur):
        if "error" in a or "error" in b:
            print(f"  [ERR ] {a['prompt'][:50]}: {a.get('error') or b.get('error')}")
            mismatched += 1
            continue
        same_c = a["content"] == b["content"]
        same_r = a["reasoning"] == b["reasoning"]
        if same_c and same_r:
            print(f"  [SAME] {a['prompt'][:50]}")
            continue
        mismatched += 1
        # Similarity separates "a token drifted" from "entirely different text".
        ratio = difflib.SequenceMatcher(None, a["content"], b["content"]).ratio()
        verdict = "minor drift" if ratio > 0.95 else "SUBSTANTIAL DIVERGENCE"
        print(f"  [DIFF] {a['prompt'][:50]}")
        print(f"         content similarity {ratio:.3f} -> {verdict}"
              f"{'' if same_r else ', reasoning also differs'}")
        for line in list(difflib.unified_diff(
                a["content"].split("\n"), b["content"].split("\n"),
                fromfile="reference", tofile="current", lineterm=""))[:8]:
            print(f"         {line[:110]}")

    print()
    if mismatched:
        print(f"RESULT: {mismatched}/{len(ref)} prompts differ.")
        print("Greedy decoding on identical weights should be near-deterministic.")
        print("Substantial divergence => the backend is numerically wrong. Do NOT ship it.")
        return 1
    print(f"RESULT: all {len(ref)} prompts identical -- backend is numerically consistent.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
