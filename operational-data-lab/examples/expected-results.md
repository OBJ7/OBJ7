# Intended fixture results — not observed

| Exercise | Expected result |
| --- | --- |
| Initial preview | One ready tail; one already-correct destination; identical duplicate mapping collapsed |
| Valid repair | TAIL-001 moves to MERCHANT-NEW-001; shared operator links unchanged |
| Parent cleanup | PARENT-001 removed; PARENT-002 retained due to dependency |
| Repeat apply | No further mutations or audit rows |
| Conflicting/missing/self/cyclic mapping | Repair blocked with no successful mutation |
| Forced transaction failure | Original tails and parent restored; no audit rows |
| Reporting 9 Oct at 15:00 | A=2 distinct events, B=3; A has one repeated row; EVENT-002 late_in_A |
| Reporting 9 Oct through midnight | A=B=3; next-day EVENT-004 excluded; unknown category included |
| Feed A unavailable | A comparable count NULL; no confirmed comparable totals |

These expectations require execution and inspection on SQL Server. None is claimed as a passed test in this release.
