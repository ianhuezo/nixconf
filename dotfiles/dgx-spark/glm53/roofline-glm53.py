#!/usr/bin/env python3
"""Is decode actually using the memory bandwidth we paid for?

Decode on a GB10 pair is memory-bandwidth bound, not compute bound: every step
has to stream the active weights out of LPDDR5X, and at batch size 1 there is
essentially no arithmetic intensity to hide behind. So the honest measure of a
decode optimisation is not tok/s in isolation -- it is what fraction of the
273 GB/s per node we are actually pulling, and whether a change moved that
number or merely moved tokens around.

Three things get reported, and they cross-check each other:

  1. ANALYTIC bytes per forward pass, read exactly from the safetensors headers
     (shapes and dtypes only -- no tensor data is read, so this costs a few
     hundred milliseconds). Routed-expert weights are charged at the fraction
     actually touched, which depends on how many tokens are in the step:
     E * (1 - (1 - k/E)^B) distinct experts for B tokens, not k*B.

  2. MEASURED decode rate and step rate from a live single-stream generation,
     plus the speculative counters, so we know how many tokens each weight
     sweep actually produced.

  3. HARDWARE utilisation sampled from `nvidia-smi dmon` on BOTH ranks for the
     duration. Only sm% is usable here: GB10 has no separate framebuffer, so
     the driver reports mem% as 0 whatever the load, and it is not printed.
     sm% still answers the question that matters -- an SM sitting idle means
     we are stalling on something other than the sweep (fabric all-reduce,
     kernel launch under --enforce-eager), whereas a busy SM alongside an
     implied read rate well under 273 GB/s means the sweep is real but
     scattered.

Why speculation is expected to move (1) and (3) together: a drafter that gets
7 tokens accepted per verify step amortises ONE weight sweep across those 7
tokens. The bytes-per-step barely change; the tokens-per-step multiply. That
shows up here as achieved bandwidth staying flat while tok/s rises -- which is
the signature of a real win rather than a measurement artefact.

Stdlib only.

  ./roofline-glm53.py                       # analytic + live measurement
  ./roofline-glm53.py --analytic-only       # no traffic; just the model maths
  ./roofline-glm53.py --worker 169.254.54.207
"""

import argparse
import json
import re
import statistics
import subprocess
import struct
import sys
import threading
import time
import urllib.request
from pathlib import Path

# DGX Spark GB10: 128 GB LPDDR5X on a 256-bit bus, 273 GB/s per node. This is
# the published figure, and it is a ceiling -- real achievable is lower.
GB10_BW_GBPS = 273.0

DEFAULT_MODEL_DIR = "~/.cache/huggingface/hub/models--local-inference-lab--GLM-5.3-Flash-NVFP4/snapshots"

PROMPT = (
    "Write a detailed technical explanation of how a tensor-parallel "
    "mixture-of-experts model decodes tokens across two nodes, covering the "
    "all-reduce, the expert routing, and where the time actually goes."
)


# ---------------------------------------------------------------------------
# 1. Analytic: bytes per forward pass, from safetensors headers
# ---------------------------------------------------------------------------

def read_header(path):
    """{name: {dtype, shape, data_offsets}} from a safetensors file.

    Only the JSON header is read. The header length is a little-endian u64 at
    byte 0, so this is two reads regardless of how big the shard is.
    """
    with open(path, "rb") as f:
        (n,) = struct.unpack("<Q", f.read(8))
        return json.loads(f.read(n))


# A routed expert weight. Shared experts deliberately do NOT match: they are
# read on every token, so they belong in the always-resident bucket.
EXPERT_RE = re.compile(r"\.experts\.(\d+)\.")
LAYER_RE = re.compile(r"\blayers\.(\d+)\.")


def classify(name, num_hidden_layers):
    # The checkpoint ships num_nextn_predict_layers=1 as one extra decoder layer
    # past the end of the stack (index == num_hidden_layers). It is the MTP
    # head. Under SPEC_METHOD=dflash it is never run, so charging it would
    # overstate the sweep by several GiB -- and it is a full MoE layer, so the
    # error lands in the expert bucket where it is easy to miss.
    m = LAYER_RE.search(name)
    if m and int(m.group(1)) >= num_hidden_layers:
        return "unused_mtp"
    if EXPERT_RE.search(name):
        return "routed_expert"
    if "embed_tokens" in name:
        # A gather of B rows out of 154,880. Charging the whole table would
        # overstate the read by ~1.3 GB per step.
        return "embedding"
    return "dense"


