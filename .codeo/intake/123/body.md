### Description

The dev container's start script also runs inside a Docker Sandboxes (sbx) issue sandbox: `.sbx/codeo-sandbox.sh issue <N> <branch>` creates the sandbox and runs `.devcontainer/scripts/devcontainer-start.sh` in it. That script takes the workflow lock with `host: container`.

For that host, `scripts/lock.sh` (lines 141-145) looks in `/proc/self/mountinfo` for the Docker volume mounted at `/workspaces`, and records it on the lock's `volume:` line. A sandbox's clone is not a Docker volume. It is a bind mount at the host path, for example `/d/Downloads/task22/codeo-99`. So the lock gets `volume: unknown`, and every `issue` run prints:

```
devcontainer-start: TODO — could not read the workspace volume's name from /proc/self/mountinfo: fill the lock's volume line in by hand (docker volume ls on the host)
```

That advice is wrong in a sandbox, because there is no volume to find. `/codeo:close` then reads the `volume:` line for its final report and names a `docker volume rm` that does not apply. In a sandbox, the removal step is `codeo-sandbox.sh end <N>`.

### Motivation / Context

#99's host acceptance printed this TODO on every `issue` run (steps 2 and 8a). An engineer following it would look for a Docker volume that does not exist. `scripts/` ships to every project that uses codeo, so #99 left the fix out of its own scope.

### Key Requirements

- When the start script runs in an sbx sandbox, the lock records the sandbox instead of a volume. `codeo-sandbox.sh` writes a marker in the sandbox, `~/.codeo-sandbox`, which `session-title.sh` already reads; the same marker tells the lock it is in a sandbox.
- No volume TODO is printed in a sandbox.
- `/codeo:close`'s final report names `codeo-sandbox.sh end <N>` as the removal step for a sandbox, in place of the Docker commands.
- A dev container (no marker) behaves exactly as it does now.

### Acceptance Criteria
- [ ] In an sbx issue sandbox, the lock taken by the start script has a `sandbox: codeo-<N>` line and no `volume:` line.
- [ ] No `could not read the workspace volume's name` TODO is printed in a sandbox.
- [ ] For a lock with a `sandbox:` line, `/codeo:close`'s final report names `codeo-sandbox.sh end <N>` and prints no `docker rm` or `docker volume rm` line.
- [ ] In a dev container, the lock's `volume:` line and the TODO when it cannot be read are unchanged.
- [ ] The tests cover the sandbox lock, the dev container lock, and close's report for both.

### Out of Scope

- `/codeo:cleanup` and `scripts/cleanup.sh` listing or removing sandboxes. They know only Docker containers today; that is a follow-up.
- Changes to `.sbx/codeo-sandbox.sh` beyond what this needs.

### Reference

- `scripts/lock.sh:141-145` (the volume lookup and the TODO).
- `skills/close/SKILL.md:504-518` (the final report reads `host` and `volume:`).
- #99: `.sbx/codeo-sandbox.sh`, its README, and the host acceptance run (`.codeo/99/implement.md`, `## Acceptance`, steps 2 and 8a). Found while planning its round 3 (`.codeo/99/plan.md` Q16).
