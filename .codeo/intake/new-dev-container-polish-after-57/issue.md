# Issue — issue (draft, no number yet)

| | |
|---|---|
| Working title | Dev container polish left after #57: tests that prove less than they look, two inexact sentences, and the registry path match |
| Source | `/codeo:triage` run 2026-11-15-2, Q2-Q4 (`qc:57:F1-F7`, `qc:57:F8`, `qc:57:F4`); engineer chose "file it", all three in one issue |
| Updated | 2026-11-15 |

## Where this stands

Restated: #57 (the dev container follow-ups from #55, merged as PR #84) left a list of non-blocking findings that `/codeo:qc` and the implementers recorded and the engineer chose to file together: some of the tests added by #57 prove less than their names say, two sentences in the README and CHANGELOG are not quite exact, and `codeo-root.sh` matches a registry `projectPath` by exact string. None breaks anything today. Two questions are open; the draft is written once they are answered.

Checked, not assumed:
- **No duplicate.** An issue search found nothing on these; #54 is the title-hook and container-name edges from #47 and #50, #87 is a `.codeo/active` that names no issue, #81 is git-identity wait edges.
- **Each item still exists on `origin/main`** (read there, not from the branch): `lock-calls-mine` at `tests/devcontainer.test.sh:611,623`; `grep -o boom … | wc -l` at `:576`; "cannot run at once" at `.devcontainer/README.md:36` and `CHANGELOG.md:12`; the `pwd -P` match at `.devcontainer/scripts/codeo-root.sh:29`; "prints the Docker name instead of the title" at `.devcontainer/scripts/container-name.sh:14`.
- **Items, as the reviewers worded them** (from `.codeo/done/57/qc.md` round 2 and `implement.md`):
  1. F1, `tests/folder-check.test.sh`: `home_folder_on_a_configured_base_is_silent` passes at the base too; the two sibling cases carry the proof.
  2. F7, `ds_lock_stub`: the stub `lock.sh` writes `.codeo/active` whether or not the file exists, so `start_empty_lock_file_is_removed_and_the_lock_taken` proves the removal only through its removal-line assertion; the real `lock.sh` prints "lock already taken:" with nothing after it for an empty file.
  3. The `lock-calls-mine` assertion in `start_ignores_another_projects_codeo` is trivially true.
  4. `grep -o boom | wc -l` in `start_lock_crash_is_a_todo` is loose.
  5. No case for an empty `.codeo/active` with a detached HEAD, or with a failed `rm`.
  6. The `container-name.sh` failure path of `window-title.sh` (the `errf` capture, the ` / ` joining, "could not name the container:") has no test.
  7. F8: the README *The folder rule* and the CHANGELOG say two containers with the same folder name "cannot run at once"; "cannot both exist" is exact, because a stopped container keeps its name.
  8. The CHANGELOG states the limit in one parenthetical, the full statement being in the README; the `--docker` usage line in `container-name.sh` could say "the name the container should have".
  9. F4, `codeo-root.sh`: the `projectPath` match is an exact string against `pwd -P`, so a project-scope entry recorded through a symlinked path, or with a trailing slash, does not match; with no user-scope entry the start script then says "codeo is not installed".
  10. `codeo-root.sh` falls through to the user entry when this project's entry has a null `installPath`; the `registry` helper in `tests/codeo-root.test.sh` splits on `@`.

## Questions

### Q1 — Which of the ten items are requirements, and which are only listed for the planner?

**Why it matters:** each requirement needs an acceptance criterion a reviewer can check, and ten small ones make an issue that is hard to close. Some items need nothing done: item 1 cannot be fixed (the case is fine, it just is not the regression guard), and items 3, 4 and 10's `@` split are harmless as they stand.

**Options:**
- *Requirements: 2, 5, 6, 7, 9; the planner may take or dismiss the rest* (recommended). Those are the ones with an effect: item 2 is a real hole (the empty-lock test would still pass if the removal were broken but a lock were taken anyway); 5 and 6 are paths with no test at all; 7 is a wrong word on a merged page; 9 is the one behaviour. Items 1, 3, 4, 8 and the two in 10 go under *Reference* as "left minors", each to be fixed or dismissed with a reason in `plan.md`, as #74 does.
- *All ten are requirements.*
- *Something else* (say which).

**Answer:**

### Q2 — For the registry match (item 9): change it, or document it?

**Why it matters:** the two are different issues. Changing it means a symlinked or trailing-slash `projectPath` matches this clone, with a test for each; documenting it means a comment in `codeo-root.sh` and a sentence in the README saying the path is matched exactly. Item 10's null `installPath` fall-through is the same question: either skip that entry or document that it falls through to the user entry.

**Options:**
- *Change the match* (recommended): compare the entry's `projectPath` and the clone's root after resolving both (`pwd -P` on each, trailing slash stripped), so the same directory matches however it was recorded; a project entry with a null `installPath` is skipped as a non-match; the "never another project's entry" rule is unchanged.
- *Document only*: exact string match, stated in the header comment and the README.
- *Something else* (say what).

**Answer:**

## Draft

_Written after Q1-Q2 are answered._

## Log

- 2026-11-15 — dossier started from triage items `qc:57:F1-F7`, `qc:57:F8`, `qc:57:F4`: Q1-Q2 raised
