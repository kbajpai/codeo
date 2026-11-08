# Issue #44 — qc

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/44 |
| Branch | `feat/dev-container-defaults-remote-control` |
| Updated | 2026-11-08 |

## Where this stands

Round 1 done: clear, forward to `/codeo:close`. Two criteria (1 and 2) need the manual check named below before or after the PR; the suite cannot see claude.ai/code.

## Questions

None.

## Outcome

### Round 1 — 2026-11-08

(first pass; implement.md round 1)

**Sync and scope.** `sync-main.sh --abort-on-conflict`: `sync-main: the branch already contains origin/main`. `overlap.sh 44`: nothing. `overlap.sh --outside 44`: nothing. `scope.sh origin/main HEAD`:

```
scope: suite shell needed for unclassified paths:
  .codeo/44/implement.md
  .codeo/44/init.md
  .codeo/44/issue.md
  .codeo/44/plan.md
  CHANGELOG.md
suite.shell=true
```

No `deploy=` line and no shared environment configured, so there is no environment step.

**Build.** `shell` suite `build` = `true`: exit 0.

**Suites.** `bash tests/run.sh` (whole `shell` suite): `all cases passed`, exit 0. `shellcheck .devcontainer/scripts/*.sh tests/devcontainer.test.sh`: no output, exit 0. The reviewer's own run of the suite also exited 0.

**Criteria**

| # | Criterion (abbreviated) | Verdict | Settled by |
|---|---|---|---|
| 1 | New session listed in claude.ai/code after `claude auth login`, without `/remote-control` | untestable here — needs a live container and a claude.ai account; the code side holds: `start_enables_remote_control` (tests/devcontainer.test.sh:578) asserts `remoteControlAtStartup == true` in the user settings, and the installed binary (2.1.319) has that key | manual check, below |
| 2 | Session started with `/clear` also listed | untestable here — same; the setting is "each session" per the binary | manual check, below |
| 3 | Credential variables or no claude.ai login → TODO, exit 0 | met | `start_env_vars_are_todos` (:635), `start_non_claude_ai_login_is_a_todo` (:656), `start_todo_when_nothing_is_set_up`; see F1 for a caveat on the advice |
| 4 | Title `codeo [home]` with no lock, `codeo [#N]` with one | met whenever the script runs; it does not re-run when the lock changes mid-session, which is plan Q2's answered decision and is stated in CHANGELOG.md | `title_is_home_without_a_lock` (:694), `title_names_the_issue_with_a_lock` (:703), `title_follows_the_lock_on_a_rerun` (:745), `post_start_command_reruns_the_title` (:64) |
| 5 | Re-run keeps title right and other keys in `.vscode/settings.json` | met | `title_keeps_other_keys` (:717), `title_rerun_and_worktree` (:727), `title_follows_the_lock_on_a_rerun` |
| 6 | `git status` clean after the title is written | met | `title_rerun_and_worktree` (:727), clone and linked worktree |
| 7 | `~/.claude/settings.json` keeps plugins and update channel | met | `start_keeps_other_settings` (:587), two runs over `enabledPlugins` and `autoUpdatesChannel` |
| 8 | `tests/devcontainer.test.sh` covers title and login checks; `bash tests/run.sh` passes | met | the cases above; `bash tests/run.sh`: `all cases passed` |

**Documentation.** The plan names `CHANGELOG.md` only; no page under `docs/` describes the dev container and there is no wiki module. The changelog entry matches the scripts (checked by the task reviewer and the code reviewer). The `window-title.sh` header promises a `window-title:` stderr line on every failure; see F2.

**Review.** Independent code review (opus, `QC review:`) of 89385f2..0728b32, given the acceptance criteria and the issue line only. Its assessment, in plain text: ready to merge with fixes. It found no Critical issue. Its two Important findings are classified below; its Minor findings are F3-F7.

**Findings**

- **F1 — non-blocking (plan's).** `.devcontainer/scripts/devcontainer-start.sh:94-108`. With `ANTHROPIC_API_KEY` or `CLAUDE_CODE_OAUTH_TOKEN` set, the real `claude auth status` reports `authMethod: api_key` / `oauth_token` (reproduced here: `CLAUDE_CONFIG_DIR=<empty> ANTHROPIC_API_KEY=x claude auth status` → exit 0, `"authMethod": "api_key"`), so the start script adds "logged in with api_key, not claude.ai … run claude auth login" and puts `claude auth login` first in the numbered list. Running it does not help while the variable is set; the second TODO (`<VAR> is set … unset it`) does. Root cause: the plan specified the two checks independently (Global Constraints); the code does what the plan says. Both TODOs are printed and criterion 3 holds, so it does not block the merge. Suggestion for whoever takes it: skip the `authMethod` TODO and the `need_login` entry when one of the three variables is set, with a test for that pair.
- **F2 — non-blocking (implement's).** `.devcontainer/scripts/window-title.sh:39-41`. If `mkdir -p` or `touch` on `info/exclude` fails, `set -e` exits 1 with no `window-title:` line, contradicting the header, and `.vscode/` has already been written, so `git status` shows it. Wrap both in `|| die`.
- **F3 — non-blocking (implement's).** `window-title.sh:19`: an `issue: #44` lock line would give `[##44]`; `lock.sh:144` writes a bare number, `intake.sh:495` accepts the `#` form. Strip a leading `#`.
- **F4 — non-blocking (implement's).** `devcontainer-start.sh:66-70`, `window-title.sh:31-33`: valid non-object JSON (`[]`) is reported as "not valid JSON".
- **F5 — non-blocking (implement's).** `devcontainer-start.sh:65-67`: a symlinked `settings.json` is replaced by a regular file.
- **F6 — non-blocking (implement's).** `.vscode/settings.json` with comments (JSONC) is left untouched with an error, so the title stays unset; worth a line in the header.
- **F7 — non-blocking (implement's).** `window-title.sh` is committed mode 100644, its siblings 100755; both callers use `bash`.

The reviewer's Important 2 (the title does not follow a lock taken mid-session) is not a finding: it is the answer to plan Q2 (hooking `lock.sh` was offered and rejected) and CHANGELOG.md states it.

**Manual check for criteria 1 and 2 (the engineer's).** In a container: `bash .devcontainer/scripts/devcontainer-start.sh` (or rebuild); `claude auth login` if it asks; open a new Claude Code session and one started with `/clear`; both should appear in claude.ai/code without `/remote-control`. If they do not, `/remote-control` prints the reason, and a send-back to `/codeo:plan` follows. Note: this container already holds the setting only after the start script has been re-run here.

No issue filed by this pass; F1-F7 are on the record for `/codeo:triage`.

**Verdict: clear — forward to `/codeo:close`.**

## Log

- 2026-11-08 — qc round 1: clear · cost: 8m · opus-5-5 309k in + 1.9M cached / 14k out · sonnet-5-5 27k in + 239k cached / 2k out
