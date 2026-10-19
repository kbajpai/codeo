# Issue #15 — plan

| | |
|---|---|
| Issue | https://example.com/acme/shop/issues/15 |
| Branch | `feat/stock-report` |
| Updated | 2026-04-02 |

## Where this stands

Plan approved; handed to `/codeo:implement`.

## Questions

### Q1 — Should discontinued products appear in the report?

**Why it matters:** decides whether the query filters on the catalogue's status column.
**Options:** include · leave out.

**Answer:**
Leave them out; nobody reorders them.

## Outcome

### Round 1 — 2026-04-02

Plan at `docs/plans/2026-04-02-stock-report.md`: three tasks — the query (discontinued products
left out, Q1), the supplier sort, and the report page in the docs.

### Footprint

```
files:      src/reports/stock/**, docs/stock-report.md
wiki:       Stock-report
exclusive:  none
sequenced:  none
```

## Log

- 2026-04-02 — Q1 raised · cost: 8m · fable-5-1 70k in + 800k cached / 12k out
- 2026-04-02 — Q1 answered, plan written
