# Issue #91 — issue

| | |
|---|---|
| Working title | Report an unreadable `.codeo/active` truthfully in the dev container start script, and clarify two spots from #87 |
| Source | `/codeo:triage` run 2026-11-15-3, items `qc:87:F1`, `qc:87:F2`, `qc:87:F3`; engineer chose "file it" for both questions and asked to consolidate issues into one |
| Updated | 2026-11-15 |

## Where this stands

Restated: #87 made the dev container start script report a `.codeo/active` that names no issue. `/codeo:qc` recorded three non-blocking findings on that change. One is a real, small defect (an unreadable lock file is reported as naming no issue); two are readability gaps (a comment that misstates the rule's order, and a test and a condition that rely on something nothing says). They are filed as one issue, at the engineer's request, and related to the open #88, which touches the same two files.

Checked, not assumed:
- **No duplicate.** Searches for the unreadable file and for the comment wording found only #40, #47 and #57 (all different scope); #88 is the nearest and does not cover these (its own Out of Scope names #87's file).
- **F1 reproduced** with the real condition from `devcontainer-start.sh:164` on a scratch file (a real lock, `issue:   55`, mode 000): `grep -Eq` exits 2, the `!` makes the arm fire, and the container would report "names no issue" for a lock that does.
- **F2 reproduced:** `printf 'issue: # 55\n' | grep -Eq '^issue:[[:space:]]*#*[0-9]+'` exits 1, so whitespace-then-`#`-then-space is not a match, while the comment at `devcontainer-start.sh:148` lists "spaces, tabs or `#`" as if they mix freely.

## Questions

None. Every answer that changes the issue was given in the triage run (file it; one issue; related to #88).

## Draft

**Title:** Report an unreadable `.codeo/active` truthfully in the dev container start script, and clarify two spots from #87

**Type:** none (user-owned repository, no Issue Types). **Labels:** `bug`.

### Description

#87 made `.devcontainer/scripts/devcontainer-start.sh` report a `.codeo/active` that has content but names no issue. Its QC found three small things left in that change: a `.codeo/active` the script cannot read is reported as naming no issue, which can be untrue of a real lock; the comment describing the rule misorders it; and one test and one condition rely on something nothing says.

### Motivation / Context

`/codeo:qc` recorded these as non-blocking findings F1-F3 of #87 (`.codeo/done/87/qc.md` round 1), and `/codeo:triage` (run 2026-11-15-3) filed them here at the engineer's choice, as one issue.

- **F1.** The arm at `devcontainer-start.sh:164` is `[[ -f .codeo/active && -s .codeo/active ]] && ! grep -Eq '^issue:[[:space:]]*#*[0-9]+' .codeo/active 2>/dev/null`. A non-empty file the script cannot read makes `grep` exit 2, the `!` turns that into "no match", and the script says `.codeo/active names no issue, so it holds no usable lock` for a file that may be a real lock. Reproduced with the real condition on a mode-000 file holding `issue:   55`. It is safe: no lock is taken, the file is untouched and the script still exits 0. It is unlikely after step 1's ownership fix.
- **F2.** The step 3a comment (`devcontainer-start.sh:148`) says "`issue:`, then spaces, tabs or `#`, then digits", which reads as if they may be mixed. The regex wants whitespace first, then `#`s, so `issue: # 55` does not count (`grep` exits 1). The wording copies `container-name.sh`'s header. The README's examples are correct.
- **F3.** `start_hash_issue_line_is_a_held_lock` in `tests/devcontainer.test.sh` renames the scratch clone to `codeo-55` and relies on `ds_run` honouring `DS_REPO`, which nothing says; and the `-f &&` before `-s` in the arm excludes a directory on purpose (a directory is out of scope of #87) with no comment saying so.

### Key Requirements

- A non-empty `.codeo/active` the script cannot read is not reported as naming no issue. It gets its own TODO that says it could not be read, names the file, and says what to do (fix its permissions or remove it, then re-run the script). Nothing is deleted, rewritten or locked over, and the script still always exits 0.
- A readable file is unchanged in behaviour: one that names no issue gets #87's TODO, one that names an issue is a held lock, an empty one is removed.
- The step 3a comment states the rule in the order the regex applies it: `issue:`, then optional whitespace, then optional `#`s, then digits. It no longer implies they may be mixed.
- `start_hash_issue_line_is_a_held_lock` states, in a comment, that `DS_REPO` points the run at the renamed clone; the `-f &&` in the arm carries a comment saying it keeps a directory out of the new TODO.

### Acceptance Criteria

- [ ] A test starts a container on an issue branch with a `.codeo/active` holding `issue:   55` and mode 000 (skipped, with the reason named, where the tests run as a user that can read it anyway): it prints one TODO that names `.codeo/active` and says it cannot be read, does not print "names no issue", takes no lock, and leaves the file unchanged.
- [ ] A readable file with no `issue:` line still prints #87's TODO, and one with an `issue:` line still prints no TODO and takes no second lock; the existing #87 cases pass unchanged.
- [ ] The step 3a comment describes the rule as `issue:`, optional whitespace, optional `#`s, then digits; the `-f &&` in the arm and the `DS_REPO` use in `start_hash_issue_line_is_a_held_lock` each have a comment saying why.
- [ ] `bash tests/run.sh` passes and `CHANGELOG.md` records the change.

### Out of Scope

- `container-name.sh`, `folder-check.sh`, `lock.sh` and anything under `scripts/`, `lib/`, `hooks/` or `skills/`; the same wording in `container-name.sh`'s header is left as it is.
- A `.codeo/active` that is a directory (still no TODO, as #87 decided).
- Repairing the file for the engineer.

### Reference

- `.codeo/done/87/qc.md` round 1 (F1, F2, F3); triage run 2026-11-15-3, Q1-Q2.
- `.devcontainer/scripts/devcontainer-start.sh` (step 3a, lines 144-170), `tests/devcontainer.test.sh` (`start_hash_issue_line_is_a_held_lock`, `ds_no_issue_reported`).
- Related, not duplicate: #88 (open, Backlog) touches the same two files for #57's findings; the two can be done together or in either order. #87 (merged, PR #89) is the change these come from.

## Log

- 2026-11-15 — drafted from triage run 2026-11-15-3, Q1-Q2: F1 reproduced, F2 reproduced; one issue for F1-F3, related to #88
- 2026-11-15 — approved and filed as #91 (https://github.com/kbajpai/codeo/issues/91), label bug
