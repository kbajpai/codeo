# Issue #12 — plan

| | |
|---|---|
| Issue | https://example.com/acme/shop/issues/12 |
| Branch | `feat/order-export` |
| Updated | 2026-03-04 |

## Where this stands

Stopped on Q2; tasks 3-4 are drafted once it is answered.

## Questions

### Q1 — Export every order, or only the paid ones?

**Why it matters:** exporting every order adds a status column and a filter flag to task 2.

**Answer:**
Paid only.

### Q2 — Which account should the export job read under?

**Why it matters:** decides whether the job needs a read-only role of its own.

**Answer:**

## Notes

### Footprint

```
files:      src/export/**
wiki:       none
exclusive:  none
sequenced:  none
```

## Outcome

_Pending — written at the hand-off._

## Log

- 2026-03-04 — Q1-Q2 raised · cost: 14m · fable-5-1 96k in + 1.2M cached / 18k out
