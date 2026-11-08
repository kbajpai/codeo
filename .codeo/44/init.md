# Issue #44 — init

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/44 |
| Branch | `feat/dev-container-defaults-remote-control` |
| Base | `main` at `89385f2` |

## Where this stands

Draft, awaiting the engineer's approval at the review gate. Nothing is cut or pushed yet.

## Questions

None.

## Outcome

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/44 — Dev container defaults: Remote Control on at startup and a `codeo [home]` window title |
| State | open · labels `enhancement` |
| Branch | `feat/dev-container-defaults-remote-control` off `main` at `89385f2` |
| Board | Ready → In progress |

**Problem.** codeo's dev container (#36) starts Claude Code with Remote Control off, so each session needs
`/remote-control` by hand, and the VS Code window reads `codeo [Dev Container: codeo @ desktop-linux]`.
Wanted: Remote Control on in every interactive session (`/clear` included), and a per-clone window title
`codeo [home]` (no lock) or `codeo [#<N>]` (lock held), not shown in `git status`, with user-level settings kept.

**Acceptance criteria** — verbatim from the issue, unchecked:
- [ ] In a freshly built container after `claude auth login`, a new Claude Code session is listed in claude.ai/code without running `/remote-control`.
- [ ] A session started with `/clear` in the same container is also listed.
- [ ] With `CLAUDE_CODE_OAUTH_TOKEN`, `ANTHROPIC_API_KEY` or `ANTHROPIC_BASE_URL` set, or no claude.ai login, the start script reports it as a TODO and still exits 0.
- [ ] The window title reads `codeo [home]` with no `.codeo/active`, and `codeo [#<N>]` with one.
- [ ] Re-running the start script keeps the title right and leaves other keys in `.vscode/settings.json` alone.
- [ ] `git status` is clean after the start script has written the title.
- [ ] `~/.claude/settings.json` still has the plugins and update channel the image set.
- [ ] `tests/devcontainer.test.sh` covers the title and the login checks, and `bash tests/run.sh` passes.

**Out of scope.** Naming sessions (`codeo [home] · <id>`; that is #45); setting this up for projects that use
codeo (`/codeo:setup`); the other items in #40.

**Open at intake.** Whether `remoteControlAtStartup` behaves the same on the Claude Code version the image
installs (2.1.319), and how `.vscode/` is kept out of `git status` (codeo's `.gitignore` has no line for it).

## Log

- 2026-11-08 — initialized: branch feat/dev-container-defaults-remote-control off main at 89385f2 · cost: 1m · sonnet-5-5 18k in + 406k cached / 3k out
