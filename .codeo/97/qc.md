# Issue #97 — qc

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/97 |
| Branch | `docs/docs-skill-wording-test-guard` |
| Updated | 2026-11-15 |

## Where this stands

Round 1, done: back to `/codeo:plan`. The code does what the plan says and the suite passes, but the plan chose the wrong text to guard (#74's third criterion is not met) and left `skills/qc/SKILL.md` saying a footprint gap is non-blocking while the new `qc-verdict` check now fails the pull request on it. Three blocking findings, all the plan's.

## Questions

None.

## Notes

Environment: none configured, so no lease check and no environment block. Overlaps: `overlap.sh 97` printed nothing (every pair is already named in a `### Q` block of `implement.md` or `plan.md`).

## Outcome

### Round 1 — 2026-11-15

**Commands and output (this pass).**

- `bash scripts/sync-main.sh --abort-on-conflict` → `sync-main: the branch already contains origin/main`, exit 0. Nothing merged this round.
- `bash scripts/overlap.sh 97` → no output, exit 0. `bash scripts/overlap.sh --outside 97` → no output, exit 0: no changed path sits outside the footprint.
- `git diff origin/main...HEAD --stat` → 22 files changed, 1034 insertions, 86 deletions (code, tests, docs, the plan and `.codeo/97/`).
- `bash scripts/scope.sh origin/main HEAD` → `suite.shell=true` (it names `.codeo/97/implement.md`, `init.md`, `plan.md` and `CHANGELOG.md` as unclassified paths); no `deploy=` line, as no environment is configured.
- Build: the `shell` suite's build command is `true` → exit 0.
- Suite: `bash tests/run.sh` → `all cases passed`, exit 0 (40 test files). Run singly, `skills-doc`, `board`, `overlap`, `qc-verdict`, `closing-exits`, `close-skill`, `plan-skill`, `dossier-check`, `closing-block` and `env` each print `all cases passed`.
- Mutation, #74 criterion 3: a copy of `skills/close/SKILL.md` with step 17's old sentence put back ("End with the closing block: the goal is the loose ends found, the first step `/codeo:triage`, then the host clean-up.") → `CLOSING_EXITS_ROOT=<copy> bash tests/closing-exits.test.sh` prints `all cases passed`, exit 0; `CLOSE_SKILL=<copy> bash tests/close-skill.test.sh` also passes. Step 17's old *lead* is guarded; this sentence is not.
- Mutation, stash prose: a copy with "Report that `/codeo:init #<N>`" and "resumes it, on any machine." put back on two lines, as the original text wrapped them → `closing-exits` prints `all cases passed`, exit 0. The guard's fixed string is on one line, and `bites` inserts it on one line.
- Overlays: `overlay.sh qc invariants-extra` and `wiki-rules` both exit 3 (none). No invariants file, no wiki module.

**Acceptance criteria.**

| Criterion | Verdict | Settled by |
|---|---|---|
| #41: `docs/skills.md` `doctor` Reads lists the extension-points file, installed-plugins file, PATH checks and the `ci.requiredChecks` fallback | met | `docs/skills.md:266`, each clause read against `scripts/doctor.sh:128-129,162,176-184,194,240` |
| #41: `docs/skills.md` `qc` mentions the sync merge commit | met | `docs/skills.md:160`, against `skills/qc/SKILL.md` step 2 and Non-goals |
| #41: a test shows fenced lines in an Extension points part are not counted | met | `tests/skills-doc.test.sh` case `fenced-part` (line 174); the reviewer reverted the fence rule and it failed |
| #41: the guard's output order is identical across runs | met | `stable-order` (lines 185-194): two runs equal, missing and extra groups each sorted; the reviewer reverted the sorting and it failed |
| #41: a skill name containing regex metacharacters is matched literally | met | `metachar-name` (lines 176-183), skill `a.b` against bullet `axb/p1`; fails against the old `=~` match (reviewer) |
| #43: a test fails when a second-round `### Footprint` omits a path `overlap.sh --outside <N>` would print, without relying on a grep of the skill text | met | `tests/qc-verdict.test.sh` cases `replan footprint omits a changed path` (exit 1, names the plan and `a.txt`), union, one-round, no-plan and the failed-check case; `tests/overlap.test.sh` for `--base`/`--head` |
| #43: reading `skills/plan/SKILL.md` from sub-step 2 through 4, no step requires `## Outcome` to be both written and still pending | met | read as an agent would: step 10 sub-steps 1-4, `skills/plan/SKILL.md` 268-334; sub-step 1 removes the old block and runs `--outside`, sub-step 4 only moves the block |
| #43: with the issue on no board, `board.sh set` does not print "no project #N is on …" | met | `tests/board.test.sh` `no-board-message` (lines 274-276); `grep` finds the old text nowhere in `scripts/` |
| #43: a failed title read is not reported as a failed add; a failed removal's message includes the reason | met | `title-read-fails` (268-269), `undo-fails` (264) |
| #43: a `tests/board.test.sh` case runs with `board.statuses` absent from the config and passes | met | `statuses-absent` (282-283) |
| #43: the `undo-fails` case fails if `item-delete` is not called | met | `tests/board.test.sh:263` |
| #43: an issue on a project beyond the first 50 items is found; a failed write on it does not delete its card | met | `lookup` uses `gh api graphql --paginate` with `$endCursor`/`pageInfo`; `beyond-50` (366-374) asserts the flag and the 60th-row failed write. The stub cannot page, so only the flag bites (minor F8) |
| #43: each of the five wording items reads correctly against the code | met | `CHANGELOG.md:43` (a card it added; "when the planning step is followed"), `lib/env.sh` "conventional default", `skills/triage/SKILL.md:220`, `docs/handoff.md:302` "every earlier path the branch still changes", `docs/dossier.md:244` |
| #74: close's abandon exit ends with a closing block (finished: a command that can run with the lock gone; interrupted: `/codeo:close`; neither names `/codeo:init #<N>` or `/codeo:close --stash`) | met | `skills/close/SKILL.md` 663-675; `closing-exits` cases `abandon-finished` and `abandon-interrupted` |
| #74: `docs/handoff.md` lists the abandon among close's exits and has rows for both abandon exits and `issue — Status unreadable`; the `init — no lock` row no longer names `lock.sh take local` unconditionally | met | `docs/handoff.md` exits bullet and rows at lines 54-58; `case_rule` pins each |
| #74: `tests/closing-exits.test.sh` has a case for each new abandon block, and a check that fails when the old unconditional sentences are put back in close step 17 and in the stash prose (shown to bite against a copy with the sentence restored) | not met — the step 17 sentence the issue names is not guarded, and the stash guard misses the sentence as it was originally wrapped | the two mutations above, both exit 0 (F1, F2); the abandon cases themselves are present |
| #74: `skills/plan/SKILL.md`'s host-task paragraph is consistent, its neutral list names single-quoted arguments, globs, `~` and `./script`, and `tests/plan-skill.test.sh` pins the changes | met | `skills/plan/SKILL.md:168-186`; pins in `tests/plan-skill.test.sh`, shown to bite against `origin/main`'s copy by the implementer and the re-reviewer |
| #74: `CHANGELOG.md` has an `## Unreleased` entry that says both branches of the host-task rule | met | `CHANGELOG.md:16`: neutral commands, and a command that cannot be neutral is asked about and labelled `Shell: <name>` |
| #74: every left minor is fixed or dismissed with a reason in `plan.md`, and step 17's unconditional lead and the empty-`step` guard are fixed | met | `.codeo/97/plan.md` and the plan's Self-Review list each minor; step 17's lead is conditioned and `case_init_no_lock` fails on an empty `step` result (`closing-exits.test.sh:204`) |
| #74: `bash tests/run.sh` passes | met | `bash tests/run.sh` prints `all cases passed`, exit 0 (40 test files) |

**Documentation.** `docs/skills.md`, `docs/handoff.md`, `docs/dossier.md`, `lib/env.sh`, `skills/triage/SKILL.md` and `CHANGELOG.md` describe what the system does and carry no issue numbers except the changelog's own convention. No page the plan named was left untouched. One page now disagrees with another: `docs/handoff.md`'s `init — no lock` row says a `lock: TODO` can follow a lock that was taken (true: `scripts/lock.sh` prints the volume-name TODO after writing the lock), while `skills/init/SKILL.md:321,329` still says that after a `lock: TODO` "there is no lock" (F10).

**Independent review.** Reviewer on `opus` (`QC review:`), given the acceptance criteria alone. It found no Critical issue and three Important ones; its mutations reproduce F1 and F2, and F3 is its reading of `skills/qc/SKILL.md:156-159` against `scripts/qc-verdict.sh:123-143`, which I re-read. It also confirmed that `overlap.sh` without flags and in pair mode is unchanged, that `qc-verdict` skips one-round plans and archives with no plan, that the paginated query has the shape `gh --paginate` follows, and that the per-page blank row cannot corrupt `status` or `set`.

**Findings.**

- **F1 — blocking, `/codeo:plan`'s.** `tests/closing-exits.test.sh:180-186`: the guard #74's third criterion asks for does not catch step 17's old unconditional sentence put back. `case_close_step17_lead` checks only the old *lead* ("Report** that the workflow is finished"); the sentence the issue and #69's qc G2 name — "End with the closing block: … the first step `/codeo:triage`, then the host clean-up" — restored into step 17 leaves `closing-exits` and `close-skill` passing. Cause: the plan's Task 7 specified the lead as the text to guard and a mutation of that lead; the code does exactly that. The plan was wrong about which text the criterion names.
- **F2 — blocking, `/codeo:plan`'s.** `tests/closing-exits.test.sh:193`: the stash guard is a fixed string on one line, and the original sentence was wrapped over two lines ("Report that `/codeo:init #<N>`" / "resumes it, on any machine."). Put back as originally wrapped, the test passes, and `bites` only proves the guard on a one-line insertion, so "shown to bite against a copy with the sentence restored" is not shown for the real revert. Cause: the plan's Task 7 specified the one-line fixed string and a one-line mutation.
- **F3 — blocking, `/codeo:plan`'s.** `skills/qc/SKILL.md:156-159` says every path `overlap.sh --outside` prints is "not blocking by rule", while `scripts/qc-verdict.sh:123-143` now fails the required check on those paths for any plan with a `### Round 2` or later. After a send-back to plan, `qc` can clear the round, `/codeo:close` opens the pull request, and the required check fails on a footprint sitting in an answered, archived round, which the dossier rules say may not be edited; no skill says how to recover. Cause: the plan changed `qc-verdict` without naming `skills/qc/SKILL.md` or the `docs/handoff.md` required-check sentence's consequence for `qc`; a footprint gap is blocking by construction once a plan has a second round.
- **F4 — non-blocking, `/codeo:implement`'s.** `skills/plan/SKILL.md:174-176`: the rewrite dropped "where none is known, the task is labelled `Shell: <name>` and asked", so nothing says what to do when no language the host is known to have exists for the script.
- **F5 — non-blocking, `/codeo:implement`'s.** `skills/plan/SKILL.md:282-289`: sub-step 1 says "puts the draft under `## Notes`", then two sentences later "The draft footprint goes under `## Notes` again all the same", which reads as a second placement.
- **F6 — non-blocking, `/codeo:implement`'s.** `skills/close/SKILL.md` "abandon finished": says the card "is at `$BACKLOG`" without allowing for a project with no board.
- **F7 — non-blocking, `/codeo:implement`'s.** `scripts/overlap.sh:24-29`: the header describes `--base` only together with `--head`; given alone it also changes the diff base, undocumented. `changes()` also swallows git errors for a mistyped ref (carried from implement.md; `qc-verdict` passes refs it resolved itself).
- **F8 — non-blocking, `/codeo:implement`'s.** `tests/board.test.sh:366-374`: half (b) of `beyond-50` passes against the old code; only the `--paginate` grep bites, because the stub cannot page (the plan's accepted limit).
- **F9 — non-blocking, `/codeo:plan`'s.** `CHANGELOG.md:16` states the neutral branch and the cannot-be-neutral branch of the host-task rule but not the condition that triggers them (host not `local`, or `local` on Windows).
- **F10 — non-blocking, `/codeo:implement`'s.** `skills/init/SKILL.md:321,329` and `docs/handoff.md`'s `init — no lock` row disagree about whether a lock exists after a `lock: TODO`; the row is right (`scripts/lock.sh` prints the TODO after writing the lock), the init text is outside this plan's scope.
- Carried from `implement.md`, not re-raised: the unanchored `/^## Outcome/` in `qc-verdict.sh`, missing cases for a PR that adds only files under `docs/plans` and `.codeo` and for a `### Round 2` outside `## Outcome`, `title-read-fails` not asserting the exit code, `row_for` matching a label's suffix, the long single-line pins in step 10 and step 17, and the `RETURN` trap in `bites`.

**Routing.** F1 and F2 are one task to rewrite (guard the sentence the issue names, joined across line breaks, and mutate it as it was wrapped); F3 needs a decision the plan owes — whether `qc` treats an out-of-footprint path as blocking once a plan has a second round, and what the recovery is when it is found at close. All three are the plan's, so the change goes back to `/codeo:plan`; nothing here was fixed.

**Verdict: back to `/codeo:plan`.**

## Log

- 2026-11-15 — qc round 1: build and suite pass, one criterion not met, three blocking findings, back to plan · cost: 10m · opus-5-5 511k in + 6.9M cached / 34k out · sonnet-5-5 395k in + 29k cached / 3k out
