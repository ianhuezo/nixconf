#!/usr/bin/env python3
"""Production-readiness gate for GLM-5.3-Flash on GB10.

This is NOT a benchmark. bench-glm53.py measures speed with a 161-token prompt;
that prompt is far too short to trip either of the two failure modes that
actually killed this deployment upstream, so a green benchmark proves nothing
about stability. The gates below are built to trip them on purpose.

Gate suite (all must pass in ONE session, engine healthy afterwards):

  1. Deep decode past the topk wall -- 28-32K-token prompt, >=100 decoded tokens.
     Catches "disease 1": the DSA indexer routes decode top-k to persistent_topk
     whenever select_k is 512/1024/2048 (GLM: always), and past ~20K context its
     CTA grid oversubscribes GB10's 48 SMs, falling back to a kernel needing
     128KB smem against SM121's 99KB -> RuntimeError -> EngineDeadError.
     A 20K gate sits UNDER the trigger and proves nothing, which is exactly how
     this got misdiagnosed as OOM for a day.

  2. Concurrent prefills -- N simultaneous ~20K prompts, each with a UNIQUE
     prefix. Catches head-rank memory transients. The uniqueness matters: with
     identical prompts, prefix caching serves them almost free and the gate
     silently tests nothing.

  3. Repeat deep decode, after the pool has been touched. Catches "disease 2",
     phantom KV backing: a reservation that "succeeds" but whose physical pages
     at the pool's far edges do not exist, faulting only when load touches them.
     Gate 1 passing on a cold pool does not imply gate 3 passes on a warm one.

  4. Vision probe -- a solid-colour image the model must name.

  5. /health returns 200. Never /v1/models: it answers 200 with a dead engine;
     /health returns 503 on EngineDeadError.

KV pool usage is sampled from /metrics between gates, because the upstream
crashes died at 1.8% pool usage -- if this fails, the number tells you
immediately whether memory was even plausibly involved.

  ./gate-glm53.py                 # full suite at the configured concurrency
  ./gate-glm53.py -c 4            # match omp's maxConcurrency
  ./gate-glm53.py --skip-vision
"""

import argparse
import base64
import json
import struct
import sys
import threading
import time
import urllib.request
import zlib

HOST = "127.0.0.1"
PORT = 8888
MODEL = "glm-5.3-flash"


def api(path):
    return f"http://{HOST}:{PORT}{path}"


def post_chat(messages, max_tokens, timeout=900, thinking=True):
    body = {
        "model": MODEL,
        "messages": messages,
        "max_tokens": max_tokens,
        "temperature": 0.0,
        "ignore_eos": True,
        "chat_template_kwargs": {"enable_thinking": thinking},
    }
    req = urllib.request.Request(
        api("/v1/chat/completions"),
        data=json.dumps(body).encode(),
        headers={"Content-Type": "application/json"},
    )
    t0 = time.perf_counter()
    with urllib.request.urlopen(req, timeout=timeout) as resp:
        out = json.loads(resp.read().decode())
    return out, time.perf_counter() - t0


def filler(target_tokens, nonce):
    """~target_tokens of prose with a unique prefix so prefix caching can't serve it.

    Varied numbered lines rather than one repeated sentence: a degenerate
    repeating string both tokenises unrealistically and is unusually friendly to
    any caching layer.
    """
    head = f"Session {nonce}. Analyse the following log excerpt.\n"
    lines = []
    # ~4 chars/token is the usual English ratio; each line lands near 18 tokens.
    for i in range(int(target_tokens / 18) + 1):
        lines.append(
            f"[{nonce}-{i:06d}] worker={i % 7} shard={i % 13} "
            f"latency_ms={(i * 37) % 991} tokens={(i * 17) % 613} "
            f"note=steady-state decode sample {i}"
        )
    return head + "\n".join(lines)


def kv_usage():
    try:
        with urllib.request.urlopen(api("/metrics"), timeout=10) as r:
            text = r.read().decode()
    except Exception:
        return None
    for line in text.splitlines():
        if line.startswith("vllm:kv_cache_usage_perc{"):
            try:
                return float(line.rsplit(None, 1)[1])
            except (ValueError, IndexError):
                return None
    return None


