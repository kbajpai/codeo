# Issue #69 — implement

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/69 |
| Branch | `feat/fix-closing-blocks-that-name` |
| Updated | 2026-11-14 |

## Where this stands

All ten tasks of `docs/plans/2026-11-14-closing-blocks-that-can-run.md` are done, reviewed and committed (Tasks 9-10 are round 2, after QC round 1); the build passes. Nothing is open. Next: `/codeo:qc`.

## Questions

None.

## Outcome

**Built** (plan tasks 1-8, each implemented by a sonnet subagent and reviewed against the brief; one fix round on Task 6, one final whole-branch review with a single fix wave):
- Task 1 — `docs/handoff.md → Closing block`: the rule `**It names only a command that can run.**` and a table of exits whose next command is not the default; `tests/closing-exits.test.sh`, which reads each skill's labelled `**Closing block — <exit>:**` paragraph (4c0548f).
- Task 2 — `skills/close/SKILL.md` steps 16-17: separate `finished` and `lock kept` blocks; the lock-kept block names `/codeo:close` and no clean-up (f283a46).
- Task 3 — the Stash section: `stash interrupted` names `/codeo:close --stash`; `stash completed` names `/codeo:init #<N>`, after the manual Ready repair when the board move failed (26abde6).
- Task 4 — `skills/init/SKILL.md` step 11: after `lock: TODO` the `no lock` block names a recovery and not `/codeo:plan` (bbffc8a).
- Task 5 — `skills/issue/SKILL.md` step 8: reads `board.sh status <N>` when a board is configured; Ready, no board or `unavailable` names `/codeo:init #<N>`, not Ready names `/codeo:triage` first, an unreadable Status names its fix first (13ef5f0).
- Task 6 — `skills/plan/SKILL.md`: host-run tasks are marked `Runs on: the engineer's host` and written shell-neutral, or the shell is asked as a numbered question (5f2e45c, 8b274ee).
- Task 7 — `docs/skills.md`: the issue, init, plan and close sections (572f8d0).
- Task 8 — `CHANGELOG.md` (the #67 entry corrected, a #69 bullet added) and `.devcontainer/README.md` (all of `~/.claude` is lost on a rebuild) (76e204b).
- Final-review wave (b38c616): close step 17's host-workflow relay, "nothing is lost" sentence and `/codeo:triage` suggestion are conditioned on step 16 having deleted `.codeo/active`; step 16 names a push as a cause of a kept lock; wording tidy-ups in init, issue, plan, `docs/skills.md` and the test.

**Documentation pages changed:** `docs/handoff.md`, `docs/skills.md`, `.devcontainer/README.md`, `CHANGELOG.md`.

**Build result:** the `shell` suite's `build` (`true`) exits 0; `bash tests/run.sh` also passes (`all cases passed`), run at the hand-off as a sanity check, not as the grade.

**Deviations from the plan:**
- The init `no lock` block says "re-running the devcontainer start script" rather than the script's path: the script-calls lint in `tests/skills.test.sh` rejects any `scripts/*.sh` path in a `SKILL.md` outside the `bash "${CLAUDE_PLUGIN_ROOT}/scripts/…"` form.
- Task 6 grew a paragraph about where the shell question goes in the dossier flow and how `Runs on:` pairs with `Needs lease:` (review findings, not in the plan's text).
- Step 16 now names "a release, a branch deletion or a push", not "step 14's release or deletion", since a push is not a step 14 failure.
- `tests/close-skill.test.sh` gained one case pinning step 17's conditioning (the plan listed it only as "update if needed").

**Left as minors** (task reviews, not fixed): `tests/closing-exits.test.sh` prints FAIL lines to stdout where `tests/closing-block.test.sh` uses stderr; long single lines in `skills/issue/SKILL.md`; `docs/skills.md` lines do not enumerate every exit; step 17's lead "Report that the workflow is finished" is unconditional.

**Deployment:** no shared environment is configured, so there is no lease and no `Deployed revision:`.

### Round 2 — 2026-11-14
(after plan.md round 2)

**Built** (plan tasks 9-10, each implemented by a sonnet subagent and reviewed against the brief; no fix rounds):
- Task 9 — `docs/handoff.md`: the `init — no lock` row of "Exits whose next command is not the default" now reads "the fix the `lock: TODO` line names, then `lock.sh take local` again", not `/codeo:plan` (QC round 1 F1). `tests/closing-exits.test.sh`: `case_rule` checks that row names `lock.sh take local` and not `/codeo:plan`; `case_init_no_lock` checks that step 11 of `skills/init/SKILL.md` no longer holds "Either way, end with the closing block" (F5), shown to bite by running it against a copy with the sentence restored (77df859).
- Task 10 — `skills/plan/SKILL.md` step 8: a host task "is marked with a line `Runs on: the engineer's host`" and a lease task "carries a line `Needs lease:`" (F2); a `host: local` session on Windows is asked the shell like any other host (F3); a replacement script is in a language the engineer's host is known to have, else the task is labelled `Shell: <name>` and asked (F4). `tests/plan-skill.test.sh`: the old local-lock pin replaced, three pins added (eab7dc4).
- F6 (`tests/close-skill.test.sh` in the footprint) is a plan change: it is in `plan.md`'s round-2 footprint.

**Documentation pages changed:** `docs/handoff.md`. `docs/skills.md`, `CHANGELOG.md` and `.devcontainer/README.md` need nothing, as the plan says.

**Build result:** the `shell` suite's `build` (`true`) exits 0. Each implementer also ran `bash tests/run.sh` before committing (`all cases passed`) — a sanity check, not the grade.

**Deviations from the plan:**
- No separate whole-branch review for this round: two small commits, each reviewed on its own diff, and `/codeo:qc` reviews the whole branch next.
- Task 10's prose came out with ragged wrapping (the pinned phrases must each sit on one line) and a sentence that overlaps the following one on the `Shell: <name>` label.

**Left as minors** (task reviews, not fixed): the Task 10 wrapping and overlap above; in `tests/closing-exits.test.sh`, a missing `init — no lock` row fails with a message that does not say the row is gone, and `case_init_no_lock`'s step-11 guard passes on an empty `step` result (`issue_step8` guards that). Round 1's minors stand.

**Deployment:** no shared environment is configured, so there is no lease and no `Deployed revision:`.

## Log

- 2026-11-14 — implemented docs/plans/2026-11-14-closing-blocks-that-can-run.md, tasks 1-8 · cost: 61m · sonnet-5-5 709k in + 22.8M cached / 114k out
- 2026-11-14 — implemented round 2, tasks 9-10 (after plan.md round 2) · cost: 11m · sonnet-5-5 160k in + 3.9M cached / 18k out
