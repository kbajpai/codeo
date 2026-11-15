# Issue #76 — qc

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/76 |
| Branch | `feat/trial-doctor-setup-haiku-5` |
| Updated | 2026-11-14 |

## Where this stands

Round 1 is written: back to `/codeo:implement` for the `CHANGELOG.md` sentence (F1 blocking, F2 non-blocking). Q1 = A and Q2 = proceed and coordinate. Nothing is open.

## Questions

### Q1 — Was item 1 of the checklist "the script ran exactly once", or "exactly one Bash call"?

**Why it matters:** the whole result turns on it. Your Q2 = A answer approved a checklist whose item 1 read "The script ran exactly once, with the right arguments (`--stack node` passed through)" (`.codeo/76/plan.md`, Q2). The plan you approved at the gate (`docs/plans/2026-11-14-trial-doctor-setup-haiku.md`, Global Constraints, item 1) wrote it as "exactly one Bash call, and it runs the skill's script". The comparison on #76 and `CHANGELOG.md` score by the second wording, and Haiku's only miss under it — in all 6 `doctor` runs and 1 of 6 `setup` runs — is a second Bash call (`grep` or `cat` of `docs/handoff.md`) where Sonnet used Read. The script still ran exactly once with the right arguments in every one of those runs. Under the first wording Haiku passes every item on every run, and criterion 2 then requires both `model:` lines to be `haiku`; under the second both stay `sonnet`. The plan's self-review named only item 6 as a refinement of Q2, so this change was not declared when the plan went to you.
**Options:**
- **A — keep "exactly one Bash call" (what the plan approved at the gate said).** Both skills stay on `sonnet`; the verdict follows the existing changelog entry and comment, after the `CHANGELOG.md` wording fixes below. Strict; the miss is about how the template is read, not what is reported.
- **B — "the script ran exactly once, with the right arguments" (what Q2 said).** Item 1 is re-scored from the saved streams, which needs no new runs: Haiku then passes all 24 runs' items. Both `model:` lines move to `haiku`, and the comment on #76 and the changelog are corrected to say so. This sends the change back to `/codeo:implement`.
- **C — switch neither now, and file a follow-up** that tells `doctor` and `setup` to read the template with Read (or relaxes item 1) and re-runs the trial. Same result as A for this branch, plus an issue through `/codeo:issue`.

**Answer:**
A (answered in the conversation): keep "exactly one Bash call"; both skills stay on `sonnet`.

### Q2 — #57 overlaps on `CHANGELOG.md`: proceed, sequence or re-scope?

**Why it matters:** `overlap.sh 76` printed `57	CHANGELOG.md` and `57	glob:CHANGELOG.md` at this resume. #57 (`feat/dev-container-follow-ups-55`, assignee kbajpai, at `init`, no commits yet) lists `CHANGELOG.md` in its footprint and its plan's Q5 answered *proceed and coordinate* about #76 (`sequenced:  none — CHANGELOG.md overlaps #76`). Both add a bullet under `## Unreleased`; whichever merges second hits a one-hunk conflict in a file where each bullet is independent. This round is about to send #76 back to `/codeo:implement` to fix the sentence in its own bullet, so the file is touched again either way.
**Options:** proceed and coordinate · sequence after #57 · re-scope (not available: criterion 4 requires the entry).

**Answer:**
proceed and coordinate (answered in the conversation).

## Notes

**Commands run, with real output.**
- `bash scripts/sync-main.sh --abort-on-conflict` → `sync-main: the branch already contains origin/main`. `overlap.sh 76` and `overlap.sh --outside 76` printed nothing.
- `scope.sh origin/main HEAD` → `suite.shell=true` (`.codeo/76/*.md` and `CHANGELOG.md` are paths no suite names, so the `shell` suite is needed for them).
- Build `true` → exit 0. `bash tests/run.sh` → `all cases passed`, exit 0.
- `git diff origin/main...HEAD --stat` → 6 files, 403 insertions: `CHANGELOG.md` (+1), `docs/plans/2026-11-14-trial-doctor-setup-haiku.md`, and four dossier files. `skills/doctor/SKILL.md:4` and `skills/setup/SKILL.md:4` are `model: sonnet`.
- Re-read the saved Sonnet `doctor` streams: all six read `handoff.md` with the Read tool, all six Haiku `doctor` runs with Bash, as the comment says.

**Documentation.** The change moves `CHANGELOG.md` only, as the plan says; no page under `docs/` names the model of either skill. No overlay rules (`qc/invariants-extra`, `qc/wiki-rules` both exit 3) and no invariants file.

**Review.** An opus reviewer (`QC review:`) judged the criteria and the diff and agreed with everything above, raising Q1's discrepancy as its one Important finding and two wording findings, recorded here for the round:
- `CHANGELOG.md:11` says "each skill ran 3 times per model on 4 cases": each skill ran 2 cases, 4 in total, so as written it implies 48 runs against the "24 runs" later in the sentence.
- `CHANGELOG.md:11` says Haiku "matched Sonnet's on every item but one": on `doctor-fail` item 5 Sonnet passed 1 of 3 and Haiku 3 of 3, so they also differed there, in Haiku's favour; "Haiku passed every other item" is accurate.
- The plan's Task 3 Step 3 command does not run; already recorded in `implement.md`.

