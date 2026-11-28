# Issue #220 — issue

| | |
|---|---|
| Issue | #220 |
| Step | issue |

## Where this stands

Filed as #220 from triage run 2026-11-28.

## Questions

None.

## Outcome

### Description

Make the shell tests deterministic under CI load: the `producer | grep -q` assertions that die of SIGPIPE under `set -o pipefail`, the simultaneous-beats race in `tests/live.test.sh`, and `tests/sandbox.test.sh`'s dependence on the machine's global gitignore.

### Motivation / Context

The required check `tests` failed four times on #214 and twice on `main` at `00de557` (run 46089672906) for reasons the release did not touch. Each red run costs a rerun and can hide a real failure. `/codeo:triage` collected this on 2026-11-28 (Q7) from `.codeo/done/213/qc.md` F4 and F6 and `.codeo/done/213/implement.md` lines 29 and 58.

### Key Requirements
- The last assertion of `tests/close-skill.test.sh` and `check_guarded` in `tests/role-guard.test.sh` stop piping a producer into `grep -q` under `pipefail`, for example by capturing the output and matching that, or with `grep -c`. The same pattern is looked for in the other tests and fixed where found.
- `tests/live.test.sh`'s `two_simultaneous_beats_from_one_checkout_leave_a_fresh_signal` ("round 9 published: want [1] got [0]") is diagnosed and made deterministic, or its timing assumption is stated and bounded.
- `tests/sandbox.test.sh` sets its own `GIT_CONFIG_GLOBAL` (lines 409 and 417 run `git add .sbx`), so it passes where the machine's global excludes list `.sbx`.

### Acceptance Criteria
- [ ] `bash tests/run.sh` passes 20 times in a row under parallel load, and the `tests` check no longer needs a rerun for these causes.
- [ ] No test pipes a producer into `grep -q` under `pipefail` without capturing the output first.
- [ ] `tests/sandbox.test.sh` passes with a global excludes file that lists `.sbx`.
- [ ] The `live.test.sh` race has a recorded cause and a fix or a stated bound.

### Out of Scope
Changing the scripts under test, and the CI configuration.

### Reference
`.codeo/done/213/qc.md` F4, F6; `.codeo/done/213/implement.md` lines 29, 58; `.codeo/intake/triage/2026-11-28.md` Q7; #211 (parallel test runs).

## Log

- 2026-11-28 — filed #220 from triage 2026-11-28
