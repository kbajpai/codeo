# Issue #170 — init

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/170 |
| Branch | `docs/docs-say-codeo-host-command` |
| Updated | 2026-11-25 |

## Where this stands

Initialized: branch `docs/docs-say-codeo-host-command` cut off `origin/main` at `6e6628336c9bd40037c1cd7c80c8694f0ecddc21`, and pushed. Next step: `/codeo:plan` in the issue's container.

## Questions

None.

## Outcome

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/170 — Docs: say the `codeo` host command installs separately, and cover macOS flock and the keychain over SSH |
| State | open · labels `documentation` |
| Branch | `docs/docs-say-codeo-host-command` off `main` at `6e6628336c9bd40037c1cd7c80c8694f0ecddc21` |
| Board | Ready → In progress |

**Problem.** The README's one-line `install.sh` installs the Claude Code plugins only, not the `codeo` host command, which has its own install line in `.devcontainer/README.md`; an engineer who runs the README line and types `codeo` gets "command not found". Two macOS facts are also undocumented: how to get `flock` (`brew install flock`), and that `codeo home` over SSH fails at the Docker build with a keychain error until the login keychain is unlocked. Found on a Mac Studio over SSH.

**Acceptance criteria** — verbatim from the issue, unchecked:
- [ ] README.md, in or next to *Installing*, has one line saying `install.sh` installs the plugins and not the `codeo` command, with a link to the `.devcontainer/README.md` section that has its install line.
- [ ] The README's macOS paragraph names `brew install flock`.
- [ ] A documented macOS note gives the keychain error text and the `security -v unlock-keychain` command.
- [ ] Every command and link the changes name exists and is spelled as in the repo.
- [ ] `bash tests/run.sh` passes (any doc-pin tests updated with the wording).

**Out of scope.** Changing `codeo` itself (a zsh-aware PATH hint, or detecting the keychain failure and printing the unlock command); other macOS behaviour not yet verified past `codeo home`.

**Open at intake.** None.

**Overlap to watch.** `inflight.sh` shows #168 (release v1.0.9, `README.md` in its footprint) and #171 (README restructure, at `/codeo:plan`) both in flight. All three edit `README.md`, and #171 reorders the *Installing* section this issue adds a line to, so whichever merges second will conflict. #170 is the smallest, so it is the easiest to land first.

## Log

- 2026-11-25 — initialized: branch docs/docs-say-codeo-host-command off main at 6e6628336c9bd40037c1cd7c80c8694f0ecddc21 · 1m · sonnet-5-5 14k in + 679k cached / 3k out
