"""Fix an incomplete method-borrow in FlashInfer's b12x MoE kernels.

SYMPTOM
-------
With moe_backend=flashinfer_b12x, both ranks die during model init:

    RuntimeError: Worker failed with error
    ''MoEDynamicKernel' object has no attribute '_collapse_to_vmk''

CAUSE
-----
FlashInfer's SM12x MoE kernels do not subclass the dense block-scaled GEMM
kernel. They borrow its unbound methods and pass their own ``self``:

    # _moe_dynamic/generic.py and gated.py
    self._dense_cls = DenseGemmKernel          # Sm120B12xBlockScaledDenseGemmKernel
    def _thrfrg_SFA(self, sfa_tensor, tiled_mma):
        return self._dense_cls._thrfrg_SFA(self, sfa_tensor, tiled_mma)

Both kernels also borrow ``_partition_fragment_SFA`` / ``_partition_fragment_SFB``
wholesale (generic.py:1619/1627/1824/2335, gated.py:1313/1326/1741/1754/4282/4294).
Those dense methods internally call ``self._collapse_to_vmk(...)`` -- and since
``self`` is the *MoE* kernel, the lookup fails. The borrow list simply misses
this one helper: _thrfrg_SFA/SFB and _get_layoutSFA/SFB_TV are all delegated,
_collapse_to_vmk is not.

FIX
---
Delegate it too, exactly like the neighbouring helpers. The dense
implementation is a pure @staticmethod with no instance state:

    rank = cute.rank(partitioned_sf)
    if rank > 3:
        partitioned_sf = cute.group_modes(partitioned_sf, 2, rank)
    return partitioned_sf

Delegating rather than copying means we inherit any upstream change to it.

NUMERICAL IMPACT: NONE for NVFP4. Per the dense method's own docstring, the
rank>3 case arises only for MXF4 (mma_nsf == 2), where the SF layout's
``blk_sf // mma_nsf`` K sub-mode has extent 2. For NVF4 (mma_nsf == 4) that
extent is 1, the view is already rank 3, and the function returns its input
untouched. So on this checkpoint the patch converts a hard AttributeError into
a no-op -- it does not alter any computation.

Applied to BOTH kernel classes: MoEDynamicKernel (generic.py) and
MoEGatedDynamicKernel (gated.py). GLM-5.3-Flash uses silu, a gated activation,
so the gated kernel is the one actually exercised; the other is patched for
symmetry since it has the identical defect.

Correctness is still not assumed -- validate with moe-compare.py against a
marlin reference before trusting the backend.
"""

from pathlib import Path

BASE = Path(
    "/usr/local/lib/python3.12/dist-packages/flashinfer"
    "/fused_moe/cute_dsl/blackwell_sm12x/_moe_dynamic"
)

# The borrow block is byte-identical in both files, so each is patched
# separately and each must match exactly once within its own file.
OLD = """    def _get_layoutSFB_TV(self, tiled_mma):
        return self._dense_cls._get_layoutSFB_TV(self, tiled_mma)  # type: ignore[arg-type]

    def _setup_attributes(self, hidden_size: int):"""

NEW = """    def _get_layoutSFB_TV(self, tiled_mma):
        return self._dense_cls._get_layoutSFB_TV(self, tiled_mma)  # type: ignore[arg-type]

    def _collapse_to_vmk(self, partitioned_sf):
        # Missing from the borrow list above, but _partition_fragment_SFA/SFB
        # are borrowed from the dense kernel and call self._collapse_to_vmk(),
        # which then resolves against THIS class. Without this delegation the
        # kernel dies with AttributeError during model init.
        # No-op for NVFP4 (rank is already 3); only MXF4 hits the rank>3 path.
        return self._dense_cls._collapse_to_vmk(partitioned_sf)

    def _setup_attributes(self, hidden_size: int):"""

patched = []
for name in ("generic.py", "gated.py"):
    p = BASE / name
    s = p.read_text()
    if s.count(OLD) != 1:
        raise SystemExit(
            "%s: borrow-block match count %d; refusing to patch" % (name, s.count(OLD))
        )
    if "_collapse_to_vmk" in s:
        raise SystemExit("%s: already defines _collapse_to_vmk; refusing" % name)
    p.write_text(s.replace(OLD, NEW))
    patched.append(name)

print("v13: _collapse_to_vmk delegated in %s" % ", ".join(patched))
