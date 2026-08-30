# NVFP4 baseline — real omp traffic, for comparison against EXL3

Scraped from `/metrics` on the outgoing NVFP4 stack immediately before it was
stopped on 2026-08-30, after ~8 h of ordinary omp use. **n = 545 requests.**
These counters are cumulative per server process, so they died with the
container; this file is the only surviving copy. Re-scrape the same fields on
EXL3 with `vllm-stats.sh` and compare like-for-like.

This is deliberately *not* a benchmark. It is what the pair actually did under
the real harness, which is the only workload whose shape matters here: very
long prompts that are mostly cache hits, and outputs 3x longer than a synthetic
c1 prose bench assumes.

## Serving config that produced it

| | |
|---|---|
| checkpoint | local-inference-lab/GLM-5.3-Flash-NVFP4 |
| max-model-len | 200,000 |
| max-num-seqs | 5 |
| speculation | DFlash2, `DFLASH2_NUM_TOKENS=3` |
| KV dtype | fp8_e4m3 |
| gpu-memory-utilization | 0.90 |
| max-num-batched-tokens | 4096 |
| CUDA graphs | **off** (`enforce_eager=True`, commit b7aff60) |

## Measured

| metric | value | derivation |
|---|---:|---|
| avg prompt | 88,344 tok | 48,147,647 / 545 |
| avg output | 1,513 tok | 824,589 / 545 |
| avg TTFT | 10.34 s | 5,655.10 / 547 |
| avg decode time | 76.75 s | 41,830.09 / 545 |
| avg queue time | 1.42 s | 775.48 / 545 |
| avg e2e latency | 87.11 s | 47,478.13 / 545 |
| **effective throughput** | **17.37 tok/s** | 824,589 / 47,478.13 |
| decode-only rate | 19.71 tok/s | 824,589 / 41,830.09 |
| prefix cache hit rate | 86.0% | 41,462,784 / 48,207,953 |
| cold prefill | 1,497 tok/s + 0.23 s fixed | `prefill-scaling.py` linear fit |

## The two facts that matter for reading any EXL3 result

**Decode is 88% of the wall clock**, prefill 12% (76.75 s vs 10.34 s). The
prompts are enormous but 86% cache-hit, so only ~12.4k tokens actually prefill.
Any change that moves decode passes through to end-to-end nearly 1:1; any
change that moves prefill is capped at ~12%.

**Cold prefill was already at parity with the EXL3 recipe** (1,497 tok/s
measured here vs its published ~1,400-1,490 @133k), so prefill was never the
axis with headroom on this hardware.

## Gap in this baseline

Speculative-decode acceptance was **not** captured from this sample --
`spec_decode_num_accepted_tokens_total` / `_draft_tokens_total` were not
scraped before shutdown. The only acceptance figures for the NVFP4 stack are
from the gate suite (37.4% / 3.61 accept length), not from live traffic, so the
live acceptance comparison against EXL3 starts fresh. Scrape both counters on
EXL3 from the first day so this gap does not repeat.
