"""Stop persistent_topk from hard-crashing decode past ~24K context on SM121.

THE critical fix for this hardware. Without it the engine dies deterministically
on any conversation that crosses roughly 24K tokens -- which every real agent
session does within minutes.

Mechanism: the DSA sparse indexer routes decode-time top-k to
torch.ops._C.persistent_topk whenever select_k is 512, 1024 or 2048.
GLM-5.3-Flash has index_topk=2048 and index_kpool=4, so select_k=512 -- always
eligible. The kernel sizes its CTA grid to the sequence's candidate set; past
~20K tokens of context it oversubscribes GB10's SM budget (total_ctas=124 vs
num_sms*occupancy=48) and falls back to FilteredTopK, which requires 128KB of
shared memory per block. SM121 has 99KB. There is no third path: it raises
RuntimeError -> EngineDeadError, and the endpoint stays dead until a full
relaunch.

Why this masqueraded as an OOM for a full day upstream: the killing requests
were MTP decode steps at ~32,760 computed tokens with kv_cache_usage at 0.018 --
1.8% of the pool -- and dmesg was clean. Every KV-size theory failed because
pool size was never the variable. Gates that prefilled 20K tokens sat just under
the trigger and proved nothing.

Fix: gate the persistent kernel on multi_processor_count >= 78 so small-SM parts
take the existing top_k_per_row_decode fallback, which has no smem wall. GB10
reports 48, so it takes the fallback.

Credit: tonyd2wild, docs/SM121-CRASH-FORENSICS-2026-08-27.md. Upstream ask filed
there: topk.cu:138 should fall back to a multi-wave persistent variant rather
than raising when smem < 128KB.

Applied as a guarded string patch rather than a whole-file bind-mount on purpose.
A bind-mount has to exist and match on BOTH ranks; if it is missing on one, that
rank silently runs the crashing path. Baking it into the image keeps the
"one image, verified identical on both ranks" property the launcher enforces.
"""

from pathlib import Path

p = Path(
    "/usr/local/lib/python3.12/dist-packages/vllm"
    "/model_executor/layers/sparse_attn_indexer_kpool.py"
)
s = p.read_text()

old = "        if current_platform.is_cuda() and select_k in (512, 1024, 2048):\n"
new = (
    "        # SM121/GB10 (48 SMs, 99KB smem): persistent_topk oversubscribes past\n"
    "        # ~24K ctx and its FilteredTopK fallback needs 128KB smem -> hard raise.\n"
    "        # Route small-SM parts to top_k_per_row_decode instead.\n"
    "        if (\n"
    "            current_platform.is_cuda()\n"
    "            and select_k in (512, 1024, 2048)\n"
    "            and torch.cuda.get_device_properties(0).multi_processor_count >= 78\n"
    "        ):\n"
)

if s.count(old) != 1:
    raise SystemExit(
        "persistent_topk dispatch site match count: %d; refusing to patch" % s.count(old)
    )

p.write_text(s.replace(old, new))
print("persistent_topk gated to >=78 SMs (GB10 has 48 -> takes the safe fallback)")
