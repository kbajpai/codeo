# Issue #116 — implement

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/116 |
| Branch | `fix/follow-ups-70-71-104` |
| Updated | 2026-11-17 |

## Where this stands

Round 2 implemented: the plan's three tasks are committed (3a6b414, c0357d0, d6c708e), each reviewed clean. Nothing is open. Next step: `/codeo:qc`.

## Questions

### Q1 — #103 (`feat/let-codeo-triage-judge-flight`, kbajpai, step implement) also changes `docs/handoff.md`, `docs/skills.md` and `CHANGELOG.md`

**Why it matters:** this round edits `docs/handoff.md` (the refused-call sentence and the live-signal diagram) and `CHANGELOG.md` (the #70 bullet). Proceeding means whoever merges second resolves a textual conflict; sequencing means waiting for #103 to merge first.
**Options:** proceed and coordinate (recommended: the edits are one sentence, one diagram and one bullet, in places #103 is unlikely to touch) · sequence after #103 · re-scope.

**Answer:**
Proceed and coordinate (engineer, in the conversation, 2026-11-17: "Proceed & Coordinate"; recorded here by the skill).

### Q2 — #99 (`feat/make-sbx-issue-sandbox-usable`, kbajpai, step plan) also changes `.devcontainer/README.md`, `CHANGELOG.md` and `tests/devcontainer.test.sh`

**Why it matters:** this round edits the guard paragraph of `.devcontainer/README.md` and the #70 bullet of `CHANGELOG.md`. #99 has only a plan so far, so nothing has merged to conflict with yet; its plan lists the same README and changelog.
**Options:** proceed and coordinate (recommended: one appended sentence and one changed phrase) · sequence after #99 · re-scope.

**Answer:**
Proceed and coordinate (engineer, in the conversation, 2026-11-17: "Proceed & Coordinate"; recorded here by the skill).

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

### Round 2

2026-11-17
(send-back from qc.md round 1)

**Plan:** `docs/plans/2026-11-17-follow-ups-116-qc-round-1.md`, committed by the engineer before this round. `receiving-code-review`: F1-F6 were each checked against the code (the four "issue container" sentences, the diagram's two lines and the cleanup test were all present as QC described) and all hold. `sync-main.sh`: merged `origin/main` (merge commit abc761a; one conflict, in `CHANGELOG.md`, where `origin/main` added the #113 bullet and rewrote the #107 and #104 bullets this branch had already reworded; resolved by keeping this branch's #107 and #104 text and adding #113's bullet). Its changed files include `.devcontainer/README.md`, `.devcontainer/scripts/devcontainer-start.sh`, `.devcontainer/scripts/session-title.sh`, `.codeo/overlays/init.md`, `tests/devcontainer.test.sh` and `tests/init-overlay.test.sh`; none is in this round's footprint except `.devcontainer/README.md` and `CHANGELOG.md`, which Task 2 edited on top of the merge. Overlaps raised and answered: Q1 (#103) and Q2 (#99), both proceed and coordinate.

**Built** (one commit per task, each by a fresh `sonnet` subagent and reviewed by another; both verdicts Approved, no Critical or Important finding):
1. 3a6b414 (F1): "(the skill is running in an issue container)" removed from `skills/plan/SKILL.md`, `skills/implement/SKILL.md`, `skills/qc/SKILL.md` and `docs/handoff.md`; `must_lack 'issue container'` in the three skill tests and a `handoff.md` check in `tests/plan-skill.test.sh`.
2. c0357d0 (F2, F3, F4): the live-signal diagram shows `/codeo:close` running `live.sh clear` and deleting the lock in one command, pinned in `tests/live-signal.test.sh`; `.devcontainer/README.md` names toolbox and distrobox; the CHANGELOG #70 bullet names `/run/.containerenv`.
3. d6c708e (F5, F6): `tests/cleanup.test.sh` asserts the `docker rm -f codeo-12` line before the export; `tests/close-skill.test.sh` gets `section_contains_flat` for the stash and abandon pins. Mutation proofs in scratch copies: with the overlay not loaded the cleanup case printed its `FAIL`; joining the stash sentence's lines still passed; dropping the clause from the abandon sentence failed only the abandon pin.

**Documentation pages changed:** `docs/handoff.md`, `.devcontainer/README.md`, `CHANGELOG.md`. No wiki module.

**Build:** the `shell` suite's `build` is `true`; it exits 0. Each task's own proof ran the test file it touched and `bash tests/run.sh`, each ending `all cases passed`. No environment is configured: no lease, no deploy.

**Deviations from the plan**
- Task 2: the brief's `.devcontainer/README.md:49` was stale; the paragraph sits near line 105 after the merge and was matched by its text.
- Plan Task 2 Step 1 (`sync-main.sh`) ran at the start of the round instead, because the skill requires it; run again after Task 2 it exited 0 with nothing to merge.
- The whole-branch review `superpowers:subagent-driven-development` ends with was not run here: grading belongs to `/codeo:qc`.

**Minor finding left for `/codeo:qc`**
- `tests/close-skill.test.sh:84-85`: the stash pin still searches the whole stash-and-abandon section, so it could in principle be satisfied by the abandon paragraph; the wording differs today, so it is not.

## Log

- 2026-11-16 — implemented: 10 tasks, commits c118828..421dbbf, build rc=0 · cost: 71m · sonnet-5-5 806k in + 17.5M cached / 91k out
- 2026-11-17 — implement round 2 paused at step 2a: merged origin/main, raised overlaps Q1 (#103) and Q2 (#99), no task dispatched · cost: 4m · sonnet-5-5 33k in + 1.1M cached / 4k out
- 2026-11-17 — implemented round 2 (send-back from qc.md round 1): 3 tasks, commits 3a6b414..d6c708e, build rc=0 · cost: 18m · sonnet-5-5 215k in + 6M cached / 30k out
