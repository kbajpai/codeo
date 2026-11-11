# New issue — throwaway target for #58's host checks

| | |
|---|---|
| Issue | _not filed yet_ |
| Branch | _none — this skill cuts none_ |
| Updated | 2026-11-11 |

## Where this stands

Draft written, waiting on the engineer's approval at the review gate. No open questions.

## Questions

_None blocking. The request names its purpose exactly: runbook step 1 of
https://github.com/kbajpai/codeo/issues/58#issuecomment-6808714302 needs an unstarted issue in
Ready with a board card._

## Notes

- No duplicate: searches for "throwaway" and "host check" return only #58, #40, #57, #55.
- This skill does not touch the board. Putting the card in Ready is a separate step
  (`/codeo:triage` or by hand) before `/codeo:init` can claim it.
- Repo is user-owned: no Issue Types.

## Draft

**Title:** Throwaway: target issue for #58's host checks (do not implement)

**Labels:** none

**Body:**

### Description

A disposable issue that exists only to be started by `/codeo:init` during the host checks in #58. It asks for no change to the code.

### Motivation / Context

The #58 runbook (step 1) needs a real issue that is unstarted, in Ready, and has a board card, so that `/codeo:init #<N>` can claim it, push a branch, and the issue container `codeo-<N>` can be cloned from it. Using a real backlog issue would leave it assigned, In progress, and with a stray branch.

### Acceptance Criteria

- [ ] `/codeo:init` was run on this issue from the home container during #58's checks.
- [ ] After the checks, the branch it pushed is deleted and this issue is closed as not planned.

### Out of Scope

- Any code, docs, or plan change. Nothing gets merged from this issue.

### Reference

- #58 and its runbook: https://github.com/kbajpai/codeo/issues/58#issuecomment-6808714302

## Outcome

_Pending — written when filed._
