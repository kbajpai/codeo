# Issue #126 — implement

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/126 |
| Branch | `feat/put-issue-number-branch-name` |
| Updated | 2026-11-19 |

## Where this stands

Round 1 is done: all four tasks of `docs/plans/2026-11-18-numbered-branch-names-126.md` are built,
reviewed and committed, and the branch is pushed. Waiting for `/codeo:qc`.

## Questions

None.

## Outcome

| | |
|---|---|
| Plan | `docs/plans/2026-11-18-numbered-branch-names-126.md`, committed at `2514a46` |
| Build | the `shell` suite's build is `true`: exit 0. Not graded here. |
| Environment | none configured; no lease taken, nothing deployed |

**Built.** `main` was already contained in the branch at the start, and `overlap.sh 126` printed nothing.

- Task 1 — `ea00838`: `scripts/branch-name.sh` prints `<type>/<N>-<slug>`; `tests/branch-name.test.sh` expects it and adds a same-title pair (#20, #21).
- Task 2 — `8889993`: `scripts/claim.sh --carries` keeps its refusal for a branch carrying another issue's dossier, now ending "rename or delete it on origin"; `tests/claim.test.sh` asserts it and that the title advice is gone.
- Task 3 — `e3cdb7c`, `7d4f999`: `skills/init/SKILL.md` step 6 finds a resume through `inflight.sh --branches` and derives the name only when there is no row; step 3 loses the "branch of any other name" stop. `tests/init-skill.test.sh` pins the wording. Review sent the first commit back once (a check that could not fail because its sentence wraps; `ls-remote` not clearly gated on "no row"); both fixed in `7d4f999`.
- Task 4 — `e16a7c3`: the `feat/12-order-export` example in `docs/dossier.md` and `docs/handoff.md`, and a new `## Unreleased` entry in `CHANGELOG.md`.
- Whole-branch review fix wave — `0aa066f`: step 6's line wrapping, "retitle" restored where the skill quotes `claim.sh`, and `claim.sh`'s header comment updated (comments only).

**Documentation pages changed.** `docs/dossier.md`, `docs/handoff.md`, `CHANGELOG.md`, and the skill text of `skills/init/SKILL.md`. No wiki module.

**Deviations from the plan.**
- Task 3's check that step 3 no longer says "restore the title" is a whole-file `grep`, not `step_lacks … 3`: the test's `step()` helper stops at the `<!-- rule: init-02 -->` comment right after step 3's first line, so the plan's form would have passed without checking anything.
- The plan's Task 4 grep proof expects no output, but it prints `tests/init-skill.test.sh:53`, a deliberate negative assertion quoting the old wording, like the `tests/claim.test.sh` line the plan already excludes.

**Build and tests, as run here.** `bash tests/run.sh` fails only `live.test.sh`, 3 assertions of the form `stamp: want [no] got [yes]`. That is this container: the live-session heartbeat keeps a throttle stamp in this checkout's git directory (`git rev-parse --git-path codeo-live-beat`) and the test sees it. From a clean `git worktree` of `HEAD` the whole suite prints `all cases passed`, and `live.test.sh` passes from one of `origin/main` too. `/codeo:qc` will meet the same failure in this checkout.

**Deferred minors.** The new claim message's parenthetical is not asserted by a test; a few lines in `skills/init/SKILL.md` are about 104-106 columns.

**Rulings made.** One, at pre-flight: Task 3's step-3 check is a whole-file check (above). If wrong, it costs nothing — the assertion is real either way.

## Log

- 2026-11-19 — implemented: 4 tasks, 1 fix round on task 3, 1 whole-branch fix wave · cost: 23m · sonnet-5-5 538k in + 13.2M cached / 63k out
