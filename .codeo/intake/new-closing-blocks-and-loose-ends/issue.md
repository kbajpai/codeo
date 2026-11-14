# Issue #new-closing-blocks-and-loose-ends — issue

| | |
|---|---|
| Issue | not filed yet |
| Called from | `/codeo:triage`, run 2026-11-14 (second run), Q1-Q7, consolidated into one issue at the engineer's request |
| Updated | 2026-11-14 |

## Where this stands

Q1 and Q2 answered. Draft written below and waiting for the engineer's approval before filing.

**Problem as I understand it.** Four skills print a closing block (`docs/handoff.md → Closing block`) that names the next command. On several exits that command cannot run: `/codeo:close` after a failed cleanup tells the engineer to remove the checkout that still holds the lock, a stash that failed halfway points at `/codeo:init`, which stops on the lock the stash kept, `/codeo:init` after `lock: TODO` points at `/codeo:plan`, which refuses without a lock, and `/codeo:issue` points a new issue at `/codeo:init` where the board's Ready gate refuses it. Around that, a plan's host-run commands were written for bash and failed on the engineer's PowerShell, and three wording notes and two stale archive lines are left over from #67 and #61. All of it is small, text-level work in the skills, their tests and two docs; none of it changes what the pipeline decides.

## Questions

### Q1 — One pull request for all of it, or may `/codeo:plan` split it?

**Why it matters:** the issue's acceptance criteria and out-of-scope list differ. As one body for one pull request, every item is a required outcome of the same change. If the plan may split it, the issue stays one tracking item and the criteria can be met across more than one pull request, which suits a mix of skill-text fixes (A, B), release-note wording (C) and archive records (D) that do not share files or risk.
**Options:** one pull request for everything · `/codeo:plan` decides the split (recommended, since the four closing-block fixes share `skills/*/SKILL.md` and a test, and C and D share nothing with them).

**Answer:**
`/codeo:plan` decides the split (answered in the conversation).

### Q2 — Part D: correct the two stale lines in archived `.codeo/done/61/plan.md`, or list it as known and left?

**Why it matters:** `.codeo/done/61/plan.md` is an archived record. `docs/dossier.md` says "Nothing is ever deleted — a closed issue's dossier is the best record of why it closed the way it did", and triage dismissed the equivalent `qc:58:F8-F10` on 2026-11-13 as archived-record-only. Correcting the two lines (`## Where this stands`, and `## Outcome`'s "unstaged") would be an edit to a closed record on `main`, by hand, in a pull request of its own; leaving them costs nothing that runs. The local-only tag `v1.0.4` (different tag object from the remote's, same commit `cf4618e`) is one clone's, not the repository's, and is out either way.
**Options:** acceptance criterion: correct the two lines · listed under Out of Scope as known and left (recommended) · leave D out of the issue entirely.

**Answer:**
Out of scope: listed as known and left (answered in the conversation).

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

## Draft

**Title:** Fix closing blocks that name a command that cannot run, and keep plan host commands shell-neutral

**Issue Type:** none. The repository is user-owned and has no Issue Types.
**Labels:** `enhancement`

```markdown
### Description

Four skills end with a closing block that names the engineer's next command, and on some exits the command it names cannot run. Separately, a plan's host-run commands were written for bash and failed on the engineer's PowerShell, and a few wording notes from #67 were merged as they stood. This issue fixes all of it together; it is small text-level work in the skills, their tests and two docs, and changes nothing the pipeline decides.

### Motivation / Context

The closing block exists so the engineer never has to work out where they stand or what to type next (`docs/handoff.md → Closing block`). Where the named command stops at its own first check, it sends them in a circle, and on a failed close it names the one action that destroys the way out.

- `/codeo:close` keeps the lock when a lease release, a branch deletion or a push fails, so that running `/codeo:close` again can finish the job. Its closing block is written the same on every exit and tells the engineer to triage and remove the checkout, which is the checkout they need to finish.
- An interrupted stash keeps `.codeo/active`. The stash's closing block sends the engineer to `/codeo:init #<N>`, whose first step stops at the lock check.
- When `/codeo:init` prints `lock: TODO — …` there is no `.codeo/active`, yet its closing block still names `/codeo:plan`, whose step 0 refuses without the lock.
- With a project board, `/codeo:issue` files an issue that is not on the board or not Ready, and its closing block names `/codeo:init #<N>`, which stops at the Ready gate. This happened with #67 on 2026-11-14 and needed a scoped `/codeo:triage` run to get past it.
- Task 3 of #67's plan was a `docker run … -v "$PWD":/src:ro …` command to run on the engineer's own host. In PowerShell `$PWD` expanded to `D:\Source\codeo` and Docker rejected it (`docker: invalid reference format`); the inner `"*"` quotes would also have been stripped. It cost a round trip unrelated to the change.
- `/codeo:qc` left three non-blocking wording notes on #67's pull request, merged as they stood.

