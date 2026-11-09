# Issue #47 — qc

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/47 |
| Branch | `fix/harden-dev-container-scripts-session` |
| Updated | 2026-11-09 |

## Where this stands

Round 1 done: back to `/codeo:plan`. The build and the whole suite pass and every criterion is met as written,
but the plan's `core.fileMode` probe (F1) can switch the setting on where it should stay off, and that is the
plan's design, not the implementer's. F2-F7 are non-blocking and fold into the same re-plan cheaply.

## Questions

None.

## Notes

- Manual checks for the engineer (named in the plan; the suite cannot see them), still to make: rebuild the
  container, set the identity once, confirm a second container prints no identity TODO; take the lock and send a
  prompt (session and window titles say `[#N]`), release it (`[home]` at the next prompt), `/rename` a session
  (kept). If Claude Code does not apply a `sessionTitle` to a session that already has one, that is a send-back
  to `/codeo:plan`.
- `bash scripts/dossier-check.sh .codeo/47` passes `qc.md` and `implement.md`; it fails `plan.md`'s
  `### Footprint` (no `sequenced:` line, which the checker wants as `none`) and says `issue.md` lacks a `## Log`
  (it was adopted from `/codeo:issue`). Both are other skills' files, so `qc` leaves them; the re-plan writes a new
  footprint and can add `sequenced:  none`.
- Pre-existing, not a finding: `shellcheck tests/devcontainer.test.sh` prints one `SC2016` info note on the
  single-quoted hook-command string; `origin/main`'s test file prints the same note for its older form.

## Outcome

### Round 1 — 2026-11-09

(first pass; implement.md round 1)

**Sync and scope.** `sync-main.sh --abort-on-conflict`: `sync-main: the branch already contains origin/main`.
`overlap.sh 47` and `overlap.sh --outside 47`: nothing. `scope.sh origin/main HEAD`:

```
scope: suite shell needed for unclassified paths:
  .claude/settings.json
  .codeo/47/implement.md
  .codeo/47/init.md
  .codeo/47/issue.md
  .codeo/47/plan.md
  CHANGELOG.md
suite.shell=true
```

No `deploy=` line and no shared environment configured, so there is no environment step. Diff stat against
`origin/main`: 13 files, 1212 insertions, 69 deletions; nothing under `scripts/`, `lib/`, `hooks/` or `skills/`.

**Build.** `shell` suite `build` = `true`: exit 0.

**Suites.** `bash tests/run.sh` (whole `shell` suite): `all cases passed`, exit 0, 48 s. `shellcheck
.devcontainer/scripts/*.sh`: no output, exit 0. `shellcheck tests/devcontainer.test.sh`: one `SC2016` info note
(line 1193), also present on `origin/main`'s file. `git ls-files -s .devcontainer/scripts/`: all four scripts
`100755`.

**Criteria**

| # | Criterion (abbreviated) | Verdict | Settled by |
|---|---|---|---|
| 1 | No `claude auth login` line with `ANTHROPIC_API_KEY` / `CLAUDE_CODE_OAUTH_TOKEN` set | met | `start_credential_variables_hide_the_login_advice` (tests/devcontainer.test.sh:747); `devcontainer-start.sh:130-143` |
| 2 | Unwritable `info/exclude` still prints a `window-title:` line | met (see F6) | `title_reports_an_unwritable_exclude` (:1014); `window-title.sh:33-39` |
| 3 | `issue: #44` gives `[#44]` exactly once | met (see F5) | `title_strips_a_hash_from_the_lock_line` (:1004); `window-title.sh:24-25` |
| 4 | `settings.json` holding `[]` is reported as not an object | met | `title_rejects_settings_that_are_not_an_object` (:903), `start_settings_that_are_not_an_object_are_a_todo` (:665) |
| 5 | Symlinked `settings.json` still a symlink | met | `title_writes_through_a_symlink` (:922), `start_settings_symlink_is_kept` (:677) |
| 6 | `window-title.sh` is mode 100755 in the index | met | `scripts_are_committed_executable` (:1228); `git ls-files -s` above |
| 7 | Failed `mv` leaves no `.tmp`; mode not 0600 unless the original's was | met | `title_leaves_no_temp_file_when_mv_fails` (:956), `start_leaves_no_temp_file_when_mv_fails` (:705), `title_keeps_the_settings_mode` (:942), `start_settings_keep_their_mode` (:690) |
| 8 | Registered hook command exits 0, no output, with `session-title.sh` removed | met | `session_title_hook_command_survives_a_missing_script` (:1204) runs the command read from `.claude/settings.json` |
| 9 | `session_title` beginning with a newline prints nothing | met for a title the hook did not set; see F3 for an input ending in ` · <id8>` | `session_title_treats_a_leading_newline_as_a_title` (:1150) |
| 10 | Lock taken/released changes `--print` and the window title follows without a restart | met on the script side; whether Claude Code fires the hook is a manual check | `title_follows_a_released_lock` (:982), `session_title_refreshes_the_window_title` (:1177), `session_title_replaces_its_own_title_when_the_lock_changes` (:1156) |
| 11 | A script added in a fresh container is staged 100755 without `update-index --chmod` | met as written; see F1 for the case the probe gets wrong | `start_sets_file_mode_so_new_scripts_are_executable` (:776) |
| 12 | `bash tests/run.sh` prints `all cases passed` | met | output above |
| 13 | Fresh container with the `~/.config/git` volume already holding an identity: no identity TODO | met in the suite (config, Dockerfile directory, and the start script reading the volume file); a real fresh container is a manual check | `start_finds_the_identity_in_the_git_volume_file` (:608), `volumes_hold_the_gh_login_and_the_git_config` (:74), `git_config_global_points_into_the_git_volume` (:79), `dockerfile_creates_the_git_config_dir` (:128), `git_global_writes_land_in_the_volume_file` (:135) |

