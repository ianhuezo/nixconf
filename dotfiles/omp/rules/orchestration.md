---
description: Parallelize independent work, compare plausible implementations, and keep delegation within machine limits.
alwaysApply: true
---

# Orchestration

- Delegate independent slices in one parallel `task` batch, then collect and verify every result. Split overloaded work early; hand-back chunking is normal.
- When several implementations are genuinely plausible, build them concurrently in isolated worktrees, run independent adversarial reviewers, fix defects, and select the strongest result.
- The orchestrator owns decomposition, contracts, integration, and final decisions. Allocate work within `task.maxConcurrency` and available CPU/RAM without oversubscription.
