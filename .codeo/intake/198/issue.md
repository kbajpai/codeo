# Issue #198 — issue

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/198 |
| Branch | none |
| Updated | 2026-11-26 |

## Where this stands

Filed as #198.

## Problem as restated

Multi-user safety gap found by a read-only audit of the whole repository (scripts, skills, containers, repo policy); details in the draft below. Parent tracker: #194.

## Questions

None open. The engineer chose to file all twelve groups, then asked to merge them into fewer issues.

## Draft

**Title:** Stop run files, intake drafts, the triage ledger and the archive colliding between engineers

**Type:** none (user-owned repository). **Labels:** enhancement, priority label as filed.

#### Description
Stop run files, intake drafts, the triage ledger and the archive from colliding between engineers.

#### Motivation / Context
Triage and cleanup run files are named `<date>.md`, with `-2` chosen from the local listing, so same-day runs overwrite each other and step 0 "resumes" any open run file including another engineer's (`intake.sh` build uses `git add -f`) (B6). The ledger merge is date-only (`scripts/intake.sh:259`), so a later `deferred` row overwrites `filed #N` or `dismissed` and the item is filed twice (B7). Two `new-<slug>` drafts with one slug overwrite each other and `--drop` deletes the other engineer's draft (B8, A12). `git mv` into an existing `done/<N>` nests it (B11).

#### Key Requirements
- Run files and intake drafts include the author login (or a unique id); step 0 resumes only the caller's own.
- Ledger merge never lets a weaker state replace `filed` or `dismissed`.
- `--drop` removes only the caller's draft; archiving into an existing `done/<N>` is refused.

#### Acceptance Criteria
- [ ] Two logins running triage the same day produce two run files.
- [ ] A `deferred` row cannot replace `filed #N`.
- [ ] Two drafts with one slug do not overwrite each other.
- [ ] Archiving into an existing `done/<N>` fails clearly.
- [ ] Tests cover each case.

#### Out of Scope
Changing the dossier format otherwise.

#### Reference
Parent #194. Audit findings B6, B7, B8, A12, B11.
