# Decisions

- Keep operator links separate: shared operators are valid, so repairing a tail must not rewrite their associations.
- Allow raw mapping duplicates, then collapse identical pairs: conflicting destinations block the full repair. Chains/cycles are unsupported rather than guessed.
- Use apply-time locks and row-count checks: a preview can become stale. The small lab uses coarse locks; a production concurrency design would need separate analysis.
- Delete only directory parents explicitly marked redundant and with no remaining dependencies. Keep merchant records and valid relationships. An untouched referenced parent is an explained result, not a failed repair.
- Keep audit in the same transaction as mutations: an unsuccessful transaction must not leave successful-change records.
- Compare feed sets at a single stated cutoff: different cutoffs can legitimately disagree. Flag late arrival separately from a record not observed at all.
- Check source availability before counting: zero events and a missing feed are different states.

These are new demonstration choices, not reconstructed employer policies.
