# Issue #new-closing-blocks-and-loose-ends — issue

| | |
|---|---|
| Issue | not filed yet |
| Called from | `/codeo:triage`, run 2026-11-14 (second run), Q1-Q7, consolidated into one issue at the engineer's request |
| Updated | 2026-11-14 |

## Where this stands

Request restated, duplicates searched (none), claims checked against the skill text. Two questions are open before the draft is written; the draft follows once they are answered.

**Problem as I understand it.** Four skills print a closing block (`docs/handoff.md → Closing block`) that names the next command. On several exits that command cannot run: `/codeo:close` after a failed cleanup tells the engineer to remove the checkout that still holds the lock, a stash that failed halfway points at `/codeo:init`, which stops on the lock the stash kept, `/codeo:init` after `lock: TODO` points at `/codeo:plan`, which refuses without a lock, and `/codeo:issue` points a new issue at `/codeo:init` where the board's Ready gate refuses it. Around that, a plan's host-run commands were written for bash and failed on the engineer's PowerShell, and three wording notes and two stale archive lines are left over from #67 and #61. All of it is small, text-level work in the skills, their tests and two docs; none of it changes what the pipeline decides.

## Questions

### Q1 — One pull request for all of it, or may `/codeo:plan` split it?

**Why it matters:** the issue's acceptance criteria and out-of-scope list differ. As one body for one pull request, every item is a required outcome of the same change. If the plan may split it, the issue stays one tracking item and the criteria can be met across more than one pull request, which suits a mix of skill-text fixes (A, B), release-note wording (C) and archive records (D) that do not share files or risk.
**Options:** one pull request for everything · `/codeo:plan` decides the split (recommended, since the four closing-block fixes share `skills/*/SKILL.md` and a test, and C and D share nothing with them).

**Answer:**

### Q2 — Part D: correct the two stale lines in archived `.codeo/done/61/plan.md`, or list it as known and left?

**Why it matters:** `.codeo/done/61/plan.md` is an archived record. `docs/dossier.md` says "Nothing is ever deleted — a closed issue's dossier is the best record of why it closed the way it did", and triage dismissed the equivalent `qc:58:F8-F10` on 2026-11-13 as archived-record-only. Correcting the two lines (`## Where this stands`, and `## Outcome`'s "unstaged") would be an edit to a closed record on `main`, by hand, in a pull request of its own; leaving them costs nothing that runs. The local-only tag `v1.0.4` (different tag object from the remote's, same commit `cf4618e`) is one clone's, not the repository's, and is out either way.
**Options:** acceptance criterion: correct the two lines · listed under Out of Scope as known and left (recommended) · leave D out of the issue entirely.

**Answer:**

## Notes

- Duplicate search (`github.sh issue search`): "closing block", "PowerShell", "closing block lock" found nothing; "Ready gate" found only #18 (closed, `board.sh set` writing Status). The closest open issue is #57 (dev container follow-ups), which carries wording fixes in the same devcontainer files as part C; #57 is a Reference, not a duplicate.
- Checked against the skill text: `/codeo:close` step 17 ends "End with the closing block: the goal is the loose ends found, the first step `/codeo:triage`, then the host's checkout clean-up above" after step 16's "keep it" branch, and the stash path ends with a block whose first step is `/codeo:init #<N>` while `.codeo/active` is kept on a failed release or push. `/codeo:issue` step 8 ends with "the next goal is starting the issue, the first step `/codeo:init #<N>`". `/codeo:init`'s Ready gate is the one #67 hit today. I did not re-read `skills/init/SKILL.md`'s closing block; the review thread's claim about `lock: TODO` goes into the issue as the reviewer's, with its link.
- Evidence for the issue's `Reference` section, as triage collected it:
  - PR #64 review threads, all unresolved at merge: https://github.com/kbajpai/codeo/pull/64#discussion_r4573610395 (close, lock kept), …#discussion_r4573610407 (stash), …#discussion_r4573610423 (init, `lock: TODO`), …#discussion_r4573610449 (issue, Ready gate).
  - `.codeo/done/67/implement.md`, Deviations: Task 3's `docker run … -v "$PWD":/src:ro … safe.directory "*"` failed on the engineer's PowerShell with `docker: invalid reference format`.
  - `.codeo/done/67/qc.md` round 3, F5-F7 (`CHANGELOG.md:9` twice, `.devcontainer/README.md:38`).
  - `.codeo/done/61/qc.md` lines 49-51, F1-F3.
- Proposed (for the draft, step 5): no Issue Type (a user-owned repository has none; `issue-types` printed nothing); label `enhancement`.
- Open unknown, goes into the draft as an open question, not asked here: whether `/codeo:issue` can read the board Status without a board configured (it would need `board.sh status`); that is `/codeo:plan`'s to settle.

## Outcome

_Pending — written at the hand-off._

## Log

- 2026-11-14 — request restated, duplicates searched, Q1-Q2 raised · cost: 1m · sonnet-5-5 11k in + 1.2M cached / 3k out
