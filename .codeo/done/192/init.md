# Issue #192 — init

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/192 |
| Branch | `feat/192-guard-home-checkout-no-project` |
| Updated | 2026-11-26 |

## Where this stands

Initialized: branch `feat/192-guard-home-checkout-no-project` cut off `origin/main` at `7b7cc0f481ddccf59126d73652c64198f9b69fae`, and pushed. Next step: `/codeo:plan` in the issue's container.

## Questions

None.

## Outcome

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/192 — Guard the home checkout: no project changes there unless the engineer overrides |
| State | open · labels `enhancement`, `priority: medium` |
| Branch | `feat/192-guard-home-checkout-no-project` off `main` at `7b7cc0f481ddccf59126d73652c64198f9b69fae` |
| Board | Ready → In progress |

**Problem.** Work on #190 was written in the home checkout, on a hand-cut branch, with no lock or dossier, and nothing stopped it: `role.sh` only gates codeo's skills, not session edits. Add a plugin `PreToolUse` hook, built on `role.sh`, that in a `home` (or `stale:?`/`stray`) checkout refuses Edit/Write/NotebookEdit on project files and Bash writes (`git commit`, `git push`, `git checkout -b`/`git switch -c`, …) with one line saying why and what to do, and names the override. Home-skill writes under `.codeo/`, the scratchpad and read-only commands stay allowed; `issue:<N>` roles, hosted sessions and non-codeo projects are unaffected.

**Acceptance criteria** — verbatim from the issue, unchecked:
- [ ] In a home checkout, an Edit or Write of a project file, `git commit` and `git push` are each refused with the one-line reason, and the same calls succeed in an `issue:<N>` checkout.
- [ ] The override lets the same calls through in home, and a session without it is still guarded.
- [ ] `/codeo:issue`, `/codeo:init`, `/codeo:triage` and `/codeo:cleanup` still run in home, including their writes under `.codeo/`.
- [ ] Hosted sessions and non-codeo projects are unaffected.
- [ ] A test covers each of the above against a scratch clone; `bash tests/run.sh` passes.

**Out of scope.** Moving or cleaning up work already done in home; guarding a plain shell outside Claude Code; a guard for the issue roles.

**Open at intake.** The override mechanism: `CODEO_HOME_EDITS=allow` in the environment or a git-ignored one-line marker in `.codeo/` — "pick one in the plan".

## Log

- 2026-11-26 — initialized: branch feat/192-guard-home-checkout-no-project off main at 7b7cc0f481ddccf59126d73652c64198f9b69fae · cost: 14m · sonnet-5-5 18k in + 580k cached / 3k out
