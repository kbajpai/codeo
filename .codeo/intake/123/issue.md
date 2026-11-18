# Issue #123 — issue

| | |
|---|---|
| Source | Delegated by `/codeo:plan` for #99 (plan.md Q16), from #99's host acceptance (`.codeo/99/implement.md`, `## Acceptance`, steps 2 and 8a) |
| Updated | 2026-11-18 |

## Where this stands

Filed as #123 (https://github.com/kbajpai/codeo/issues/123), approved by the engineer 2026-11-18.

## Questions

### Q1 — What should the lock say about the workspace when the start script runs in an sbx sandbox?

**The problem.** The dev container's start script runs inside an sbx issue sandbox too (`.sbx/codeo-sandbox.sh issue`). It takes the lock with `host: container`, and `scripts/lock.sh:141-145` then looks in `/proc/self/mountinfo` for the Docker volume mounted at `/workspaces`. A sandbox's clone is a bind mount at the host path (`/d/Downloads/task22/codeo-99`), not a volume at `/workspaces`, so the lock gets `volume: unknown`. The start script then prints:

`TODO — could not read the workspace volume's name from /proc/self/mountinfo: fill the lock's volume line in by hand (docker volume ls on the host)`

That advice is wrong for a sandbox: there is no volume to find, and `/codeo:close` uses the `volume:` line to print `docker volume rm …`, which does not apply. It printed on every `issue` run in #99's acceptance.

**Why it matters:** it decides what the issue asks for, and whether it reaches `/codeo:close`.

**Options:**
- *The lock knows it is in a sandbox* (recommended): when the sbx marker (`~/.codeo-sandbox`, written by `codeo-sandbox.sh`) is present, the lock records the sandbox (`sandbox: codeo-<N>`) instead of a `volume:` line, prints no volume TODO, and `/codeo:close`'s report names `codeo-sandbox.sh end <N>` as the removal step. Fixes the advice everywhere it is read.
- *Only stop the wrong TODO:* with the marker present, the lock writes no `volume:` line and no TODO. `/codeo:close` then has nothing to name, and says so as it would for an unknown volume.
- *Something else:* say what.

**Answer:**
Accepted the recommendation (engineer, in the conversation, 2026-11-18).

### Q2 — Is anything else out of scope for this issue?

**Why it matters:** the issue's Out of Scope section. My proposal: `scripts/cleanup.sh` and `/codeo:cleanup` listing sandboxes (they only know Docker containers today) stay out, as a follow-up; so does any change to `.sbx/codeo-sandbox.sh` beyond what Q1 needs. Say if you want either in, or anything else out.

**Answer:**
Accepted the recommendation (engineer, in the conversation, 2026-11-18).

## Notes

- Not a duplicate: `github.sh issue search` for "lock volume sandbox" and "volume TODO lock" found only #99, #73, #113, #55, #47, #96.
- `skills/close/SKILL.md:504-518` reads the lock's `host` and `volume:` lines for its final report.

## Outcome

Filed #123: "Record an sbx sandbox in the workflow lock instead of a Docker volume", label `enhancement`, no Issue Type. Body in `body.md`.

## Log
- 2026-11-18 — filed #123 (delegated by /codeo:plan for #99, Q16) · cost: 7m · opus-5-5 16k in + 2.4M cached / 7k out
