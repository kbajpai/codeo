# Issue #87 — qc

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/87 |
| Branch | `fix/dev-container-start-script-reports` |
| Plan | `docs/plans/2026-11-15-report-lock-file-naming-no-issue.md` |
| Updated | 2026-11-15 |

## Where this stands

Round 1 done: clear, forward to `/codeo:close`. The build and the full `shell` suite pass, all five acceptance criteria are met, and the independent review found nothing blocking. Nothing is open.

## Questions

None.

## Notes

Ran from the head `40aec02`, which contains `origin/main` (merge base `aaf4883`).

## Outcome

### Round 1 — 2026-11-15

**Sync and scope.**

- `sync-main.sh --abort-on-conflict`: `sync-main: the branch already contains origin/main`, exit 0, so no `also changed on main:` files.
- `overlap.sh 87`: printed nothing, so no overlap is unraised. `overlap.sh --outside 87`: printed nothing, so every path the branch changed is inside its footprint.
- `git diff origin/main...HEAD --stat`: 9 files, 509 insertions, 4 deletions. The change is `.devcontainer/scripts/devcontainer-start.sh` (+9/-3), `tests/devcontainer.test.sh` (+91), `.devcontainer/README.md` (+3/-1) and `CHANGELOG.md` (+1). The rest is the plan and `.codeo/87/` dossiers.
- `scope.sh origin/main HEAD`:

```
scope: suite shell needed for unclassified paths:
  .codeo/87/implement.md
  .codeo/87/init.md
  .codeo/87/issue.md
  .codeo/87/plan.md
  CHANGELOG.md
suite.shell=true
```

  No environment is configured, so there is no `deploy=` line and no environment step.

**Build.** The `shell` suite's `build` is `true`: exit 0.

**Tests.** The `shell` suite's `test`, run whole: `bash tests/run.sh` printed `all cases passed`, exit 0 (1m58s). `tests/devcontainer.test.sh`, where the new cases live, is part of that run.

**Criteria.**

| Criterion | Verdict | Settled by |
|---|---|---|
| 1. Newline-only file, and text with no `issue:` line, on an issue branch: one TODO naming `.codeo/active`, no lock taken, file unchanged | met | `start_newline_only_lock_file_is_a_todo`, `start_lock_file_without_an_issue_line_is_a_todo`, plus `start_issue_line_without_a_number_is_a_todo` and the detached-HEAD case; each asserts exit 0, exactly one TODO and it is this one, no `lock.sh` call, and `cmp` against a copy taken before the run (`tests/devcontainer.test.sh`, `ds_no_issue_reported`) |
| 2. The same file on the base branch: the same TODO, unchanged | met | `start_no_issue_lock_file_on_the_base_branch_is_a_todo` (newline-only and `garbage`, each on its own scratch clone) |
| 3. `issue:   55` and `issue: #55` print no such TODO and take no second lock; a zero-byte file is still removed | met | `start_nonempty_lock_file_is_left_alone` (`issue:   55`, now also asserting no TODO), `start_hash_issue_line_is_a_held_lock` (`issue: #55`, empty stderr, no lock call), and the existing `start_empty_lock_file_is_removed_and_the_lock_taken` and `start_empty_lock_file_on_the_base_branch_is_removed` |
| 4. `.devcontainer/README.md` states the behaviour in its list of what the start script does | met | `.devcontainer/README.md` lines 27-29, *What the start script does*: a new bullet for a file with content that names no issue, with the TODO text and "the same on `main` and on an issue's branch" |
| 5. `bash tests/run.sh` passes and `CHANGELOG.md` records the change | met | `bash tests/run.sh` above; `CHANGELOG.md` line 13, the last bullet under `## Unreleased`, ending `(#87)` |

**Documentation check.** The one page the plan named, `.devcontainer/README.md`, now matches `devcontainer-start.sh` step 3a: the regex, the branch order and the TODO text were read against the code, and the TODO sentence appears once in each of the script, the README and the CHANGELOG. Present tense, no issue number and no history in the README. No page under `docs/` describes the start script, as the plan said, and that claim holds. The CHANGELOG's "Nothing in `scripts/`, `lib/`, `hooks/` or `skills/` changes" is true: the diff touches none of them.

**Independent review** (Opus 5.5, handed the acceptance criteria and the diff range only). No Critical or Important findings. Its assessment was ready to merge: yes. It confirmed that the regex matches `container-name.sh`'s, that the script still exits 0 under `set -euo pipefail`, that CRLF content still counts as naming an issue, and that the tests would fail on the old code.

**Findings.** Blocking findings: none. Each finding below is non-blocking and belongs to `/codeo:implement`'s code; none changes the verdict.

- F1 (non-blocking) — `.devcontainer/scripts/devcontainer-start.sh:164`: a non-empty `.codeo/active` the script cannot read makes `grep` exit 2, and the `!` then reports it as "names no issue", which may be untrue of a real lock. It is safe (no lock taken, file untouched, exit 0) and unlikely after step 1's ownership fix. A readability check or its own wording would remove it. Not in the acceptance criteria.
- F2 (non-blocking) — `.devcontainer/scripts/devcontainer-start.sh:148`, comment: "`issue:`, then spaces, tabs or `#`, then digits" reads as if spaces and `#` may be mixed; the regex wants whitespace first, then `#`s, so `issue: # 55` does not count. The wording copies `container-name.sh`'s header. The README's examples are correct.
- F3 (non-blocking) — carried from the task reviews, `tests/devcontainer.test.sh`: `start_hash_issue_line_is_a_held_lock` relies implicitly on `ds_run` honouring `DS_REPO` after the folder rename, and the `-f &&` before `-s` in the new arm, which excludes a directory on purpose, has no comment saying so.

No issue was filed for this pass. F1-F3 are small polish on code this change added; they can go to `/codeo:triage` if the engineer wants them tracked.

**Verdict: clear — forward to `/codeo:close`.**

## Log

- 2026-11-15 — round 1: build and full suite pass, 5 of 5 criteria met, review clear (F1-F3 non-blocking) · cost: 2m · opus-5-5 241k in + 1.2M cached / 7k out · sonnet-5-5 190k in + 242k cached / 310 out
