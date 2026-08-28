"""TEMPORARY DIAGNOSTIC -- not part of the production stack.

Prints the prefix and quant-config state every time a RoutedExperts layer falls
back to UnquantizedFusedMoEMethod. That fallback is what makes
moe_backend=marlin illegal and kills the engine at MTP draft-model load, and
static analysis has now twice produced a plausible-but-wrong theory about which
prefix is actually in play. This prints the answer instead.

Build into a throwaway tag (never the production image), boot once with
--load-format dummy to reach draft construction in ~1 minute instead of ~12,
then read MOEDEBUG lines from the head's log.
"""

from pathlib import Path

p = Path(
    "/usr/local/lib/python3.12/dist-packages/vllm"
    "/model_executor/layers/fused_moe/routed_experts.py"
)
s = p.read_text()

old = """        quant_method = None
        if quant_config is not None:
            quant_method = quant_config.get_quant_method(self, prefix)
        if quant_method is None:
            quant_method = UnquantizedFusedMoEMethod(moe_config)"""

new = """        quant_method = None
        if quant_config is not None:
            quant_method = quant_config.get_quant_method(self, prefix)
        if quant_method is None:
            import sys as _dbg_sys
            _qs = getattr(quant_config, "quantized_layers", None) or {}
            _keys = list(_qs)
            _cands = ()
            try:
                _cands = type(quant_config)._quantized_layer_prefix_candidates(prefix)
            except Exception as _e:
                _cands = ("<err %s>" % _e,)
            print(
                "MOEDEBUG prefix=%r quant_config=%s n_keys=%d cands=%r "
                "hits=%r sample_keys=%r"
                % (
                    prefix,
                    type(quant_config).__name__,
                    len(_keys),
                    _cands,
                    [c for c in _cands if c in _qs],
                    _keys[:3],
                ),
                file=_dbg_sys.stderr,
                flush=True,
            )
            quant_method = UnquantizedFusedMoEMethod(moe_config)"""

if s.count(old) != 1:
    raise SystemExit("unexpected _get_quant_method body; refusing to patch")

p.write_text(s.replace(old, new))
print("MOEDEBUG diagnostic installed")
