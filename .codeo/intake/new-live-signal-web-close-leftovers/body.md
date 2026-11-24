### Description

`/codeo:qc` passed #157 (the live-signal leftovers from #138) with non-blocking findings that were recorded for triage and have no issue. A hosted web session's `/codeo:close` tells the engineer there is nothing to remove although its `codeo-live/<N>/<machine>` branch stays on origin; two pages describe close's sweep without the web-session exception that the rest of the docs state; and `/codeo:cleanup` prints no leftover-branch delete command when only the container-name proof failed.

### Motivation / Context

- **#157 F12:** `skills/close/SKILL.md:537` (step 17, `host: web`) says "nothing to remove: the hosted session is done once the engineer closes it". In a hosted web session step 16's `live.sh sweep` is a no-op (`scripts/live.sh:240`), so the session's `codeo-live/<N>/<machine>` branch stays on origin, and the report neither says so nor names the delete command (`git push origin --delete codeo-live/<issue>/<machine>`, `docs/handoff.md:173`). The same holds for `host: local` with `CLAUDE_CODE_REMOTE=true`. The sentence is about the checkout and nothing is lost, so #157 merged with it.
- **#157 F13:** `skills/close/SKILL.md:3` and `docs/skills.md:185` say close "sweeps the issue's leftover live-signal branches" without the web-session exception that step 16, `docs/handoff.md:173` and the CHANGELOG state; `docs/skills.md:193` carries it.
- **#157 F8:** `scripts/cleanup.sh:134` skips `leftover_proof` when only the `name` proof failed (`[[ $out == name ]] || leftover_proof "$n"`), although whether the branches can be deleted does not depend on the container name. With a misconfigured overlay no leftover command is ever printed for that issue.

### Key Requirements

- A hosted web session's close report says its live-signal branch stays on origin and names the command that deletes it (also for `host: local` with `CLAUDE_CODE_REMOTE=true`).
- Every page that describes close's sweep states, or does not contradict, the web-session exception.
- `/codeo:cleanup` prints the leftover-branch command for a proven issue's branches whether or not the container-name proof passed.

### Acceptance Criteria
- [ ] Step 17 of `skills/close/SKILL.md`, for `host: web` and for `host: local` with `CLAUDE_CODE_REMOTE=true`, does not say "nothing to remove" while a `codeo-live/<N>/*` branch remains; it names `git push origin --delete codeo-live/<issue>/<machine>`, and a test pins it.
- [ ] `skills/close/SKILL.md:3` and `docs/skills.md:185` carry the web-session exception, or say nothing the exception contradicts.
- [ ] A test of `scripts/cleanup.sh` with the `name` proof failing and a `codeo-live/<N>/<machine>` branch present on origin expects the `leftover` line.

### Out of Scope

- #157 F10: the saved web label locking in a `hostname` or `unknown` fallback (unlikely, since a hosted session sets `CLAUDE_CODE_REMOTE_SESSION_ID`).
- #157 F11: `sweep` and `cleanup.sh` skipping branch names with more path segments, such as `codeo-live/<N>/a/b` (the documented manual command covers them).
- Making a hosted web session able to delete its own branch.

### Reference

- `.codeo/done/157/qc.md` round 3 (F8, F10-F13).
- `skills/close/SKILL.md`, `docs/skills.md`, `docs/handoff.md:173`, `scripts/live.sh`, `scripts/cleanup.sh`, `CHANGELOG.md`.
- Surfaced in `/codeo:triage` run 2026-11-24 (`qc:157:F8-F10-F11-F12-F13`).