def healthy():
    try:
        req = urllib.request.Request(api("/health"))
        with urllib.request.urlopen(req, timeout=10) as r:
            return r.status == 200
    except Exception:
        return False


def spec_counters():
    """(drafted, accepted) since engine start, or None if not speculating."""
    try:
        with urllib.request.urlopen(api("/metrics"), timeout=10) as r:
            text = r.read().decode()
    except Exception:
        return None
    got = {}
    for line in text.splitlines():
        for key, name in (
            ("vllm:spec_decode_num_draft_tokens_total", "draft"),
            ("vllm:spec_decode_num_accepted_tokens_total", "accept"),
        ):
            if line.startswith(key + "{") or line.startswith(key + " "):
                try:
                    got[name] = float(line.rsplit(None, 1)[1])
                except (ValueError, IndexError):
                    pass
    if "draft" not in got or got.get("draft", 0) <= 0:
        return None
    return got["draft"], got.get("accept", 0.0)


def solid_png(w=96, h=96, rgb=(220, 20, 20)):
    """Minimal RGB PNG, stdlib only -- the nodes have no PIL."""
    raw = b"".join(b"\x00" + bytes(rgb) * w for _ in range(h))

    def chunk(tag, data):
        return (
            struct.pack(">I", len(data))
            + tag
            + data
            + struct.pack(">I", zlib.crc32(tag + data) & 0xFFFFFFFF)
        )

    return (
        b"\x89PNG\r\n\x1a\n"
        + chunk(b"IHDR", struct.pack(">IIBBBBB", w, h, 8, 2, 0, 0, 0))
        + chunk(b"IDAT", zlib.compress(raw))
        + chunk(b"IEND", b"")
    )


results = []


def record(name, ok, detail):
    results.append((name, ok, detail))
    print(f"  [{'PASS' if ok else 'FAIL'}] {name}: {detail}", flush=True)
    return ok


def gate_deep_decode(label, ctx_tokens, out_tokens, nonce):
    try:
        out, dt = post_chat(
            [{"role": "user", "content": filler(ctx_tokens, nonce)
              + "\n\nSummarise the pattern in one paragraph."}],
            out_tokens,
        )
        u = out.get("usage", {})
        pt, ct = u.get("prompt_tokens", 0), u.get("completion_tokens", 0)
        if pt < 28000:
            return record(label, False,
                          f"prompt only {pt} tokens -- UNDER the ~24K trigger, "
                          f"this gate proved nothing; raise ctx_tokens")
        if ct < 100:
            return record(label, False, f"only {ct} decoded tokens (need >=100)")
        return record(label, True,
                      f"{pt} prompt / {ct} decoded in {dt:.1f}s, kv={kv_usage()}")
    except Exception as exc:
        return record(label, False, f"{type(exc).__name__}: {exc}")


def gate_concurrent_prefill(n, ctx_tokens):
    out = [None] * n

    def one(i):
        try:
            r, dt = post_chat(
                [{"role": "user", "content": filler(ctx_tokens, f"conc{i}-{int(time.time())}")
                  + "\n\nReply with the single word OK."}],
                32,
            )
            out[i] = ("ok", r.get("usage", {}).get("prompt_tokens", 0), dt)
        except Exception as exc:
            out[i] = ("err", f"{type(exc).__name__}: {exc}", 0)

    threads = [threading.Thread(target=one, args=(i,)) for i in range(n)]
    t0 = time.perf_counter()
    for t in threads:
        t.start()
    for t in threads:
        t.join()
    wall = time.perf_counter() - t0

    errs = [r for r in out if r and r[0] == "err"]
    oks = [r for r in out if r and r[0] == "ok"]
    if errs:
        return record(f"{n}x concurrent ~{ctx_tokens // 1000}K prefills", False,
                      f"{len(errs)}/{n} failed: {errs[0][1]}")
    toks = sum(r[1] for r in oks)
    return record(f"{n}x concurrent ~{ctx_tokens // 1000}K prefills", True,
                  f"all {n} ok, {toks} prompt tokens in {wall:.1f}s, kv={kv_usage()}")