def analytic_bytes(model_dir, batch_tokens, n_experts, top_k, num_hidden_layers):
    buckets = {"dense": 0, "routed_expert": 0, "embedding": 0, "unused_mtp": 0}
    shards = sorted(Path(model_dir).glob("*.safetensors"))
    if not shards:
        raise SystemExit(f"no safetensors under {model_dir}")
    for shard in shards:
        for name, meta in read_header(shard).items():
            if name == "__metadata__" or not isinstance(meta, dict):
                continue
            off = meta.get("data_offsets")
            if not off:
                continue
            buckets[classify(name, num_hidden_layers)] += off[1] - off[0]

    # Expected distinct experts touched by a step holding `batch_tokens`
    # tokens. At B=1 this is exactly top_k; it saturates towards n_experts as
    # the batch grows, which is why concurrency erodes the MoE bandwidth
    # advantage long before it erodes the dense part.
    p_untouched = (1.0 - top_k / n_experts) ** batch_tokens
    expected_experts = n_experts * (1.0 - p_untouched)
    expert_fraction = expected_experts / n_experts

    active = buckets["dense"] + buckets["routed_expert"] * expert_fraction
    return {
        "buckets": buckets,
        "expected_experts": expected_experts,
        "expert_fraction": expert_fraction,
        "active_bytes": active,
        "resident_bytes": sum(buckets.values()),
        "shards": len(shards),
    }


# ---------------------------------------------------------------------------
# 2. Live: decode rate + speculative counters
# ---------------------------------------------------------------------------

def metrics(host, port):
    try:
        with urllib.request.urlopen(f"http://{host}:{port}/metrics", timeout=10) as r:
            text = r.read().decode()
    except Exception as exc:
        raise SystemExit(f"cannot scrape /metrics: {exc}")
    out = {}
    for line in text.splitlines():
        if line.startswith("#") or not line:
            continue
        key = line.split("{", 1)[0].split(" ", 1)[0]
        try:
            out[key] = out.get(key, 0.0) + float(line.rsplit(None, 1)[1])
        except (ValueError, IndexError):
            pass
    return out


def generate(host, port, model, max_tokens, stop_flag):
    body = {
        "model": model,
        "messages": [{"role": "user", "content": PROMPT}],
        "max_tokens": max_tokens,
        "temperature": 0.0,
        "ignore_eos": True,
        "stream": True,
        "stream_options": {"include_usage": True},
    }
    req = urllib.request.Request(
        f"http://{host}:{port}/v1/chat/completions",
        data=json.dumps(body).encode(),
        headers={"Content-Type": "application/json"},
    )
    start = time.perf_counter()
    ttft = None
    completion = 0
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
                completion = chunk["usage"].get("completion_tokens", completion)
            for choice in chunk.get("choices", []):
                delta = choice.get("delta") or {}
                if ttft is None and any(
                    delta.get(k) for k in ("content", "reasoning", "reasoning_content")
                ):
                    ttft = time.perf_counter() - start
    stop_flag.set()
    total = time.perf_counter() - start
    return {
        "ttft": ttft or 0.0,
        "decode_seconds": total - (ttft or 0.0),
        "completion_tokens": completion,
    }


# ---------------------------------------------------------------------------
# 3. Hardware: nvidia-smi dmon on both ranks
# ---------------------------------------------------------------------------

