# Issue #217 — init

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/217 |
| Branch | `feat/217-add-codeo-go-codeo-done` |
| Updated | 2026-11-28 |

## Where this stands

Approved and pushed. Branch `feat/217-add-codeo-go-codeo-done` off `main` at `00de557a939e7b7b3477c34c23dff81820ff03ae`.

## Questions

None.

## Outcome

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/217 — Add `codeo go` and `codeo done`, a `--version` flag, and a more verbose `codeo update` |
| State | open · labels `enhancement`, `priority: medium` |
| Branch | `feat/217-add-codeo-go-codeo-done` off `main` at `00de557a939e7b7b3477c34c23dff81820ff03ae` |
| Board | Ready → In progress |

**Problem.** Starting an issue takes three manual steps (mark Ready, `/codeo:init`, `codeo issue <N>`), and finishing takes `/codeo:cleanup` plus copying the printed command. `codeo` also has no version of its own, and `codeo update` prints one line at the end. The issue adds `codeo go <N>` and `codeo done <N>` as host commands, a `--version`/`-v` flag, a verbose `codeo update`, and a macOS keychain preflight before `go` and `done`.

**Acceptance criteria** — verbatim from the issue, unchecked:
- [ ] `codeo go <N>` on a Ready or Backlog issue ends with the container running and its name and branch printed.
- [ ] A failed step in `go` prints one line naming it and leaves later steps unrun.
- [ ] `codeo done <N>` removes the container only when every proof passes, and otherwise prints the failed proof and removes nothing.
- [ ] `codeo --version` and `-v` print the version; the test fails when it differs from `plugin.json`.
- [ ] `codeo update` prints old and new version and a line per file; the failure paths still change nothing installed.
- [ ] With a stubbed `security` reporting a locked keychain, `go` and `done` stop before any board, git or Docker call and print the unlock command; unlocked or non-macOS, they go on.
- [ ] README, the keychain section and the release checklist are updated.

**Out of scope.** A web page or dashboard. Automatic removal by any other command. How Claude Desktop attaches to a container's volume.

**Open at intake.** Does `claude -p` run `/codeo:init` as a slash command? How does `codeo go` find the home clone from the host? The macOS keychain path is not verified on a real Mac; tests stub `security`.

## Log

- 2026-11-28 — initialized: branch feat/217-add-codeo-go-codeo-done off main at 00de557 · cost: 1m · sonnet-5-5 17k in + 869k cached   4k out
