# Issue — sync-main.sh exits 1 after a clean merge when `sort` and `comm` disagree on order

| | |
|---|---|
| Source | `/codeo:triage` 2026-11-15, item `implement:83:sync-main-comm` (answered *file it* in the conversation) |
| Updated | 2026-11-15 |

## Where this stands

Reproduced; draft below awaiting approval. No question is open.

## Questions

None. The engineer chose *file it*; scope and criteria below follow the finding, and the one thing nobody knows (the exact collation rule) is in the draft as an open question.

## Notes

Reproduction (Phase 1, this clone, `LANG=en_US.UTF-8`): `printf '.codeo/done/57/a\n.devcontainer/x\nCHANGELOG.md\ndocs/plans/y\ntests/a.sh\n' | sort | comm -12 - <(printf 'CHANGELOG.md\ntests/a.sh\n' | sort)` prints `comm: file 1 is not in sorted order` and `comm: input is not in sorted order`, and exits 1; `LC_ALL=C sort` orders the same paths differently. `scripts/sync-main.sh:50-53` runs `comm -12 <(… | sort) <(… | sort)` under `set -euo pipefail`, so the merge is committed and the script then exits 1, which its header documents as "the tree has tracked changes". `tests/sync-main.test.sh` uses scratch repos whose paths sort the same either way, so it does not catch this.

## Outcome

_Pending — written at filing._

## Log

- 2026-11-15 — draft written from triage item `implement:83:sync-main-comm`
