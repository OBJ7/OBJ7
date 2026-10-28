# Everyday SQL work

I support commercial systems and operational reporting. A recurring part of that work is making sure a useful-looking number means what people think it means, or that a record from one source has not displaced the right record from another.

These are **redacted adaptations of real working SQL artifacts**, prepared for public review on 28 October 2026. The operational problems come from my work; the public schemas, identifiers and fixture records are replacements. They are not copies of production data. The excerpts have been reduced to the reasoning a reviewer can inspect without internal databases, correspondence or access details.

| Case | Problem and contribution | Inspect |
| --- | --- | --- |
| [Daily activity transitions](daily-transitions.md) | Working on a reporting revision that distinguishes a daily change of state from the total population already inactive; checking missing history, duplicate daily states and report grain. | [T-SQL excerpt and fictional fixture](daily-transitions.sql) |
| [Duplicate-source precedence](source-precedence.md) | Working on a hierarchy correction where the same entity could enter a consolidated dataset through two source branches; applying source exclusion and explicit ranking. | [T-SQL excerpt and fictional fixture](source-precedence.sql) |

## What the evidence establishes

The underlying working files establish the problems and the SQL approaches under review. They do **not** establish a measured reduction in incidents, recovered revenue or successful production execution of every revision. One source revision explicitly records that it had not been executed on the employer's SQL Server. I do not present it as a completed deployment.

The public adaptations remove employer object names, business thresholds, channel codes, contact details, real identifiers and operational configuration. They omit mail delivery, account provisioning, procedure patching and destructive actions. The replacement records are deliberately small enough to reason through.

## Reading or running the excerpts

Each `.sql` file contains its own table-variable fixtures and read-only result queries. Use an isolated **SQL Server 2012 or later** query window: the excerpts use `THROW`. They do not require employer connections or create persistent database objects.

Expected fixture results and important limitations are documented with each case. **Native SQL Server execution of these public adaptations has not been performed in this portfolio environment.** The environment had no SQL Server client or server runtime. Static review is not a runtime pass. The fixture results below are expected results, not captured SSMS output.

[Provenance, redaction and authorship](provenance.md) · [Main portfolio](../../README.md)
