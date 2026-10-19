# Issue #12 — qc

| | |
|---|---|
| Issue | https://example.com/acme/shop/issues/12 |
| Branch | `feat/order-export` |
| Updated | 2026-03-04 |

## Where this stands

Round 2 clear; the environment released.

## Questions

None.

## Outcome

### Round 1 — 2026-03-06

| Criterion | Verdict | Settled by |
|---|---|---|
| The export lists only paid orders | met | `tests/export.test.sh` — paid-only case |
| The export file names the day it covers | not met — names the run time | `src/export/file.sh:14` |
| The nightly job writes to the shared bucket | not yet checkable — lease not held | environment |

#### Environment

Lease not held: lease env is held by #13 since 2026-03-05

Findings:

- F1 (blocking, implement) — the file name carries the run time, not the day covered.

**Verdict: back to `/codeo:implement`.**

### Round 2 — 2026-03-09

| Criterion | Verdict | Settled by |
|---|---|---|
| The export lists only paid orders | met | `tests/export.test.sh` — paid-only case |
| The export file names the day it covers | met | `tests/export.test.sh` — file-name case |
| The nightly job writes to the shared bucket | met | environment |

#### Environment

Deployed revision: rev-0043

```
$ shop-env deployed
export-job	rev-0043	running	yes
```

No findings; nothing blocking.

**Verdict: clear — forward to `/codeo:close`.**

Environment released at the clear verdict: lease env released by #12

## Log

- 2026-03-06 — round 1 · cost: 7m · opus-5 120k in + 1.1M cached / 9k out
- 2026-03-09 — round 2: clear, environment released · cost: 8m · opus-5 130k in + 1.2M cached / 9k out
