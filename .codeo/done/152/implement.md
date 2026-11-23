# Issue #152 — implement

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/152 |
| Branch | `feat/run-home-role-host-strict` |
| Updated | 2026-11-23 |

## Where this stands

Round 2 is done and written up under `## Outcome`: Tasks 8-12 and a final-review fix wave are complete, nothing is open. The next step is `/codeo:qc`.

## Questions

### Q1 — #154 overlaps this branch on `glob:.devcontainer/codeo`, `glob:.devcontainer/README.md`, `glob:.sbx/README.md`, `glob:CHANGELOG.md`, `glob:tests/codeo-command.test.sh` and `glob:skills/triage/SKILL.md`: how do we handle it?

**Why it matters:** #154 (`fix/close-149-145-leftovers-codeo`, assignee kbajpai, step implement, live on `codeo-154` 2m ago) plans changes to the same files: `.devcontainer/codeo` and `tests/codeo-command.test.sh` (this branch changed `cmd_issue`, `cmd_rm`, `cmd_update`, `ensure_home`, usage and help), `.devcontainer/README.md`, `.sbx/README.md`, `CHANGELOG.md`, and `skills/triage/SKILL.md` (this branch changed none of `skills/`, so that token is #154's alone through the footprint glob `skills/**`). The first to merge makes the other resolve conflicts in `.devcontainer/codeo` and the CHANGELOG/README sections.
**Options:** proceed and coordinate (recommended: both are additive edits to different functions and sections; whoever merges second rebases the merge with `sync-main.sh`) · sequence after #154 (this branch then waits for #154 to merge before `/codeo:qc`) · re-scope (drop the README/CHANGELOG edits from this branch).

**Answer:**
Proceed and coordinate. Relayed from the engineer in the conversation, 2026-11-22: "Proceed and coordinate on Q1, then re-run implement".

## Notes

Tasks ran through `superpowers:subagent-driven-development` with every implementer, reviewer and fix dispatch on the `sonnet` subagent model, never escalated. Rulings made while running: (1) Task 3's first test bullet was garbled in the plan; its intent (confirm is called with no `--local` and before any build or run; rows are added image, container, volume afterwards) was ruled before dispatch. (2) A reviewer's optional suggestion to silence the tracker's stdout in `codeo rm` was not adopted, because the tracker's `track:` line is the by-hand fallback the engineer must see. (3) `codeo-sandbox.sh` asks for confirmation after the host clone, because `read_pin` needs the clone; a refusal leaves a `codeo-<N>` directory behind that a later run reuses.

Left as minor, not fixed: the `/codeo:init` resume trigger wording in `.codeo/overlays/init.md`; `codeo rm` of a stash is not test-pinned; the T3 and T4 tracker helpers are duplicated across two shipped scripts; test-scaffolding nits; `.devcontainer/README.md:267` still gives the raw `docker rm -f …; docker volume rm …` before a resumed `issue` without naming `codeo rm <N>`; `codeo rm` on a host without `codeo-track.sh` prints one note and leaves the rows `active` until `codeo update`.

## Outcome

### Round 1

