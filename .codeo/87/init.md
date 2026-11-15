# Issue #87 — init

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/87 |
| Branch | `fix/dev-container-start-script-reports` |
| Updated | 2026-11-15 |

## Where this stands

Branch `fix/dev-container-start-script-reports` cut off `main` at aaf4883, claimed and pushed. Nothing is open; the next step is `/codeo:plan`, run in this issue's own container.

## Questions

None.

## Outcome

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/87 — The dev container start script reports a `.codeo/active` that names no issue |
| State | open · labels `bug` |
| Branch | `fix/dev-container-start-script-reports` off `main` at `aaf4883` |
| Board | Ready → In progress |

**Problem.** `devcontainer-start.sh` treats any non-empty `.codeo/active` as a held lock. A file holding only a newline, or text with no `issue:` line, therefore takes no lock and prints nothing; `container-name.sh` names the container "home" and `folder-check.sh` says nothing, so the container looks started and has no lock. #57 fixed the same silent state for a zero-byte file (the script removes it and takes the lock); this is the non-empty, no-issue case, found by `/codeo:qc` as #57's F2 and brought here by `/codeo:triage`. The fix is a single `todo:` line from the start script, which leaves the file alone.

**Acceptance criteria** — verbatim from the issue, unchecked:
- [ ] A test starts a container on an issue branch with a `.codeo/active` holding only a newline, and another with one holding text with no `issue:` line: each prints one TODO that names `.codeo/active`, no lock is taken, and the file is unchanged afterwards.
- [ ] The same file on the base branch prints the same TODO and is unchanged.
- [ ] A `.codeo/active` with an `issue:` line (`issue:   55`, `issue: #55`) prints no such TODO and takes no second lock; a zero-byte one is still removed, as before.
- [ ] `.devcontainer/README.md` states the behaviour in its list of what the start script does.
- [ ] `bash tests/run.sh` passes and `CHANGELOG.md` records the change.

**Out of scope.**
- `lock.sh`, and anything under `scripts/`, `lib/`, `hooks/` or `skills/`.
- `container-name.sh`, `folder-check.sh` and `window-title.sh`: the titles and the folder check keep reading the file as they do.
- A `.codeo/active` that is a directory (it predates #57 and is not a lock file).
- Repairing a half-written lock for the engineer.

**Open at intake.** None. The issue's dossier (`issue.md`, adopted) settled the scope: the start script only, report and leave the file, "names an issue" is `container-name.sh`'s existing rule (`issue:` at the start of a line, then optional spaces, tabs or `#`, then digits).

## Log

- 2026-11-15 — initialized: branch fix/dev-container-start-script-reports off main at aaf4883 · cost: 1m · sonnet-5-5 84k in + 689k cached / 4k out
