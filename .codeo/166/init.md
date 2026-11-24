# Issue #166 — init

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/166 |
| Branch | `docs/close-157-leftovers-hosted-web` |
| Updated | 2026-11-24 |

## Where this stands

Initialized. Branch `docs/close-157-leftovers-hosted-web` off `main` at `a389a6577b15ff9529023666f63e42a7cd2967ed`. Next step: `/codeo:plan`, in the issue's container.

## Questions

None.

## Outcome

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/166 — Close the #157 leftovers: a hosted web close that says nothing remains, a sweep description without its web exception, and a cleanup that drops the leftover command |
| State | open · labels `documentation` |
| Branch | `docs/close-157-leftovers-hosted-web` off `main` at `a389a6577b15ff9529023666f63e42a7cd2967ed` |
| Board | Ready → In progress |

**Problem.** `/codeo:qc` passed #157 with non-blocking findings that have no issue. A hosted web session's `/codeo:close` says "nothing to remove" while its `codeo-live/<N>/<machine>` branch stays on origin (the sweep is a no-op there); two pages describe close's sweep without the web-session exception that the rest of the docs state; and `/codeo:cleanup` prints no leftover-branch delete command when only the container-name proof failed (`scripts/cleanup.sh:134`).

**Acceptance criteria** — verbatim from the issue, unchecked:
- [ ] Step 17 of `skills/close/SKILL.md`, for `host: web` and for `host: local` with `CLAUDE_CODE_REMOTE=true`, does not say "nothing to remove" while a `codeo-live/<N>/*` branch remains; it names `git push origin --delete codeo-live/<issue>/<machine>`, and a test pins it.
- [ ] `skills/close/SKILL.md:3` and `docs/skills.md:185` carry the web-session exception, or say nothing the exception contradicts.
- [ ] A test of `scripts/cleanup.sh` with the `name` proof failing and a `codeo-live/<N>/<machine>` branch present on origin expects the `leftover` line.

**Out of scope.** #157 F10 (saved web label locking in a `hostname`/`unknown` fallback); #157 F11 (`sweep` and `cleanup.sh` skipping branch names with more path segments); making a hosted web session able to delete its own branch.

**Open at intake.** Nothing: the issue's dossier recorded no open question.

## Log

- 2026-11-24 — drafted for the gate