**Built.** All seven tasks of `docs/plans/2026-11-22-host-home-strict-guard-and-tracking-152.md`:
- Task 1 — `role.sh`: a host checkout (no container marker) holding a lock is `issue:<N>` in any folder; a `<codename>-home` clone on the base branch is `home`; off the base branch it is `stale:?`; any other host checkout is the new role `stray`. The check table is two-way: home-only skills run only on `home`, lock skills only on `issue:<N>`; a container in an unshaped folder and a hosted web session stay `unguarded`; refusals say "a home checkout" / "an issue's checkout". `tests/role.test.sh` covers every skill in every role, host and container.
- Task 2 — `.devcontainer/codeo-track.sh` (`add`, `mark`, `confirm`): one comment per issue found by `<!-- codeo:tracking -->`, edited with `PATCH`; hostname and UTC times; an active row is never duplicated and history is kept; a `gh` failure or a malformed table prints the row or the finding and exits 3; `confirm` warns and asks (`--yes`, or stops when there is no terminal). `tests/track.test.sh`.
- Task 3 — `codeo-container.sh issue … [--yes]`: confirm before any build or run, then image, container and volume rows; `--rebuild` marks the old container and image `removed`; an existing local container still refuses, after one warning line. `tests/cmd-mode.test.sh`. A fix round made the tracker found when the script is run by its bare name.
- Task 4 — `codeo-sandbox.sh issue <N> <branch> [--yes]` records the sandbox row after a successful create, warns (also about a local `codeo-<N>` container) before one is created, and `end` marks the row `removed`. `tests/sandbox.test.sh`.
- Task 5 — `codeo issue … [--yes]` forwards `--yes`; `codeo rm` marks the container, volume and image rows `removed` for what it removed; `ensure_home` and `update` fetch `codeo-track.sh` as a third script (`updated codeo and its three scripts`). `tests/codeo-command.test.sh`.
- Task 6 — `scripts/cleanup.sh` expands `{N}` in `command:`; the project overlays print `codeo rm <N>`, run `codeo-track.sh add <N> branch <branch>` after the claim push and `mark … branch … deleted` after a deleted branch, and name "a home checkout". `tests/cleanup.test.sh`, `cleanup-skill`, `close-removal`, `init-overlay`.
- Task 7 — `README.md` (the home checkout, the guard, the tracking comment, Linux/macOS/WSL; `codeo-home` still supported), `.devcontainer/README.md`, `.sbx/README.md`, `CHANGELOG.md` (an `## Unreleased` section). Each took fix rounds for accuracy against the code.
- Final review fix wave: the removal wording in the two sub-READMEs and `init.md`, host wording in `role.sh`'s refusals, and a `local` in `cmd_confirm`.

**Documentation pages changed:** `README.md`, `.devcontainer/README.md`, `.sbx/README.md`, `CHANGELOG.md`, `docs/extension-points.md` (the `cleanup/removal-command` paragraph), as planned.

