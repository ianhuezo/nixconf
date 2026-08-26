---
description: Choose efficient algorithms and concurrency, and verify idle cost, teardown, and resource cleanup.
alwaysApply: true
---

# Performance

- Prefer the fastest effective algorithm: vectorize data-parallel numeric work; use threads/async for I/O, processes for CPU-bound work, and single-pass compute where appropriate.
- Match concurrency to available CPU, GPU, and memory; do not oversubscribe.
- Idle programs should use ~0% CPU with flat RSS. Long-running work must exit when input or its parent disappears; an ended stream is terminal, not an idle tick.
- Measure the running process at rest and teardown (`top`/`ps`, RSS, exit status). Verify no orphaned processes, threads, or temp files remain, and include blocking dependencies in the check.
