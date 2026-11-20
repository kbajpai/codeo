# Issue #132 — init

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/132 |
| Branch | `fix/fix-test-suite-gaps-left` |
| Updated | 2026-11-19 |

## Where this stands

Initialized: branch `fix/fix-test-suite-gaps-left` cut off `origin/main` at `4a4572e9624bad14b5753a3f455190a31789b290` and pushed. Next step: `/codeo:plan` in the issue's container.

## Questions

None.

## Outcome

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/132 — Fix test-suite gaps left by #116 and #100: stamp checks against the clone, and two mislabelled pins (consolidates #121, #130) |
| State | open · labels `bug` |
| Branch | `fix/fix-test-suite-gaps-left` off `main` at `4a4572e` |
| Board | Ready → In progress |

**Problem.** Two small sets of test-suite fixes with no behaviour change. From #116's QC: criterion 13 left unchecked on a merged issue (F7), `both_markers_are_guarded_the_same` in `tests/role.test.sh` passing with or without the `/run/.containerenv` check (F10), and two stash/abandon pins in `tests/close-skill.test.sh` that search the whole section (F11). From #100's QC: `tests/live.test.sh` tests a relative `git rev-parse --git-path` result with `[[ -e ]]` against the current directory instead of the clone, so the "stamp absent" assertions fail in any checkout with its own `.git/codeo-live-beat`. Supersedes #121 and #130.

**Acceptance criteria** — verbatim from the issue, unchecked:
- [ ] #116's criterion 13 is checked off or struck, with the reason on the issue.
- [ ] `both_markers_are_guarded_the_same` fails when the `/run/.containerenv` check is removed, or is renamed so it does not claim to pin it.
- [ ] Each of the two stash and abandon pins fails when only the other paragraph carries its text.
- [ ] With a `.git/codeo-live-beat` file present in the checkout running the suite, `bash tests/live.test.sh` passes; with none present, it passes as before.
- [ ] No stamp assertion in `tests/live.test.sh` tests a relative `--git-path` result against the current directory.
- [ ] The "no lock", "base" and "clear deletes the ref and the stamp" cases still fail when the clone's stamp exists (or is not deleted).

**Out of scope.** F8 and F9 of #116's QC round (they go into #118); other changes to `live.sh` or `live-signal.sh`; anything else #116 recorded.

**Open at intake.** None. The issue notes #118 (in review) also edits `tests/live.test.sh`: plan this after #118 merges to avoid a conflict.

## Log

- 2026-11-19 — initialized: branch fix/fix-test-suite-gaps-left off main at 4a4572e · cost: 1m · sonnet-5-5 44k in + 380k cached / 3k out
