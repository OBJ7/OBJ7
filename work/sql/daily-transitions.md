# Daily activity transitions: inactive is not newly inactive

## The operational question

A daily report needed to identify entities that had moved from active to inactive. Counting everything currently inactive answers a different question. A rolling activity total also cannot be summed across snapshot dates to reconstruct daily changes.

My working revision separated a merchant's state on the latest source date from its state on the preceding calendar date. It also added checks for conflicting duplicate totals, missing prior-day history and inconsistent mappings before allowing report delivery. This is work on report definitions, SQL logic and validation; a successful production rollout of that revision is not established here.

## The redacted excerpt

[Open the SQL](daily-transitions.sql). The private working query used transaction thresholds to derive an active flag. Those commercial thresholds and source objects are omitted here. The excerpt starts with an already classified daily state and shows the comparison at one row per entity per date.

The public adaptation also makes an important assumption visible: **a missing current entity row is flagged for review, rather than automatically called inactive**. The working revision treated an absent current row as inactive. That interpretation is valid only if the upstream feed contract supports it. This public change is a review safeguard, not a claim about an implemented production correction.

## Expected fixture results

The dates and entity IDs below are invented replacement values.

| Entity | Prior state | Current state | Expected classification |
| --- | --- | --- | --- |
| E-A | Active | Inactive | NEWLY_INACTIVE |
| E-B | Active | Active, repeated identically | STILL_ACTIVE; counted once |
| E-C | Active | No current row | MISSING_CURRENT; requires review |
| E-D | Inactive | Active | Outside the prior-active cohort |

The expected newly-inactive count is **1**, with **1** missing-current exception. These are fixture outputs, not business performance metrics.

## Checks that matter

- Stop if the preceding calendar date is absent; a prior-day state is unknown, not zero.
- Reject two different states for the same entity and date; deduplicate identical states.
- Compare states at the same entity/date grain.
- Keep missing-current records visible so a stale or incomplete feed cannot silently become a business event.

The source's wider territory/channel rollups and email delivery are intentionally absent. A complete implementation also needs feed completeness, event definitions, historical mapping rules and reconciliation across report levels. The excerpt does not claim to solve those omitted parts.

## Validation status

Reviewed against the working revision and its companion validation script; public fixture logic reviewed statically on 28 October 2026. **Not executed on SQL Server in this environment.** To check the failure paths in an isolated query window, remove the entire prior-day fixture or add a contradictory current state for E-A: the corresponding guard should raise an error before results are reported.
