# Operational data lab — implementation draft

New independent T-SQL demonstration, prepared 10 October 2026, using fictional data and simplified rules. It illustrates general data-quality and operational reasoning developed through my work. It contains no employer code, records, internal schemas, or production connections. Its results are not evidence of historical production outcomes.

**Execution status: NOT EXECUTED on SQL Server.** No SQL Server or `sqlcmd` runtime was available during preparation. Syntax and behavior need validation on a disposable SQL Server database before this is treated as a technical flagship. No alternative database run is represented as T-SQL validation. Substantial AI assistance was used to write this implementation.

## Two questions

1. How can a relationship be repaired without changing already-valid relationships?
2. When do different report totals reflect different information rather than a broken query?

The identity module previews mappings, rejects ambiguity, applies changes transactionally, and preserves shared operator relationships. The reporting module uses explicit occurrence date and ingestion cutoff, counts distinct event IDs, and distinguishes an unavailable feed from zero activity.

## Intended local workflow

Use only a new disposable database on an existing local SQL Server instance (target: SQL Server 2019 or later; no edition/version tested). The schema script refuses to run in system databases or overwrite an existing `demo` schema. It does not create an instance or connect to production.

In SSMS, select that disposable database and run these scripts in order:

1. `sql/00-create-demo-schema.sql`
2. `sql/01-seed.sql` (one-time fixtures, no reset/deletion)
3. `sql/10-preview-identity-repair.sql`
4. `sql/11-apply-identity-repair.sql` (defines procedure; does not execute a repair)
5. `sql/20-reconcile-reports.sql` (defines procedure; does not run it)
6. `tests/identity-repair.sql` and `tests/report-reconciliation.sql`

The tests require untouched fixtures. They roll back their fixture changes. Then, if validation passes, use:

```sql
SELECT * FROM demo.RepairPlan;
EXEC demo.ApplyIdentityRepair @ExpectedTailChanges = 1;
EXEC demo.ApplyIdentityRepair @ExpectedTailChanges = 0; -- intended no-op
EXEC demo.ReconcileReports @ReportingDate = '20261009',
    @Cutoff = '2026-10-09T15:00:00';
```

[Expected results, not observed results](examples/expected-results.md) · [Data dictionary](docs/data-dictionary.md) · [Decisions](docs/decisions.md) · [Runbook](docs/runbook.md) · [Provenance](docs/provenance.md)

## Limits

Global mapping validation holds the entire repair if any mapping is ambiguous. Identical duplicate mapping rows collapse deliberately. Chained and cyclic mappings are unsupported. Parent-record cleanup is separate from deleting a merchant; referenced parents remain and are reported as blocked. No committed-change reversal is implemented. The demonstration takes coarse locks for simplicity and is not a performance design for production.

The reporting contract treats identifiers as unique event identities; conflicting repeated payloads are flagged rather than silently assigned to one category. Unknown regions/channels stay explicit. Automated customer contact, production access, and historical performance claims are outside scope.

## Ownership questions

Before featuring this work, I should be able to explain why operator links stay untouched, why a preview is not a lock, what a repeat run does, when cleanup is blocked, and why a missing feed cannot count as confirmed zero. A model cannot certify my understanding.

Publication terms have not been separately settled; no new license is applied by this update.