**Documentation.** The plan names `CHANGELOG.md` only, says no page under `docs/` describes the dev container
and there is no wiki module; I checked: `docs/` has no such page. The #47 entry matches the code. Two untruths
in the changelog, F4 and F7 below. The script header comments match the code except `devcontainer-start.sh`'s
"each step checks before it acts" (F2).

**Review.** Independent code review (opus, `QC review:`) of `162720b..67ec94f`, given the acceptance criteria
and the issue line only. Its assessment, in plain text: ready to merge with fixes — one Important finding
(F1), five Minor. Its other points are classified below.

**Findings**

- **F1 — blocking (plan's).** `.devcontainer/scripts/devcontainer-start.sh:55-60`. The `core.fileMode` probe
  `chmod u+x`s a fresh `0600` file and asks only whether `-x` then holds. It never checks that the filesystem
  can also clear the bit. `core.fileMode=false` is typical of a Windows checkout, and when that checkout is
  bind-mounted into the container (a case this very script discusses at step 1) files commonly read as
  `0755`/`0777` whatever `chmod` does, so the probe passes and `core.fileMode` is set to `true`: every tracked
  `100644` file then shows as a mode change, and a `git commit -a` would flip them. Reviewer's evidence: a
  scratch repo with `core.fileMode false`, a tracked file at `755`, the same probe printing "keeps", and
  ` M a.txt` with no content change after `git config core.fileMode true`. The code does what the plan's
  Global Constraints say (create `0600`, `chmod u+x`, test `-x`); the plan's probe is the defect. Suggested
  direction for the re-plan: probe both ways (`chmod a-x` must give `! -x`, then `chmod u+x` must give `-x`),
  and add a case whose `chmod` stub leaves every file executable.
- **F2 — non-blocking (plan's).** `devcontainer-start.sh:38`. `git config --global --add safe.directory`
  appends a line on every run and every container creation. The global config now lives in the shared
  `codeo-git` volume, so the duplicates, and every other container's clone path, outlive the container; the
  header's "each step checks before it acts" is untrue for this step. Harmless to git. Fix: skip when
  `git config --global --get-all safe.directory` already has the path.
- **F3 — non-blocking (plan's).** `session-title.sh:36-38`. Any title ending in ` · <id8>` counts as the hook's
  own, including one that begins with a newline: `{"session_title":"\nfoo · a21b9973", …}` with the lock on #47
  printed a `sessionTitle`. Contrived, and it follows the plan's own-title rule, but it is literally outside
  criterion 9. Fix: require the old title to look like `<codename> [home|#N] · <id8>`, or treat any title with
  a newline as not the hook's.
- **F4 — non-blocking (plan's).** `CHANGELOG.md:13`. The reworded #45 line says "a session that already has a
  title, such as a resumed or `/rename`d one, keeps it"; a resumed session whose title the hook set is
  retitled when the lock changed (`session-title.sh:36-38`). Restore "a `/rename`d title is kept", or say the
  hook's own title follows the lock.
- **F5 — non-blocking (implement's).** `window-title.sh:24-25`. `issue:#44` (no space) gives `[home]` and
  `issue: ##44` gives `[##44]`; `scripts/intake.sh:495` accepts the first. The lock writers always add the
  space, so the risk is low. A `sed -n 's/^issue: *#\{0,1\}//p'` matches `intake.sh`'s parser.
- **F6 — non-blocking (implement's).** `tests/devcontainer.test.sh` `title_reports_an_unwritable_exclude`
  replaces `info/exclude` with a directory (so it works as root) rather than making the file read-only. The
  reviewer confirmed `chmod 444` on the file gives the same `window-title:` line, exit 1. A `chmod 444` leg,
  skipped when the tests run as root, would match the criterion's wording.
- **F7 — non-blocking (plan's).** Two tests check less than their names say: `git_global_writes_land_in_the_volume_file`
  exercises git's own `GIT_CONFIG_GLOBAL` behaviour (it pins the plan's premise, which is its purpose), and in
  `start_credential_variables_hide_the_login_advice` the `STUB_CLAUDE_RC` 0/1 loop changes nothing once the
  `claude auth status` call is skipped. Also, the #44 changelog line "the title follows the lock at the next
  container start or when … is run" is now incomplete, because the prompt hook refreshes it too; the #47 line
  says so.

Recorded, not findings: the window title now depends on `info/exclude` being writable (`die` before `.vscode`
is touched), which is the plan's stated order; an existing `~/.gitconfig` is ignored once `GIT_CONFIG_GLOBAL`
is set, which the changelog's "set the identity once" covers. The reviewer declined to judge whether Claude
Code applies a `sessionTitle` to a session that already has one, and what VS Code writes into `~/.gitconfig`;
both stay with the manual checks under Notes.

No issue filed by this pass. F2-F7 fold into the re-plan; none needs an issue of its own.

**Verdict: back to `/codeo:plan`.**

## Log

- 2026-11-09 — qc round 1: back to plan · 1 blocking, 6 non-blocking · no issue filed · opus reviewer · cost: 6m · opus-5-5 397k in + 2.8M cached / 20k out
