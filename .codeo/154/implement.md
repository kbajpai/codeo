# Issue #154 — implement

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/154 |
| Branch | `fix/close-149-145-leftovers-codeo` |
| Updated | 2026-11-22 |

## Where this stands

Round 1 is done: all ten tasks of `docs/plans/2026-11-22-close-149-145-leftovers-154.md` are built, each reviewed, and the whole branch reviewed once. The build exits 0. Next step: `/codeo:qc`.

## Questions

None.

## Notes

None.

## Outcome

**Built** (nine commits, `b455adc` to `e841208`, on top of the base merge `e099b62`):

- **Task 1, F7** (`b455adc`): `container_check --no-restart` stops a container it started on every return, so a refused `codeo rm` after a failed `docker inspect` (no `--force`) leaves a stopped container stopped. New `t_rm_inspect_fails_stops_started_container` (clean read, dirty read, and `--force` which does not stop); its RED was `no docker stop`, and restoring the old line failed it again.
- **Task 2, F13** (`8a541a0`): after the sandbox script's no-branches refusal, `codeo rm <N>` without `--force` adds `codeo: codeo rm <N> --force removes it anyway`. New `t_rm_sandbox_no_branches_hint` (the line, no line with `--force`, and `codeo-15` text does not match `rm 1`); the `elif` made unconditional failed the last case.
- **Task 3** (`f4d6159`, `.devcontainer/README.md`): the F12 remedies (`no sandbox`: nothing to remove; missing clone: `sbx rm --force codeo-<N>`), the F13 clause, the hint's conditions including no `sbx` installed, `open` of a container in the home-directory list, the inspect paragraph, and the flowchart's node Q and removal-failure edges.
- **Task 4** (`5c5634d`, `.sbx/README.md`) and **Task 5** (`3cc819e`, `CHANGELOG.md`): the hint conditions and the no-branches clause; the v1.0.8 `CODEO_HOME` sentence corrected in place; a new `## Unreleased` bullet.
- **Task 6, F15** (`f85e3c2`): a second `must_precede` in both skill tests. Mutation of each skill (the `overlap: skipping` sentence moved before the stop sentence) failed its test, then reverted.
- **Task 7, #145 F1** (`e4deb31`): `skills/triage/SKILL.md` names step 1's branch bullet; pinned by `must_contain` and `must_lack` in `tests/triage-skill.test.sh` (a `must_lack` helper added, the file had none).
- **Task 8, #145 F3** (`70b2799`): both `scripts/inflight.sh` comments name the check that exits 0 or 4 with no output; comment lines only.
- **Task 9, #145 F2** (`e841208`): the #29 case's tip date is 2026-11-16, newer than the dossier's `Updated` row; both stated mutations fail it.
- **Task 10:** `bash tests/run.sh` ends `all cases passed`.

**Documentation pages changed:** `.devcontainer/README.md`, `.sbx/README.md`, `CHANGELOG.md`, `skills/triage/SKILL.md`. No wiki module.

**Build result:** the `shell` suite's `build` is `true`: exit 0.

**F7 reproduced** before the fix (plan time): a stub `docker` with a failing `inspect` and a stopped container gave exit 1, `docker start`, no `docker stop`; the new test reproduces that and passes now.

**Deviations from the plan, and why:**
- Task 1: the plan's "case 3" (running container) was skipped as the plan allows; `t_rm_inspect_fails_no_restart` already covers it.
- Task 3: the brief's first grep matched the new "name no command" sentence, so it was reworded ("Fixing what failed and running it again is the remedy, except for the first and the third"), and the sandbox paragraph was soft-wrapped at two points so the brief's `grep -c` counts 2 (README paragraphs elsewhere are single lines).
- Task 8: the second comment wraps so the phrase `exited 0 or 4 with no output` stays on one line (the brief's `grep -c` prints 2).
- Step 2a merged `origin/main` (one commit: the v1.0.8 release); it changed only `.codeo/done/146/` and `docs/plans/2026-11-22-release-v1-0-8.md`, nothing this branch edits. `overlap.sh` printed nothing (all five #152 overlaps were raised as Q4, answered *proceed and coordinate*).

**Minor findings left for `/codeo:qc`, none blocking:**
- The flowchart edge for a failed `docker rm -f` with `--force` says "only while the container is still listed"; the code also dies when the follow-up `docker ps` listing fails (`.devcontainer/codeo`, the `--force` branch after `docker rm -f`). One clause to add to the label and prose.
- `.devcontainer/README.md`: the soft-wrapped sandbox paragraph; "the script stops before it reads `--force`" is loose (`end` parses it, then dies on the missing clone without acting on it); the node Q label has a `;` inside a quoted label (valid Mermaid).
- `CHANGELOG.md`: the last sentence of the Unreleased bullet is vague.

**Subagents:** every implementer and reviewer, the final whole-branch review included, ran on `sonnet` (`models.subagent` is unset), as `/codeo:implement` requires, never a more capable model. Tasks 4-5 and 6-9 were batched into one dispatch each (small independent edits, separate commits).

## Log

- 2026-11-22 — round 1: ten tasks built and reviewed, build exit 0, `bash tests/run.sh` all cases passed · cost: 86m · sonnet-5-5 545k in + 19.2M cached / 87k out
