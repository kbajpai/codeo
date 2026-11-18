# Issue — new-test-suite-fixes-116-100

## Outcome

Delegated from `/codeo:triage` (consolidation of #121 and #130, approved by the engineer). Both bodies read from GitHub and merged with nothing dropped; no open question. Proposed: no Issue Type (the repo has none), label `bug`? No — tests only, so `enhancement` is wrong too; label `bug` for the live.test.sh defect.

## Draft

**Title:** Fix test-suite gaps left by #116 and #100: stamp checks against the clone, and two mislabelled pins (consolidates #121, #130)

### Description

Two small sets of test-suite fixes, with no behaviour change, left by merged workflows: three non-blocking findings from #116's QC (#121) and one defect `/codeo:qc` found in `tests/live.test.sh` on #100 (#130). They are consolidated so one workflow fixes the tests together. It supersedes #121 and #130, which the engineer closes after this is filed.

### Motivation / Context

**From #116's QC, round 2 (`.codeo/done/116/qc.md`):**
- **F7** — "Criterion 13 stays unchecked on GitHub. The engineer dropped it at plan Q4 with the output (`rc=0`) already in `plan.md`, so no code or plan defect remains." #116 has merged, so the criterion is still unchecked on a closed issue and nothing on the issue explains why.
- **F10** — "`tests/role.test.sh:221-225` `both_markers_are_guarded_the_same` creates `/.dockerenv` as well, so it passes with or without the `/run/.containerenv` check; its name suggests more. `containerenv_alone_is_guarded` is the case that pins the change."
- **F11** — "`tests/close-skill.test.sh:321-322` still search the whole stash-and-abandon section, so one pin could in principle be met by the other's paragraph; the two needles differ in their lead-in, so neither is today."

**From #100's QC (`.codeo/done/100/qc.md`, line 19):** `tests/live.test.sh` checks whether the live-signal stamp exists with `[[ -e $(git -C "$clone" rev-parse --git-path codeo-live-beat) ]]`. `git rev-parse --git-path` prints a path relative to the directory git ran in (here `.git/codeo-live-beat` for a normal clone), but `[[ -e ]]` resolves it against the shell's current directory, not `$clone`. When the suite runs from a checkout that has its own `.git/codeo-live-beat`, the "stamp absent" assertions find that checkout's stamp and fail. Every checkout with a running workflow has one. On `origin/main`:
- `tests/live.test.sh:229` (`no lock: stamp`) and `:236` (`base: stamp`) use the form above.
- `:370-375` read the same `--git-path` into `$stamp` and test `[[ -e $clone/$stamp || -e $stamp ]]`; the `-e $stamp` half has the same flaw, so "stamp gone" (`:375`) can fail for the same reason.

### Key Requirements

- Criterion 13 on #116 is either struck with a one-line reason or answered by posting the `rc=0` output (it is in `docs/plans/2026-11-16-follow-ups-70-71-104-107.md`).
- `both_markers_are_guarded_the_same` is renamed, or changed, so its name says what it pins.
- The two stash and abandon pins in `tests/close-skill.test.sh` each search only their own paragraph.
- Every stamp assertion in `tests/live.test.sh` resolves the stamp path against the clone it names, never against the current directory.
- The suite passes in a checkout that has its own `.git/codeo-live-beat`.

### Acceptance Criteria
- [ ] #116's criterion 13 is checked off or struck, with the reason on the issue.
- [ ] `both_markers_are_guarded_the_same` fails when the `/run/.containerenv` check is removed, or is renamed so it does not claim to pin it.
- [ ] Each of the two stash and abandon pins fails when only the other paragraph carries its text.
- [ ] With a `.git/codeo-live-beat` file present in the checkout running the suite, `bash tests/live.test.sh` passes; with none present, it passes as before.
- [ ] No stamp assertion in `tests/live.test.sh` tests a relative `--git-path` result against the current directory.
- [ ] The "no lock", "base" and "clear deletes the ref and the stamp" cases still fail when the clone's stamp exists (or is not deleted).

### Out of Scope

- F8 and F9 of #116's QC round: they go into #118.
- Other changes to `live.sh` or `live-signal.sh`; #118 covers its own leftovers in the same files.
- Anything else #116 recorded.

### Reference

- Supersedes #121 and #130.
- `.codeo/done/116/qc.md`, round 2, F7, F10, F11; `.codeo/done/100/qc.md`, line 19 (both on `origin/main`).
- `tests/role.test.sh`, `tests/close-skill.test.sh`, `tests/live.test.sh`.
- #118 (in review) also edits `tests/live.test.sh`; plan this after #118 merges to avoid a conflict.