**Base branch.** `sync-main.sh` merged `origin/main` (one commit, the #146 pin) at the start of the round; no `also changed on main` lines. ``overlap.sh` printed nothing at the start of the round; at the end it printed #154's overlap, raised as Q1 and answered proceed and coordinate.

**Build.** The one configured suite (`shell`) has build command `true`; it exited 0. No shared environment is configured, so there is no lease and no deployment. The implementers each ran `bash tests/run.sh` (`all cases passed`) at their task's end, and the final reviewer ran it once on the whole branch.

**Deviations from the plan:**
- The README section is `### The home checkout`, not `##`, because `tests/install.test.sh` pins exactly nine `##` headings and Q5 says to leave that test alone.
- `.sbx/README.md` keeps the phrase "`codeo rm` replaces the `docker rm`" that `tests/sandbox.test.sh` pins; the sentence was reworded to stay true.
- The plan's Task 7 `CHANGELOG.md` field line `Config schema: 1 (unchanged)` was written as the plan said; nothing else in `skills/` changed (none was needed).

**Q1 (overlap with #154).** Answered proceed and coordinate: `overlap.sh` prints nothing now that the pair is raised, and the branch already contains `origin/main` (`sync-main.sh` merged nothing new).

### Round 2 — 2026-11-23
(after plan.md round 2)

**Base branch.** `sync-main.sh` at the start of the round merged `origin/main` (one commit, #154's close of the #149 and #145 leftovers) and conflicted in `.devcontainer/README.md`, `.sbx/README.md` and `CHANGELOG.md`. Resolved in `0e842f8`, keeping both sides: `.devcontainer/README.md` takes this branch's three-script sentence plus main's clause that `open` of a container fails before it reads the home directory; `.sbx/README.md` takes main's two parenthetical changes (the no-branches refusal, `sbx` not installed) and this branch's tail about what `/codeo:close` and `/codeo:cleanup` print; `CHANGELOG.md` keeps this branch's `## Unreleased` block and main's bullet. `also changed on main:` lines: the same six files #154 touched (`.devcontainer/codeo`, the two READMEs, `CHANGELOG.md`, `tests/codeo-command.test.sh`, `skills/triage/SKILL.md`), re-checked against this round's work. `overlap.sh 152` printed nothing (the #154 pair was raised in round 1 and #154 has since merged).

**Built** (`docs/plans/2026-11-22-host-home-strict-guard-and-tracking-152.md`, `## Round 2`), the findings of `qc.md` round 1 checked against the code first:
- Task 8 (F2, F3, F6): `codeo-track.sh` reads the repository from `CODEO_REPO_URL`, else the checkout's `origin`, else the upstream default; a row without exactly six cells, a known kind and a known status makes the table malformed (nothing written, exit 3, one `track:` line with the line number; `confirm` keeps the rows before it); `mark` prints a `track:` note when no row or comment matches.
- Task 9 (F5, F7, F11): a rebuild of an existing container no longer asks for confirmation and no longer marks the image `removed`; `codeo-sandbox.sh issue` confirms before the host clone.
- Task 10 (F8): `codeo rm` of a container fetches a missing `codeo-track.sh` (`ensure_tracker`) and never stops the removal over it.
- Task 11 (F1): `scripts/cleanup.sh` prints a fourth TAB field, the overlay's `fallback:` text; `/codeo:cleanup` and `/codeo:close` print `codeo rm <N>` with a `docker` fallback sentence; the PowerShell claim is gone.
- Task 12 (F4, F9, F10, F12): the four pages, the init overlay and the CHANGELOG say what the code does (repository order, malformed rows, `mark`, the untracked VS Code route, the second `curl` line, `flock` on macOS).
- Final-review fix wave (`4342711`): the host scripts (`codeo rm`'s `track_mark`, `codeo-container.sh`, `codeo-sandbox.sh`) run the tracker with `CODEO_REPO_URL` set to the repository they clone from, because the checkout's `origin` made `codeo issue` (run from `~/codeo`) and `codeo rm` (run from the caller's directory) record against different repositories in a fork; a README sentence, a comment, a doc paragraph and a PowerShell test assertion tidied.

**Documentation pages changed:** `README.md`, `.devcontainer/README.md`, `.sbx/README.md`, `CHANGELOG.md`, `.codeo/overlays/init.md`, `docs/extension-points.md`, as planned.

**Build.** The one configured suite (`shell`) has build command `true`; it exited 0. Each implementer and the fix wave ran `bash tests/run.sh` (`all cases passed`). No shared environment is configured: no lease, no deployment.

**Deviations from the plan:**
- The fix wave's `CODEO_REPO_URL` on the host scripts' tracker calls is not in the plan. It follows Q9's own rationale (the host scripts record against the repository they clone from); `codeo-track.sh`'s repository order is unchanged.
- Plan gap: `docs/skills.md`'s `/codeo:cleanup` section does not mention the fourth field or the `fallback:` line. It is outside the plan's documentation list and footprint; nothing there is false.
- Left as minor: three `sbx ls` calls in the sandbox `issue` path; no `--rebuild --yes` test; no test for an unparseable `origin`; `confirm` skips rows after a malformed row without saying so.

## Log

- 2026-11-22 — Tasks 1-7 done through subagent-driven-development (sonnet), final review fix wave merged; built: ok; Q1 raised (overlap with #154), outcome pending · cost: 155m · sonnet-5-5 1.3M in + 44.4M cached / 246k out
- 2026-11-22 — Q1 answered (proceed and coordinate); Round 1 written up; built: ok · cost: 0m · sonnet-5-5 829 in + 689k cached / 916 out
- 2026-11-23 — round 2: Tasks 8-12 and one final-review fix wave through subagent-driven-development (sonnet), origin/main merged (conflicts in two READMEs and CHANGELOG resolved); built: ok · cost: 67m · sonnet-5-5 820k in + 21.6M cached / 132k out