## Outcome

### Round 1 — 2026-11-15

Reviewed `origin/main` (`09e3013`)…`6d5de6f`; since then only `.codeo/76/qc.md` changed (`git diff 6d5de6f..HEAD --stat`: 1 file), so the build and suite run below stand for this tree.

**Commands and output.**
- `sync-main.sh --abort-on-conflict` → `sync-main: the branch already contains origin/main` (re-run at resume: the same).
- `overlap.sh 76` → at resume `57	CHANGELOG.md`, `57	glob:CHANGELOG.md`, raised as Q2 and answered *proceed and coordinate*; re-run after the answer: nothing. `overlap.sh --outside 76` → nothing.
- `scope.sh origin/main HEAD` → `suite.shell=true` (the dossiers and `CHANGELOG.md` are paths no suite classifies).
- `shell` build `true` → exit 0. `bash tests/run.sh` → `all cases passed`, exit 0.
- `gh issue view 76 --json comments` → the comparison comment (https://github.com/kbajpai/codeo/issues/76#issuecomment-6885759871) is there; re-read against the saved run streams: all six Sonnet `doctor` runs read `handoff.md` with Read, all six Haiku ones with Bash, as it says.
- No overlay rules (`qc/invariants-extra`, `qc/wiki-rules` exit 3), no invariants file, no shared environment.

| # | Criterion | Verdict | Settled by |
|---|---|---|---|
| 1 | A comparison of a Haiku run and a Sonnet run is recorded for `doctor`, and another for `setup`, naming what was compared and the result. | met | the comment on #76: method, the four cases, the six items, a per-case table, and a decision per skill |
| 2 | A skill whose Haiku run matched has `model: haiku`; a skill whose Haiku run differed keeps `model: sonnet`, and the issue says how it differed. | met — under Q1 = A (item 1 is "exactly one Bash call") | `skills/doctor/SKILL.md:4` and `skills/setup/SKILL.md:4` are `model: sonnet`; the comment's Decision section says how each differed |
| 3 | `bash tests/run.sh` passes. | met | `all cases passed`, exit 0, this round |
| 4 | `CHANGELOG.md` records the change, or the trial's result when nothing switched. | met — the entry exists, but see F1 and F2 on its accuracy | `CHANGELOG.md:11` |

**Documentation.** Only `CHANGELOG.md` moves; no page under `docs/` names the model of `doctor` or `setup` (checked with `grep`), so the plan's "nothing else to document" holds.

**Review.** An opus reviewer (`QC review:`) given the criteria and the diff: "Ready to merge? With fixes". Its findings are F1-F4 below together with this pass's own.

**Findings.**
- **F1 (blocking) — `/codeo:implement`'s.** `CHANGELOG.md:11` says "each skill ran 3 times per model on 4 cases". Each skill ran on 2 cases (4 in total), so as written it implies 48 runs, against the "24 runs" later in the same sentence. A released changelog that misstates the trial is untrue documentation. Fix: "each skill ran 3 times per model on 2 cases (`doctor` passing and failing, `setup` fresh with `--stack node` and refused), 24 runs in all", or equivalent.
- **F2 (non-blocking) — `/codeo:implement`'s.** `CHANGELOG.md:11` says Haiku's reports "matched Sonnet's on every item but one". On `doctor-fail` item 5 Sonnet passed 1 of 3 and Haiku 3 of 3, so they also differed there, in Haiku's favour. "Haiku passed every other item on every run" is accurate. Fix it in the same edit as F1.
- **F3 (non-blocking) — `/codeo:plan`'s.** The plan's item 1 ("exactly one Bash call") was a tightening of Q2's "the script ran exactly once" that its self-review did not declare. Settled by Q1 = A in this file; recorded so the next plan declares such a change.
- **F4 (non-blocking) — `/codeo:plan`'s.** The plan's Task 3 Step 3 command (`gh issue view --comments --json`) does not run; already recorded in `implement.md`. Nothing depends on it.

**Overlap.** #57 also adds a `CHANGELOG.md` bullet; Q2 = proceed and coordinate. Whichever merges second resolves the one-hunk conflict.

**Routing.** F1 is blocking and the code (the changelog line) does not say what the plan asked for (the trial's result, recorded accurately), so it is `/codeo:implement`'s: rewrite the one sentence of `CHANGELOG.md:11` for F1 and F2 together. Nothing else changes; neither `model:` line moves.

**Verdict: back to `/codeo:implement`.**

## Log

- 2026-11-14 — Q1 raised · cost: 4m · opus-5-5 241k in + 1.5M cached / 7k out · sonnet-5-5 27k in + 619k cached / 2k out
- 2026-11-14 — Q1 answered A; Q2 raised (overlap with #57) · cost: 0m · sonnet-5-5 2k in + 662k cached / 2k out
- 2026-11-15 — round 1: back to /codeo:implement (F1 blocking: CHANGELOG run count) · cost: 0m · opus-5-5 29k in + 226k cached / 706 out
