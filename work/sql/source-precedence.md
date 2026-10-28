# Duplicate-source precedence in a consolidated entity dataset

## The operational question

The same entity could enter a consolidated dataset through both a specialist source and a general parent-source branch. Removing duplicates at the end could keep the wrong role if the rule did not explicitly give the specialist source precedence.

My working hierarchy correction addressed both points: exclude specialist entities from the general branch with `NOT EXISTS`, then rank remaining records with `ROW_NUMBER()` using explicit role precedence, active status and recency. The source included a transaction-controlled procedure patch and verification of the stored definition. Those deployment mechanics are not published here, and their successful execution is not claimed.

## The redacted excerpt

[Open the SQL](source-precedence.sql). Employer role names, object names and identifiers are replaced. The public version returns a proposed consolidated result; it does not delete source records or alter procedures.

The public fixture adds an explicitly unique `source_row_key` as a final tie-breaker. The working artifact's last tie-break field was not proven unique by the evidence available for this review. Adding this fixture key makes the public query's ordering deterministic; it does not establish that the production source has that property. In a real system, define and verify a stable unique key before relying on it.

## Expected fixture results

| Entity | Relevant input | Expected selected row |
| --- | --- | --- |
| E-A | Specialist record plus newer general record | Specialist source; general branch excluded |
| E-B | Two active general records with the same timestamp | Lowest unique source-row key |
| E-C | Older active record and newer inactive record | Active record, following the stated precedence |
| Blank ID | Unusable business identifier | Exception result; excluded from consolidation |

The precedence itself needs agreement from the people who own the business definition. Recency alone is not automatically the right rule, and an inactive specialist row should not silently be treated as an active general role. This sample makes the choice inspectable instead of concealing it in a final deletion.

## Checks that matter

- Confirm that the specialist source is the authority for the role.
- Normalize the business identifier consistently before comparing branches.
- Keep blank identifiers visible as exceptions.
- Reject duplicate source-row keys before treating them as a deterministic tie-breaker.
- Inspect the selected result before any separately controlled write operation.

## Validation status

Reviewed against the real working hierarchy-correction artifact; public adaptation reviewed statically on 28 October 2026. **Not executed on SQL Server in this environment.** In an isolated query window, duplicate a `source_row_key` to exercise the guard. There is no claim of production deployment, affected-record count or measured business benefit.
