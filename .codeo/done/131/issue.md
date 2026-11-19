# Issue #131 — issue

## Outcome

Delegated from `/codeo:triage` (consolidation of #123 and #125, approved by the engineer in triage). Both bodies were read from GitHub and merged without dropping a requirement or criterion; no open question. Proposed: no Issue Type (user-owned repo has none), label `enhancement`.

## Draft

**Title:** Make the sbx sandbox lock and follow-ups right: record the sandbox, not a volume, and close the #99 script and test gaps (consolidates #123, #125)

### Description

#99 (merged as #124) made the sbx issue sandbox usable, and left two sets of work in the same feature: the lock and `/codeo:close` still treat a sandbox as a Docker volume, and `.sbx/codeo-sandbox.sh` and its tests have gaps. This issue consolidates both so one workflow does them together. They share the `~/.codeo-sandbox` marker, `.sbx/codeo-sandbox.sh`, `scripts/lock.sh` and the sandbox and dev container tests, so doing them apart would edit the same files twice.

It supersedes #123 and #125, which the engineer closes after this is filed.

### Motivation / Context

**The lock and close treat a sandbox as a volume (from #123).** `.sbx/codeo-sandbox.sh issue <N> <branch>` creates the sandbox and runs `.devcontainer/scripts/devcontainer-start.sh` in it, which takes the workflow lock with `host: container`. For that host, `scripts/lock.sh` (lines 141-145) looks in `/proc/self/mountinfo` for the Docker volume mounted at `/workspaces` and records it on the lock's `volume:` line. A sandbox's clone is a bind mount at the host path (for example `/d/Downloads/task22/codeo-99`), not a volume. So the lock gets `volume: unknown` and every `issue` run prints:

```
devcontainer-start: TODO — could not read the workspace volume's name from /proc/self/mountinfo: fill the lock's volume line in by hand (docker volume ls on the host)
```

That advice is wrong in a sandbox, because there is no volume to find. `/codeo:close` then reads the `volume:` line for its final report and names a `docker volume rm` that does not apply; in a sandbox the removal step is `codeo-sandbox.sh end <N>`. #99's host acceptance printed this TODO on every `issue` run (steps 2 and 8a). `scripts/` ships to every project that uses codeo, so #99 left the fix out of its own scope.

**Gaps in `.sbx/codeo-sandbox.sh` and its tests (from #125, QC F19-F21 and F24).**
- **F19:** if the start script's `exec` fails (`.sbx/codeo-sandbox.sh:182`), `issue` ends with sbx's own error and no `codeo-sandbox:` line naming the next step.
- **F20:** rerunning `issue` on an existing sandbox still needs a valid pin, because `read_pin` runs before `ensure_sandbox` (`:214`). QC called this rare, because the pin is committed.
- **F21:** when `end` cannot fetch the sandbox's state (`:372-374`), the message names no way out, even with `--force`. A broken sandbox can then be removed only with a raw `sbx rm --force`.
- **Test gaps** (QC F24 and the deferred minors in `implement.md` round 3):
  - The dev container test "without the marker" relies on the real `$HOME/.codeo-sandbox` being absent. Running `tests/run.sh` inside an sbx sandbox, which is where #99 sends engineers, fails it. QC called this the one most worth doing.
  - `tests/sandbox.test.sh` reads `CHANGELOG.md` line 9 by number.
  - `issue` has no test for a failed `run -d` (only `open` has one).
  - `required_state` is an undeclared global.
  - `sandbox_state` has no test for a row with fewer than three columns.
  - The CHANGELOG check guards only that the old clause is gone, not that the new one is present.

### Key Requirements

- When the start script runs in an sbx sandbox, the lock records the sandbox instead of a volume. `codeo-sandbox.sh` writes a marker in the sandbox, `~/.codeo-sandbox`, which `session-title.sh` already reads; the same marker tells the lock it is in a sandbox.
- No volume TODO is printed in a sandbox.
- `/codeo:close`'s final report names `codeo-sandbox.sh end <N>` as the removal step for a sandbox, in place of the Docker commands.
- A dev container (no marker) behaves exactly as it does now.
- A failed start-script `exec` in `issue` ends with a `codeo-sandbox:` line that names the next step.
- Rerunning `issue` on an existing sandbox does not need a readable pin.
- A failed state fetch in `end` names a way to remove the sandbox, including what `--force` does.
- `tests/run.sh` passes inside an sbx sandbox as well as outside one.
- Each test gap listed above is closed, or is dropped with a reason in the plan.

### Acceptance Criteria
- [ ] In an sbx issue sandbox, the lock taken by the start script has a `sandbox: codeo-<N>` line and no `volume:` line.
- [ ] No `could not read the workspace volume's name` TODO is printed in a sandbox.
- [ ] For a lock with a `sandbox:` line, `/codeo:close`'s final report names `codeo-sandbox.sh end <N>` and prints no `docker rm` or `docker volume rm` line.
- [ ] In a dev container, the lock's `volume:` line and the TODO when it cannot be read are unchanged.
- [ ] The tests cover the sandbox lock, the dev container lock, and close's report for both.
- [ ] With the start script's `exec` failing, `issue` prints a `codeo-sandbox:` line that names the next step; a test covers it.
- [ ] `issue` on an existing sandbox succeeds with the pin unreadable; a test covers it.
- [ ] When `end`'s state fetch fails, the output names a way to remove the sandbox; a test covers it with and without `--force`.
- [ ] The dev container test without the marker passes when `$HOME/.codeo-sandbox` exists, and a test shows it.
- [ ] A failed `run -d` in `issue` has a test.
- [ ] No test reads `CHANGELOG.md` by line number.
- [ ] `tests/run.sh` passes.

### Out of Scope

- `/codeo:cleanup` and `scripts/cleanup.sh` listing or removing sandboxes. They know only Docker containers today; that is a follow-up.
- Changes to `.sbx/codeo-sandbox.sh` beyond what the requirements above need.
- The evaluation page's wording findings F17, F18 and F22, which were dismissed in triage.
- Changes to the sbx CLI's behaviour.

### Reference

- Supersedes #123 (lock and close record a volume in a sandbox) and #125 (sandbox follow-ups from #99, QC F19-F21 and F24).
- `scripts/lock.sh:141-145` (the volume lookup and the TODO); `skills/close/SKILL.md:504-518` (the final report reads `host` and `volume:`).
- `.codeo/done/99/qc.md`, round 3, findings F19-F21 and F24, on `origin/main`; `.codeo/done/99/implement.md`, round 3, *Deferred minors from the task reviews*; #99's host acceptance run (`.codeo/done/99/implement.md`, `## Acceptance`, steps 2 and 8a).
- PR #124; issue #99.