### Key Requirements

- Each closing block that names a next command names one that can run in the state the skill leaves behind. For the four exits above, that means the command that finishes the interrupted step, and no mention of removing the checkout while the lock is kept.
- A stash whose board move failed says so, and names the manual Ready repair before `/codeo:init` is offered.
- `/codeo:issue`'s closing block names `/codeo:triage` before `/codeo:init` when the project has a board and the new issue's Status is not Ready. With no board, nothing changes.
- A command in a plan that the engineer must run on their own host runs from their shell unmodified, or the plan says which shell it is written for. How `/codeo:plan` learns the shell is `/codeo:plan`'s to decide.
- `CHANGELOG.md`'s `## Unreleased` entry for the dev container image says what is true: `gh` and Claude Code come from their own sources and are not "at 26.04's versions"; it does not present `stat`, `readlink` and `install` as the whole of the Rust coreutils (`chmod`, `chown`, `mv`, `mktemp` and `ls` are too, and the start scripts use `chmod --reference`). `.devcontainer/README.md` says a rebuild loses all of `~/.claude` (the login, past sessions, user settings), not only the login.
- The pull request or pull requests that carry this may be split as `/codeo:plan` sees fit; the closing-block fixes share files and a test, the dev container wording shares nothing with them.

### Acceptance Criteria

- [ ] After a failed lease release, branch deletion or push that keeps the lock, `/codeo:close`'s closing block names `/codeo:close` as its first step and does not name removing the checkout.
- [ ] After an interrupted stash that keeps `.codeo/active`, the closing block names `/codeo:close --stash` as its first step; `/codeo:init #<N>` is named only after a completed stash; a failed board move adds the manual Ready repair before it.
- [ ] After `/codeo:init` prints `lock: TODO`, its closing block names a recovery step and does not name `/codeo:plan`; `/codeo:plan` is named only once the lock was taken.
- [ ] With a board, after `/codeo:issue` files an issue whose Status is not Ready, the closing block names `/codeo:triage` before `/codeo:init #<N>`; with no board, or with a Ready issue, it names `/codeo:init #<N>` as it does today.
- [ ] A test in `tests/` fails if any of the four closing blocks goes back to naming the command that cannot run in its state (alongside `tests/closing-block.test.sh`, which already fails when a skill does not cite the block).
- [ ] A task in a plan that the engineer runs on their own host has a command that runs from their shell without editing, or names the shell it is written for, and `/codeo:plan` says how it decides.
- [ ] `CHANGELOG.md`'s dev container entry no longer says the tools are "at 26.04's versions" without exempting `gh` and Claude Code, and no longer lists three Rust coreutils as if complete; `.devcontainer/README.md` says all of `~/.claude` is lost on a rebuild.
- [ ] `CHANGELOG.md` has an `## Unreleased` entry for this change, and `bash tests/run.sh` passes.

### Out of Scope

- The move of the dev container image to `ubuntu:26.04` itself (#67, merged).
- The two stale lines in the archived `.codeo/done/61/plan.md` and the local-only `v1.0.4` tag in one clone: known and left. They are an archived record and one clone's state, and nothing runs from them.
- The open dev container follow-ups #40, #51, #54 and #57. The wording notes above touch the same files as #57's wording items, but are not part of it.

### Open questions

- Can `/codeo:issue` read the new issue's board Status itself (`board.sh status <N>`), and what does it say when the board is not configured or the read is unavailable? `/codeo:plan` settles this.
- Is the closing-block rule ("name only a command that can run in the state this exit leaves") written once in `docs/handoff.md` and checked there, or four separate edits to four skills? `/codeo:plan` settles this.

### Reference

- `docs/handoff.md → Closing block`; `skills/close/SKILL.md` (steps 14-17 and *Stash*), `skills/init/SKILL.md` (step 11), `skills/issue/SKILL.md` (step 8).
- Unresolved review threads on merged PR #64: https://github.com/kbajpai/codeo/pull/64#discussion_r4573610395 (close, lock kept), https://github.com/kbajpai/codeo/pull/64#discussion_r4573610407 (stash), https://github.com/kbajpai/codeo/pull/64#discussion_r4573610423 (init, `lock: TODO`), https://github.com/kbajpai/codeo/pull/64#discussion_r4573610449 (issue, Ready gate).
- #67 (its `qc.md` round 3, F5-F7, and `implement.md` Deviations for Task 3), merged as PR #68.
- Surfaced by `/codeo:triage`, run 2026-11-14, Q1-Q7.
- #57, the nearest open issue (dev container follow-ups).
```

## Outcome

_Pending — written at the hand-off._

## Log

- 2026-11-14 — request restated, duplicates searched, Q1-Q2 raised · cost: 1m · sonnet-5-5 11k in + 1.2M cached / 3k out
