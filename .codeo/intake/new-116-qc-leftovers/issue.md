# Issue — issue

## Questions

**Q1. Scope.** From /codeo:triage run 2026-11-17-4 Q1: F7, F10, F11 of #116's QC become one new issue; F8-F9 are folded into #118 (edited in place).
**Answer:** engineer: "file both, fold F8-F9 into #118".

## Draft

**Title:** Tests and criteria left over from #116's QC: Podman marker test, stash/abandon pins, and criterion 13 on #107

**Labels:** none proposed beyond `enhancement` (the repository has no Issue Types)

### Description

Three non-blocking findings from #116's QC round 2 were never filed. None breaks behaviour.

### Motivation / Context

From `.codeo/done/116/qc.md` (on `origin/main`), round 2:

- **F7** — "Criterion 13 stays unchecked on GitHub. The engineer dropped it at plan Q4 with the output (`rc=0`) already in `plan.md`, so no code or plan defect remains." #116 has merged, so the criterion is still unchecked on a closed issue and nothing on the issue explains why.
- **F10** — "`tests/role.test.sh:221-225` `both_markers_are_guarded_the_same` creates `/.dockerenv` as well, so it passes with or without the `/run/.containerenv` check; its name suggests more. `containerenv_alone_is_guarded` is the case that pins the change."
- **F11** — "`tests/close-skill.test.sh:321-322` still search the whole stash-and-abandon section, so one pin could in principle be met by the other's paragraph; the two needles differ in their lead-in, so neither is today."

### Key Requirements

- Criterion 13 on #116 is either struck with a one-line reason or answered by posting the `rc=0` output (it is in `docs/plans/2026-11-16-follow-ups-70-71-104-107.md`).
- `both_markers_are_guarded_the_same` is renamed, or changed, so its name says what it pins.
- The two stash and abandon pins in `tests/close-skill.test.sh` each search only their own paragraph.

### Acceptance Criteria

- [ ] #116's criterion 13 is checked off or struck, with the reason on the issue.
- [ ] `both_markers_are_guarded_the_same` fails when the `/run/.containerenv` check is removed, or is renamed so it does not claim to pin it.
- [ ] Each of the two stash and abandon pins fails when only the other paragraph carries its text.

### Out of Scope

- F8 and F9 of the same QC round: they go into #118.
- Anything else #116 recorded.

### Reference

- `.codeo/done/116/qc.md`, round 2, F7, F10, F11 (on `origin/main`)
- `tests/role.test.sh`, `tests/close-skill.test.sh`
- `/codeo:triage` run 2026-11-17-4, Q1
