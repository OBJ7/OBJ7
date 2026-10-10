# Fictional model

| Object | Grain and constraints |
| --- | --- |
| Merchant | One fictional merchant ID |
| Tail | One tail; unique merchant association |
| OperatorMerchant | Operator/merchant pair; operators can serve multiple merchants |
| MerchantMapping | Raw mapping row; duplicates allowed for validation exercise |
| ParentRecord | Directory entry with explicit redundancy flag; not the merchant itself |
| ParentDependency | One dependency preventing parent cleanup |
| RepairAudit | One mutation; run ID, entity, before/after merchant IDs, UTC time |
| FeedState | One source availability and ingestion-coverage watermark |
| EventFeed | One received event row; duplicate event IDs allowed |

All timestamps are UTC, which corresponds to Ghana time for these fictional dates. Report windows are occurrence-date intervals `[midnight, next midnight)`, with ingestion `<= cutoff`. Deduplication is by source/event ID. Unknown channels remain in totals; category conflicts stop comparable output. NULL is unknown information, not confirmed absence.
