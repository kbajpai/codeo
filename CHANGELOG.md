# Changelog

## Unreleased

Config schema: 1
Shared state: unchanged
Safe to bump mid-workflow: yes

- The repository names no project that uses it: design documents about a specific project live in that
  project's repository. `tests/agnostic.test.sh` fails if a tracked file mentions one.
- `docs/skills-inventory.md`: the generic rules each pipeline skill must keep.

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
