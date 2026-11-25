# Issue #173 — implement

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/173 |
| Branch | `docs/173-close-161-leftovers-release-checklist` |
| Updated | 2026-11-25 |

## Where this stands

Round 1 is built and its build command passes. Nothing is open; next is `/codeo:qc`.

## Questions

None.

## Notes

- A finding outside the plan, to file with `/codeo:issue` once this merges: `docs/release-checklist.md` step 6 does not name `docs/updating.md`, which carries release-version examples (`v1.0.8 -> v1.0.9`, a downgrade to `v1.0.8`) that a release leaves stale.
- Minor review notes, none load-bearing and none acted on: the `rm_stubs` dirty-read case does not assert stdout; the hook has no test case for an entry with no `enabled` key (treated as enabled, as `install.sh` does); `.claude/hooks/session-start.sh:20` is a 103-column code line (the header comment is within 100); `tests/session-start-hook.test.sh` is mode 100644, which `run.sh` does not need; the v1.0.8 #144 changelog bullet says "as `qc-verdict` does", which holds for qc-verdict after #108.

## Outcome

### Round 1

2026-11-25

Built from `docs/plans/2026-11-25-close-161-leftovers-173.md` by `superpowers:subagent-driven-development`, one implementer and one reviewer per task, all on `sonnet` (`models.subagent`), then one whole-branch review; every review came back clean, and there was no fix round. `sync-main.sh` said the branch already contained `origin/main`; `overlap.sh 173` printed nothing.

**Built**
- Task 1, `d7eef54`: `stop_started` in `.devcontainer/codeo` prints `codeo: could not stop codeo-<N> again; it is left running` on stderr when `docker stop` fails after a refusal; exit statuses and refusal lines are unchanged. `t_rm_reports_a_failed_stop` in `tests/codeo-command.test.sh` pins it (failing stop after a cannot-check and after a dirty read, a successful stop, a running container).
- Task 2, `5e3e4ae`: `.claude/hooks/session-start.sh` skips only when `codeo@codeo` and a `superpowers@*` plugin are installed and enabled at user scope, read from `claude plugin list --json`; any read failure runs `install.sh`. The hook's `SessionStart` group has the matcher `startup|resume|fork`. New `tests/session-start-hook.test.sh` (12 cases), a matcher assertion in `tests/live-signal.test.sh`.
- Task 5, `0bd4932`: `docs/release-checklist.md` step 6 names what moves to the release being cut, what moves to the one before it, and what does not move.
- Task 3, `80c082f`: `.devcontainer/README.md`, the removal flowchart's three edges and node `Q` and the two paragraphs, hold when `docker ps -a` fails, and quote the new stderr line.
- Task 4, `54a5ad2`: `CHANGELOG.md`, the v1.0.9 #154 bullet and the v1.0.8 `Shared state:` line corrected in place, three `(#173)` bullets under `## Unreleased`.
- Task 6: no change. `grep -n "so /codeo" .claude/hooks/session-start.sh` prints nothing; the whole-branch review checked each of the eight acceptance criteria against the diff.

**Documentation pages changed:** `.devcontainer/README.md`, `CONTRIBUTING.md` (new `## Hosted sessions`), `CHANGELOG.md`, `docs/release-checklist.md`.

**Build result:** the `shell` suite's `build` is `true` and passes. Each implementer ran `bash tests/run.sh` on its task and it ended `all cases passed`; the grading run belongs to `/codeo:qc`.

**Deviations from the plan:** none. Task 4's two `git show` verification commands, run literally as written, matched nothing (`grep` read `^` mid-pattern as literal and `git show` took two paths); the implementer re-ran them with `grep -F` and the expectation held.

## Log

- 2026-11-25 — built round 1: five task commits `d7eef54..54a5ad2`, five task reviews and one whole-branch review, all clean · cost: 36m · sonnet-5-5 456k in + 10.5M cached / 62k out
