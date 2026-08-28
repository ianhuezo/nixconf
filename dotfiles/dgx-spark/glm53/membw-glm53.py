#!/usr/bin/env python3
"""What memory bandwidth can this GB10 ACTUALLY reach?

roofline-glm53.py compares the implied read rate against GB10's datasheet
273 GB/s. That is the right denominator for "how much did we pay for", but the
wrong one for "how much is left on the table": no LPDDR system attains its peak
number. Refresh, bank conflicts and read/write turnaround typically cost
15-20%, so a kernel at 77% of peak may already be at ~92% of what the part can
actually deliver -- and chasing the difference would be chasing nothing.

This measures the real ceiling with STREAM-style kernels, so the roofline has
an honest denominator.

Run it with the engine DOWN, or at least idle. It allocates several GiB and
saturates the bus by construction; sharing the machine with a live engine
measures the contention, not the ceiling.

  ./membw-glm53.py                # inside the runtime container
  ./membw-glm53.py --gib 4
"""

import argparse
import sys

import torch


def timed(fn, warmup=3, iters=10):
    for _ in range(warmup):
        fn()
    torch.cuda.synchronize()
    start = torch.cuda.Event(enable_timing=True)
    end = torch.cuda.Event(enable_timing=True)
    start.record()
    for _ in range(iters):
        fn()
    end.record()
    torch.cuda.synchronize()
    return start.elapsed_time(end) / iters / 1000.0  # seconds


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--gib", type=float, default=4.0, help="working-set size per buffer")
    ap.add_argument("--dtype", default="bfloat16", choices=["bfloat16", "float16", "uint8"])
    args = ap.parse_args()

    if not torch.cuda.is_available():
        print("no CUDA device", file=sys.stderr)
        return 1

    dev = torch.device("cuda")
    dtype = getattr(torch, args.dtype)
    itemsize = torch.empty((), dtype=dtype).element_size()
    n = int(args.gib * (1024 ** 3) // itemsize)

    name = torch.cuda.get_device_name(0)
    print(f"device     : {name}")
    print(f"buffer     : {args.gib:.1f} GiB of {args.dtype}  ({n:,} elements)")
    print()

    a = torch.randn(n, device=dev, dtype=torch.float32).to(dtype) if dtype != torch.uint8 \
        else torch.randint(0, 255, (n,), device=dev, dtype=torch.uint8)
    b = torch.empty_like(a)

    gib = 1024 ** 3
    results = []

    # read-only: a reduction touches every byte once and writes ~nothing.
    # This is the number that matters for decode, which is read-bound.
    t = timed(lambda: torch.sum(a.view(torch.int8) if dtype == torch.uint8 else a))
    results.append(("read (reduction)", a.numel() * itemsize, t))

    # copy: reads a, writes b -- 2x the traffic.
    t = timed(lambda: b.copy_(a))
    results.append(("copy (read+write)", 2 * a.numel() * itemsize, t))

    # scale: read + write, with arithmetic, closest to a real weight sweep.
    if dtype != torch.uint8:
        t = timed(lambda: torch.mul(a, 2.0, out=b))
        results.append(("scale (read+write)", 2 * a.numel() * itemsize, t))

    print(f"{'kernel':<22} {'bytes moved':>14} {'time':>9} {'GB/s':>9}")
    print("-" * 58)
    peak = 0.0
    for label, nbytes, secs in results:
        gbps = nbytes / secs / 1e9
        peak = max(peak, gbps)
        print(f"{label:<22} {nbytes / gib:>11.2f} GiB {secs * 1e3:>7.2f}ms {gbps:>8.1f}")

    print()
    print(f"attainable  : {peak:.1f} GB/s")
    print(f"datasheet   : 273.0 GB/s")
    print(f"efficiency  : {peak / 273.0 * 100:.1f}% of peak")
    print()
    print("Use the ATTAINABLE number as the roofline denominator. Comparing a")
    print("real kernel against the datasheet figure overstates the headroom by")
    print("whatever the memory system loses to refresh and turnaround.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
