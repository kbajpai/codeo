# Issue #47 — issue

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/47 |
| Branch | none |
| Updated | 2026-11-08 |

## Where this stands

Filed from `/codeo:triage` (run 2026-11-08, Q1+Q2). The engineer chose to file qc:44 F1 and F2-F7 plus
the implement:44 "left unfixed" minors as one issue. Draft below approved and filed; no open questions.

## Questions

None open.

## Notes

- Evidence: `.codeo/done/44/qc.md` F1-F7 and `.codeo/done/44/implement.md` ("Left unfixed") on `main`.
- No duplicate found (`issue search`); repository has no Issue Types, so none proposed. Label: `bug`.

## Outcome

Filed as #47 (label `bug`, no Issue Type).

## Draft

**Title:** Harden the dev container start script and window-title script

### Description
Follow-ups from #44's QC that did not block the merge. The main one: when `ANTHROPIC_API_KEY` or
`CLAUDE_CODE_OAUTH_TOKEN` is set, `.devcontainer/scripts/devcontainer-start.sh` still tells the engineer to
run `claude auth login`, which does nothing while the variable is set. The rest are edge cases in
`devcontainer-start.sh` and `window-title.sh` that fail with a wrong message, no message, or a surprising
file change.

### Motivation / Context
The start script is what a new container tells the engineer to do next; wrong advice there costs a
confused round trip. The edge cases are small, but each is a silent or misleading failure in a script
that runs on every container start.

### Key Requirements
- With either variable set, the start script does not print the `claude auth login` TODO or list it first;
  the "unset the variable" TODO is the one shown. (qc:44 F1)
- A failure creating or touching `info/exclude` still ends with a `window-title:` line, not a bare exit 1. (F2)
- A lock line `issue: #44` yields `[#44]`, not `[##44]`. (F3)
- Valid JSON that is not an object (`[]`) gets its own message, not "not valid JSON". (F4)
- A symlinked `settings.json` is not replaced by a regular file. (F5)
- A JSONC `.vscode/settings.json` is still left untouched; the script header says so. (F6)
- `window-title.sh` is committed executable like its siblings. (F7)
- Minors: the temp file keeps the target's mode after `mv`; no stray `.tmp` if `mv` fails; the stdout
  line of a plain title run is asserted in the tests.

### Acceptance Criteria
- [ ] With `ANTHROPIC_API_KEY` set, the start script's output has no `claude auth login` line; same for `CLAUDE_CODE_OAUTH_TOKEN`.
- [ ] Making `info/exclude` unwritable still prints a `window-title:` line.
- [ ] `issue: #44` in the lock gives a title containing `[#44]` exactly once.
- [ ] A `settings.json` holding `[]` is reported as not an object.
- [ ] A symlinked `settings.json` is still a symlink afterwards.
- [ ] `git ls-files -s .devcontainer/scripts/window-title.sh` shows mode 100755.
- [ ] A failed `mv` leaves no `.tmp` file; the written file's mode is not 0600 unless the original's was.
- [ ] `bash tests/run.sh` prints `all cases passed`.

### Out of Scope
Handling JSONC by parsing comments; session titles (#45).

### Reference
Surfaced by `/codeo:qc` on #44 (PR #46): `.codeo/done/44/qc.md` F1-F7, `.codeo/done/44/implement.md`;
`.devcontainer/scripts/devcontainer-start.sh:65-108`, `.devcontainer/scripts/window-title.sh`. Similar
bundle: #40 (follow-ups from #36).

Label: `bug`. No Issue Type.

## Amendment — 2026-11-08

At the engineer's request, a requirement and criterion for persisting the git identity across dev
containers (`~/.config/git` volume) were folded into #47 and its title extended; found when container
`codeo-45` printed the "git identity is not set" TODO again. Edited on GitHub with `gh api -X PATCH`.
