# Issue #195 — implement

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/195 |
| Branch | `feat/195-identify-acting-user-strictly-verify` |
| Updated | 2026-11-27 |

## Where this stands

Round 1 complete: all 8 plan tasks built, reviewed and committed; build passes. Next: `/codeo:qc`.

## Questions

None.

## Outcome

**Built** (plan `docs/plans/2026-11-27-identify-acting-user-195.md`, 8 tasks, each reviewed by a fresh reviewer; a whole-branch review and one fix wave followed).

1. `lib/identity.sh` (`codeo_is_web_session`, `codeo_whoami`, `codeo_owner_of_init`) and `github.sh user whoami`: strict identity, refuses unresolved and non-`User` logins; `$CODEO_GITHUB_LOGIN` counts only in a hosted web session (also for the lenient `user login`).
2. `github.sh issue assignee-remove` requires a login.
3. `claim.sh --resume-line` requires the acting login.
4. `lock.sh`: `user:` line in the lock; `take` refuses (TODO, no lock) for an unresolved login or another engineer's branch; new `verify [--override "<words>"]` and `owner`; the owner is read from `FETCH_HEAD` of the pushed branch (fail closed when origin is unreachable or the branch has no dossier).
5. `live.sh` no longer reads the variable itself; the signal's user comes from `github.sh user login`.
6. `skills/init/SKILL.md` (rule `init-11`): `user whoami`, stop on refusal, the `| Owner |` row in the header table, the resume line carries the whoami login.
7. Step 0 of `plan`, `implement`, `qc`, `close` runs `lock.sh verify` (rules `plan-10`, `implement-11`, `qc-15`, `close-15`); stash/abandon remove the recorded owner (`close-16`).
8. Documentation: `docs/handoff.md` (lock sample, four checks, `verify` flowchart, live-signal user order), `docs/dossier.md` (Owner row, override line), `docs/skills.md`, `README.md` (init step, Troubleshooting), `CHANGELOG.md`. `docs/skills-inventory.md` carries the new rules.

**Build result.** The `shell` suite's `build` command is `true`: exit 0. Each task ran its own tests and the full `bash tests/run.sh`; the only failures anywhere in the branch are `live.test.sh` (`hostname: command not found`) and `sandbox.test.sh` (`.sbx` is gitignored), both environmental and failing identically without this change. `/codeo:qc` owns the grading run.

**Deviations from the plan, and why.**
- `lock.sh` treats a repository with no `origin` remote as "ref absent" and reads the local dossier (the plan says any failure to reach origin fails closed; existing repos and tests have no remote). A configured but unreachable origin still fails closed.
- "Could not check" refusals (origin unreachable, no dossier on origin's branch, assignees unreadable) are not overridable; ownership refusals are.
- The `Claim` line concept was removed from the init skill (a failed `assignee-add` is reported in the closing message, the claim stands on the pushed branch): after the strict-login change nothing could write it.
- `tests/live-signal.test.sh` uses `lock.test.sh`'s `gh` stub instead of an always-failing one, because `take` now needs a resolved login; `tests/qc-skill.test.sh`'s pin forbidding `--override` is narrowed to `lease take` lines.
- `lock.sh owner` reads the local dossier (a display helper, used after `verify` passed); `verify` reads the pushed copy.
- The Task 1 minors (empty-type message, stale "is unset" text, stderr assertions) were folded into Task 2.

**Deferred minors** (reviewed and accepted, not fixed): some test-strength gaps (no end-to-end live-signal test for web + variable + failing `/user`; text-only pins for the step-0 placement; a weak `assert_contains "local" "local"`), `## Notes` matched by exact string (trailing space/CRLF), the unverified-web legacy-lock note, cosmetic long lines in `skills/init/SKILL.md`, `skills/close/SKILL.md` and `CHANGELOG.md`, and `close` wording that still says "the assignee" in two places.

**Limit for the PR description.** Criteria 1, 2 and 5-9 rest partly on skill prose: the checks (`user whoami`, `lock.sh verify`) are script-enforced, but nothing forces the model to call them.

**Rulings I made.** (1) Task 1's minors folded into Task 2 — costs one small extra edit if wrong. (2) Claim line deleted — costs: a failed `assignee-add` leaves no dossier trace. (3) One final-review fix wave for the Important finding plus cheap minors, the rest deferred — costs: deferred minors ship. (4) No-origin-remote falls back to the local dossier — costs: a checkout with no remote can be judged on its own files. (5) Could-not-check refusals not overridable — costs: an engineer on an offline machine cannot override a check that could not run.

## Log

- 2026-11-27 — implemented plan docs/plans/2026-11-27-identify-acting-user-195.md, 8 tasks + review fix rounds · cost: 122m · sonnet-5-5 1.5M in + 42M cached / 247k out
