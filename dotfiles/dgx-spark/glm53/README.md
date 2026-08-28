# GLM-5.3-Flash NVFP4 on the DGX Spark pair

Serves [local-inference-lab/GLM-5.3-Flash-NVFP4](https://huggingface.co/local-inference-lab/GLM-5.3-Flash-NVFP4)
(320B total / 18B active, NoPE-MLA + KDA hybrid) across both GX10 nodes at
tensor-parallel 2, on `:8888` — the same port DeepSeek uses, because only one
of the two models is ever resident.

The patch stack is from [tonyd2wild/GLM-5.3-Flash-NVFP4-DFlash2-2x-DGX-Spark](https://github.com/tonyd2wild/GLM-5.3-Flash-NVFP4-DFlash2-2x-DGX-Spark),
whose `docs/DEPLOY-REPORT.md` root-causes each of the seven day-0 bugs this
image works around. Stage numbering matches his through v9 so the
cross-references hold; v10–v13 are ours, and v14 is his DFlash2 overlay
(his `sm121-v11-dflash2`) restacked on top of them.

Speculative decoding is **DFlash2**, not the checkpoint's MTP head — see
"Speculative decoding" below for why that reversal matters here.

## Bring-up

Everything below runs on node1 (the head) after `dotfiles/dgx-spark/deploy.sh`.

```bash
cd ~/dspark-recipe/glm53

./fetch-glm53-weights.sh --watch     # download once, then mirror over the fabric
./fetch-glm53-weights.sh draft       # DFlash2 drafter, 2.3 GiB, both ranks
./build-glm53-runtime.sh --ship      # build 12 stages, verify, copy to worker
~/dspark-recipe/model-select.sh glm53
```

Both ranks need the weights on local disk — NFS-mounted ranks are reliably the
ones that die when the KV slab is carved, because NFS client memory resists
kernel reclaim harder than page cache does. That is an argument for two copies,
not two downloads: the fetch script pulls ~186 GiB from HuggingFace once, then
mirrors it to the worker over the 200 Gb/s fabric, where the cost is NVMe and
ssh crypto rather than WAN bandwidth.

First boot after that is roughly 15 minutes: ~10 for weight load, ~3 for warmup
JIT. Subsequent boots are the same — the JIT caches persist, the load does not.

## Day-to-day

`model-select.sh` is the only command needed after that:

```bash
model-select.sh            # menu
model-select.sh glm53      # switch to GLM
model-select.sh deepseek   # switch back
model-select.sh status     # what is up
```

It always stops the outgoing model before starting the incoming one. That
matters beyond tidiness: both stacks run `restart: unless-stopped`, so a
container merely *stopped* rather than *downed* comes back after the idle
monitor's overnight poweroff, and two half-models will not fit.

## Things that will bite

**Tune `MAX_MODEL_LEN` against the KV pool you actually get.** The shipped
config targets jack6464's measured TP2 profile (NVIDIA forum, GLM-5.3-Flash
thread post 22): 200,000-token limit, 848,717-token pool, 4.24× — four full
200K sessions guaranteed, a fifth when contexts are short. But he measured that
on a "native SM12x extension" build he doesn't identify, plus InstantTensor
loading; this image is Tony's FlashInfer-SM90-extended-to-SM121 stack, which
measured 507,041. `start-glm53.sh` prints the real pool after a successful
boot. Concurrency is exactly `pool / MAX_MODEL_LEN` — if the ratio comes back
under ~4×, lower `MAX_MODEL_LEN` until it doesn't.

**Take vLLM's own `--kv-cache-memory` number.** GB10 has no VRAM — every GPU
allocation is host DRAM through a driver path that fails outright rather than
reclaiming clean page cache. vLLM meanwhile reports "free memory" as psutil
*available*, which counts reclaimable cache, so it will happily suggest pools
the driver cannot deliver. Upstream's ladder on the smaller quant: 4.14 GiB
worked 3/3, and all five attempts at ≥5.5 GiB killed a rank with
`NVRM: NV_ERR_NO_MEMORY`. `KV_CACHE_MEMORY` in `.env.glm53` starts empty (let
vLLM choose); pin it to the number vLLM prints once you have seen a good boot.

**This quant is 4.4 GiB larger than the one upstream validated** — 185.7 GiB
vs 181.3 GiB, so ~2.2 GiB more per rank. That comes straight out of the same
budget the KV slab is carved from. If a rank dies during warmup, the levers in
order: let vLLM pick `KV_CACHE_MEMORY` (or lower it), lower `MM_LIMIT_IMAGE`
/`MM_LIMIT_VIDEO` to 2/0, then lower `MAX_MODEL_LEN`. Dropping the drafter
(`SPEC_METHOD=none`) is far down that list, not up it: it frees 2.3 GiB of
weights and no KV pool at all, so it is the smallest lever available.

**Speculative decoding: DFlash2, and MTP is off.** `SPEC_METHOD` picks between
`dflash`, `mtp` and `none`.

MTP was measured on this pair and *lost*: it bought +18% single-stream at N=3
and paid for it twice at concurrency — speculation competes with a full batch,
and the draft head cost ~4.3 GiB, roughly halving the KV pool.

|          | c1 solo | c5 aggregate | KV pool | slots @200K |
|----------|---------|--------------|---------|-------------|
| off      | 14.62   | 52.43        | 1,943,396 | 9.7 |
| MTP N=3  | 17.22   | 45.59        | 1,093,333 | 5.5 |
| MTP N=5  | 13.54   | 37.89        | 1,121,212 | 5.6 |

DFlash2 wins on the throughput axis and roughly ties on the memory one. It is a
separate 2.3 GiB block-diffusion drafter that proposes a whole 8-token block and
refines it, rather than re-running a single nextn layer autoregressively, so it
sustains far longer accepted runs. Measured on this pair, thinking on except
where noted, against a 14.62 tok/s no-drafter baseline:

| output regime | tok/s | acceptance |
|---|---|---|
| structured list (count 1–200) | 37.41 | 98.7% |
| Python source | 27.42 | 60.8% |
| JSON tool arguments | 27.27 | 54.6% |
| prose, thinking off | 25.26 | 47.4% |
| prose, thinking on | 23.65 | 45.5% |

and at concurrency, at the shipped `DFLASH2_NUM_TOKENS=3`:

| | no drafter | DFlash2 N=7 | **DFlash2 N=3** |
|---|---|---|---|
| c1 per-stream | 14.62 | 23.38 | **30.33** |
| c5 aggregate | 52.43 | 56.37 | **72.61** |
| c5 TTFT | — | 1.347 s | **0.774 s** |
| KV pool | 1,547,169 | 832,941 | **1,026,086** |

**2.07× the no-drafter baseline at c1**, and the c5 aggregate sits 29% above
upstream's own DFlash2 peak of 56.2. See `DFLASH2_NUM_TOKENS` in `env.glm53`
for why 3 beats the 7 upstream ships — briefly: fewer draft positions sweep far
fewer distinct experts, *and* the drafter is materially more accurate at the
positions it does propose, because block diffusion denoises them jointly.

**On KV pool cost, be precise about which claim is which.** The drafter's five
sliding-window layers do slot-share the MLA tensors the way GLM's mamba layers
do, so *per-block* pool bytes are bit-identical to running with no drafter —
the build's simulation harness asserts exactly that
(`bytes/block unchanged by drafter`). But the drafter's *weights and workspace*
come out of the same unified-memory budget the KV slab is carved from, and that
does shrink the pool: 1,547,169 tokens (7.7× at 200K) without it,
**832,941 tokens (4.16×)** with it — consumed memory 92.1 → 97.4 GiB per rank,
peak activation 2.63 → 2.97 GiB. That is a similar bill to MTP's, so the
argument for DFlash2 over MTP is the throughput, not the memory.

4.16× still clears the ≥4× rule below, and real traffic here averages ~41K-token
prompts, where the pool seats about twenty sessions rather than four.

The drafter must be present on **both** ranks; `start-glm53.sh` refuses to
launch otherwise, because the alternative is a rank-1 death fifteen minutes
into a boot with nothing useful in the head's log.

**A miswired drafter does not crash — it degrades silently.** Shapes stay
valid, the drafter consumes garbage features, and decode still "works", just
slower than with no drafter at all. Three things prove the wiring, and
`start-glm53.sh` prints the first two after every boot:

- the aux-capture layer ids log as `(6, 15, 25, 34, 43)` — the runner's `+1`
  over the drafter config's `[5, 14, 24, 33, 42]`;
- the rejection sampler warms up at `num_spec=7`;
- draft acceptance stays clear of the broken-glue signature, which pins it near
  0.15 on *every* regime. `gate-glm53.py` fails the run under 0.35;
  `vllm-stats.sh` reports acceptance length, which should sit well above 1.0.
  Gated at 37.4% / 3.61 across the full gate suite on this deployment.

### Why our acceptance is below upstream's, and what is ruled out

Upstream's headline is 46.9 tok/s at 74.1% acceptance. That is a hand-picked
warm single-stream best case; his own repeatable harness
(`docs/BENCH-C1-C6-DFLASH2.md`, six code/reasoning prompts, temp 1.0/top-p 0.95)
reports **C1 = 35.1 tok/s at 0.525**. Running those exact prompts at those exact
settings here gives **20.93 tok/s at 0.381**.

The gap is entirely acceptance, not engine speed — decomposing his 46.9 gives
7.58 target forward passes/s against our 8.09, so **our sweep is 6.7% faster**.

vLLM's per-position rates are MARGINAL, not conditional: mean acceptance length
is exactly `1 + sum(per_position)`, verified against all three datasets below.

| position | 1 | 2 | 3 | 4 | 5 | 6 | 7 | acc.len |
|---|---|---|---|---|---|---|---|---|
| ours, code (fp8 drafter KV) | 0.735 | 0.521 | 0.325 | 0.239 | 0.137 | 0.103 | 0.085 | 3.15 |
| ours, structured (fp8 drafter KV) | 0.971 | 0.900 | 0.857 | 0.843 | 0.800 | 0.757 | 0.714 | 6.84 |
| upstream, code (**bf16** drafter KV) | 0.770 | 0.640 | 0.590 | 0.520 | 0.460 | 0.390 | 0.360 | 4.90 |

What this rules out:

- **The target-side glue.** Position 1 matches upstream (0.735 vs 0.770). A wrong
  aux-layer tap or a wrong mHC contraction would tank position 1 first.
- **The candidate selector.** On structured output our curve is nearly flat
  (0.971 → 0.714), so the selector demonstrably holds a coherent path when the
  drafter has signal. Its three weights (`predecessor_codebook`,
  `successor_codebook`, `hidden_projection.weight`) are present in the
  checkpoint and the module names match exactly.
- **The quant.** Both NVFP4 checkpoints quantize *only* the routed experts;
  attention, shared experts, dense MLP, lm_head and embed stay bf16 in each. The
  sole difference is layer 45's experts (MXFP8 here, NVFP4 there) — the MTP head,
  which DFlash2 never runs.
- **Thinking.** `chat_template_kwargs: {"enable_thinking": false}` genuinely
  works on this checkpoint (reasoning 1291 chars → 0), so the regime table above
  is labelled correctly.

What remains: the flat upstream curve is published for the lane where the
drafter's KV is explicitly kept **bf16** (`--kv-cache-dtype-skip-layers
sliding_window` — "the drafter's KV must stay bf16"). Ours is fp8, because
`--kv-cache-dtype fp8_e4m3` applies to its five sliding-window layers too.

Testing that needs a patch first: `patch_glm5_drafter_group.py` returns None if
any drafter spec carries `page_size_padded`, and the skip-quant branch stamps
exactly that. Upstream hit this and describes the fix ("strip the inherited
padding before any geometry math") in the NVFP4-KV lane notes, but did not ship
it in the overlay.

**Thinking stays on.** Upstream's launcher passes
`--default-chat-template-kwargs '{"enable_thinking": false}'`; his own deploy
report then documents why that is wrong for agent harnesses — with thinking
off GLM emits untagged reasoning prose straight into `content`, and there is
nothing for `--reasoning-parser glm45` to split. Left on, the monologue lands
in `reasoning` and `content` carries only the answer. Disable per-request with
`chat_template_kwargs: {"enable_thinking": false}` if you ever want it off.

**Vision is on, and needs no template override here.** GLM-5.3-Flash is
natively multimodal, and *this* quant's shipped `chat_template.jinja` already
emits the placeholders vLLM's multimodal processor scans for. Upstream needed a
hand-written `chat_template_mm.jinja` because the LibertAIDAI checkpoint ships
a text-only template that renders images as an "unable to process this image"
reminder — a quant-specific problem this one does not have. Video is disabled
by default (`MM_LIMIT_VIDEO=0`): one video can encode up to 240,000 tokens,
nearly 2× the whole context window.

**`--block-size 2304` is not a tuning knob.** DeepGEMM's arch-12 fp8 paged-MQA
accepts only 64-entry pool pages; 2304 is the smallest size satisfying that and
the MLA 128 alignment. Changing it reintroduces an assert death in warmup.

**Never leave one rank up.** A new rank that rendezvouses with a dying one
hangs or dies confusingly. `stop-glm53.sh` always downs both, and
`model-select.sh` always calls it. Capture `docker logs` *before* any teardown
— NVRM failures surface minutes after the event that caused them.

**Image skew between ranks is a real failure mode** and produces garbage output
rather than an error. `build-glm53-runtime.sh --ship` compares image IDs after
copying, and `start-glm53.sh` refuses to launch unless they match.

## The bandwidth roofline (read this before chasing tok/s)

Decode here is memory-bandwidth bound, and knowing the ceiling stops a lot of
wasted tuning. `roofline-glm53.py --analytic-only` reads it straight out of the
safetensors headers:

```
dense weights            17.67 GiB   swept every forward pass
routed experts          159.47 GiB   only top-8 of 288 per token
MTP head (unused)         7.31 GiB   resident, never swept under SPEC_METHOD=dflash
embedding                 1.18 GiB   a gather, not a sweep

active bytes per pass    22.10 GiB   -> 11.05 GiB per rank at TP2
roofline at 273 GB/s      23.0 forward passes/s
```

So **23 tok/s is the hard ceiling for unspeculated single-stream decode**, and
the 14.62 tok/s measured with no drafter is 64% of it. There was never 60 tok/s
of headroom to find in kernels — the only way past 23 is to carry more than one
token through each weight sweep.

That is exactly what speculation buys, and it is why the drafter's *acceptance*
matters more than its draft depth. The catch the arithmetic exposes: a verify
step holding 8 positions touches ~58 distinct experts rather than 8, so the
sweep grows to ~25 GiB per rank. Tokens per step multiply by ~5; bytes per step
multiply by ~2.3; the net is ~2.3×, not ~5×. Roofline with a drafter at 74%
acceptance is therefore around 57 tok/s, not 115.

Measured with DFlash2 on a prose prompt (`./roofline-glm53.py --worker 169.254.54.207`):

```
batch positions per step    8.05     -> 58.4 of 288 experts touched
active bytes per rank      25.01 GiB
forward passes/s            7.85
implied read rate         211.0 GB/s per node   (77.3% of 273)
sm                         94% on both ranks
```

**Do not score this against 273.** That is the datasheet number, and no LPDDR
system attains its peak. `membw-glm53.py` measures what this part actually
delivers with STREAM-style kernels:

```
read (reduction)   231.5 GB/s
copy (read+write)  190.5 GB/s
attainable         231.5 GB/s   =  84.8% of the 273 datasheet
```

The missing 15% is refresh and read/write turnaround — normal, and not
recoverable. Re-scored against the honest denominator:

| | tok/s | step | weight sweep | fixed | % of datasheet | **% of attainable** |
|---|---|---|---|---|---|---|
| N=7 | 22.77 | 127.4 ms | 115.6 ms | 11.8 ms | 76.9% | **90.7%** |
| N=3 | 26.70 | 99.2 ms | 80.4 ms | 18.8 ms | 68.7% | **81.0%** |

So at N=7 decode was already at **91% of what the part can deliver** — there
was no bandwidth headroom to find, and the apparent 23% gap was mostly the
wrong denominator. The fall to 81% at N=3 is not a regression: shrinking the
sweep makes the *fixed* per-step cost a larger fraction, so utilisation drops
while throughput rises 30%.

What is actually left is **~19 ms per step of non-sweep cost (19% of the
step), worth at most ~1.23×** — attention, the TP2 all-reduce across the
fabric, and eager-mode launch. That also retires the CUDA-graphs idea: graphs
address only one slice of that 19 ms, and the fabric all-reduce is structural
to running TP2 across two machines.

Two measurement traps worth knowing. `mem%` from `nvidia-smi dmon` is useless
on GB10 — with no separate framebuffer the driver reports 0 regardless of load,
which is why the script does not print it. And run `membw-glm53.py` with small
buffers while the engine is resident: at ~2.4 GB free, a full-size probe will
OOM the engine, and on GB10 that wedges the node.

## What is deliberately not here

- **v2** — upstream's env-gated NaN-localizer debug build. It is a side branch
  off v1, not a link in the chain; his README's "v1..v7 in order" is wrong on
  this point, and the `FROM` lines in his Dockerfiles are what to trust.
- **v9 / InstantTensor** (`--load-format instanttensor`) — loads 15× faster,
  then kills a rank silently 60–90 s later in every multi-node TP2 boot
  upstream tried, including at KV budgets that are otherwise stable.
- **`radixark/vllm-glm53-flash`** — upstream's prebuilt images are not publicly
  pullable, which is why `build-glm53-runtime.sh` exists.

## Files

| File | Purpose |
|---|---|
| `env.glm53` | All tunables, deployed as `.env.glm53`. Read the KV comment first. |
| `docker-compose.glm53.yml` | Serve args and container/NCCL environment. |
| `build-glm53-runtime.sh` | Chains the 12 patch stages onto the day-0 image, verifies 24 checks, ships. |
| `fetch-glm53-weights.sh` | Downloads ~186 GiB once on the head, mirrors it to the worker over the 200 Gb/s fabric, verifies both. `draft` fetches the DFlash2 drafter on both. |
| `start-glm53.sh` / `stop-glm53.sh` | Worker-first bring-up; both-ranks teardown. |
| `patches/` | Our v10–v13 source patches, each guarded on an exact match. |
| `overlay-dflash2/` | Upstream's DFlash2 overlay, vendored verbatim: the drafter model, the speculator, four anchored patches, and the KV-geometry simulation the build runs. |
| `gate-glm53.py` | Production gates: deep decode cold/warm, concurrent prefills, vision, draft acceptance, health. |
| `bench-glm53.py` | TTFT / per-stream / aggregate tok/s at chosen concurrency levels. |
| `roofline-glm53.py` | Bytes swept per forward pass, achieved read rate, and a draft-depth sweep derived from the live per-position acceptance curve. |
| `membw-glm53.py` | What memory bandwidth this GB10 *actually* attains, so the roofline has an honest denominator. Run it with small buffers — see the bandwidth section. |
