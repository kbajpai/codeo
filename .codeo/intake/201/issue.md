# Issue #201 — issue

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/201 |
| Branch | none |
| Updated | 2026-11-26 |

## Where this stands

Filed as #201.

## Problem as restated

Multi-user safety gap found by a read-only audit of the whole repository (scripts, skills, containers, repo policy); details in the draft below. Parent tracker: #194.

## Questions

None open. The engineer chose to file all twelve groups, then asked to merge them into fewer issues.

## Draft

**Title:** Add the server-side backstop: issue-branch rules, CODEOWNERS, plugin pin and a full doctor ruleset check

**Type:** none (user-owned repository). **Labels:** enhancement, priority label as filed.

#### Description
Add the server-side rules that back the client-side guards, and make `codeo doctor` and the release checklist assert them.

#### Motivation / Context
Live check of `kbajpai/codeo`: nothing server-side protects `issue/*`, `feat/*` or `fix/*` branches, so any writer can force-push or delete a teammate's in-flight branch and dossier (D1). The required `tests` and `qc-verdict` checks run `tests/run.sh`, `scripts/qc-verdict.sh` and `ci.yml` from the PR's own head, so a PR can weaken them; `qc-verdict` only reads a `qc.md` the PR writes (D2, B10). Required approvals are 0 and there is no CODEOWNERS, so an author can self-merge (D3). `.codeo/config.json` is an unreviewed trust anchor: `plugin.repo`/`plugin.ref` have no allow-list or SHA pin and `.devcontainer/scripts/plugins.sh:35-57` installs them on every container start; suite commands and overlays run for every user; a container auto-trusts the checked-out branch (D4, D11, C8). `doctor` (`scripts/doctor.sh:140-167`) compares only required-check names (D5). Admin bypass on the default branch is "always" (D6). The `main-checks` ruleset is not in `docs/release-checklist.md` (D14). Merge methods are unrestricted and branches are not auto-deleted (D13).

#### Key Requirements
- A ruleset on the issue-branch prefixes blocking deletion and non-fast-forward.
- CODEOWNERS covering `.codeo/config.json`, `.codeo/overlays/**`, `.github/**`, `scripts/qc-verdict.sh`, `tests/**` and `.devcontainer/**`, with a required review (see Out of Scope for the single-owner case).
- The checks that gate merge run the base branch's copy of the gating scripts, not the PR's.
- `plugins.sh` installs only from an allow-listed repo and a pinned SHA.
- `doctor` asserts the whole rule set: PR rule, non-fast-forward, deletion, review count, integration id, bypass actors and the issue-branch rules.
- `docs/release-checklist.md` lists every ruleset needed to rebuild.

- Assignee and override policy is recorded in a structured field, not free text (D12).

#### Acceptance Criteria
- [ ] Force-push to and deletion of an issue branch by a non-owner is rejected by GitHub.
- [ ] A PR that edits a gating script or `.codeo/config.json` needs the CODEOWNERS review.
- [ ] `plugins.sh` refuses a repo or ref not on the allow-list.
- [ ] `doctor` fails on each missing rule and passes on the full set.
- [ ] The release checklist lists all rulesets.

#### Out of Scope
While the repository has a single collaborator a required second reviewer would block the owner's own merges: the plan decides whether that rule waits for a second collaborator or is enforced by a documented bypass.

#### Reference
Parent #194. Audit findings D1-D6, D11-D14, C8, B10.
