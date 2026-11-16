# Issue #116 — implement

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/116 |
| Branch | `fix/follow-ups-70-71-104` |
| Updated | 2026-11-16 |

## Where this stands

Implemented: all ten tasks of `docs/plans/2026-11-16-follow-ups-70-71-104-107.md` are committed on the branch, each reviewed clean. Nothing is open. Next step: `/codeo:qc`.

## Questions

None.

## Outcome

### Round 1

**Plan:** `docs/plans/2026-11-16-follow-ups-70-71-104-107.md`, committed as b9146e2 after the engineer's approval ("Approved then /codeo:implement"). `sync-main.sh`: the branch already contained `origin/main`, so nothing was merged and no `also changed on` lines. `overlap.sh 116` and `overlap.sh --outside 116` printed nothing.

**Built** (one commit per task, each implemented and reviewed by a fresh `sonnet` subagent; every review came back Approved with no Critical or Important finding):
1. c118828: `role.sh` also treats `/run/.containerenv` (`CODEO_CONTAINERENV`) as a container marker; tests in `tests/role.test.sh`.
2. 486888c: `cleanup.sh` no longer reads `CODEO_CLEANUP_REMOVAL`; tests supply the overlay as `.codeo/overlays/cleanup.md`; a new case proves an exported variable changes nothing.
3. bfe73c6: generic "home container" wording becomes "the checkout the project's role check allows" in the cleanup skill, `docs/skills.md`, the plan, implement and qc skills and `docs/handoff.md`; the cleanup list's reach is stated.
4. ce0465e: `live.sh` `read_lock` uses `^[1-9][0-9]{0,8}$`; `list` skips a `beat` more than the TTL ahead; header wording.
5. a6d44ba: `github.sh ref delete` counts only `Reference does not exist` as already deleted.
6. 5b5b676: `SessionEnd` hook timeout 20.
7. 152e379: `/codeo:close` clears the live signal in the command that deletes the lock, at all three exits.
8. 3612050: `board.sh` names `board.statuses.<key>` when no option matches a logical key; `skills/issue/SKILL.md` says `set` prints one line per project.
9. 8b4f7b9: `docs/handoff.md` live-signal bullet and diagram.
10. 421dbbf: `.devcontainer/README.md` guard line, `CHANGELOG.md`, and the comment on the title test (mutation proof: with the join replaced by `cat` the case printed its `FAIL`).

**Documentation pages changed:** `docs/skills.md` (cleanup and close sections), `docs/handoff.md` (live-signal bullet, diagram, issue-filing sentence), `.devcontainer/README.md`, `CHANGELOG.md`. No wiki module.

**Build:** the `shell` suite's `build` is `true`; it exits 0. Each task's own proof ran the test file it touched and the full `bash tests/run.sh`, each ending `all cases passed`. No environment is configured: no lease, no deploy.

**Deviations from the plan**
- Task 1: the test scratch directory is `podman`, not `containerenv`, because `mk containerenv` created a directory at the marker file's path.
- Task 2: four cases call `set_overlay` again after their fixture, since `setup_repo` makes a fresh work directory per case.
- Task 8: the existing needle `Quote that line in the report.` became `Quote them in the report.`, a direct result of the planned wording.
- Task 9: one sentence is reordered so `CODEO_MACHINE` precedes "same volume name", which the planned test needs.
- Task 7: the stash and abandon pins differ by phrase and depend on the line wrap in `skills/close/SKILL.md`.
- The whole-branch review `superpowers:subagent-driven-development` ends with was not run here: grading belongs to `/codeo:qc`.

**Minor findings left for `/codeo:qc`**
- `tests/cleanup.test.sh`, `an_exported_removal_override_changes_nothing`: the with-overlay half compares to `$plain` without asserting that `$plain` is the `docker rm -f codeo-12` line.
- `tests/close-skill.test.sh`: the stash and abandon pins depend on where a line wraps.

## Log

- 2026-11-16 — implemented: 10 tasks, commits c118828..421dbbf, build rc=0 · cost: 71m · sonnet-5-5 806k in + 17.5M cached / 91k out
