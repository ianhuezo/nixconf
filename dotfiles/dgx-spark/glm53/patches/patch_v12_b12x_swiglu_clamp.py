"""Make the native SM12x FP4 MoE kernel (b12x) usable for GLM-5.3-Flash.

WHY THIS MATTERS
----------------
Routed experts are the main compute path: 18B active parameters, every token,
prefill and decode. With moe_backend=marlin those matmuls are *weight-only*
FP4 -- weights stored at 4 bits, dequantised to BF16 inside the kernel, BF16
math. The b12x path (FlashInfer PR #3080, FlashInferB12xExperts) instead fuses
dispatch + both GEMMs + SwiGLU + topk reduction into a single kernel and
quantises BF16->FP4 in-kernel, so there is no dequant round trip at all.

WHY IT WAS BLOCKED
------------------
Booting with moe_backend=flashinfer_b12x failed on this pair with:

    ValueError: Model sets swiglu_limit=10.0, but the explicitly requested
    moe_backend='flashinfer_b12x' does not apply the SwiGLU clamp.

GLM-5.3-Flash sets swiglu_limit=10.0 with hidden_act=silu. vLLM's
NVFP4_BACKENDS_WITH_CLAMP set excludes b12x, and that exclusion is CORRECT as
shipped: FlashInfer's gated_activation_f32 applies the clamp only on the
"swigluoai_uninterleave" branch, so a silu model would silently compute
UNCLAMPED activations. Note this is NOT the "upstream CUTLASS SM121 MMA op
guard" the vLLM source comment mentions -- that guard (thrfrg_SFA/thrfrg_SFB,
atom_K in {32,64}) never applies here, since NVFP4 uses atom_K=64.

THE FIX
-------
The clamp is already implemented, just scoped to the wrong branch, and the
existing implementation already matches vLLM's reference semantics exactly.
Verified against BOTH of vLLM's implementations, which agree:

    _swiglu_limit_torch (fused_moe/utils.py):
        gate = clamp(gate, max=limit)
        up   = clamp(up, min=-limit, max=limit)
        out  = silu(gate) * up

    _swiglu_limit_pad_aware_kernel (Triton, same file):
        gate = tl.minimum(gate, limit)
        up   = tl.maximum(up, -limit); up = tl.minimum(up, limit)
        result = (gate / (1 + exp(-gate))) * up

Both clamp PRE-silu, and note the asymmetry that is easy to get wrong: gate
takes an UPPER clamp only, up takes a SYMMETRIC clamp. FlashInfer's swigluoai
branch already does precisely this:

    g = fmin_f32(g, lim)
    u = fmax_f32(fmin_f32(u, lim), Float32(-limit))

and the tail of the function computes ``g * sigmoid(g) * u`` for silu -- which
is silu(gate)*up. So hoisting the clamp so it also covers silu reproduces the
reference bit-for-bit in intent.

Three coordinated changes:
  1. flashinfer moe_activation.py -- apply the clamp for silu, not just swigluoai
  2. vllm flashinfer_b12x_moe.py  -- actually pass swiglu_limit to the wrapper
  3. vllm oracle/nvfp4.py         -- allow b12x when swiglu_limit is set

gelu_tanh is deliberately left untouched: vLLM's reference defines this clamp
for the SwiGLU family, and silently extending it elsewhere would be a guess.

CORRECTNESS IS NOT ASSUMED. A wrong FP4 MoE kernel here does not crash, it
returns fluent wrong text. Validate with moe-compare.py against a marlin
reference before trusting this.
"""

from pathlib import Path

FI = Path(
    "/usr/local/lib/python3.12/dist-packages/flashinfer"
    "/fused_moe/cute_dsl/blackwell_sm12x/moe_activation.py"
)
VL = Path(
    "/usr/local/lib/python3.12/dist-packages/vllm"
    "/model_executor/layers/fused_moe/experts/flashinfer_b12x_moe.py"
)
OR = Path(
    "/usr/local/lib/python3.12/dist-packages/vllm"
    "/model_executor/layers/fused_moe/oracle/nvfp4.py"
)

