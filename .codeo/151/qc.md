# Issue #151 — qc

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/151 |
| Branch | `docs/install-codeo-one-command-document` |
| Updated | 2026-11-21 |

## Where this stands

Round 1 stopped at step 2. The branch already contains `origin/main` (`sync-main: the branch already contains origin/main`). `overlap.sh 151` printed a new overlap with #138, raised as Q1. Criterion 6 needs the engineer's own check, and how to treat it decides the verdict, so it is Q2. Nothing has been built, run or reviewed yet; the pass resumes from step 2 once both are answered.

## Questions

### Q1 — #138 also changes `CHANGELOG.md`: proceed, sequence, or re-scope?

**Why it matters:** `overlap.sh 151` printed `138	CHANGELOG.md` and `138	glob:CHANGELOG.md`. #138 has since reached `implement` and its branch already changes `CHANGELOG.md`; this branch adds one bullet under `## Unreleased` there. Whichever merges second will meet a conflict in that one file. Sequencing would hold this change until #138 merges; proceeding changes nothing here.
**The other workflow:** #138, branch `fix/live-session-signal-does-not`, assignee kbajpai, step `implement` (working), waiting on its own `qc.md` Q1-Q3. Its footprint also names `.claude/settings.json`, `scripts/live.sh`, `skills/triage/SKILL.md`, `docs/handoff.md` and tests; this branch changes none of them. The only shared path is `CHANGELOG.md`.
**Options:**
- *Proceed and coordinate* (recommended). The same answer #149 got in `implement.md` Q1: this branch's bullet is its own new bullet and touches no other line, so the branch that merges second rebases and keeps both.
- *Sequence after #138.* Hold this change until #138 has merged, then rebase.
- *Re-scope.* Drop the changelog bullet; acceptance criterion 10 would then not be met.

**Answer:**

### Q2 — Criterion 6 (Claude Code offers the install when the folder is trusted): run it now, or let `/codeo:close` record it in the pull request?

**Why it matters:** the criterion reads "shown on a clean machine, with the result recorded in the PR". Only you can run it (it is interactive: plan Task 8, Step 2), and `implement.md` records that nobody has yet. It decides whether this round's verdict can be clear: a criterion marked `not yet checkable` is not a pass, but its evidence can only land in a pull request, which does not exist until `/codeo:close`.
**How to run it** (in this container's terminal, bash): `d=$(mktemp -d) && cd "$d" && git init -q && CLAUDE_CONFIG_DIR=$(mktemp -d) bash /workspaces/codeo-151/install.sh --scope project`, then `CLAUDE_CONFIG_DIR=$(mktemp -d) claude` in the same folder, trust it when asked, and note what Claude Code offers.
**Options:**
- *Run it now and answer here with what you saw* (recommended). This round then settles criterion 6 as met or not met, and `/codeo:close` copies your answer into the pull request.
- *Treat it as a close-time check.* This round records criterion 6 as `not yet checkable — the engineer's check, recorded in the pull request at /codeo:close`, non-blocking, and the verdict can be clear; `/codeo:close` must not merge without it.
- *Not met.* If you already know it offers nothing, say so: that is a blocking finding, and its owner is decided from why.

**Answer:**

## Notes

- `sync-main.sh --abort-on-conflict`: `sync-main: the branch already contains origin/main` (exit 0).
- `overlap.sh --outside 151`: no output (no path outside the footprint).
- `scope.sh origin/main HEAD`: `suite.shell=true` (unclassified paths: `.codeo/151/*`, `CHANGELOG.md`, `CONTRIBUTING.md`, `README.md`, `install.sh`).
- No shared environment, no invariants file, no wiki module; the `invariants-extra` and `wiki-rules` overlays do not exist (exit 3).

## Outcome

_Pending — written at the hand-off._

## Log

- 2026-11-21 — Q1-Q2 raised (overlap with #138 on CHANGELOG.md; criterion 6 is the engineer's) · cost: 0m · opus-5-5 290k in + 333k cached / 1k out