def gate_vision():
    b64 = base64.b64encode(solid_png()).decode()
    try:
        out, dt = post_chat(
            [{"role": "user", "content": [
                {"type": "image_url",
                 "image_url": {"url": f"data:image/png;base64,{b64}"}},
                {"type": "text", "text": "What colour is this image? One word."},
            ]}],
            256,
            thinking=False,
        )
        msg = out["choices"][0]["message"]
        text = "".join(msg.get(k) or "" for k in ("content", "reasoning", "reasoning_content"))
        u = out.get("usage", {})
        ok = "red" in text.lower()
        return record("vision probe", ok,
                      f"{'saw red' if ok else 'did NOT say red'} "
                      f"({u.get('prompt_tokens')} prompt tok, {dt:.1f}s): {text.strip()[:90]!r}")
    except Exception as exc:
        return record("vision probe", False, f"{type(exc).__name__}: {exc}")


def main():
    global HOST, PORT, MODEL
    ap = argparse.ArgumentParser()
    ap.add_argument("--host", default=HOST)
    ap.add_argument("--port", type=int, default=PORT)
    ap.add_argument("--model", default=MODEL)
    ap.add_argument("-c", "--concurrency", type=int, default=4)
    ap.add_argument("--deep-ctx", type=int, default=30000)
    ap.add_argument("--conc-ctx", type=int, default=20000)
    ap.add_argument("--skip-vision", action="store_true")
    args = ap.parse_args()
    HOST, PORT, MODEL = args.host, args.port, args.model

    print(f"gating {MODEL} @ {HOST}:{PORT}")
    print(f"  deep ctx {args.deep_ctx}, concurrent {args.concurrency}x{args.conc_ctx}")
    print()

    if not healthy():
        print("  /health is not 200 -- engine not ready or dead. Aborting.", file=sys.stderr)
        return 1
    print(f"  starting kv usage: {kv_usage()}\n")

    # Order matters: 1 on a cold pool, then 2 to touch it, then 3 on the warm
    # pool. Running 3 before 2 would not test phantom backing at all.
    gate_deep_decode("gate 1: deep decode (cold pool)", args.deep_ctx, 128, f"g1-{int(time.time())}")
    gate_concurrent_prefill(args.concurrency, args.conc_ctx)
    gate_deep_decode("gate 3: deep decode (warm pool)", args.deep_ctx, 128, f"g3-{int(time.time())}")
    if not args.skip_vision:
        gate_vision()

    # Speculative decoding is the one thing here that fails SILENTLY. A wrong
    # aux-layer tap or a wrong hidden-state contraction keeps every shape valid;
    # the drafter simply proposes from garbage features, acceptance collapses,
    # and decode still "works" -- just slower than with no drafter at all. So
    # gate on the counters, not on output correctness. Measured over the gates
    # above rather than a dedicated prompt, since they have already generated a
    # few thousand tokens of exactly the traffic we care about.
    spec = spec_counters()
    if spec is None:
        print("  [skip] gate 5: draft acceptance (engine is not speculating)")
    else:
        drafted, accepted = spec
        rate = accepted / drafted
        # Upstream measures 0.74 on code and 0.53 on a mixed prompt set; the
        # broken-glue signature is first-position acceptance under ~0.5, which
        # drags the overall rate to ~0.15. 0.35 sits well clear of both.
        record(
            "gate 5: draft acceptance",
            rate >= 0.35,
            f"{rate:.1%} ({accepted:.0f}/{drafted:.0f} drafted)"
            + ("" if rate >= 0.35 else " -- suspect miswired aux capture"),
        )

    record("gate 6: /health after all gates", healthy(), "200" if healthy() else "NOT 200")

    print()
    failed = [n for n, ok, _ in results if not ok]
    if failed:
        print(f"RESULT: {len(failed)} GATE(S) FAILED -- not production ready")
        for n in failed:
            print(f"  - {n}")
        return 1
    print(f"RESULT: all {len(results)} gates passed; engine healthy")
    return 0


if __name__ == "__main__":
    sys.exit(main())
