# Issue #47 — implement

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/47 |
| Branch | `fix/harden-dev-container-scripts-session` |
| Updated | 2026-11-09 |

## Where this stands

Round 2 done, answering `qc.md` round 1: Tasks 11-15 of `docs/plans/2026-11-09-dev-container-hardening.md`
(`## Round 2`) are implemented and committed (`8988cea`..`e59e859`), each passed its own spec and quality review
(Task 11 after one fix round), and the round's whole review found no Critical or Important issue. The `shell`
suite's build (`true`) exits 0. Ready for `/codeo:qc` round 2.

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

### Round 2

2026-11-09
(send-back from qc.md round 1)

Round 1's findings were checked against the code before any dispatch (F1 `devcontainer-start.sh` probe, F2 the
`--add safe.directory` line, F3 the suffix-only own-title test, F4 the changelog line, F5 the `awk` lock parse,
F6/F7 the tests): all held, none was argued back. `sync-main.sh`: the branch already contained `origin/main`;
`overlap.sh 47`: nothing. One sonnet implementer and one sonnet reviewer per task (`models.subagent` unset).

**Built.** One commit per task:

| Task | Commit | What |
|---|---|---|
| 11 (F1) | `8988cea`, then `e59e859` | the `core.fileMode` probe needs the bit to be absent on the fresh file, settable and clearable (`! -x`, `chmod u+x` → `-x`, `chmod u-x` → `! -x`); any failing step leaves `core.fileMode` false with the `update-index --chmod` TODO; new case with a `chmod` stub that always leaves the file executable; every path removes the probe file. `e59e859` replaces three `ls \| grep` assertions with a glob test and writes the stub with a heredoc, after Task 15's shellcheck run showed warnings `8988cea` had introduced |
| 12 (F2) | `f331d45` | `safe.directory` is added only when `git config --global --get-all` does not already list the clone as a whole line; test: two runs on a seeded config add it once |
| 13 (F3) | `3e5a1aa` | the hook treats a session title as its own only when it has no newline and ends ` [home]` or ` [#<digits>]` before ` · <sid8>`; `my name · <sid8>`, `codeo [x] · <sid8>` and a title with a newline are kept |
| 14 (F5, F6) | `c132cd5` | `window-title.sh` reads the digits after `issue:`, any spaces and `#`s (`issue:#44`, `issue: ##44` → `[#44]`; no digits → `[home]`); a `chmod 444` `info/exclude` leg, skipped as root |
| 15 (F4, F7) | `7e549a7` | `CHANGELOG.md`: #45 "A `/rename`d title is kept.", #44 gains "at the next Claude Code prompt in the container", #47 "keeps the executable bit as set"; the credential test is one run per variable with a failing `claude auth status`, shown to fail when the step-6 skip is removed (in a scratch copy) |

**Documentation changed:** `CHANGELOG.md` only, as the plan says; no page under `docs/`, no wiki module.

**Build:** `shell` suite `build` = `true`: exit 0. No shared environment, so no lease and no deploy. The full suite
and the criteria are `/codeo:qc`'s; the implementers reported `bash tests/run.sh devcontainer` and the whole
suite passing, and `shellcheck .devcontainer/scripts/*.sh` printing nothing. `shellcheck tests/devcontainer.test.sh`
prints only the one `SC2016` info note on the single-quoted hook-command string in
`session_title_hooks_are_registered`, which `origin/main`'s test file also prints.

**Deviations from the plan, and why:**
- Task 11 needed a fix round: its own tests introduced three `SC2010` warnings and an `SC2016` note that the plan's
  proof (no shellcheck output beyond the one note) rules out; found by Task 15's run, fixed by resuming Task 11's
  implementer, re-reviewed, addressed.
- Task 14's read-only `info/exclude` leg passed before the change, as the plan expected: it pins behaviour that
  already existed.

**Deferred minors** (none blocks):
- The newline guard in the own-title rule has no test of its own: the added case `\nfoo · <sid8>` is kept by the
  shape rule alone. A case with a newline before a valid-looking suffix (`\ncodeo [home] · <sid8>`) would pin it.
- `start_credential_variables_hide_the_login_advice` no longer has a leg where `claude auth status` succeeds with
  `api_key`/`oauth_token` while the variable is set; one extra `STUB_CLAUDE_RC=0` run would restore it.
- `window-title.sh` takes the leading digits of the lock line, so `issue: 44abc` and `##44` give `[#44]`, while
  `intake.sh` rejects them; "as `intake.sh` does" in the header is slightly loose.
- A long comment line in the test file; the `chmod` stubs are broader than the scenarios they model; the empty
  glob wording in `scripts_are_committed_executable`; no test for a dangling symlink in step 3c.

**For `/codeo:qc` and the engineer:** the manual checks at the end of the plan still stand (rebuild the container,
set the identity once, a second container prints no identity TODO; titles follow the lock; a `/rename` is kept;
a bind-mounted host checkout keeps `core.fileMode` false). If Claude Code does not apply a `sessionTitle` to a
session that already has one, that is a send-back to `/codeo:plan`.

## Log

- 2026-11-09 — implemented: 10 tasks, 10 commits · sonnet-5-5 subagents for every dispatch · build `true` passed · cost: 73m · sonnet-5-5 979k in + 18.6M cached / 125k out
- 2026-11-09 — implemented (round 2, send-back from qc.md round 1): 5 tasks, 7 commits (one fix round on Task 11) · sonnet-5-5 subagents for every dispatch · build `true` passed · cost: 32m · sonnet-5-5 507k in + 17.9M cached / 65k out
