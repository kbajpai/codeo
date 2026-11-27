# Issue #204 — qc

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/204 |
| Branch | `chore/204-fix-codeo-close-opens-pr` |
| Updated | 2026-11-27 |

## Where this stands

Round 2, stopped at step 2: `overlap.sh 204` printed a new overlap with #195 (Q3). Nothing in round 2 is judged until it is answered.

## Questions

### Q1 — #188 plans to change `skills/close/SKILL.md`, `tests/close-skill.test.sh` and `CHANGELOG.md` too. Proceed, sequence, or re-scope?

**Why it matters:** `#188` (branch `docs/188-close-177-qc-leftovers-utc`, assignee kbajpai, step `plan (working)`, waiting on `/codeo:implement`) declares a footprint that `overlap.sh` reports against this branch as: `CHANGELOG.md`, `glob:CHANGELOG.md`, `glob:skills/close/SKILL.md`, `glob:tests/cleanup-skill.test.sh`, `glob:tests/close-removal.test.sh`, `glob:tests/close-skill.test.sh`, `skills/close/SKILL.md`, `tests/close-skill.test.sh`. Its branch has changed only its plan file so far. This branch rewrites Phase 1 of the close skill (steps 1-7) and the pins on it; #188's plan is about leftovers from #177's qc, so it likely edits other steps (Phase 3 and the host clean-up). No exclusive resource is shared.

