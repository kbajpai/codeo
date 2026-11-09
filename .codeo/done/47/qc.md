# Issue #47 — qc

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/47 |
| Branch | `fix/harden-dev-container-scripts-session` |
| Updated | 2026-11-09 |

## Where this stands

Round 4 done: clear, forward to `/codeo:close`. The blocking finding of round 3 (F16) and F17 are fixed, the build
and the whole suite pass, every criterion is met as written (criteria 10, 11 and 13 in the suite; a real container
is a manual check), and no blocking finding remains. One Important point from the opus review (the start script does
not say that executable-on-disk, `100644`-in-index files will now show as mode changes) is a consequence of the
engineer's own Q1 answer and non-blocking; it and five minors are recorded for `/codeo:triage` or a follow-up.

## Questions

### Q1 — Should the start script strip an executable bit the engineer set on a file the index records as `100644`?

**Why it matters:** F16 below (opus review, reproduced by reading `restore_modes` and Q4's own text). Round 3 did
what Q4 decided: restore each tracked file's mode on disk to the index's before turning `core.fileMode` on. Q4's
option text said the restore only touches files "that differ from the index, which with the setting off could
neither be seen nor staged, so nothing of yours is lost" — that is true for the direction `100755` in the index and
`644` on disk (the clone's artefact), but not for the other: with `core.fileMode=false`, `git add` records every
new script as `100644` even after `chmod +x`, which is the very mistake criterion 11 exists to fix. In that state
the file is `755` on disk and `100644` in the index, `restore_modes` runs `chmod -x` on it, `git status` goes clean,
and the wrong `100644` record is hidden for good (the files are only counted in the message, never named). The
engineer's script then fails with "Permission denied". Whether that is acceptable decides if F16 is blocking and
whether it goes back to `/codeo:plan` (Q4's rule was wrong in one direction) or stands as decided.

**Options:**
- *Restore only the `100755`-in-index direction (my recommendation):* `chmod +x` where the index says `100755` and
  the file is not executable (what a clone on a bit-dropping mount leaves). Where the file is executable on disk but
  `100644` in the index, leave it, turn `core.fileMode` on, and let git show `mode change 100644 => 100755`, ready
  to commit. The second listing then ignores that direction. The message names the files it changed (or the first
  five), not just a count. Pro: nothing the engineer set is removed; criterion 11 still holds. Con: `git status`
  is not always clean afterwards — it shows the changes that were really made.
- *Keep Q4 as decided, but name every file changed and say how to undo it:* a TODO/line listing the paths that
  lost their `x`. Pro: no logic change. Con: still removes bits the engineer set; the hidden wrong records remain.
- *Do not touch modes at all:* only flip when the tree already shows no mode difference, else the TODO (Q4's
  rejected second option).

**Answer:**
Accepted the recommendation (answered in the conversation, 2026-11-09): restore only the `100755`-in-index
direction, leave an executable `100644`-in-index file for git to show as a mode change, and name the files changed.

### Q2 — Should step 2b (the `core.fileMode` flip and the mode restore) apply to a bind-mounted host checkout, as step 1 deliberately does not?

**Why it matters:** F17 below (opus review). Step 1 leaves a bind-mounted host checkout alone because changing it
"would change the engineer's files on the host". Step 2b has no such guard: when the filesystem keeps the bit
(a Linux or WSL host bind-mounted into the container, which passes the probe), it writes `core.fileMode true` into
the shared `.git/config` and `chmod`s tracked files on the host, overriding an explicit `core.fileMode=false` the
engineer may have set on purpose. The plan's manual check says "a bind-mounted host checkout keeps `core.fileMode`
false", which holds only where the probe fails (a Docker Desktop mount that drops the bit), not on a Linux bind mount.

**Options:**
- *Apply 2b only to a clone on a Docker named volume (my recommendation):* reuse `clone_on_named_volume`, as step 1
  does. A bind-mounted checkout gets the existing "stage with `git update-index --chmod=+x`" TODO instead. Pro: the
  script never writes the host's config or modes; this repository's own clone (named volume `codeo-47`) is unaffected.
  Con: on a bind mount criterion 11 is met only by the TODO's manual step.
- *Keep it as is:* the probe is the only guard. Pro: simplest. Con: the host's config and file modes change.
- *Apply it on a bind mount only when `core.fileMode` was never set explicitly:* distinguishes "unset/inherited" from
  "set false on purpose". Pro: respects intent. Con: git cannot tell a clone-time autodetected `false` from a
  deliberate one without reading the config's origin; more code for an edge case.

**Answer:**
Accepted the recommendation (answered in the conversation, 2026-11-09): apply step 2b only to a clone on a Docker
named volume; a bind-mounted checkout gets the `update-index --chmod` TODO.

## Notes

- Manual checks for the engineer (named in the plan; the suite cannot see them), still to make: rebuild the
  container, set the identity once, confirm a second container prints no identity TODO; take the lock and send a
  prompt (session and window titles say `[#N]`), release it (`[home]` at the next prompt), `/rename` a session
  (kept). If Claude Code does not apply a `sessionTitle` to a session that already has one, that is a send-back
  to `/codeo:plan`.
- `bash scripts/dossier-check.sh .codeo/47` passes `plan.md`, `implement.md` and `qc.md`; its one remaining drift
  is `issue.md` lacking a `## Log` (adopted from `/codeo:issue`), another skill's file that `qc` leaves alone.
- Also check by hand, with F8's fix in place: in a clone with `core.fileMode false` whose tracked scripts are
  `644` on disk, the start script leaves `core.fileMode` false and `git status` clean; and what VS Code writes
  into the shared `codeo-git` config (F9).
- Pre-existing, not a finding: `shellcheck tests/devcontainer.test.sh` prints one `SC2016` info note on the
  single-quoted hook-command string; `origin/main`'s test file prints the same note for its older form.

- Round 3 findings (classified in Round 3 below once Q1/Q2 were answered). Opus review of `162720b..HEAD` (code only), `tests/run.sh
  devcontainer` passing: **F16** (`devcontainer-start.sh:63-81,88`, the Q1 behaviour) — `restore_modes` strips the
  executable bit from files that are `755` on disk and `100644` in the index; the test `ds_modes_repo` (`data.txt`
  755 on disk → back to 644) codifies it. Provisionally blocking, the plan's (Q4's rule was stated wrongly), pending
  Q1. **F17** (`devcontainer-start.sh:83-109`, the Q2 behaviour) — step 2b flips `core.fileMode` and chmods on a
  bind-mounted host checkout. Provisionally non-blocking unless Q2 says otherwise; the plan's. Minor,
  non-blocking, mostly the code's own edges and none needing a send-back on its own: **F18** `session-title.sh:40-41`
  a forked or resumed session (new id) keeps a stale `· <old sid8>` title because the suffix must be this
  session's id; **F19** `session-title.sh:41` the codename is not compared, so a `/rename` of the shape
  `x [home] · <sid8>` is replaced; **F20** `window-title.sh:26` `issue: 44abc` → `[#44]`, `issue: 4 4` → `[#4]`
  (deliberate, Round 3 plan); **F21** both merges: `mv` replaces the inode, so owner and hard links of
  `settings.json` are not kept (only the mode); **F22** `devcontainer-start.sh:126` a non-regular
  `~/.claude/settings.json` is skipped with no TODO; **F23** `devcontainer-start.sh:84,93` the probe file goes in
  `git rev-parse --git-dir` and `git config` writes the common config, wrong in a linked worktree on another
  filesystem (not this layout). Deferred minors from `implement.md` round 3 (swallowed `git diff` error in the second
  listing; changelog comma) stand. The reviewer could not check: whether Claude Code applies `sessionTitle` to a
  session that already has one, what VS Code writes into `~/.config/git/config`, and the two fresh-container
  criteria (11, 13) — those stay the manual checks above.
- Criteria 1-9, 12 are met by named tests (e.g. `start_credential_variables_hide_the_login_advice`,
  `title_reports_an_unwritable_exclude`, `title_strips_a_hash_from_the_lock_line`,
  `title_rejects_settings_that_are_not_an_object`, `*_symlink_*`, `scripts_are_committed_executable`,
  `*_leaves_no_temp_file_when_mv_fails`, `session_title_hook_command_survives_a_missing_script`,
  `session_title_treats_a_leading_newline_as_a_title`); the final table is written with the round.

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

### Round 2 — 2026-11-09

(second pass; implement.md round 2, answering this file's round 1)

**Sync and scope.** `sync-main.sh --abort-on-conflict`: `sync-main: the branch already contains origin/main`.
`overlap.sh 47` and `overlap.sh --outside 47`: nothing. `scope.sh origin/main HEAD`:

```
scope: suite shell needed for unclassified paths:
  .claude/settings.json
  .codeo/47/implement.md
  .codeo/47/init.md
  .codeo/47/issue.md
  .codeo/47/plan.md
  .codeo/47/qc.md
  CHANGELOG.md
suite.shell=true
```

No `deploy=` line and no shared environment configured, so there is no environment step. Diff stat against
`origin/main`: 14 files, 1686 insertions, 72 deletions; nothing under `scripts/`, `lib/`, `hooks/` or `skills/`.

**Build.** `shell` suite `build` = `true`: exit 0.

**Suites.** `bash tests/run.sh` (whole `shell` suite): `all cases passed`, exit 0, 48 s.
`shellcheck .devcontainer/scripts/*.sh`: no output, exit 0. `shellcheck tests/devcontainer.test.sh`: one `SC2016`
info note (line 1249, the single-quoted hook-command string), also present on `origin/main`'s file. All four
`.devcontainer/scripts/*.sh` are `100755` in the index.

**Round 1's findings.** F1 (blocking in round 1) — fixed by `8988cea` (the probe needs the bit to set and to
clear) and `e59e859` (its tests' lint); F8 below is the part it did not reach. F2 (non-blocking in round 1) —
fixed by `f331d45`; F3 — fixed by `3e5a1aa`; F4 and F7 — fixed by `7e549a7`; F5 and F6 — fixed by `c132cd5`.
Each re-read in the diff and by its test, `start_file_mode_that_cannot_clear_is_a_todo`,
`start_trusts_the_clone_once`, `session_title_keeps_a_renamed_title`, `title_strips_a_hash_from_the_lock_line`,
`title_reports_an_unwritable_exclude`.

**Criteria**

| # | Criterion (abbreviated) | Verdict | Settled by |
|---|---|---|---|
| 1 | No `claude auth login` line with `ANTHROPIC_API_KEY` / `CLAUDE_CODE_OAUTH_TOKEN` set | met | `start_credential_variables_hide_the_login_advice` (tests/devcontainer.test.sh:759); `devcontainer-start.sh` step 6 guard |
| 2 | Unwritable `info/exclude` still prints a `window-title:` line | met | `title_reports_an_unwritable_exclude` (:1051), both legs; `window-title.sh` exclude block |
| 3 | `issue: #44` gives `[#44]` exactly once | met | `title_strips_a_hash_from_the_lock_line` (:1031); `window-title.sh:24-26` |
| 4 | `settings.json` holding `[]` is reported as not an object | met | `title_rejects_settings_that_are_not_an_object`, `start_settings_that_are_not_an_object_are_a_todo` |
| 5 | Symlinked `settings.json` still a symlink | met | `title_writes_through_a_symlink`, `start_settings_symlink_is_kept` |
| 6 | `window-title.sh` is mode 100755 in the index | met | `scripts_are_committed_executable`; `git ls-files -s` above |
| 7 | Failed `mv` leaves no `.tmp`; mode not 0600 unless the original's was | met | `title_leaves_no_temp_file_when_mv_fails`, `start_leaves_no_temp_file_when_mv_fails`, `title_keeps_the_settings_mode`, `start_settings_keep_their_mode` |
| 8 | Registered hook command exits 0, no output, with `session-title.sh` removed | met | `session_title_hook_command_survives_a_missing_script` (:1250 region) runs the command read from `.claude/settings.json` |
| 9 | `session_title` beginning with a newline prints nothing | met (the newline guard has no test that isolates it, F15) | `session_title_treats_a_leading_newline_as_a_title` (:1199) |
| 10 | Lock taken/released changes `--print` and the window title follows without a restart | met on the script side; whether Claude Code fires the hook is a manual check | `title_follows_a_released_lock`, `session_title_refreshes_the_window_title`, `session_title_replaces_its_own_title_when_the_lock_changes` |
| 11 | A script added in a fresh container is staged 100755 without `update-index --chmod` | met in a fresh container whose tracked files' modes match the index; see F8 for a clone whose modes do not | `start_sets_file_mode_so_new_scripts_are_executable` (:788), `start_file_mode_that_cannot_clear_is_a_todo` (:826) |
| 12 | `bash tests/run.sh` prints `all cases passed` | met | output above |
| 13 | Fresh container with the `~/.config/git` volume already holding an identity: no identity TODO | met in the suite (config, Dockerfile directory, the start script reading a file at that path); a real fresh container is a manual check | `start_finds_the_identity_in_the_git_volume_file` (:620), `volumes_hold_the_gh_login_and_the_git_config`, `git_config_global_points_into_the_git_volume`, `dockerfile_creates_the_git_config_dir`, `git_global_writes_land_in_the_volume_file` |

**Documentation.** The plan names `CHANGELOG.md` only and says no page under `docs/` describes the dev container;
I checked, none does, and there is no wiki module. The #44 and #45 lines now match the code; the #47 line has two
untruths (F9, F10).

**Review.** Independent code review (opus, `QC review:`) of `162720b..fdf15c2`, given the acceptance criteria and
the issue line only. Its assessment, in plain text: ready to merge with fixes — two Important findings, six
Minor. I reproduced its first one before classifying it: in a scratch repo with `core.fileMode=false`, a tracked
`100755` file that is `644` on disk shows a clean `git status`; after `git config core.fileMode true` it shows
` M run.sh` and `mode change 100755 => 100644`. The reviewer saw the same on this repository's own
`plugins.sh`.

**Findings**

- **F8 — blocking (plan's).** `.devcontainer/scripts/devcontainer-start.sh:57-74`. The probe shows that a *new*
  file in the git dir keeps `chmod`; it never looks at the files already checked out. A clone has
  `core.fileMode=false` precisely because modes on disk and in the index disagreed or could not be trusted (a
  checkout made with the setting off writes tracked scripts without the executable bit), so flipping it to true
  makes `git status` list every tracked script whose disk mode differs from the index, and a later `git add -A`
  or `git commit -a` would commit the mode changes. This is round 1's F1 in its other shape: F1 covered a
  filesystem that reports every file executable, F8 a filesystem that behaves but a tree whose modes are stale.
  The code does what the round 2 plan's amended constraint says; the plan's check is insufficient. Direction for
  the re-plan: after `git config core.fileMode true`, run `git diff --summary` (or `git status --porcelain`) and,
  if it lists any `mode change`, set `core.fileMode` back to `false` and add a TODO naming those files and
  `git update-index --chmod=+x` (or telling the engineer to `chmod` them to the index's modes first); add a case
  with a committed `100755` file at `644` on disk and `core.fileMode false`, which must stay `false` and leave
  `git status` clean.
- **F9 — non-blocking (plan's).** `.devcontainer/devcontainer.json` `containerEnv`, `CHANGELOG.md:14`. With
  `GIT_CONFIG_GLOBAL` set, git ignores `~/.gitconfig`, which VS Code's Dev Containers copies from the host by
  default, so host aliases and signing settings stop applying; the changelog says only "set the identity once".
  Plan Q2 accepted this cost, but the entry should say it. Also to verify by hand: VS Code writes a credential
  helper into `~/.gitconfig` that names a per-container `/tmp/vscode-remote-containers-*.js`; if it now lands in
  the shared `codeo-git` file, another container sharing the volume would call a helper that does not exist
  there (git skips a failing helper and falls through to `gh`'s, so the expected harm is a warning). The reviewer
  could not confirm what VS Code writes.
- **F10 — non-blocking (implement's).** `CHANGELOG.md:14` says `window-title.sh` "reads `issue: #N` from the
  dossier"; it reads the lock, `.codeo/active` (`window-title.sh:24-26`).
- **F11 — non-blocking (plan's).** `window-title.sh` and `devcontainer-start.sh` step 3c: `jq '[inputs][0] // {}
  | type'` reports `object` for a settings file holding `false` or `null` (and for one holding two top-level
  values, the second being dropped), so they are rewritten, while both headers say a value that is not a JSON
  object is left untouched. Fix: classify `[inputs]` by length first (`0` → object, `1` → the value's type,
  more → "multi").
- **F12 — non-blocking (implement's).** `window-title.sh` header (lines 9-11) promises exactly one
  `window-title:` stderr line on every failure, but `mkdir -p "$root/.vscode"`, `mktemp` and `mv` print their own
  messages too. `title_leaves_no_temp_file_when_mv_fails` passes only because its `mv` stub is silent. Redirect
  those tools' stderr, or soften the header.
- **F13 — non-blocking (implement's).** `devcontainer-start.sh:92`: if `readlink -f` fails, the empty target
  produces the TODO "is not valid JSON", which is wrong.
- **F14 — non-blocking (plan's).** `window-title.sh:25` is looser than `scripts/intake.sh:495-497`: it takes the
  leading digits, so `issue: 44abc` and `issue: ##44` give `[#44]` where `intake.sh` rejects them, and `issue:` +
  TAB gives `[home]`. `lock.sh` always writes `issue:   N`, so the effect is cosmetic, but commit `c132cd5`'s
  subject and the header say "as `intake.sh` does".
- **F15 — non-blocking (implement's).** Tests that claim more than they check: `start_finds_the_identity_in_the_git_volume_file`
  points `GIT_CONFIG_GLOBAL` at a file by hand, so it shows nothing beyond `ds_identity`; the newline guard in
  the own-title rule has no test of its own (`$'\nfoo · <sid8>'` is kept by the shape rule alone; a case such as
  `$'\ncodeo [home] · <sid8>'` would pin it); `start_credential_variables_hide_the_login_advice` lost its leg
  where `claude auth status` succeeds with `api_key`/`oauth_token` while the variable is set.

Recorded, not findings: an unwritable `info/exclude` now stops the window title being written at all (the plan's
stated order); two hooks racing on `info/exclude` can add a duplicate line, harmless; a `/rename` to exactly
`<x> [home] · <this sid8>` is retitled, inherent in the rule; the reviewer declined to judge whether Claude Code
applies a `sessionTitle` to a session that already has one, and what VS Code writes into `~/.gitconfig`; both
stay with the manual checks under Notes.

No issue filed by this pass. F9-F15 fold into the re-plan; none needs an issue of its own.

**Verdict: back to `/codeo:plan`.**

### Round 3 — 2026-11-09

(implement.md round 3, `b1e21ca`..`8ef25ff`, plus the dossier commit `0dc9e87`; answers Q1 and Q2 of this file)

**Sync and scope.** `sync-main.sh --abort-on-conflict`: `sync-main: the branch already contains origin/main`.
`overlap.sh 47`: nothing. `overlap.sh --outside 47`: `.claude/settings.json`, `.devcontainer/Dockerfile`,
`.devcontainer/devcontainer.json`, `.devcontainer/scripts/session-title.sh` — files rounds 1-2 touched that the
round 3 footprint (the four files of this round) does not list; non-blocking, as in round 2, the original
footprint (round 1/2) covers them. `scope.sh origin/main HEAD`:

```
scope: suite shell needed for unclassified paths:
  .claude/settings.json
  .codeo/47/implement.md  .codeo/47/init.md  .codeo/47/issue.md  .codeo/47/plan.md  .codeo/47/qc.md
  CHANGELOG.md
suite.shell=true
```

No `deploy=` line: no shared environment is configured. `git diff origin/main...HEAD --stat`: 14 files changed,
2326 insertions, 73 deletions.

**Build.** `shell` suite `build` = `true`: exit 0.

**Suites.** `bash tests/run.sh` (whole `shell` suite): `all cases passed`, exit 0.
`shellcheck .devcontainer/scripts/*.sh tests/devcontainer.test.sh`: only the one `SC2016` info note on the
single-quoted hook-command string in `session_title_hooks_are_registered`.

**Round 2's findings.** F8 (blocking in round 2) — fixed by `b1e21ca` and `44783f8`: `restore_modes` lists the
tracked mode differences as if `core.fileMode` were on, `chmod`s them to the index's modes and sets the setting only
when a second listing is empty. Re-run by hand in a scratch repo (`core.fileMode false`, `bin/run.sh` `755` in the
index and `644` on disk, `data.txt` content-edited): `restore_modes` returned 0 with `restored=1`, `bin/run.sh` is
`755`, `data.txt` untouched, and after `git config core.fileMode true` `git status --short` shows only ` M data.txt`.
F9 (reworded) and F10 — fixed by `8ef25ff` (changelog). F11, F12, F13, F14, F15 — fixed by `42dea00`, `4ad09a7`,
`49556eb`, each with a test that fails without it (the implementer's mutation runs are in `implement.md`).

**Criteria**

| # | Criterion (abbreviated) | Verdict | Settled by |
|---|---|---|---|
| 1 | No `claude auth login` line with `ANTHROPIC_API_KEY` / `CLAUDE_CODE_OAUTH_TOKEN` set | met | `start_credential_variables_hide_the_login_advice` (now with a `claude auth status` that succeeds as well as one that fails) |
| 2 | Unwritable `info/exclude` still prints a `window-title:` line | met | `title_reports_an_unwritable_exclude`; `title_reports_an_unwritable_vscode_dir` |
| 3 | `issue: #44` gives `[#44]` exactly once | met | `title_strips_a_hash_from_the_lock_line` (also a TAB after `issue:`) |
| 4 | `settings.json` holding `[]` is reported as not an object | met | `title_rejects_settings_that_are_not_an_object`, `start_settings_that_are_not_an_object_are_a_todo` (now also `false`, `null`, two values) |
| 5 | Symlinked `settings.json` still a symlink | met | `title_writes_through_a_symlink`, `start_settings_symlink_is_kept` |
| 6 | `window-title.sh` is mode 100755 in the index | met | `scripts_are_committed_executable` |
| 7 | Failed `mv` leaves no `.tmp`; mode not 0600 unless the original's was | met | `title_leaves_no_temp_file_when_mv_fails` (noisy `mv` stub), `start_leaves_no_temp_file_when_mv_fails`, `title_keeps_the_settings_mode`, `start_settings_keep_their_mode` |
| 8 | Registered hook command exits 0, no output, with `session-title.sh` removed | met | `session_title_hook_command_survives_a_missing_script` |
| 9 | `session_title` beginning with a newline prints nothing | met | `session_title_treats_a_leading_newline_as_a_title`, `session_title_keeps_a_renamed_title` (newline before a valid-looking suffix) |
| 10 | Lock taken/released changes `--print` and the window title follows without a restart | met on the script side; whether Claude Code fires the hook is a manual check | `title_follows_the_lock_on_a_rerun`, `title_follows_a_released_lock`, `session_title_refreshes_the_window_title`, `session_title_replaces_its_own_title_when_the_lock_changes` |
| 11 | A script added in a fresh container is staged 100755 without `update-index --chmod` | met as written; F16 and F17 are about how the start script gets there | `start_sets_file_mode_so_new_scripts_are_executable`, `start_restores_tracked_modes_before_turning_file_mode_on` |
| 12 | `bash tests/run.sh` prints `all cases passed` | met | output above |
| 13 | Fresh container with the volume already holding an identity: no identity TODO | met in the suite; a real fresh container is a manual check | `start_reads_the_identity_from_the_global_config_file`, `volumes_hold_the_gh_login_and_the_git_config`, `git_config_global_points_into_the_git_volume`, `dockerfile_creates_the_git_config_dir` |

**Documentation.** The plan names `CHANGELOG.md` only; no page under `docs/` describes the dev container and there is
no wiki module. The #47 line says the number is read from the lock, that tracked modes are restored before
`core.fileMode` goes on, and that the host `~/.gitconfig` no longer applies; all true to the code today. It will
need a matching edit when F16 and F17 are fixed (restoring only one direction; the flip only on a named volume).

**Review.** Independent code review (opus, `QC review:`) of `162720b..HEAD`, code only, given the acceptance
criteria and the issue line. Its assessment, in plain text: ready to merge with fixes; no Critical, two Important
(F16, F17), six Minor.

**Findings**

- **F16 — blocking, the plan's.** `devcontainer-start.sh:63-81,88` `restore_modes` strips the executable bit from a
  tracked file that is `755` on disk and `100644` in the index (the state `git add` leaves under
  `core.fileMode=false`, which is the mistake criterion 11 exists to fix). Scenario: `tool.sh` created, `chmod +x`,
  committed under `core.fileMode=false` (index `100644`); after the start script it is `-rw-r--r--`, `git status` is
  clean, the wrong record is hidden and `./tool.sh` fails; only a count is printed, not the files. The code does what
  the round 3 plan says (Q4's rule restored in both directions, and its "nothing of yours is lost" holds only for the
  `100755`-in-index direction); `ds_modes_repo` codifies it. Q1 settled the fix: restore only the
  `100755`-in-index, not-executable-on-disk direction, leave an executable `100644`-in-index file for git to show,
  ignore it in the second listing, and name the files changed.
- **F17 — non-blocking, the plan's.** `devcontainer-start.sh:83-109` step 2b flips `core.fileMode` and `chmod`s
  tracked files on a bind-mounted host checkout (a Linux or WSL host passes the probe), which step 1 deliberately
  does not touch; it can override a `core.fileMode=false` set on purpose and writes the host's `.git/config`. Q2
  settled the fix: apply 2b only to a clone on a named volume (`clone_on_named_volume`), a bind mount gets the
  `update-index --chmod` TODO.
- **F18 — non-blocking, the plan's.** `session-title.sh:40-41` a forked or resumed session (new id) keeps a title
  ending in another session's ` · <sid8>`; it is read as a `/rename` and never follows the lock.
- **F19 — non-blocking, the plan's.** `session-title.sh:41` the codename is not compared, so a `/rename` shaped
  `x [home] · <sid8>` is replaced; comparing against `"$codename [...]"` would be exact.
- **F20 — non-blocking, deliberate.** `window-title.sh:26` `issue: 44abc` gives `[#44]`, `issue: 4 4` gives `[#4]`;
  Round 3 chose leading digits on purpose. Recorded, no action needed.
- **F21 — non-blocking, the plan's.** Both merges replace the inode with `mv`: only the mode is copied
  (`chmod --reference`), so an owner other than `dev` and hard links of `settings.json` are not kept.
- **F22 — non-blocking, the plan's.** `devcontainer-start.sh:126` a non-regular `~/.claude/settings.json` (a
  directory, or a link to one) is skipped with no TODO.
- **F23 — non-blocking, the plan's.** `devcontainer-start.sh:84,93` the probe file goes in `git rev-parse --git-dir`
  and `git config` writes the common config; wrong in a linked worktree on another filesystem. Not this layout.
- From `implement.md` round 3, non-blocking: the second `git diff … 2>/dev/null` listing in `restore_modes` reads a
  failure as empty and would turn the setting on (not reproducible without a corrupt index); a missing comma in the
  changelog line ("with or without a `#` and writes through a symlink"); no test for a file that differs in both mode
  and content, or the singular "1 tracked file".

No issue filed by this pass. F18-F23 are small enough to fold into the re-plan or be left; the engineer can say which.

**Manual checks still to make** (named in the plan, the suite cannot see them): rebuild the container, set the
identity once, confirm a second container prints no identity TODO; take the lock and send a prompt (titles say
`[#N]`), release it (`[home]` at the next prompt), `/rename` a session (kept); read `/home/dev/.config/git/config`
for a VS Code credential helper naming `/tmp/vscode-remote-containers-*.js` (Q5). If Claude Code does not apply a
`sessionTitle` to a session that already has one, that is a send-back to `/codeo:plan`.

**Verdict: back to `/codeo:plan`.**

### Round 4 — 2026-11-09

(implement.md round 4, `e5b219b`..`dbc051e` and the fix commit `9788c68`; plus the dossier commit `35aa413`)

**Sync and scope.** `sync-main.sh --abort-on-conflict`: `sync-main: the branch already contains origin/main`.
`overlap.sh 47`: nothing. `overlap.sh --outside 47`: `.claude/settings.json`, `.devcontainer/Dockerfile`,
`.devcontainer/devcontainer.json`, `.devcontainer/scripts/window-title.sh` — files rounds 1-3 touched that this
round's footprint (four files) does not list; non-blocking, the round 1-3 footprints covered them. `scope.sh origin/main HEAD`:

```
scope: suite shell needed for unclassified paths:
  .claude/settings.json
  .codeo/47/implement.md  .codeo/47/init.md  .codeo/47/issue.md  .codeo/47/plan.md  .codeo/47/qc.md
  CHANGELOG.md
suite.shell=true
```

No `deploy=` line: no shared environment is configured. `git diff origin/main...HEAD --stat`: 14 files changed,
2956 insertions, 73 deletions.

**Build.** `shell` suite `build` = `true`: exit 0.

**Suites.** `bash tests/run.sh` (whole `shell` suite): `all cases passed`, exit 0.
`shellcheck .devcontainer/scripts/*.sh tests/devcontainer.test.sh`: only the one `SC2016` info note on the
single-quoted hook-command string in `session_title_hooks_are_registered`.

**Round 3's findings.** F16 (blocking in round 3) — fixed by `f7a64dc`: `restore_modes` acts only on index `100755` /
disk `100644`, leaves an executable file the index records `100644`, names the restored files, and a failed listing
keeps `core.fileMode` false. Re-run by hand in a scratch repo (`core.fileMode false`; `bin/run.sh` `755` in the index
and `644` on disk, `tool.sh` `644` in the index and `755` on disk): `restore_modes` returned 0 with
`restored=1 paths=bin/run.sh left=`, `bin/run.sh` is `755`, `tool.sh` is still `755`, no `modes.*` file is left in
`.git`, and after `git config core.fileMode true` `git status --short` is ` M tool.sh` with `git diff --summary`
`mode change 100644 => 100755 tool.sh`. F17 — fixed by `e5b219b` (step 2b only on a Docker named volume; the
bind-mount case prints one TODO and changes nothing). F18, F19 — fixed by `906d7b1` (a fork's inherited title is
replaced, another codename or a bad suffix is kept; the opus review ran both). F22 — fixed by `3ee872d` and
`9788c68`. The deferred minors of `implement.md` round 3 (`git diff` exit check, changelog comma) — fixed by `f7a64dc`
and `dbc051e`. F20, F21, F23 were left recorded by the engineer's choice (`plan.md` Q6) and stay non-blocking.

**Criteria**

| # | Criterion (abbreviated) | Verdict | Settled by |
|---|---|---|---|
| 1 | No `claude auth login` line with `ANTHROPIC_API_KEY` / `CLAUDE_CODE_OAUTH_TOKEN` set | met | `start_credential_variables_hide_the_login_advice` |
| 2 | Unwritable `info/exclude` still prints a `window-title:` line | met | `title_reports_an_unwritable_exclude`, `title_reports_an_unwritable_vscode_dir` |
| 3 | `issue: #44` gives `[#44]` exactly once | met | `title_strips_a_hash_from_the_lock_line` |
| 4 | `settings.json` holding `[]` is reported as not an object | met | `title_rejects_settings_that_are_not_an_object`, `start_settings_that_are_not_an_object_are_a_todo` |
| 5 | Symlinked `settings.json` still a symlink | met | `title_writes_through_a_symlink`, `start_settings_symlink_is_kept` |
| 6 | `window-title.sh` is mode 100755 in the index | met | `scripts_are_committed_executable` |
| 7 | Failed `mv` leaves no `.tmp`; mode not 0600 unless the original's was | met | `title_leaves_no_temp_file_when_mv_fails`, `start_leaves_no_temp_file_when_mv_fails`, `title_keeps_the_settings_mode`, `start_settings_keep_their_mode` |
| 8 | Registered hook command exits 0, no output, with `session-title.sh` removed | met | `session_title_hook_command_survives_a_missing_script` |
| 9 | `session_title` beginning with a newline prints nothing | met | `session_title_treats_a_leading_newline_as_a_title`, `session_title_keeps_a_renamed_title` |
| 10 | Lock taken/released changes `--print` and the window title follows without a restart | met on the script side; whether Claude Code fires the hook and VS Code applies the rewritten file live is a manual check | `title_follows_the_lock_on_a_rerun`, `title_follows_a_released_lock`, `session_title_refreshes_the_window_title`, `session_title_replaces_its_own_title_when_the_lock_changes` |
| 11 | A script added in a fresh container is staged 100755 without `update-index --chmod` | met as written for a clone on a Docker volume; a bind mount gets the TODO by design (Q2) | `start_sets_file_mode_so_new_scripts_are_executable`, `start_restores_tracked_modes_before_turning_file_mode_on`, `start_keeps_an_executable_bit_the_index_does_not_record`, `start_leaves_a_bind_mounted_clone_alone` |
| 12 | `bash tests/run.sh` prints `all cases passed` | met | output above |
| 13 | Fresh container with the volume already holding an identity: no identity TODO | met in the suite; a real fresh container is a manual check | `start_reads_the_identity_from_the_global_config_file`, `volumes_hold_the_gh_login_and_the_git_config`, `git_config_global_points_into_the_git_volume`, `dockerfile_creates_the_git_config_dir` |

**Documentation.** The plan names `CHANGELOG.md` only; no page under `docs/` describes the dev container and there is
no wiki module. The #47 line says what the code does now: the number read from the lock, `core.fileMode` back on only
on a clone on a Docker volume, only the executable bit the index records restored, an executable file recorded without
it left for git to show, a forked session's inherited title retitled, the host `~/.gitconfig` no longer applying.
The script header comments match the code after `9788c68`.

**Review.** Independent code review (opus, `QC review:`) of `162720b..HEAD`, code only, given the acceptance
criteria and the issue line. Its assessment, in plain text: ready to merge with fixes — no Critical, one Important, five Minor.

**Findings**

- **F24 — non-blocking, the plan's.** `devcontainer-start.sh:118-130` (step 2b success branch): when `core.fileMode`
  goes on, files that are executable on disk but recorded `100644` start to show as mode changes, and the script says
  nothing about them. Reproduced by the reviewer: 20 such tracked files plus one `100755` file at `644`; `git status`
  was clean before, the only message was "restored the modes of 1 tracked file (run.sh) … set it to true", afterwards
  `git status --porcelain` listed 20 ` M` lines, which a `git add -A` would commit. Leaving those bits alone is the
  engineer's own Q1 answer ("let git show `mode change 100644 => 100755`, ready to commit"), so this is the
  message, not the behaviour: count the reverse-direction paths in the second listing and name them in the `say`
  line or a TODO. Not blocking: nothing is lost or changed, and `git status` shows the cause.
- **F25 — non-blocking.** `window-title.sh:38` `touch "$exclude"` runs on every call before the grep that shows
  the line is already there; through the prompt hook that updates the exclude file's mtime on every prompt, which
  makes `session-title.sh`'s header claim "a no-op when it is current" untrue for that file, and an exclude file
  `touch` cannot update makes the script die without writing a title although nothing needed writing.
- **F26 — non-blocking.** `window-title.sh:34-41` with an unwritable `info/exclude` the title is no longer written
  at all (the criterion asks only that a `window-title:` line be printed, and `title_reports_an_unwritable_exclude`
  pins this on purpose); noted as a trade-off.
- **F27 — non-blocking.** `window-title.sh:47-49` a `settings.json` path that resolves to a directory or an
  unreadable file is reported as "is not valid JSON"; the behaviour (left untouched, exit 1) is fine, the wording is not.
- **F28 — non-blocking.** `devcontainer-start.sh:99` the step fires on `core.fileMode=false` from any scope, a global
  `false` in the shared `codeo-git` config included, and sets a local `true`; the message does not say it overrode one.
- **F29 — non-blocking.** `devcontainer-start.sh:38-40` `safe.directory` entries now accumulate in the shared
  `codeo-git` volume, one per clone path ever created, unpruned. Harmless.
- Earlier rounds' non-blocking findings F18-F23 that stay recorded: F20 (leading digits of the lock line), F21 (owner
  and hard links of `settings.json`), F23 (linked worktrees); and from `implement.md`: the stderr of a failed listing
  is discarded; no test for a file differing in both mode and content.

No issue filed by this pass. F24 is the one worth a follow-up (`/codeo:triage` will find it here); F25-F29 are small.

**Manual checks still to make** (named in the plan, the suite cannot see them): rebuild the container, set the
identity once, confirm a second container prints no identity TODO; take the lock and send a prompt (titles say
`[#N]`), release it (`[home]` at the next prompt), `/rename` a session (kept); on the `codeo-47` volume with
`core.fileMode false`, a script made executable and committed as `100644` is still executable after the start script
and `git status` shows it as a mode change; in a bind-mounted host checkout the start script prints the "left alone"
TODO and changes nothing in the host's `.git/config`; read `/home/dev/.config/git/config` for a VS Code credential
helper naming `/tmp/vscode-remote-containers-*.js` (Q5). If Claude Code does not apply a `sessionTitle` to a session
that already has one, that is a send-back to `/codeo:plan`.

**Verdict: clear — forward to `/codeo:close`.**

## Log

- 2026-11-09 — qc round 1: back to plan · 1 blocking, 6 non-blocking · no issue filed · opus reviewer · cost: 6m · opus-5-5 397k in + 2.8M cached / 20k out
- 2026-11-09 — qc round 2: back to plan · 1 blocking, 7 non-blocking · no issue filed · opus reviewer · cost: 5m · opus-5-5 550k in + 2.2M cached / 19k out · sonnet-5-5 28k in + 456k cached / 2k out
- 2026-11-09 — qc round 3: Q1-Q2 raised, no verdict yet · opus reviewer · cost: 4m · opus-5-5 271k in + 2M cached / 17k out · sonnet-5-5 195k in + 29k cached / 1k out
- 2026-11-09 — qc round 3: back to plan · 1 blocking, 7 non-blocking · no issue filed · opus reviewer · Q1-Q2 answered · cost: 25m · opus-5-5 271k in + 2M cached / 17k out · sonnet-5-5 204k in + 1.2M cached / 8k out
- 2026-11-09 — qc round 4: clear · 0 blocking, 6 non-blocking · no issue filed · opus reviewer · no shared environment · cost: 6m · opus-5-5 445k in + 1.5M cached / 20k out · sonnet-5-5 22k in + 363k cached / 821 out
