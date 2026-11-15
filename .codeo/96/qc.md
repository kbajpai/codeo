# Issue #96 — qc

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/96 |
| Branch | `feat/dev-container-follow-ups-40` |
| Updated | 2026-11-15 |

## Where this stands

Round 1, stopped at step 2. `sync-main.sh --abort-on-conflict` printed `sync-main: the branch already contains origin/main`. `overlap.sh 96` then printed seven new overlap lines with #70, #71 and #97, which were not raised when the plan was written (#71 and #97 had no footprint then, and `tests/env.test.sh` and `lib/env.sh` joined this plan's footprint after the Q6/Q7 answers). Nothing is built, run or reviewed yet; the pass resumes once Q1-Q3 are answered.

What `overlap.sh 96` printed, verbatim:

```
70	tests/env.test.sh
71	CHANGELOG.md
71	glob:CHANGELOG.md
97	CHANGELOG.md
97	glob:CHANGELOG.md
97	glob:lib/env.sh
97	lib/env.sh
```

A trial merge of this branch's head with each other branch (`git merge-tree --write-tree HEAD <their branch>`, read-only) gives: `CHANGELOG.md` conflicts with all three (each adds a bullet at the end of `## Unreleased`), `lib/env.sh` merges cleanly with #97 (#97 rewords the `board{...}` entry, this branch adds the `plugin{repo,ref}` line), `.devcontainer/README.md` merges cleanly with #70, and #70 has not changed `tests/env.test.sh` (it is in #70's `tests/**` glob only).

## Questions

### Q1 — #70 and this branch: `tests/env.test.sh`

**Why it matters:** #70 (`feat/guard-home-only-skills-against`, assignee kbajpai, step `qc (working)`) lists `tests/**` in its footprint, which covers `tests/env.test.sh`; this branch adds one case to that file (`env_key_reference_lists_plugin`). #70's branch has not changed the file, so today there is nothing to merge. The answer decides whether this pass goes on, or this branch waits for #70 to merge first.
**Options:** proceed and coordinate (my pick: no change on #70's side, so no conflict) · sequence after #70 · re-scope.

**Answer:**

### Q2 — #71 and this branch: `CHANGELOG.md` (`glob:CHANGELOG.md`)

**Why it matters:** #71 (`feat/file-new-issues-straight-board`, assignee kbajpai, step `plan (working)`) changes `CHANGELOG.md`; a trial merge conflicts there because both branches append a bullet to `## Unreleased`. The resolution is keeping both bullets, done by whichever branch merges second. The answer decides whether this pass goes on, or waits for #71.
**Options:** proceed and coordinate (my pick: keep both bullets at merge time) · sequence after #71 · re-scope.

**Answer:**

### Q3 — #97 and this branch: `CHANGELOG.md`, `lib/env.sh` (`glob:CHANGELOG.md`, `glob:lib/env.sh`)

**Why it matters:** #97 (`docs/docs-skill-wording-test-guard`, assignee kbajpai, step `implement (working)`) changes both files. `lib/env.sh` merges cleanly (different lines of the key reference); `CHANGELOG.md` conflicts the same way as Q2 (both bullets kept). The answer decides whether this pass goes on, or waits for #97.
**Options:** proceed and coordinate (my pick: `lib/env.sh` is clean, `CHANGELOG.md` keeps both bullets) · sequence after #97 · re-scope.

**Answer:**

## Notes

## Outcome

_Pending — written at the hand-off._

## Log

- 2026-11-15 — Q1-Q3 raised (overlaps with #70, #71, #97 at step 2) · cost: 1m · opus-5-5 359k in + 792k cached / 1k out
