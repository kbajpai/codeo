# Changelog

## Unreleased

Config schema: 1
Shared state: unchanged
Safe to bump mid-workflow: yes

- The repository names no project that uses it: design documents about a specific project live in that
  project's repository. `tests/agnostic.test.sh` fails if a tracked file mentions one.
- `docs/skills-inventory.md`: the generic rules each pipeline skill must keep.
- Skills: `/codeo:issue`, `/codeo:init`, `/codeo:plan`, `/codeo:implement` and `/codeo:triage`.
- `/codeo:implement` registers two extension points, `environment-lease-notes` and `wiki-rules`.
- Suite field `parallel`, read by `/codeo:implement`.
- The `environment.hooks.deploy` contract: its last stdout line is the deployed revision, a non-zero exit
  fails the task, and a dirty working tree after the hook is a stop.
- The overlay mechanism: a project's `.codeo/overlays/<skill>.md` sections are read at the skills' extension
  points through `scripts/overlay.sh`, against the registry `lib/extension-points.tsv`.
  `docs/extension-points.md` documents the format and each point.
- `/codeo:doctor` gains the `overlays` check (section names must be registered points, no duplicates) and the
  `superpowers` check (the plugin `plan` calls into).
- Config keys `docsDir` and `plansDir`, read by the skills (defaults `docs` and `docs/plans`).
- `docs/dossier.md` and `docs/handoff.md`: the dossier and hand-off protocols the skills follow.
- `lock.sh take local`: a lock host for a checkout that is not a container or a web session.
- `tests/skills.test.sh`: a lint over every skill (frontmatter, the precedence sentence, script calls,
  extension points, rule markers), with a self-test, and a pin on the rule IDs and text of
  `docs/skills-inventory.md`.
- `scripts/scope.sh`: with suites configured, an unresolvable revision exits 1 with a `scope:` message
  instead of reading as "nothing changed".

### Known limits

- The pinned rule inventory must be regenerated deliberately: editing `docs/skills-inventory.md` without
  updating the pin fails `tests/inventory.test.sh`.
- `qc` and `close` are not in this release.
- A suite's `filter` is a command template for one test, `{}` standing for the test's name; a suite without
  one has no single-test form and its whole `test` command is the proof.

## v0.1.0 — 2026-10-18

Config schema: 1
Shared state: none fixed yet (dossier layout, lock files and the intake ledger are defined by later plans)
Safe to bump mid-workflow: n/a — not for projects to adopt; this tag exists for testing

- `lib/env.sh` and the project config (`.codeo/config.json`, schema 1).
- The ported engine scripts: branch naming, locks, claims, sync with the base branch, in-flight overlap, QC verdicts, GitHub and board access, usage.
- `scope.sh`, which decides which suites and deploys a change needs.
- Intake, with environment hooks (start, preflight, activate, revoke) around resource leases.
- `/codeo:setup` and `/codeo:doctor`.
- The subagent model hook.

### Known limits

- Skills for issue, init, plan, implement, qc, close and triage are not in this release.
- Hook order is start -> preflight -> activate. start, preflight and activate run before the lease is held, so they must not be exclusive, and revoke must be idempotent.
- `--override` is exported to hooks as `CODEO_OVERRIDE` and bypasses no hook failure.
- Board access uses `gh project` (GraphQL).
- bash >= 4.3 is required (`scope.sh` uses namerefs); `/codeo:doctor` checks it.