- Proceed and coordinate: both go on; whichever merges second merges `main` and resolves any conflict (through `/codeo:close`'s conflict send-back).
- Sequence after #188: this pull request waits until #188 merges. #188 has not started implementing.
- Re-scope: nothing here can be cut; the close skill is the fix.

I recommend proceed and coordinate, #204 merging first: it is finished and has no other step left.

**Options:** proceed and coordinate (recommended) · sequence after #188 · re-scope.

**Answer:**
Proceed and coordinate, as recommended; #204 merges first. Given in the conversation: "go with your picks".

### Q2 — #195's branch now changes many of the files this branch changes. Proceed, sequence, or re-scope?

**Why it matters:** plan.md Q2 settled the overlap with `#195` (branch `feat/195-identify-acting-user-strictly-verify`, assignee kbajpai) on its footprint's globs, when its branch had changed nothing. It is now at step `implement (working)`, waiting on its own `qc.md` Q1-Q3, and `overlap.sh` reports the paths both branches change: `skills/init/SKILL.md`, `tests/close-skill.test.sh`, `tests/fixtures/dossiers/good-basic/close.md`, `tests/fixtures/golden/case-a/close.md`, `tests/inventory.test.sh`, `tests/qc-verdict.test.sh`, `tests/role.test.sh`, `tests/readme.test.sh`, `tests/skills-doc.test.sh`, plus files of its own this branch does not change (`tests/claim.test.sh`, `tests/github.test.sh`, `tests/implement-skill.test.sh`, `tests/init-skill.test.sh`, `tests/live-signal.test.sh`, `tests/live.test.sh`, `tests/lock-verify.test.sh`, `tests/lock.test.sh`, `tests/plan-skill.test.sh`, `tests/qc-skill.test.sh`). Shared files now carry real edits on both sides, so whichever merges second will very likely have to resolve conflicts in `tests/inventory.test.sh` (rule counts), the inventory hash fixture and the two close fixtures. No exclusive resource is shared.

- Proceed and coordinate: as plan.md Q2 decided; #204 merges first, #195 resolves.
- Sequence after #195: this pull request waits for #195, which is blocked on its own qc questions.
- Re-scope: nothing here can be cut.

I recommend proceed and coordinate, as plan.md Q2 decided, with #204 merging first.

**Options:** proceed and coordinate (recommended) · sequence after #195 · re-scope.

**Answer:**
Proceed and coordinate, as recommended; #204 merges first. Given in the conversation: "go with your picks".

### Q3 — #195 now changes `tests/identity.test.sh`, inside this plan's `tests/**`. Proceed, sequence, or re-scope?

**Why it matters:** `overlap.sh 204` printed `195	tests/identity.test.sh`. `#195` (branch `feat/195-identify-acting-user-strictly-verify`, assignee kbajpai, step `implement (working)`) has added that file since Q2. This branch does not change it — the overlap is this plan's coarse `tests/**` footprint glob, not a shared edit — so it cannot conflict. No exclusive resource is shared.

- Proceed and coordinate: as Q2 decided for #195.
- Sequence after #195.
- Re-scope.

I recommend proceed and coordinate.

**Options:** proceed and coordinate (recommended) · sequence after #195 · re-scope.

**Answer:**

## Notes

- Filed nothing with `/codeo:issue`. F5 (below) concerns `scripts/inflight.sh`, which this change leaves alone; it is recorded as non-blocking rather than filed, because the cure is likely part of F4's wording fix.

## Outcome

### Round 1 — 2026-11-27

**Sync.** `sync-main.sh --abort-on-conflict`: `sync-main: the branch already contains origin/main`, exit 0. `overlap.sh 204` printed overlaps with #188 and #195; Q1-Q2 were raised, answered "proceed and coordinate" and the pass was re-run from step 2.

**Scope.** `scope.sh origin/main HEAD`: `suite.shell=true` (unclassified paths: `.codeo/204/*.md`, `CHANGELOG.md`, `README.md`, and the rest). No `deploy=` line: no shared environment is configured.

**Build.** The `shell` suite's `build` is `true`: exit 0.

**Suites.** `bash tests/run.sh` (the whole `shell` suite; it has no `filter`): `all cases passed`, exit 0.

**Acceptance criteria.**

| # | Criterion | Verdict | Settled by |
|---|---|---|---|
| 1 | The first CI run on a PR opened by `/codeo:close` passes qc-verdict | met on the main path — see F1 and F2 for two resume paths | `tests/qc-verdict.test.sh` case "the archive commit and the record commit both pass": `qc-verdict.sh <base> <archive commit>` exits 0 and prints `round 1 clear`; `skills/close/SKILL.md` step 4 pushes the archive before step 5's `pr create` |
| 2 | `close.md` in `.codeo/done/<N>/` still records the PR number and URL | met on the main path — see F1 | `skills/close/SKILL.md` step 6 writes the `— pull request opened` round into `.codeo/done/<N>/close.md`, step 7 commits and pushes it; the same test case's second commit carries the `#9 <url>` line and exits 0 |
| 3 | A review send-back still makes qc-verdict fail until the dossier is archived again | met | step 11 is unchanged (`git mv .codeo/done/<N> .codeo/<N>`); `tests/qc-verdict.test.sh` case "live dossier" (existing, line 425) moves `done/7` back to `.codeo/7` and expects exit 1 naming `.codeo/7` |
| 4 | Close fixtures and tests and `docs/dossier.md` match the new order | met | `tests/fixtures/dossiers/good-basic/close.md` and `tests/fixtures/golden/case-a/close.md` log wording, a new `tests/role.test.sh` case, `docs/dossier.md`'s paragraph and *The pull request* bullet; full suite exit 0 |

**Documentation check.** `docs/dossier.md`, `docs/handoff.md`, `docs/skills.md` and `README.md` (lines 306, 379-380) describe the new order; `skills/triage/SKILL.md` and `skills/init/SKILL.md` name the archived-with-no-pull-request state; `CHANGELOG.md` has the entry. The plan names these pages and the diff touches each. No other page says the pull request opens before the archive (`skills/qc/SKILL.md:475` and `skills/close/SKILL.md:12` say only that close opens it, which stays true). The one inaccuracy is F4. No wiki module; no diagram changes.

**Independent review** (opus, `QC review:`): read the skill, the new test and the docs against the criteria; its verdict was not ready to merge on two resume paths the change itself introduces, quoted here in plain text. Its findings, classified:

- **F1 (blocking, `/codeo:implement`'s) — `skills/close/SKILL.md` lines 111-112, 351-373.** The row "resumed after `pr create`" and Phase 2 differ only on whether a round in `close.md` records this pull request, and the skill says only the dossier's location is read from `HEAD`. Scenario: a run is interrupted after step 6 writes the `— pull request opened` round into `.codeo/done/<N>/close.md` but before step 7 commits it. The next run reads the working tree, finds the round, lands in Phase 2, and step 9 treats the modified file as step 3's stop; the record is never committed and, if the pull request merges, `done/<N>/close.md` on the base has no number or URL (criterion 2). The old order had no such window. Cause: the plan's table does not say which tree the round is read from; the skill text must (read from `HEAD`, so an uncommitted round counts as not yet recorded and step 3's kept-as-it-stands exception commits it).
- **F2 (blocking, `/codeo:implement`'s) — `skills/close/SKILL.md` lines 179, 207-209.** Step 3's `close.md` exception and its conflict un-archive bullet are gated on "a resume after the archive push", which names the row with no pull request, not the "resumed after `pr create`" row (step 2 says "the two resumed rows"). Scenario: a pull request is open, the dossier is archived, nothing is recorded, and the branch conflicts with the base: read literally, step 3 writes the conflict round "under `.codeo/<N>/`", a path that does not exist at `HEAD`, and the workflow is left with an archived dossier and a conflict. Cause: the implementer's own open question (implement.md, Outcome): step 3 is not gated to the rows it applies to.
- **F6 (non-blocking, `/codeo:implement`'s, fix with F2) — line 110.** "skip step 4, run step 5 onward" literally skips steps 2-3, which the same row needs; say "steps 2, 3 and 5 onward".
- **F3 (non-blocking, `/codeo:implement`'s) — `tests/qc-verdict.test.sh` 446-476.** The new case builds `qc.md` inside the archive commit rather than renaming it in, and its "live dossier fails" assertion repeats the existing case at line 425 instead of un-archiving on top of the archived head, so it does not itself exercise criterion 3 (the existing case does).
- **F4 (non-blocking, `/codeo:implement`'s) — `docs/handoff.md` line 156.** "a pull request is open unless `close` stopped between its two pushes" blurs the window: the no-pull-request state is between the archive push and `pr create`. `scripts/inflight.sh` lines 17-18 carry the older wording.
- **F5 (non-blocking, `/codeo:implement`'s) — `scripts/inflight.sh` line 325 (untouched).** An archive with no pull request is labelled `(PR open)`, and `skills/init/SKILL.md` lines 91-92 still say that listing means the workflow is waiting on its pull request. Cosmetic: `skills/triage/SKILL.md` now names the case.
- **F7 (non-blocking, `/codeo:implement`'s) — `tests/close-skill.test.sh` line 161.** The push-before-`pr create` order check passes whenever steps 4 and 5 appear in that order; it would not catch step 4 opening the pull request first. Recorded already as a deferred minor in implement.md.

Declined to judge by the reviewer, accepted: a staged-but-uncommitted rename stranding step 3 (existed before, unchanged); a second pull request under a different number (close-02 covers it); pull requests opened outside close beyond the older-plugin row (out of scope in the issue).

**Verdict: back to `/codeo:implement`.**

## Log

- 2026-11-27 — Q1-Q2 raised (overlaps with #188 and #195) · cost: 1m · opus-5-5 255k in + 304k cached / 875 out
- 2026-11-27 — Q1-Q2 answered; round 1: build true exit 0, `tests/run.sh` exit 0, 4 criteria (all met on the main path), reviewer on opus; 2 blocking findings (F1, F2), 5 non-blocking; back to /codeo:implement · cost: 43m · opus-5-5 357k in + 1.9M cached / 17k out · sonnet-5-5 110k in + 4.5M cached / 7k out
- 2026-11-27 — round 2: Q3 raised (#195, tests/identity.test.sh) · cost: 0m · opus-5-5 333k in + 29k cached / 556 out
