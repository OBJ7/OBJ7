# Runbook — awaiting execution

Use only a fresh disposable database. Follow the README order. The setup refuses system databases and an existing demo schema. The fixture load is intended once; it has no reset function.

Save a preview and inspect every blocker. Pass the expected number of tail mutations explicitly. If the count or mapping state changes, re-preview; never relax the validation just to force an update.

On a failure, the procedure rolls back its own transaction. Inside a caller-owned transaction it uses a savepoint when possible; if SQL Server marks that transaction uncommittable, the caller must roll it back. Tests account for this distinction. Transaction rollback is not reversal of a committed repair; no committed-repair reversal is supplied.

After a successful repair, inspect the audit and blocked-cleanup output, and verify unchanged operator links. Rerun with zero expected tail mutations to check idempotency. Do not translate the fictional code into a production procedure without a separate, authorized review.

Reporting requires an explicit date and cutoff. Read source status before totals, then duplicate/unknown counts and event-level reasons. Later data can change the result; the two queries are not a stored immutable snapshot. A production snapshot strategy is outside this draft.

Validation remains outstanding. The report script uses the procedure’s result-set selector to assert totals and mismatch reasons with `INSERT ... EXEC`. These assertions are written but not executed.
