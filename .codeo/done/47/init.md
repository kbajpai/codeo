# Issue #47 — init

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/47 |
| Branch | `fix/harden-dev-container-scripts-session` |
| Updated | 2026-11-09 |

## Where this stands

Branch `fix/harden-dev-container-scripts-session` cut off `origin/main` at `162720b`; the
dossier is pushed to claim it, the assignee and board card are set. The engineer asked to work this issue in a
separate container, so this checkout is **not** switched to the branch and takes no lock; the lock is taken in
the new container (`lock.sh take container`) once it has the branch checked out.

## Questions

None.

## Outcome

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/47 — Harden the dev container scripts and the session-title hook; persist the git identity; keep titles current |
| State | open · labels `bug` |
| Branch | `fix/harden-dev-container-scripts-session` off `main` at `162720b` |
| Board | Ready → In progress |

**Problem.** The dev container's `devcontainer-start.sh` and `window-title.sh` (from #44) print a misleading
`claude auth login` TODO when an auth variable is set, and fail with a wrong, missing or surprising result in
several edge cases (`info/exclude`, `issue: #44`, non-object JSON, a symlinked `settings.json`, file modes).
The git identity is lost whenever a container is recreated or a second container is made. The session-title hook
from #45 has a few gaps of its own (an unguarded command, weak tests), titles do not follow the lock taken or
released mid-session, and a container with `core.fileMode=false` commits new scripts as non-executable.

**Acceptance criteria** — verbatim from the issue, unchecked:
- [ ] With `ANTHROPIC_API_KEY` set, the start script's output has no `claude auth login` line; same for `CLAUDE_CODE_OAUTH_TOKEN`.
- [ ] Making `info/exclude` unwritable still prints a `window-title:` line.
- [ ] `issue: #44` in the lock gives a title containing `[#44]` exactly once.
- [ ] A `settings.json` holding `[]` is reported as not an object.
- [ ] A symlinked `settings.json` is still a symlink afterwards.
- [ ] `git ls-files -s .devcontainer/scripts/window-title.sh` shows mode 100755.
- [ ] A failed `mv` leaves no `.tmp` file; the written file's mode is not 0600 unless the original's was.
- [ ] With `session-title.sh` removed, running the registered hook command exits 0 with no output.
- [ ] A hook input whose `session_title` begins with a newline prints nothing.
- [ ] Taking and releasing the lock changes the title `window-title.sh --print` reports, and the window title written for the clone follows without a container restart.
- [ ] A script added in a fresh container is staged with mode 100755 without `git update-index --chmod`.
- [ ] `bash tests/run.sh` prints `all cases passed`.
- [ ] A container created fresh, with the `~/.config/git` volume already holding an identity, reports no git identity TODO.

**Out of scope.** Handling JSONC by parsing comments; Claude login and plugins persistence (#40).

**Open at intake.** None as questions. The issue leaves one design choice to the plan: how an already-running
session is retitled when the lock changes. It is a large bundle (the #44 hardening, the git-identity volume and
the #45 follow-ups); the plan may propose splitting it.

## Log

- 2026-11-09 — initialized: branch fix/harden-dev-container-scripts-session off main at 162720b · cost: 2m · sonnet-5-5 16k in + 1.3M cached / 4k out
