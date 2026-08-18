# DeepSeek-V4-Flash-0731 verification — 2026-08-18

## Reproduced stack

- Nodes: `gx10-64b7` (rank 0) + `gx10-08bb` (rank 1), one GB10 each, TP=2
- Recipe commit: `2d4820f025d2e8eb118cdecb07ccafdd0587aa48`
- Model snapshot: `7872f01b1d1fe23eabc4c98b48bffcef5a386062`
- Model size: 155.44 GiB; all 48 shards loaded on both ranks
- Runtime: vLLM `0.21.1rc1.dev339+g1967a5627bc3`
- Image ID on both nodes: `sha256:bc3ed5808d10c0054fa2ff814c65191d540fff3548a3f5c519f978a356785ab3`
- Patch 4 (shared-expert loader), Patch 5 (reasoning stop guard), and the three-level reasoning-effort fix from upstream PR #24 commit `8bceae3`: verified in both images
- Profile: 1,048,576 context, 12 sequences, 8,192 batched tokens, GMU 0.85, DSpark k=5, NVFP4 KV
- Prefix caching: enabled in the rendered command and producing live cache hits
- MoE backend: `Using 'B12X' Mxfp4 MoE backend` on both ranks

The current post-fix boot reported a 2,936,309-token shared KV pool and 2.80x maximum concurrency for a full 1,048,576-token request. Actual CUDA graph memory was 1.13 GiB. Neither container restarted or OOM-killed during the tests.

## Method

Decode measurements used non-streaming OpenAI chat requests and authoritative `usage.completion_tokens / wall time`. Server `vllm:generation_tokens_total` deltas matched client token counts. SSE chunks were not counted as tokens. Thinking was disabled unless a test explicitly exercised reasoning.

## Exact advertised peak shape

Prompt: `Count from 1 to 300, separated by commas.`

- 899 tokens / 11.353 s = **79.19 tok/s**
- Server counter: **79.19 tok/s**
- Draft acceptance: **98.94%** (747 / 755)
- Accepted output: complete 1 through 300

This directly reproduces the recipe's published 78.4 tok/s result for the same prompt shape. A post-reasoning-fix regression run measured **86.35 tok/s** with 99.07% acceptance and complete output, confirming no thinking-off performance regression.

## Single-stream by content

| Shape | Tokens | Seconds | tok/s | Draft acceptance |
|---|---:|---:|---:|---:|
| Repeated SQL structure | 1,500 | 17.701 | **84.74** | 98.97% |
| Binary-search-tree code | 600 | 8.498 | **70.60** | 76.77% |
| Original prose | 267 | 7.858 | **33.98** | 26.03% |

Arithmetic mean: **63.11 tok/s**. The large content-dependent spread is expected: DSpark speed is acceptance-driven, so prose is not a 60 tok/s workload.

The recipe's full `benchmarks/bench_full.py` harness measured:

- Decode: **89.0 peak / 71.5 mean tok/s** across five shapes
- Concurrency aggregate: c1 70.8, c2 97.4, c4 178.3, c6 154.5 tok/s
- Prefill: 1,562 tok/s at 8K; 2,362 at 32K; 2,681 at 100K

## Twelve-sequence check

Two fixed-256-token rounds per concurrency produced these ranges:

| Concurrency | Successful | Aggregate tok/s range |
|---:|---:|---:|
| 1 | 2/2 | 57.3–58.4 |
| 2 | 4/4 | 89.4–96.9 |
| 4 | 8/8 | 130.2–130.5 |
| 6 | 12/12 | 85.9–163.4 |
| 12 | 24/24 | **179.9–209.5** |

A separate agent-sanity sweep passed through c12 with **0 bad outputs** (no CJK drift, repetition, template leakage, or empty content). Its harder agent-shaped c12 workload measured 110.2 aggregate / 10.5 mean per stream, demonstrating why 12 slots are a burst ceiling rather than twelve independent 60 tok/s lanes.

## Integration and correctness

- Direct OpenAI function call: emitted a valid `get_weather({"city":"Paris, France"})` call
- OMP 17.3.5: model registry loaded and a real Bash tool round-trip returned `DGX_TOOL_OK`
- True effort mapping: before `low/high/max = 5/5/84` prompt tokens; after `5/84/97`. Low remained byte-identical, and high/max now use the checkpoint's distinct native prefixes.
- OMP `--thinking max` consumed exactly 92 more prompt tokens than `--thinking low` (97 - 5), proving OMP reaches the corrected true-max path.
- Max-effort tool parsing emitted a valid `get_weather` call with structured reasoning.
- Patch 5 reproducer: a client stop string deliberately emitted inside reasoning did not truncate reasoning; final content was `FINAL=42`
- Prefix cache counters showed real hits, not merely a configured flag
- RDMA preflight: 109.2 Gb/s (one QP), 111.6 Gb/s (eight QPs), GID 3 / RoCE v2; zero RDMA and interface errors
- Busy clocks were symmetric (about 2,492 MHz mean on each node); maximum observed temperature was 83 C

## Soak

Ten minutes of sustained mixed four-way agent traffic completed **163 requests / 58,176 generated tokens** at 24.9 tok/s mean per request, with zero soft-empty outputs, zero degenerate outputs, zero request errors, zero OOMs, and zero container restarts.

## Caveats

- `MAX_NUM_SEQS=12` / GMU 0.85 is the aggressive C12 profile. It passed this verification, but the upstream recipe recommends 6 / 0.78 for longer production stability testing.
- This verifies serving, speed, concurrency, tools, 100K prefill, and short-soak behavior. It is not a full 1M-token retrieval-quality evaluation.
- The supported 3003 MHz graphics-clock lock is reset by reboot; use `lock-gpu-clock.sh` on both nodes before comparing throughput.
