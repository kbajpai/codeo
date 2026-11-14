# Issue #69 — implement

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/69 |
| Branch | `feat/fix-closing-blocks-that-name` |
| Updated | 2026-11-14 |

## Where this stands

All eight tasks of `docs/plans/2026-11-14-closing-blocks-that-can-run.md` are done, reviewed and committed; the build and the `shell` suite pass. Nothing is open. Next: `/codeo:qc`.

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

## Log

- 2026-11-14 — implemented docs/plans/2026-11-14-closing-blocks-that-can-run.md, tasks 1-8 · cost: 61m · sonnet-5-5 709k in + 22.8M cached / 114k out
