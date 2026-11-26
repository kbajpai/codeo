# Issue #194 — issue

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/194 |
| Branch | none |
| Updated | 2026-11-26 |

## Where this stands

Filed as #194.

## Problem as restated

Multi-user safety gap found by a read-only audit of the whole repository (scripts, skills, containers, repo policy); details in the draft below. Parent tracker: #194.

## Questions

None open. The engineer chose to file all twelve groups, then asked to merge them into fewer issues.

## Draft

**Title:** Make codeo safe for several engineers working at once (tracking)

**Type:** none (user-owned repository). **Labels:** enhancement, priority label as filed.

#### Description
Tracking issue for making codeo safe when several engineers use one repository at the same time. A read-only audit of the whole repository (scripts, skills, containers and sandbox, repo and GitHub policy) found 56 places where a second user can override, release, delete or act as another user's work. They reduce to four root causes: nothing records or checks **who owns** a lease, signal, container or commit; the claim is **keyed on the wrong thing** (a branch name derived from an editable title); checks **fail open**; and the repository has **no server-side backstop** behind the client-side guards.

#### Motivation / Context
codeo works for one user. As soon as a second engineer starts issues from their own machine against the same repository, today's guards (a create-only claim push, a lease queue, a live signal) rely on every client behaving, and several read-then-write steps are racy. Keeping state in git and GitHub stays the design; this work adds ownership checks, atomic claims and server-side rules around it rather than introducing a separate service.

#### Key Requirements
Close the gaps through the child issues below, in this order (1 and 2 first: most other guards need a trustworthy identity to compare against):

- [ ] #195 Identify the acting user strictly and verify ownership at every workflow step (do first)
- [ ] #196 Own and expire shared-environment leases and live signals, with an audited takeover
- [ ] #197 Claim per issue, and make shared-state checks and board moves fail closed and conditional
- [ ] #198 Stop run files, intake drafts, the triage ledger and the archive colliding between engineers
- [ ] #199 Give containers, sandboxes and volumes an owner, and close the low-severity container gaps
- [ ] #200 Detect and report codeo version skew between engineers and the repository state
- [ ] #201 Add the server-side backstop: issue-branch rules, CODEOWNERS, plugin pin and a full doctor ruleset check

#### Acceptance Criteria
- [ ] Every child issue is closed.
- [ ] A second engineer cannot release, take over, close, stash, abandon, delete or overwrite another engineer's in-flight workflow, lease, signal, branch or container without an explicit, recorded override.
- [ ] A failed or unreadable check refuses the action instead of reading as "all clear".
- [ ] The repository settings the guards rely on are documented, checked by `codeo doctor`, and listed in the release checklist.

#### Out of Scope
A hosted REST service or separate datastore for issue status. Git and GitHub remain the source of truth.

#### Reference
Audit reports (read-only, from the session that filed this): claim/lock scripts (A1-A14), skills and dossier flow (B1-B14), containers and sandbox (C1-C14), repository and GitHub policy (D1-D14). Each child names the findings it covers.
