# Issue — issue

## Questions

Answered in the conversation (triage run 6, 2026-11-18).

## Draft

**Title:** Sandbox follow-ups from #99: failed-step next steps in codeo-sandbox.sh, and sandbox-proof tests (consolidates QC F19-F21, F24)
**Type:** none (user-owned repository) · **Labels:** enhancement

### Description

#99 made the sbx issue sandbox usable and merged as #124. Its QC and implementation rounds recorded non-blocking gaps that nobody filed. Three are in `.sbx/codeo-sandbox.sh`: when a step fails it leaves the engineer without a named way forward. The rest are gaps in `tests/sandbox.test.sh` and the dev container test. One of them makes the dev container test fail when the suite runs inside an sbx sandbox.

### Motivation / Context

- **F19:** if the start script's `exec` fails (`.sbx/codeo-sandbox.sh:182`), `issue` ends with sbx's own error and no `codeo-sandbox:` line naming the next step.
- **F20:** rerunning `issue` on an existing sandbox still needs a valid pin, because `read_pin` runs before `ensure_sandbox` (`:214`). QC called this rare, because the pin is committed.
- **F21:** when `end` cannot fetch the sandbox's state (`:372-374`), the message names no way out, even with `--force`. A broken sandbox can then be removed only with a raw `sbx rm --force`.
- **Test gaps** (QC F24 and the deferred minors in `implement.md` round 3):
  - The dev container test "without the marker" relies on the real `$HOME/.codeo-sandbox` being absent. Running `tests/run.sh` inside an sbx sandbox, which is where #99 sends engineers, fails it. This is the one QC called most worth doing.
  - `tests/sandbox.test.sh` reads `CHANGELOG.md` line 9 by number.
  - `issue` has no test for a failed `run -d` (only `open` has one).
  - `required_state` is an undeclared global.
  - `sandbox_state` has no test for a row with fewer than three columns.
  - The CHANGELOG check guards only that the old clause is gone, not that the new one is present.

### Key Requirements

- A failed start-script `exec` in `issue` ends with a `codeo-sandbox:` line that names the next step.
- Rerunning `issue` on an existing sandbox does not need a readable pin.
- A failed state fetch in `end` names a way to remove the sandbox, including what `--force` does.
- `tests/run.sh` passes inside an sbx sandbox as well as outside one.
- Each test gap listed above is closed, or is dropped with a reason in the plan.

### Acceptance Criteria

- [ ] With the start script's `exec` failing, `issue` prints a `codeo-sandbox:` line that names the next step; a test covers it.
- [ ] `issue` on an existing sandbox succeeds with the pin unreadable; a test covers it.
- [ ] When `end`'s state fetch fails, the output names a way to remove the sandbox; a test covers it with and without `--force`.
- [ ] The dev container test without the marker passes when `$HOME/.codeo-sandbox` exists, and a test shows it.
- [ ] A failed `run -d` in `issue` has a test.
- [ ] No test reads `CHANGELOG.md` by line number.
- [ ] `tests/run.sh` passes.

### Out of Scope

- The `scripts/lock.sh` volume TODO in a sandbox (#123).
- The evaluation page's wording findings F17, F18 and F22, which were dismissed in triage.
- Changes to the sbx CLI's behaviour.

### Reference

- `.codeo/done/99/qc.md`, round 3, findings F19-F21 and F24, on `origin/main`.
- `.codeo/done/99/implement.md`, round 3, *Deferred minors from the task reviews*.
- PR #124; issue #99.

## Log

2026-11-18 — drafted, awaiting approval · cost: unavailable
