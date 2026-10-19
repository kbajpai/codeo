# Issue #12 — plan

| | |
|---|---|
| Issue | https://example.com/acme/shop/issues/12 |
| Branch | `feat/order-export` |
| Updated | 2026-03-04 |

## Where this stands

Round 2, after a send-back from `/codeo:qc`: the file writer now names the day the export covers.

## Questions

### Q1 — Which account should the export job read under?

**Why it matters:** decides whether the job needs a read-only role of its own or reuses the
service's.

**Answer:**
A read-only role of its own.

### Q2 — Name the file by the day covered, or by the run date?

**Why it matters:** task 2's file writer takes one or the other as its input.
**Options:** day covered · run date.

**Answer:** Day covered.

## Notes

The orders table already has a `paid_at` column.

## Outcome

Plan at `docs/plans/2026-03-04-order-export.md`: four tasks — the query, the file writer, the
nightly job under its own read-only role (Q1), and the export page in the docs.

### Round 2 — 2026-03-08

2026-03-08
(send-back from qc.md round 1)

Task 2 rewritten: the file writer takes the day covered (Q2), not the run time.

### Footprint

```
files:      src/export/**, docs/export.md
wiki:       Order-export
exclusive:  none
sequenced:  none
```

## Log

- 2026-03-04 — Q1 answered, plan written · cost: 12m · fable-5-1 96k in + 1.2M cached / 18k out
- 2026-03-08 — round 2: Q2 raised · cost: 4m · fable-5-1 40k in + 600k cached / 6k out
- 2026-03-08 — round 2: Q2 answered, task 2 rewritten · cost: unavailable — the session was resumed
