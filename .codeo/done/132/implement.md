# Issue #132 — implement

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/132 |
| Branch | `fix/fix-test-suite-gaps-left` |
| Updated | 2026-11-19 |

## Where this stands

All five tasks of `docs/plans/2026-11-19-test-suite-gaps-132.md` are done and the build passes. Next step: `/codeo:qc`.

## Questions

None.

## Outcome

**Built** (implementers and reviewers on sonnet, per task):
- Task 1 (`4d551c8`): `tests/role.test.sh`'s `both_markers_are_guarded_the_same` is now `both_markers_present_is_guarded`, with a comment that `containerenv_alone_is_guarded` pins the `/run/.containerenv` check. In a scratch copy with that check removed, only `containerenv_alone_is_guarded` failed.
- Task 2 (`b9cb10d`): new `paragraph_contains_flat` in `tests/close-skill.test.sh`; the stash and abandon signal pins use it and fail unless exactly one paragraph holds their anchor. Mutated copies of `skills/close/SKILL.md` (the needle moved into the other paragraph) fail the right pin under the new test: `a stash clears the signal with the lock` and `an abandon clears the signal with the lock`.
- Task 3 (no edit, criteria 4, 5, 6): `bash tests/live.test.sh` ends `all cases passed` with this checkout's `.git/codeo-live-beat` present and with it moved aside; no `--git-path` call in the file lacks `--path-format=absolute`, and no `[[ -e $stamp ]]`-style relative test remains. On a scratch copy of `live.sh`, deleting `rm -f "$(stamp)"` makes `stamp gone` fail, and writing the stamp at the top of `beat` makes `no lock: stamp` and `base: stamp` fail (plus `beat_is_throttled_and_force_is_not`).
- Task 4 (criterion 1): the `rc=0` output is commented on #107 (issuecomment-7025343874), #116's criterion 13 is ticked, and #116 has a linking comment (issuecomment-7025346040). The proof greps print 1 and 1.

**Documentation changed:** none, as planned (no changelog entry).

**Build:** the `shell` suite's build is `true` and exits 0. `bash tests/run.sh` also ended `all cases passed` (run as Task 5's proof; grading the suites is `/codeo:qc`'s).

**Deviations from the plan:**
- Task 2 Step 1's abandon-copy mutation did not show the gap: it capitalised "The lock" while the needle is lowercase, so the old pin failed for a reason of its own. A corrected mutation (the exact lowercase needle in the stash paragraph, removed from the abandon one) was run by hand: the old test did not fail `an abandon clears the signal with the lock`, the new one does. The plan text is not edited.
- No separate whole-branch review was dispatched: the change is two small, individually reviewed test edits, and the plan's no-escalation rule keeps reviewers on sonnet.
- `sync-main` merged one commit from `origin/main` at the start of the round; it printed no `also changed` lines and `overlap.sh 132` printed nothing.

## Log

- 2026-11-19 — implemented Tasks 1-5 of docs/plans/2026-11-19-test-suite-gaps-132.md; build ok · cost: $cost
