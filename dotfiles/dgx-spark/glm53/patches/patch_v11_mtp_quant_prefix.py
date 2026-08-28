"""Let the MTP draft model find its quantization group, so MTP can be enabled.

Without this, MTP is unusable on this checkpoint: the engine dies at draft-model
load with

    ValueError: moe_backend='marlin' is not supported for unquantized MoE.

...and MTP is worth roughly 23 vs 14.6 tok/s single-stream, so losing it is the
difference between a snappy interactive model and a sluggish one.

The mechanism is a naming asymmetry, not a memory or kernel problem:

  * The checkpoint is multimodal, so every text-tower tensor is named
    "model.language_model.layers.N.*", and hf_quant_config.json's targets use
    that same form. This quant puts the MTP layer's experts in their own MXFP8
    group ("model.language_model.layers.45.mlp.experts") while layers 3-44 are
    NVFP4.

  * The MTP draft model is built STANDALONE, with prefix "model.layers.45"
    (mtp.py: f"{prefix}.layers.{idx}", idx = num_hidden_layers = 45). It drops
    the "language_model" segment the multimodal wrapper adds.

  * mtp.py's load_weights already compensates for this when loading TENSORS:
        if name.startswith("model.language_model."):
            name = name.replace("model.language_model.", "model.", 1)
    ...but nothing applies the inverse mapping when resolving the QUANT GROUP.

So the weights load fine while _resolve_quant_algo misses, returns None, and
RoutedExperts falls back to UnquantizedFusedMoEMethod -- whose backend list
does not include marlin. The crash names the backend, which is why this looks
like a backend problem and isn't.

Fix: teach _quantized_layer_prefix_candidates the same rename load_weights
already does, in reverse. It only ever APPENDS a candidate, consulted after a
direct hit fails, so a model that genuinely has "model.layers.N" in its quant
config is unaffected.

Verified upstream-adjacent facts before writing this:
  - ModelOptMxFp8FusedMoE exists (modelopt.py, RoutedExperts branch), so MXFP8
    MoE is a real path, not a hypothetical one.
  - oracle/mxfp8.py _SUPPORTED_BACKENDS includes Fp8MoeBackend.MARLIN, so the
    main model keeps the validated marlin backend and the draft can share it.
"""

from pathlib import Path

p = Path(
    "/usr/local/lib/python3.12/dist-packages/vllm"
    "/model_executor/layers/quantization/modelopt.py"
)
s = p.read_text()

old = '''        elif prefix.startswith("model.language_model."):
            candidates.append(
                "language_model.model." + prefix[len("model.language_model.") :]
            )

        return tuple(dict.fromkeys(candidates))'''

new = '''        elif prefix.startswith("model.language_model."):
            candidates.append(
                "language_model.model." + prefix[len("model.language_model.") :]
            )
        elif prefix.startswith("model.layers."):
            # MTP/draft models are built standalone as "model.layers.N", without
            # the "language_model" segment the multimodal wrapper adds, so their
            # experts miss the quant group and silently resolve to unquantized --
            # which then rejects moe_backend=marlin and kills the engine.
            #
            # Both spellings are offered because the key form depends on WHEN
            # this runs. The raw hf_quant_config uses "model.language_model.*",
            # but apply_vllm_mapper rewrites quantized_layers into vLLM's
            # internal "language_model.model.*" before serving. Verified on a
            # live boot: prefix='model.layers.45.mlp.experts' against
            # sample_keys=['language_model.model.layers.10.mlp.experts', ...].
            # Checking only the raw form is a silent no-op in production.
            _tail = prefix[len("model.") :]
            candidates.append("language_model.model." + _tail)
            candidates.append("model.language_model." + _tail)

        return tuple(dict.fromkeys(candidates))'''

if s.count(old) != 1:
    raise SystemExit(
        "unexpected _quantized_layer_prefix_candidates body (match count: %d); "
        "refusing to patch" % s.count(old)
    )

p.write_text(s.replace(old, new))
print("MTP draft-model quant prefix mapping added")
