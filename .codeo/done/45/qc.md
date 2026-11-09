# Issue #45 — qc

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/45 |
| Branch | `feat/dev-container-title-each-claude` |
| Updated | 2026-11-09 |

## Where this stands

Round 1 done: clear, forward to `/codeo:close`. The manual checks in the plan's last section are still the engineer's to make and record under Notes.

## Questions

None.

## Notes

- Manual checks (engineer, not yet made): the picker (`claude --resume`) and claude.ai/code list a new session as `codeo [#45] · <id8>`; `/clear` then one prompt gives the same title; `/rename`, exit, `claude --resume` keeps the name; on the host a session in a clone of this branch has no hook-set title. If the installed Claude Code does not apply a bare `sessionTitle`, or does not deliver `session_title` on stdin, that is a send-back to `/codeo:plan`.

## Outcome

### Round 1 — 2026-11-09

Sync: `sync-main.sh --abort-on-conflict` → "the branch already contains origin/main"; `overlap.sh 45` and `overlap.sh --outside 45` printed nothing.
Scope: `scope.sh origin/main HEAD` → `suite.shell=true` (dossier and CHANGELOG paths unclassified). No environment, so no `deploy=` line and no Environment block.
Build: shell suite `build` is `true` → exit 0.
Suite: `bash tests/run.sh` → `all cases passed`, exit 0. `shellcheck .devcontainer/scripts/*.sh` → no output, exit 0. `git ls-files -s .devcontainer/scripts/session-title.sh` → `100755`.
Live runs of the hook with `REMOTE_CONTAINERS=true`: `SessionStart` fixture → `{"hookSpecificOutput":{"hookEventName":"SessionStart","sessionTitle":"codeo [#45] · a21b9973"}}`, rc 0; fixture with `session_title` set → no output, rc 0; with `REMOTE_CONTAINERS` unset → no output, rc 0.

| # | Criterion | Verdict | Settled by |
|---|---|---|---|
| 1 | New session in the home container is `codeo [home] · <id8>` | met (script output) — listing in the picker is a manual check | `session_title_names_home_and_the_id` |
| 2 | Container holding issue N's lock is `codeo [#N] · <id8>` | met (script output) — listing is a manual check | `session_title_names_the_issue_with_a_lock`; live run above |
| 3 | `/clear` session titled the same way | untestable here — the script titles the first prompt (`session_title_on_a_prompt_after_clear`); that Claude Code applies it is a manual check | `session-title.sh`, `.claude/settings.json` `UserPromptSubmit` |
| 4 | `/rename` keeps its name after resume | untestable here — the script prints nothing when `session_title` is set (`session_title_keeps_an_existing_title`); that Claude Code delivers it is a manual check | same |
| 5 | Outside a dev container no hook-set title | met | `session_title_is_silent_outside_a_dev_container` (unset, `false`, `1`); live run above |
| 6 | Title script missing or failing: exit 0, no output | met for `window-title.sh` (`session_title_is_silent_when_the_title_script_fails`: missing, exit 1, empty output); see F1 for `session-title.sh` itself | tests; F1 |
| 7 | One script for window and session titles, tests cover it | met | `session-title.sh` calls `window-title.sh --print`; eight `session_title_*` cases and `session_title_hooks_are_registered` |
| 8 | `bash tests/run.sh` passes | met | output above |

Documentation: `CHANGELOG.md` Unreleased entry added, as the plan says; no page under `docs/` describes the dev container, and the plan states none moves. See F2.

Independent review (opus, criteria only): Critical none, Important none, two Minor. Assessment quoted: "Ready to merge: Yes".

Findings:
- F1 (non-blocking, `/codeo:implement`'s if wanted): `.claude/settings.json:11,22` — the hook command is not guarded against `session-title.sh` itself being missing: `bash <missing path>` exits 127 with a message on stderr. The session still starts (a non-blocking hook error). The plan reads "the title script" in criterion 6 as `window-title.sh`, which is fully handled, so the gap is only in the other reading.
- F2 (non-blocking, wording): `CHANGELOG.md:13` says "every Claude Code session is titled"; a resumed session keeps a title set at an earlier start, which the next sentence and the issue allow.

Declined to judge by the reviewer and left to the manual checks above: whether Claude Code applies a bare `sessionTitle`, and whether `REMOTE_CONTAINERS` reaches every way Claude is launched in the container.

No issue filed for this pass.

**Verdict: clear — forward to `/codeo:close`.**

## Log

- 2026-11-09 — qc round 1: clear · 0 blocking, 2 non-blocking · no issue filed · opus reviewer · cost: 4m · opus-5-5 195k in + 1.3M cached / 9k out · sonnet-5-5 145k in + 26k cached / 3k out
