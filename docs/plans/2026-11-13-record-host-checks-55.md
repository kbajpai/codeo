# Record the host checks for #55 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Leave #58 with a complete, honest record of the host checks for #55's Docker acceptance criteria, in the issue, as the engineer attested them.

**Architecture:** A recording-only change. No code, test or documentation page changes. The record is two comments on #58 and this branch's dossier, which reaches `main` through the `/codeo:close` pull request.

**Tech Stack:** `gh` (issue comments), `git ls-remote`.

**Spec:** `.codeo/58/issue.md`; intake Q1 (record in the issue); plan Q1 and Q2 of this dossier (attestation, recorded as such; a plan file).

## Global Constraints

- Results are recorded in the issue (#58), not in a doc under `docs/` (intake Q1).
- Evidence level is attestation: the engineer's terminal output was not kept (plan Q1 = A). The record says so and never shows an output that was not seen.
- No criterion is reported as failed: the engineer reports none failed, so no follow-up issue is filed.
- No change under `scripts/`, `lib/`, `hooks/`, `skills/`, `tests/` or `.devcontainer/`. No documentation page moves.
- Fixing what the checks find is out of scope; so is automating them.
- No `Needs lease:` task: there is no shared environment.
- Every task is proved by a `gh` or `git` command, because the configured `shell` suite covers none of the paths touched.

## Review Focus

- The attestation comment must not read as if output was captured. Its "Evidence level" paragraph is the guard.
- Criterion 1's GitHub-visible facts (assignee, pushed branch, card) must come from a command run in this task, not from memory.

---

### Task 1: Confirm the attestation comment is on #58

**Files:**
- None changed. The comment already exists: https://github.com/kbajpai/codeo/issues/58#issuecomment-6839269538

- [ ] **Step 1: Read the comment back**

Run: `gh api repos/kbajpai/codeo/issues/comments/6839269538 --jq .body`
Expected: a table with one row per criterion 1, 2, 3, 4, 5, 7 and 8, each `held`, and a paragraph beginning `**Evidence level:** attestation only`.

- [ ] **Step 2: Count the rows**

Run: `gh api repos/kbajpai/codeo/issues/comments/6839269538 --jq .body | grep -c '| held |'`
Expected: `7`

### Task 2: Record what GitHub still shows for criterion 1

**Files:**
- None changed. Output is one new comment on #58.

**Interfaces:**
- Consumes: Task 1's comment, which this one extends.
- Produces: a comment on #58 headed `## Criterion 1: what GitHub shows` listing each fact with the command that showed it.

- [ ] **Step 1: Collect the facts**

Run each and keep its output:
- `gh issue view 59 --json state,stateReason,assignees --jq '[.state,.stateReason,(.assignees[0].login)]'`
  Expected: `["CLOSED","NOT_PLANNED","kbajpai"]`
- `gh issue view 59 | grep '^projects'`
  Expected: a line ending `Codeo (Done)`
- `git ls-remote --heads origin chore/throwaway-target-issue-58-s`
  Expected: nothing (the branch was deleted after the checks; it carried only #59's init dossier, commit `b4e75e5`)

- [ ] **Step 2: Post the comment**

Post to #58 with `gh issue comment 58 --body-file <file>`. The comment quotes each command and its output from Step 1, and says that the branch's existence while the checks ran is evidence from 2026-11-12 (this plan's exploration), not from a command run at the time.

- [ ] **Step 3: Verify it posted**

Run: `gh issue view 58 --comments | grep -c 'Criterion 1: what GitHub shows'`
Expected: `1`
