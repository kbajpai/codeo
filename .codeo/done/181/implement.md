# Issue #181 — implement

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/181 |
| Branch | `feat/181-session-title-prefix-session-id` |
| Updated | 2026-11-28 |

## Where this stands

Round 1, done. All three tasks are built, reviewed and committed; the build passes. Next step: `/codeo:qc`.

## Questions

None.

## Notes

- Models: every implementer and reviewer ran on `sonnet` (`models.subagent` unset), including the final whole-branch review; nothing was escalated.

## Outcome

Plan: `docs/plans/2026-11-28-session-title-sequence-181.md`. `sync-main.sh` found the branch already containing `origin/main`; `overlap.sh` printed nothing.

**Built.**
- Task 1 (`52bdb4c`): `.devcontainer/scripts/session-title.sh` titles a session `<window title> · <NN>-<id8>`, with a ledger of `<NN> <session id>` lines at `$(git rev-parse --git-path codeo/session-seq)`; ownership of the existing title is decided before any number is taken. Tests in `tests/devcontainer.test.sh` moved to the new shape plus new cases for order, keep, clear, fork, resume, wrap, per-clone counts, lock change, old-shape migration and look-alike titles.
- Task 2 (`7e391c4`): the number is taken under `flock -w 2` on a lock file beside the ledger; a missing `flock`, a lock timeout or an unusable ledger prints the old shape. Tests for eight parallel starts, the fallback, a missing `flock`, a garbage ledger, ledger trimming, an unreadable ledger and a resume that must not reuse a number.
- Task 3 (`0c875dc`): `.devcontainer/README.md` (the session-title bullet) and a new `## Unreleased` section in `CHANGELOG.md`.

**Documentation changed.** `.devcontainer/README.md` and `CHANGELOG.md`, as the plan names. No wiki module.

**Build result.** The `shell` suite's build is `true`: exit 0. The implementers ran `bash tests/run.sh` (exit 0, three times in a row after Task 2); the full suite is `/codeo:qc`'s.

**Deviations from the plan, and why.**
- Task 1's lock-change test: its last case now expects `00-a21b9973`, because the ledger already holds that session id at `00` and a session id spends one number (Q2).
- Three fixes ruled into Task 2 from Task 1's review: the ledger read leaked `Permission denied` to stderr on an unreadable ledger (redirect order); the header comment said "own title, ledger, next" where the code checks the ledger first; and a resume under a new id recorded its inherited number as the last ledger line, so the next fresh session reused an earlier session's number (now recorded before the last line).
- Task 1 step 1 (the hook-input check) was recorded in the commit body, not in this file: the hooks documentation lists `SessionStart` `source` as `startup`, `resume`, `clear`, `compact`, `fork`, and does not say whether a resume keeps its `session_id`. The plan's flow chart is not contradicted.

**Left open, none blocking** (from the reviews): no test holds the lock for over 2 seconds; a state path that is a directory falls back through a later failure, not an explicit check; `git rev-parse --path-format=absolute` needs git 2.31 (the images have 2.53); a `/clear` `SessionStart` carrying an inherited numbered title is not in the suite (checked by hand, it takes the next number); a resume that first reaches the hook through `UserPromptSubmit` takes a fresh number; `<id8>` is not defined in the README or changelog prose.

## Log

- 2026-11-28 — implemented: 3 tasks, commits 52bdb4c 7e391c4 0c875dc · cost: 26m · sonnet-5-5 398k in + 7.7M cached / 74k out
