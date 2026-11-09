# Issue #47 — implement

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/47 |
| Branch | `fix/harden-dev-container-scripts-session` |
| Updated | 2026-11-09 |

## Where this stands

Round 1 done: all ten tasks of `docs/plans/2026-11-09-dev-container-hardening.md` are implemented and committed
(`d963bfa`..`dbccb2c`), each passed its own spec and quality review, and the whole-branch review found no
Critical or Important issue. The `shell` suite's build (`true`) exits 0. Ready for `/codeo:qc`.

## Questions

None.

## Outcome

**Built.** One commit per task, all dispatched to sonnet implementers and reviewers (`models.subagent` unset):

| Task | Commit | What |
|---|---|---|
| 1 | `d963bfa` | `window-title.sh` committed 100755; case `scripts_are_committed_executable` pins the mode of every `.devcontainer/scripts/*.sh` |
| 2 | `43ba6c6` | `window-title.sh` puts the `info/exclude` entry in before writing `.vscode`, ends every failure in one `window-title:` line (including a non-repository), reads `issue: #N` |
| 3 | `643de93` | `window-title.sh` settings merge: `[]` is "not a JSON object", invalid JSON and JSONC "not valid JSON", symlinks written through, mode kept, no temp file on failure, a current title is not rewritten |
| 4 | `cdde886` | `devcontainer-start.sh` skips the `claude auth status` check (and its `claude auth login` advice) while `ANTHROPIC_API_KEY` or `CLAUDE_CODE_OAUTH_TOKEN` is set; `ds_run` gains `DS_SET` |
| 5 | `c531444` | `devcontainer-start.sh` step 3c follows the same merge contract for the Claude user settings |
| 6 | `af8aee8` | `devcontainer-start.sh` probes `core.fileMode` and sets it back to true where the executable bit sticks, else a TODO naming `git update-index --chmod=+x` |
| 7 | `126b2ea` | `session-title.sh` reads stdin NUL-separated, refreshes the window title on every run, replaces its own session title (` · <id8>` suffix) when the lock changes, keeps any other |
| 8 | `92c8e19` | the registered hook command in `.claude/settings.json` is guarded (exits 0 with no output when the script is missing); registration test no longer depends on key order |
| 9 | `7369e41` | `codeo-git` volume at `/home/dev/.config/git` + `containerEnv.GIT_CONFIG_GLOBAL`; Dockerfile creates the directory; `ds_run` gains `DS_GITCONFIG` |
| 10 | `dbccb2c` | test-file header and `CHANGELOG.md` (the #45 line reworded, a #47 entry) |

**Documentation changed:** `CHANGELOG.md` only, as the plan says; no page under `docs/` describes the dev
container and there is no wiki module.

**Build:** `shell` suite `build` = `true`: exit 0. The full suite and the acceptance criteria are `/codeo:qc`'s.
No shared environment is configured, so no lease and no deploy. `sync-main.sh`: the branch already contained
`origin/main`; `overlap.sh 47` printed nothing.

**Deviations from the plan, and why:**
- Task 3: two of the six new cases, `title_leaves_no_temp_file_when_mv_fails` and `title_follows_a_released_lock`,
  passed before the change (the old code already removed its temp file and followed the lock). The plan expected
  all six to fail first; they stay as regression guards.
- Task 10: the plan's proof says `shellcheck … tests/devcontainer.test.sh` prints nothing. It prints one `SC2016`
  info note on the single-quoted hook command string in the registration/missing-script test, which is
  deliberately literal (the earlier #45 registration test held the same kind of string). Nothing at warning level
  or above; `shellcheck .devcontainer/scripts/*.sh` prints nothing.

**Deferred minors** (task and whole-branch reviews; none blocks, none is a plan finding):
- `CHANGELOG.md`, the reworded #45 line: "a session that already has a title … keeps it" is slightly broader than
  the code, since a title the hook itself set is replaced when the lock changes (the #47 line says so). The
  wording is the plan's.
- `devcontainer-start.sh` step 1 uses `git config --global --add safe.directory`, which appends a duplicate on
  every container creation; with the global config now in the shared `codeo-git` volume the duplicates outlive
  the container. Harmless to git; `--replace-all` or a presence check would fix it. Outside the plan.
- Empty-glob wording in `scripts_are_committed_executable`; an over-long header line in
  `devcontainer-start.sh` and a long Dockerfile comment; no test for a dangling symlink in step 3c or for the
  window refresh on a short session id or an unsupported event.

**For `/codeo:qc` and the engineer:** the manual checks at the end of the plan still stand and go in `qc.md` —
rebuild the container, set the identity once, confirm a second container prints no identity TODO; take the lock
and send a prompt (session and window titles say `[#N]`), release it (`[home]` at the next prompt), `/rename` a
session (kept). If Claude Code does not apply a `sessionTitle` to a session that already has one, that is a
send-back to `/codeo:plan`.

## Log

- 2026-11-09 — implemented: 10 tasks, 10 commits · sonnet-5-5 subagents for every dispatch · build `true` passed · cost: 73m · sonnet-5-5 979k in + 18.6M cached / 125k out