# --- 1. Hoist the clamp so it covers silu ----------------------------------
s = FI.read_text()
old = '''    if cutlass.const_expr(activation == "swigluoai_uninterleave"):
        if cutlass.const_expr(limit is not None):
            lim = Float32(limit)
            g = fmin_f32(g, lim)
            u = fmax_f32(fmin_f32(u, lim), Float32(-limit))
        sig_arg = Float32(alpha) * g
        up_term = u + Float32(beta)'''
new = '''    # Clamp hoisted out of the swigluoai branch so plain silu gets it too.
    # vLLM's reference (_swiglu_limit_torch and _swiglu_limit_pad_aware_kernel)
    # defines this clamp for silu as well, and GLM-5.3-Flash ships
    # swiglu_limit=10.0 with hidden_act=silu. Upstream applies it only for
    # swigluoai, so silu models would compute unclamped activations here.
    # Asymmetric on purpose: gate upper-clamped, up symmetrically clamped.
    if cutlass.const_expr(limit is not None):
        if cutlass.const_expr(
            activation == "swigluoai_uninterleave" or activation == "silu"
        ):
            lim = Float32(limit)
            g = fmin_f32(g, lim)
            u = fmax_f32(fmin_f32(u, lim), Float32(-limit))

    if cutlass.const_expr(activation == "swigluoai_uninterleave"):
        sig_arg = Float32(alpha) * g
        up_term = u + Float32(beta)'''
if s.count(old) != 1:
    raise SystemExit("moe_activation.py: swigluoai clamp block match count %d" % s.count(old))
FI.write_text(s.replace(old, new))

# --- 2. Pass swiglu_limit through vLLM's wrapper ----------------------------
s = VL.read_text()
old = """            num_local_experts=self.num_local_experts,
            activation=self._activation_str,
        )"""
new = """            num_local_experts=self.num_local_experts,
            activation=self._activation_str,
            # Without this the kernel silently skips the SwiGLU clamp that
            # models like GLM-5.3-Flash (swiglu_limit=10.0) require.
            swiglu_limit=self.moe_config.swiglu_limit,
        )"""
if s.count(old) != 1:
    raise SystemExit("flashinfer_b12x_moe.py: wrapper ctor match count %d" % s.count(old))
s = s.replace(old, new)

# The ctor reads moe_config lazily, so keep a reference to it on the instance.
old_init = """        self.out_dtype = moe_config.in_dtype
        self.num_local_experts = moe_config.num_local_experts"""
new_init = """        self.out_dtype = moe_config.in_dtype
        # Retained so _ensure_wrapper() can pass swiglu_limit through.
        self.moe_config = moe_config
        self.num_local_experts = moe_config.num_local_experts"""
if s.count(old_init) != 1:
    raise SystemExit("flashinfer_b12x_moe.py: __init__ match count %d" % s.count(old_init))
VL.write_text(s.replace(old_init, new_init))

# --- 3. Let the oracle select b12x when a clamp is required -----------------
s = OR.read_text()
old = """    NVFP4_BACKENDS_WITH_CLAMP = {
        NvFp4MoeBackend.FLASHINFER_TRTLLM,"""
new = """    NVFP4_BACKENDS_WITH_CLAMP = {
        # b12x applies the clamp as of patch v12 (see
        # patches/patch_v12_b12x_swiglu_clamp.py); without that patch this
        # entry would let a silu model run with UNCLAMPED activations.
        NvFp4MoeBackend.FLASHINFER_B12X,
        NvFp4MoeBackend.FLASHINFER_TRTLLM,"""
if s.count(old) != 1:
    raise SystemExit("oracle/nvfp4.py: clamp set match count %d" % s.count(old))
OR.write_text(s.replace(old, new))

print("v12: b12x SwiGLU clamp wired for silu; swiglu_limit plumbed; oracle updated")
