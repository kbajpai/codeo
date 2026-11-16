# Issue #113 — implement

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/113 |
| Branch | `feat/cmd-mode-start-use-home` |
| Updated | 2026-11-16 |

## Where this stands

Round 1. Tasks 1-9 of `docs/plans/2026-11-16-cmd-mode-containers.md` are built, reviewed task by task and as a whole branch (verdict: ship), and pushed; the configured build (`true`) passes and the full `bash tests/run.sh` passed in each task. Task 10 is the engineer's (host checks on WSL2 and a Mac), not this skill's.

The round stops on Q1-Q3: a new workflow, #116, started after the plan was written and lists three of this branch's files in its footprint. Nothing else is open, and no `## Outcome` is written while these are.

## Questions

### Q1 — #116 also changes `.devcontainer/README.md`: proceed, sequence or re-scope?

**Why it matters:** this branch adds a section to `.devcontainer/README.md` (the command-line route, `--rebuild`, removal, the table row). #116 (branch `fix/follow-ups-70-71-104`, assignee kbajpai, at `init`) lists `.devcontainer/README.md` in its footprint, and `overlap.sh` prints `116  .devcontainer/README.md` and `116  glob:.devcontainer/README.md`. If #116 edits other paragraphs, whichever merges second resolves a text conflict; if both edit the same lines, the second has to merge by hand. The answer decides whether anything is changed here.

**Options:** *proceed and coordinate* (recommended: this branch only adds a new section after *Opening a container* and one table row, so a conflict is unlikely and small) · *sequence after #116* (this branch waits for #116's merge, then merges `main`) · *re-scope* (drop the README change from this branch; the docs task would be reopened).

**Answer:**

### Q2 — #116 also changes `CHANGELOG.md`: proceed, sequence or re-scope?

**Why it matters:** this branch adds one bullet under `## Unreleased`. #116 (branch `fix/follow-ups-70-71-104`, assignee kbajpai, at `init`) lists `CHANGELOG.md` in its footprint (`overlap.sh`: `116  CHANGELOG.md`, `116  glob:CHANGELOG.md`). Both add bullets to the same list; the second to merge resolves a one-line conflict.

**Options:** *proceed and coordinate* (recommended, as with #104, whose merge was clean) · *sequence after #116* · *re-scope* (leave `CHANGELOG.md` out).

**Answer:**

### Q3 — #116 also changes `tests/devcontainer.test.sh`: proceed, sequence or re-scope?

**Why it matters:** Tasks 1-2 added six cases and their `cases=( … )` entries, a `ds_run` line and an `st_run` line to `tests/devcontainer.test.sh`. #116 (branch `fix/follow-ups-70-71-104`, assignee kbajpai, at `init`) lists `tests/devcontainer.test.sh` in its footprint (`overlap.sh`: `116  tests/devcontainer.test.sh`, `116  glob:tests/devcontainer.test.sh`). A second branch to merge adds its own cases to the same `cases=( … )` array, so a conflict there is likely but mechanical.

**Options:** *proceed and coordinate* (recommended) · *sequence after #116* · *re-scope* (not workable: the cases belong with the code they test).

**Answer:**

## Outcome

_Pending — written at the hand-off._

## Log

- 2026-11-16 — Tasks 1-9 built and reviewed, Q1-Q3 raised on #116's overlap · cost: 71m · sonnet-5-5 992k in + 26.4M cached / 160k out