def sample_dmon(ssh_host, stop_flag, out, key):
    """Collect (sm%, mem%, power W) samples until stop_flag is set.

    dmon prints one row per second and re-emits its header periodically, so
    rows are parsed positionally after skipping anything starting with '#'.
    """
    cmd = ["nvidia-smi", "dmon", "-s", "pu", "-d", "1"]
    if ssh_host:
        cmd = ["ssh", "-o", "BatchMode=yes", ssh_host] + cmd
    rows = []
    try:
        proc = subprocess.Popen(
            cmd, stdout=subprocess.PIPE, stderr=subprocess.DEVNULL, text=True
        )
    except OSError as exc:
        out[key] = {"error": str(exc)}
        return
    try:
        for line in proc.stdout:
            if stop_flag.is_set():
                break
            line = line.strip()
            if not line or line.startswith("#"):
                continue
            parts = line.split()
            # gpu pwr gtemp mtemp sm mem enc dec ...
            if len(parts) < 6:
                continue
            try:
                rows.append((float(parts[1]), float(parts[4]), float(parts[5])))
            except ValueError:
                continue
    finally:
        proc.terminate()
        try:
            proc.wait(timeout=5)
        except subprocess.TimeoutExpired:
            proc.kill()
    if not rows:
        out[key] = {"error": "no samples"}
        return
    # Drop the first sample: it is a cumulative-since-boot artefact on some
    # driver versions and reads low regardless of load.
    rows = rows[1:] or rows
    out[key] = {
        "n": len(rows),
        "pwr": statistics.median(r[0] for r in rows),
        "sm": statistics.median(r[1] for r in rows),
        "mem": statistics.median(r[2] for r in rows),
        "sm_max": max(r[1] for r in rows),
        "mem_max": max(r[2] for r in rows),
    }


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--host", default="127.0.0.1")
    ap.add_argument("--port", type=int, default=8888)
    ap.add_argument("--model", default="glm-5.3-flash")
    ap.add_argument("--model-dir", default=None, help="snapshot dir (auto-detected)")
    ap.add_argument("--worker", default=None, help="ssh host of rank 1, to sample its GPU too")
    ap.add_argument("--max-tokens", type=int, default=400)
    ap.add_argument("--tp", type=int, default=2, help="tensor-parallel size; bytes are split this way")
    ap.add_argument("--analytic-only", action="store_true")
    args = ap.parse_args()

    model_dir = args.model_dir
    if model_dir is None:
        snaps = sorted(Path(DEFAULT_MODEL_DIR).expanduser().glob("*"))
        if not snaps:
            raise SystemExit(f"no snapshot under {DEFAULT_MODEL_DIR}")
        model_dir = str(snaps[0])

    cfg_path = Path(model_dir) / "config.json"
    cfg = json.loads(cfg_path.read_text())
    text_cfg = cfg.get("text_config", cfg)
    n_experts = text_cfg["n_routed_experts"]
    top_k = text_cfg["num_experts_per_tok"]

    # --- warm-up pass so the measurement is not paying for a JIT compile ---
    if not args.analytic_only:
        print("warming up (JIT of the drafter kernels reads ~10 tok/s low if skipped)...")
        try:
            generate(args.host, args.port, args.model, 32, threading.Event())
        except Exception as exc:  # noqa: BLE001
            raise SystemExit(f"warm-up failed: {exc}")

    before = None if args.analytic_only else metrics(args.host, args.port)

    live = None
    dmon = {}
    if not args.analytic_only:
        stop = threading.Event()
        samplers = [threading.Thread(target=sample_dmon, args=(None, stop, dmon, "rank0"))]
        if args.worker:
            samplers.append(
                threading.Thread(target=sample_dmon, args=(args.worker, stop, dmon, "rank1"))
            )
        for t in samplers:
            t.daemon = True
            t.start()
        time.sleep(1.5)  # let dmon emit its first (discarded) row before traffic
        live = generate(args.host, args.port, args.model, args.max_tokens, stop)
        stop.set()
        for t in samplers:
            t.join(timeout=10)

    after = None if args.analytic_only else metrics(args.host, args.port)

    # --- how many tokens rode along in each weight sweep? ---
    #
    # Derived from the counters rather than from the configured flag, so a
    # drafter that is quietly proposing fewer positions than asked shows up.
    # Every verify step emits exactly one non-speculated token, so the number of
    # verify steps is (emitted - accepted); num_spec then falls out of the
    # drafted count, and the batch holds num_spec + 1 positions.
    spec_n = accepted = drafted = 0.0
    tokens_per_step = 1.0
    batch_positions = 1.0
    if after:
        drafted = after.get("vllm:spec_decode_num_draft_tokens_total", 0.0) - before.get(
            "vllm:spec_decode_num_draft_tokens_total", 0.0
        )
        accepted = after.get("vllm:spec_decode_num_accepted_tokens_total", 0.0) - before.get(
            "vllm:spec_decode_num_accepted_tokens_total", 0.0
        )
        if drafted > 0 and live["completion_tokens"] > accepted:
            verify_steps = live["completion_tokens"] - accepted
            spec_n = drafted / verify_steps
            batch_positions = spec_n + 1.0
            tokens_per_step = live["completion_tokens"] / verify_steps

    an = analytic_bytes(
        model_dir, batch_positions, n_experts, top_k, text_cfg["num_hidden_layers"]
    )

    gib = 1024 ** 3
    print()
    print(f"model dir  : {model_dir}")
    print(f"experts    : {n_experts} routed, top-{top_k} per token")
    print(f"shards     : {an['shards']}")
    print()
    print("--- resident weight bytes (whole model, both ranks) ---")
    for k in ("dense", "routed_expert", "embedding", "unused_mtp"):
        print(f"  {k:<15}: {an['buckets'][k] / gib:8.2f} GiB")
    print(f"  {'TOTAL':<15}: {an['resident_bytes'] / gib:8.2f} GiB")
    print()
    print("--- bytes swept per forward pass ---")
    print(f"  batch positions per step : {batch_positions:.2f}")
    print(f"  distinct experts touched : {an['expected_experts']:.1f} of {n_experts}"
          f"  ({an['expert_fraction'] * 100:.1f}%)")
    print(f"  active bytes (all ranks) : {an['active_bytes'] / gib:.2f} GiB")
    print(f"  active bytes per rank    : {an['active_bytes'] / args.tp / gib:.2f} GiB"
          f"   (TP{args.tp}; both ranks stream concurrently)")

    if args.analytic_only:
        per_rank = an["active_bytes"] / args.tp
        ceiling = GB10_BW_GBPS * 1e9 / per_rank
        print()
        print(f"  roofline at {GB10_BW_GBPS:.0f} GB/s/node:"
              f" {ceiling:.1f} forward passes/s")
        print(f"  = {ceiling:.1f} tok/s with no speculation,"
              f" {ceiling:.1f}x(accepted+1) with a drafter")
        return 0

    decode_rate = live["completion_tokens"] / live["decode_seconds"]
    step_rate = decode_rate / tokens_per_step
    per_rank = an["active_bytes"] / args.tp
    achieved = per_rank * step_rate  # bytes/s per node
    pct = achieved / (GB10_BW_GBPS * 1e9) * 100

    print()
    print("--- measured ---")
    print(f"  TTFT               : {live['ttft']:.3f} s")
    print(f"  output tokens      : {live['completion_tokens']}")
    print(f"  decode             : {decode_rate:.2f} tok/s")
    if drafted > 0:
        print(f"  draft acceptance   : {accepted / drafted * 100:.1f}%"
              f"  ({accepted:.0f}/{drafted:.0f}), num_spec ~= {spec_n:.1f}")
        print(f"  tokens per step    : {tokens_per_step:.2f}"
              f"   <- this is the whole speculative win")
    else:
        print("  draft acceptance   : (not speculating)")
    print(f"  forward passes/s   : {step_rate:.2f}")

    print()
    print("--- bandwidth ---")
    print(f"  implied read rate  : {achieved / 1e9:.1f} GB/s per node"
          f"  ({pct:.1f}% of {GB10_BW_GBPS:.0f})")
    for key, label in (("rank0", "rank 0 (head)"), ("rank1", "rank 1 (worker)")):
        d = dmon.get(key)
        if d is None:
            continue
        if "error" in d:
            print(f"  {label:<18}: dmon unavailable ({d['error']})")
            continue
        # mem% is deliberately not shown: GB10 reports 0 for it always.
        print(f"  {label:<18}: sm {d['sm']:.0f}% (peak {d['sm_max']:.0f}%),"
              f" {d['pwr']:.0f} W, n={d['n']}")

    print()
    ceiling = GB10_BW_GBPS * 1e9 / per_rank * tokens_per_step
    print(f"  roofline at this acceptance: {ceiling:.1f} tok/s"
          f"   (we are at {decode_rate / ceiling * 100:.0f}% of it)")
    print()
    print("Reading it: a busy sm% alongside an implied rate well under 273 GB/s")
    print("means the sweep is real but scattered -- eager mode plus 58 separate")
    print("expert reads per step. An IDLE sm% means we are stalling instead, on")
    print("the fabric all-reduce or on kernel launch, and there is bandwidth left")
    print("to claim. Note the implied rate is a lower bound: it charges only")
    print("weights, not KV reads or activations.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
