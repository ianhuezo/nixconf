---
description: Query existing repository graphs first, refresh them after verified changes, and use Git only at meaningful change boundaries.
alwaysApply: true
---

# Repository discipline

## Graphify
- For any repository question, if `graphify-out/graph.json` exists, the first discovery command MUST be `graphify query "<question>"`; use `path`/`explain` next as needed. NEVER list, glob, grep, or explore files first. Exact known-file verification MAY go directly to source.
- Treat graph results as leads, not authority. Verify current source, especially `INFERRED` or `AMBIGUOUS` edges. Require Graphify-first discovery in relevant subagent tasks.
- The orchestrator exclusively owns Graphify lifecycle operations. After verified material changes to an existing graph: run `graphify update .` directly for code-only changes; for docs/config/media, read `skill://graphify`, delegate semantic extraction chunks, then merge, rebuild, and smoke-query. Subagents NEVER run whole-graph updates independently.
- Do not create a new full graph implicitly. No material change means no graph update.

## Git
- Only the orchestrator may mutate Git state or history (`add`, `commit`, `push`, `merge`, `rebase`, `reset`, `restore`, `checkout`, `clean`, `stash`, tags, or branches). Subagents MAY use read-only `status`, `diff`, `log`, `show`, and `blame`.
- Existing modifications are user work. NEVER discard them without an explicit request. Use Git for meaningful boundaries, history questions, or requested commits—not routine post-edit inspection or behavioral verification.
- Commit only when requested or required by repository workflow. Keep it focused: inspect the intended diff, exclude unrelated work and secrets, verify behavior, then use a concrete message.
