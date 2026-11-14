# Issue #76 — qc

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/76 |
| Branch | `feat/trial-doctor-setup-haiku-5` |
| Updated | 2026-11-14 |

## Where this stands

Round 1 is checked. Q1 is answered A; Q2 (the #57 overlap on `CHANGELOG.md`, new at this resume) is open, so the verdict waits for it.

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

_Pending — written at the hand-off._

## Log

- 2026-11-14 — Q1 raised · cost: 4m · opus-5-5 241k in + 1.5M cached / 7k out · sonnet-5-5 27k in + 619k cached / 2k out
- 2026-11-14 — Q1 answered A; Q2 raised (overlap with #57) · cost: 0m · sonnet-5-5 2k in + 662k cached / 2k out
