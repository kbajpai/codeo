# Issue #195 — issue

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/195 |
| Branch | none |
| Updated | 2026-11-26 |

## Where this stands

Filed as #195.

## Problem as restated

Multi-user safety gap found by a read-only audit of the whole repository (scripts, skills, containers, repo policy); details in the draft below. Parent tracker: #194.

## Questions

None open. The engineer chose to file all twelve groups, then asked to merge them into fewer issues.

## Draft

**Title:** Identify the acting user strictly and verify ownership at every workflow step

**Type:** none (user-owned repository). **Labels:** enhancement, priority label as filed.

#### Description
Resolve the acting user's identity strictly, record it, and verify ownership by script at every workflow step, so one engineer cannot act as another.

#### Motivation / Context
**Identity**
`scripts/github.sh:35-45` falls back to the unverified `CODEO_GITHUB_LOGIN` environment variable when `gh api user` is refused. With a shared bot token every engineer is the same login, and with no login `init` skips the assignee check and the assignee-add, so the claim rests on the branch alone. The live-signal `user` field is forgeable and the lock records no user (A6, A14). An unassigned live branch can be taken over (B9).

**Ownership**
Step 0 of plan, implement, qc and close only checks that `.codeo/active` exists and matches the branch. They never compare the person running them to the assignee or the last `resumed: by` line. `scripts/lock.sh:62` locks any pushed dossier branch for anyone. So engineer B can check out A's branch and run `close`, which opens the PR, archives the dossier, moves the card and releases leases as A; A's stale checkout after B resumed does the same (B1). The three lock checks are prose the model re-implements, with no script (B13). `github.sh:109` defaults `assignee-remove` to the current login, so a non-assignee's stash releases leases and sets the card to Ready while A stays assigned (B4).

#### Key Requirements
**Identity**
- A login that cannot be resolved, or resolves to a Bot account, refuses `init`, `lock take` and claim outside hosted web sessions, with one `codeo:` line saying why.
- `CODEO_GITHUB_LOGIN` is honoured only where no real login can exist (hosted web sessions) and is never used to satisfy an ownership check.
- `init.md` records the resolved login; the lock and live signal record it too.
- Requirement-level only: the plan decides the file format.

**Ownership**
- One script (`lock.sh verify`) compares the current login to the assignees and the resume line, called at step 0 of plan, implement, qc and close and from `take`.
- Taking another engineer's workflow needs an explicit override that is recorded in the dossier.
- Stash and abandon remove the actual assignee, and refuse when the caller is not the owner without the override.
- Depends on the strict-identity issue.

#### Acceptance Criteria
- [ ] With `gh api user` failing and the variable set, `init` outside a web session refuses.
- [ ] With a Bot login, `init` refuses.
- [ ] A normal `init` records the login in `init.md`, the lock and the live signal.
- [ ] Tests cover each case.
- [ ] B running close, plan, implement or qc on A's branch is refused with one line naming the owner.
- [ ] A stale checkout of A after B resumed is refused.
- [ ] The override works once and is recorded.
- [ ] Stash by a non-owner does not remove the owner's assignment or move the card.
- [ ] Tests cover each step.

#### Out of Scope
Comparing the recorded login at later steps (see the ownership-verify issue).

Lease ownership (separate issue).

#### Reference
Parent #194.
