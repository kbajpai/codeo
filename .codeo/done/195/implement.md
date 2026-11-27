# Issue #195 — implement

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/195 |
| Branch | `feat/195-identify-acting-user-strictly-verify` |
| Updated | 2026-11-27 |

## Where this stands

Round 2 complete: all 6 plan tasks built and reviewed; build passes. Next: `/codeo:qc`.

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

### Round 2

2026-11-27
(send-back from qc.md round 1)

**Built** (plan `docs/plans/2026-11-27-identify-acting-user-195-round-2.md`, 6 tasks, each reviewed by a fresh sonnet reviewer; a whole-round review followed; nothing deployed — no shared environment).

1. `lib/identity.sh`: the Owner row accepts backticks and flexible spacing (F6); new `codeo_owner_date_of_init` so a refusal date never comes from a legacy `by no login` line (F4).
2. `scripts/lock.sh` (F1, F4, F5, Q9, Q11): an `unverified` web login is compared with the pushed owner, the assignees and the lock user like a verified one; a mismatch refuses (overridable) in `verify` and gives no lock in `take`; a match passes with `not independently verified: hosted web session`. The pushed dossier is fetched into `refs/codeo/verify/<branch>` (`--no-write-fetch-head` when git lists it) and never read from `FETCH_HEAD`. The recorded owner who is not an assignee gets a refusal naming `github.sh issue assignee-add`.
3. `skills/init/SKILL.md` (`init-11`, step 3, step 6, step 9): an `unverified` login is compared; a failed `assignee-add`, on a fresh init or a resume, is recorded under `## Notes` in its own commit (F3, Q11).
4. `skills/close/SKILL.md` (`close-16`): a legacy stash with no recorded owner removes the verified caller, only when `verify` passed without an override (F2, Q10).
5. Test pins (F8): the wrapped `lease take … --override` pin, and the variable set on the `take, unresolved login` case.
6. Documentation: `docs/handoff.md` (never-satisfies passage, flowchart, refusal forms, private ref), `docs/dossier.md`, `docs/skills.md`, `README.md`, `CHANGELOG.md`; rule text of `init-11` and `close-16` and the inventory fixture.

**Build result.** The `shell` suite's `build` command is `true`: exit 0. The full `bash tests/run.sh` passes on the committed state (all cases). `/codeo:qc` owns the grading run.

**Deviations from the plan, and why.**
- Task 2's `--no-write-fetch-head` detection matched a string git never prints (`--[no-]write-fetch-head`); fixed in a review round, with tests that log the fetch arguments.
- The plan scoped the failed-`assignee-add` record to step 9; the resume path is where a takeover runs, so step 6 points to the same rule too.
- `docs/skills.md`'s stale "never the caller" in the `close` entry was corrected in Task 6.
- Task 5's 17-line test-only diff got no separate task review; the whole-round review covered it.
- README's lock entry no longer says every refusal means someone else owns the issue.

**Deferred minors** (reviewed, not fixed): a legacy dossier with no owner on an unassigned issue gives a web login nothing to be compared with, so it passes (inherent, noted); a stale `refs/codeo/verify/feat` can block a fetch into `feat/x` and fails closed with a misleading "cannot reach origin"; the `take` web-checkout path is not tested with an `unverified` login; the `verify` flowchart omits the no-owner pass and the could-not-check refusal in the assignees read; `ls-remote` tail matching; a failed `assignee-add` is not read by any later step, only by the refusal that names the fix.

**Rulings I made.** (1) The unverified-login-with-nothing-to-compare pass accepted rather than refused — costs: a legacy unassigned workflow on web is unprotected until it has an owner. (2) Step 6's resume path made to record a failed `assignee-add` — costs: a slightly larger init change than the plan named. (3) No second fix wave for the final review's minors — costs: they ship.

## Log

- 2026-11-27 — implemented plan docs/plans/2026-11-27-identify-acting-user-195.md, 8 tasks + review fix rounds · cost: 122m · sonnet-5-5 1.5M in + 42M cached / 247k out
- 2026-11-27 — round 2 (send-back from qc.md round 1): implemented plan docs/plans/2026-11-27-identify-acting-user-195-round-2.md, 6 tasks + 2 fix rounds · cost: 30m · sonnet-5-5 598k in + 11.5M cached / 75k out
