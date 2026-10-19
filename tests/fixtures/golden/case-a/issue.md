# Issue #7 — issue

| | |
|---|---|
| Issue | https://example.com/acme/shop/issues/7 |
| Branch | `feat/order-export` |
| Updated | 2026-03-04 |

## Where this stands

Filed as #7. Nothing open.

## Questions

### Q1 — Should the export include refunded orders?

**Why it matters:** including them adds a refund column and a sign convention to the draft;
leaving them out needs neither.
**Options:** include · leave out.

**Answer:**
Leave them out. Finance reconciles refunds separately.

## Draft

**Title:** Export the day's paid orders as a CSV file

The shop's finance team copies paid orders out of the admin screen by hand every morning.

- [ ] The export lists only paid orders
- [ ] The export file names the day it covers

## Outcome

Filed as #7, Issue Type Feature, labels `export`.

## Log

- 2026-03-02 — Q1 raised · cost: 6m · opus-5 40k in + 210k cached / 5k out
- 2026-03-02 — Q1 answered, issue filed as #7 · cost: 3m · opus-5 22k in + 150k cached / 2k out
