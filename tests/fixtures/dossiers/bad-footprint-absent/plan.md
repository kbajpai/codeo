# Issue #12 — plan

| | |
|---|---|
| Issue | https://example.com/acme/shop/issues/12 |
| Branch | `feat/order-export` |
| Updated | 2026-03-04 |

## Where this stands

Plan approved; handed to `/codeo:implement`.

## Questions

### Q1 — Which account should the export job read under?

**Why it matters:** decides whether the job needs a read-only role of its own or reuses the
service's.
**Options:** a role of its own · the service's.

**Answer:**
A read-only role of its own.

## Notes

### Footprint

```
files:      src/export/**, docs/export.md
wiki:       Order-export
exclusive:  none
sequenced:  none
```

The orders table already has a `paid_at` column; no migration is needed.

## Outcome

### Round 1 — 2026-03-04

Plan at `docs/plans/2026-03-04-order-export.md`: four tasks — the query, the file writer, the
nightly job under its own read-only role (Q1), and the export page in the docs.

## Log

- 2026-03-04 — Q1 raised · cost: 9m · fable-5-1 80k in + 900k cached / 14k out
- 2026-03-04 — Q1 answered, plan written · cost: 12m · fable-5-1 96k in + 1.2M cached / 18k out
