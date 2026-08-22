---
description: Use fast, effective algorithms — vectorization, threading, multiprocessing, and async — chosen correctly for the workload, and treat idle resource cost as a test criterion.
alwaysApply: true
---

# Performance

- Prefer fast, effective algorithms; never ship a slow path when a fast one exists.
- Use vectorization (SIMD, numpy-style batch/vectorized operations) for data-parallel numeric work instead of scalar loops.
- Use threading, multiprocessing, and async correctly: threads/async for I/O-bound and concurrent work, processes for CPU-bound parallelism, and vectorized or single-pass code for compute. Don't oversubscribe the available cores.
- Match the parallelism to the actual hardware (cores, GPU, memory) available at runtime.

## Resource cost is a test criterion
- Idle cost is part of the contract: a program doing nothing must use ~0% CPU and flat memory. Anything burning a core while idle, or growing RSS at rest, is a bug even when the output is correct.
- Long-running work must be checked at rest and at teardown, not just for throughput: it must stay idle when there is nothing to do, and exit when its input dies (closed terminal, dropped socket, vanished parent). A stream that ends is a terminal condition, never an idle tick.
- Leave nothing behind. After a run, verify no orphaned processes, threads, or temp files survive — a leak of one spinning process per run is invisible until the load average is read.
- Verify by measuring the running process (`top`/`ps`, RSS over time, exit codes), not by reading the code. Suspect dependencies too: a loop that never returns inside a library starves every shutdown check in the caller.
