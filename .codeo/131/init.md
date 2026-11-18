# Issue #131 — init

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/131 |
| Branch | `feat/make-sbx-sandbox-lock-follow` |
| Updated | 2026-11-18 |

## Where this stands

Draft, awaiting approval at the review gate: branch `feat/make-sbx-sandbox-lock-follow` to be cut off `origin/main` at `9f1446158255d557f79970bd3774d418af75c733`. Next step: `/codeo:plan` in the issue's container.

## Questions

None.

## Outcome

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/131 — Make the sbx sandbox lock and follow-ups right: record the sandbox, not a volume, and close the #99 script and test gaps (consolidates #123, #125) |
| State | open · labels `enhancement` |
| Branch | `feat/make-sbx-sandbox-lock-follow` off `main` at `9f14461` |
| Board | Ready → In progress |

**Problem.** The sbx issue sandbox runs the dev container's start script, which takes the lock with `host: container`; `scripts/lock.sh` then looks for a Docker volume that a sandbox does not have, so the lock gets `volume: unknown`, a wrong TODO prints on every `issue` run, and `/codeo:close` names a `docker volume rm` that does not apply (the removal is `codeo-sandbox.sh end <N>`). Separately, `.sbx/codeo-sandbox.sh` leaves the engineer without a named next step when a start-script `exec` fails (F19) or `end` cannot fetch the sandbox state (F21), needs a readable pin to rerun `issue` (F20), and its tests have gaps, one of which fails `tests/run.sh` when it runs inside a sandbox. Supersedes #123 and #125 (both closed).

**Acceptance criteria** — verbatim from the issue, unchecked:
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

**Out of scope.** `/codeo:cleanup` and `scripts/cleanup.sh` listing or removing sandboxes; changes to `.sbx/codeo-sandbox.sh` beyond what the requirements need; the evaluation page's wording findings F17, F18 and F22; changes to the sbx CLI's behaviour.

**Open at intake.** None; the issue records no unresolved question.

## Log

- 2026-11-18 — initialized: branch feat/make-sbx-sandbox-lock-follow off main at 9f14461 · cost: 2m · sonnet-5-5 17k in + 940k cached / 3k out
