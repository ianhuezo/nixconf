---
description: Profile real data before branching, validate joins by cardinality, and turn measured assumptions into assertions.
alwaysApply: true
---

# Data

Applies to stored data and representative synthetic data.

- Before branching on a field, measure its population, distinct count, and common values across the full dataset. Samples, docs, and metadata are not profiles.
- Treat uniformly empty fields or outputs as defects until proven legitimate. State the expected distribution, then measure it; successful execution is not verification.
- Before a join, confirm both keys exist and predict its cardinality. Afterward verify the result is nonzero, not explosive, and close to prediction; empty joins often fail silently.
- Fixtures MUST reflect measured distributions and required field combinations. Each field existing separately proves nothing.
- Anchor tests to measured source facts, not transform assumptions or recorded outputs. Preserve durable facts as executable assertions, not prose.
