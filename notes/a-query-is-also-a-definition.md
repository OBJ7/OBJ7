# A query is also a definition

Written 10 October 2026 as a new teaching note. The example is fictional.

Two reports can disagree without either query being broken. Before comparing the numbers, I ask what each number means.

Suppose three registrations occurred on Monday. Two reached the reporting feed before 15:00; the third arrived at 17:00. An hourly report at 15:00 counts two. A report using the complete feed later counts three. Comparing them as if they had the same cutoff turns a timing difference into an apparent error.

| Question | Example definition |
| --- | --- |
| What is one unit? | A distinct registration event, not a feed row |
| Which day? | The occurrence date in Ghana time |
| Which records were available? | Ingestion at or before the stated cutoff |
| What about repeat rows? | Count once per event ID; show repeated rows separately |
| What about an unknown channel? | Preserve it in an explicit unknown category |
| What if the feed is absent? | Say unavailable; do not report confirmed zero |

A duplicate feed row could increase a raw count without adding an event. A missing category could make a regional breakdown look smaller than its national total. A missing batch could produce zero rows even when the business had activity.

My starting point is therefore a short count contract: unit, qualifying conditions, timestamp, timezone, cutoff, duplicate rule, and missingness rule. Then I can use the query to implement that contract and a reconciliation to test it.

When investigating a mismatch, I would compare the event IDs as well as the totals. Equal totals can hide two different sets of records. Unequal totals tell me where to investigate; they do not identify the cause by themselves.

The [new SQL demonstration](../operational-data-lab/README.md) turns these definitions into fictional fixtures. It is an exercise, not evidence that these exact rules existed in my employer’s reporting system.

Prepared with AI assistance; no historical teaching session or production result is claimed.
