# Changelog

## Unreleased

Config schema: 1
Shared state: unchanged from v1.0.1.
Safe to bump mid-workflow: yes

- `scripts/scope.sh --delivered-since <base> <revision> <head>` judges the branch's own delivery since a revision: only the paths changed between `<revision>` and `<head>` that are also in `git diff <base>...<head>`. Base-branch code merged in after the last deploy no longer flips `deploy=` to true, but a path the branch changed before the deploy and the base branch changed after it stays in scope. `/codeo:qc` and `/codeo:implement` use it for their redeploy checks (#17). Without the flag, behaviour is unchanged.

**Upgrading.** No config change. A project's own scripts that call `scope.sh <revision> HEAD` for a redeploy check can switch to the new form.

## v1.0.1 — 2026-10-25

Config schema: 1
Shared state: unchanged from v1.0.0.
Safe to bump mid-workflow: yes

- **Behaviour change.** `scripts/board.sh set` writes Status only on the synced projects — `board.projects` plus `board.gateProject` — and leaves a card the issue has on any other project exactly as it is, with no write, no field lookup and no line on either stream. It used to write every project the issue was a card on, so a project retired from `board.projects` kept being stamped for every issue still on it (#18). The gate project is synced even when `board.projects` does not list it, so `set` adds the issue there. `status` is unchanged: it reads the gate project, and its drift line still compares the listed projects.
- `docs/handoff.md → The board` and `/codeo:init` describe the synced set.

**Upgrading.** No config change. A project that listed fewer projects than its issues sit on will see `set` stop writing the unlisted ones; list a project to keep it written. A project's own tests that stub `gh` must answer `project field-list` for the gate project if it is not listed.

## v0.2.1 — 2026-10-22

Config schema: 1
Shared state: unchanged from v0.2.0 — the `### Round <n> — stashed|abandoned` headings `claim.sh --stash-live` reads, the `qc round at review: <k>` line `/codeo:close` reads back, and the forms `scripts/dossier-check.sh` reads.
Safe to bump mid-workflow: yes

- `scripts/dossier-check.sh`: new check `gate-sections` (FAIL) — `plan.md` must have `## Questions` and `## Outcome`, and any file with an `**Answer:**` line must have `## Questions`. A truncated plan used to pass with only a `sections` drift, so the open-question gate and the footprint check never ran (#11). `sections` stays drift and no longer reports a section `gate-sections` requires.
- `/codeo:init` drafts `init.md` in the shape `docs/dossier.md` gives every step, `## Questions` included (`None.` when empty) (#12).
- `scripts/github.sh pr create --draft` opens the pull request as a draft; `/codeo:close` passes it when the engineer asks for one (#13).
- `/codeo:close` creates `.codeo/done/` before archiving, so a project's first close no longer fails at `git mv` (#14).
- `scripts/overlap.sh --outside` leaves out the configured `plansDir` instead of a hard-coded `docs/plans` (#7).

**Upgrading.** No config change. `gate-sections` can report a FAIL on a dossier written before this version whose `plan.md` lacks `## Questions` or `## Outcome`, where v0.2.0 reported only `drift [sections]`. A project's golden replay records findings in `expected.tsv`; re-record any such dossier there. A dossier mid-workflow written by the v0.2.0 skills already carries both sections.

## v0.2.0 — 2026-10-19

Config schema: 1
Shared state: dossier conventions in `close.md` — the `### Round <n> — stashed|abandoned` headings `claim.sh --stash-live` reads, the `qc round at review: <k>` line `/codeo:close` reads back, and the forms `scripts/dossier-check.sh` reads (the `**Verdict: …**` span, `(send-back from <file> round <k>)`, `(after plan.md round <k>)`, the `### Footprint` block, the criteria table).
Safe to bump mid-workflow: yes

- `scripts/dossier-check.sh`: checks the structure of one dossier directory against the forms the protocol documents state (except the date line, which is not checked), printing `<FAIL|drift> <file> [<check-id>] <text>` per finding and exiting 1 on any `FAIL`.
- Dossiers written before this version have no `#<number> <html_url>` line and no send-back parenthesis. A project's golden replay of those older dossiers therefore records the findings this produces in its `expected.tsv`.
- `tests/run.sh` unsets `CODEO_GOLDEN_DIR`, so the suite stays hermetic.
- `tests/replay.test.sh`: the golden replay, which runs the checker over a project's finished dossiers (`CODEO_GOLDEN_DIR`) and compares its findings with an `expected.tsv`; skipped when unset, with a synthetic directory proving the harness.
- `docs/dossier.md` gains the section `What a finished dossier looks like`.
- Skill edits so the skills write the forms the checker reads: `/codeo:qc` words findings blocking or non-blocking and writes the criteria table; `/codeo:implement` and `/codeo:plan` write the send-back parenthesis and the `(after plan.md round <k>)` form; `/codeo:plan` replaces the old footprint with a send-back round's new one; `/codeo:close` writes the `— pull request updated` round and the `#<n> <url>` line.
- The repository names no project that uses it: design documents about a specific project live in that
  project's repository. `tests/agnostic.test.sh` fails if a tracked file mentions one.
- `docs/skills-inventory.md`: the generic rules each pipeline skill must keep.
- Skills: `/codeo:issue`, `/codeo:init`, `/codeo:plan`, `/codeo:implement`, `/codeo:qc`, `/codeo:close` and `/codeo:triage`: the whole pipeline ships.
- `/codeo:qc` checks the build, the suites, the acceptance criteria, the documentation and an independent review, reads what the environment runs, and routes forward or back. It registers three extension points, `environment-evidence`, `wiki-rules` and `invariants-extra`.
- The reviewer rule: the code reviewer runs on `models.reviewer` (default `opus`) with a `description` starting `QC review:`; there is no external second reviewer.
- The environment-evidence contract: `/codeo:qc` reads the most recent `Deployed revision:` in `implement.md` and the rows of the `environment.hooks.deployed` hook, and never deploys.
- `/codeo:close` opens the pull request, waits for the merge, routes review feedback or a conflict back through `/codeo:implement` and `/codeo:qc` onto the same pull request, releases the environment at approval when still held, verifies the merge, deletes the remote branch on the engineer's yes, releases every lease and the lock, and is the way to stash or abandon a workflow. It registers three extension points, `put-back`, `ci-publish-check` and `host-workflow`.
- The `qc round at review: <k>` convention: every send-back round `close` writes records the latest `qc` round number, and the next clear round must be numbered higher; round numbers are compared, never dates.
- A stash or an abandon takes the environment lease for the put-back when the issue no longer holds it, behind any waiter and never with `--override`, and releases it with the rest.
- With no board configured `close` moves no card and logs `board: not configured`; with no environment it releases and puts back nothing.
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
