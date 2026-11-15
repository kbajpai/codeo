# Issue #97 — qc

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/97 |
| Branch | `docs/docs-skill-wording-test-guard` |
| Updated | 2026-11-15 |

## Where this stands

Round 3, done: clear, forward to `/codeo:close`. All twenty criteria are met and no finding is blocking; two small documentation overstatements (F16, F17) and four minor test and script notes are recorded for the engineer to fix in this pull request or send on to `/codeo:triage`.

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


### Round 2 — 2026-11-15

(send-back from implement.md round 2, answering this file's round 1)

**Commands and output (this pass).**

- `bash scripts/sync-main.sh --abort-on-conflict` → `the branch already contains origin/main`, exit 0. Nothing merged this round.
- `bash scripts/overlap.sh 97` → no output, exit 0. `bash scripts/overlap.sh --outside 97` → no output, exit 0.
- `git diff origin/main...HEAD --stat` → 26 files changed, 1366 insertions, 89 deletions.
- `bash scripts/scope.sh origin/main HEAD` → `suite.shell=true`; no `deploy=` line (no environment configured).
- Build: the `shell` suite's build command is `true` → exit 0.
- Suite: `bash tests/run.sh` → `all cases passed`, exit 0.
- Round 1's two failed guards, re-run: step 17's old ending put back, and the stash sentence put back with its original line break, each in a scratch copy → `CLOSING_EXITS_ROOT=<copy> bash tests/closing-exits.test.sh close-step17-lead` and `… stash-prose` both exit 1 (round 1: both exited 0).
- `QC_SKILL=<origin/main's skills/qc/SKILL.md> bash tests/qc-skill.test.sh` → three FAIL lines (the two new pins and the old-phrase check), `3 case(s) failed`: the pins bite.
- Reproduction of F11 below: a scratch repo whose base has a re-planned `done/7` archive, and a pull request that appends a line to `done/7/qc.md` and adds `c.txt` → `bash scripts/qc-verdict.sh <base> <head>` prints `qc-verdict: .codeo/done/7/plan.md: round 2 footprint omits: c.txt`, exit 1; the same change without touching `done/7` prints `qc-verdict: no archived dossier in this PR`, exit 0.
- Overlays: `overlay.sh qc invariants-extra` and `wiki-rules` both exit 3 (none). No invariants file, no wiki module, no environment.

**Acceptance criteria.**

| Criterion | Verdict | Settled by |
|---|---|---|
| #41: `docs/skills.md` `doctor` Reads lists the extension-points file, installed-plugins file, PATH checks and the `ci.requiredChecks` fallback | met | `docs/skills.md:266`; unchanged since round 1, where each clause was read against `scripts/doctor.sh` |
| #41: `docs/skills.md` `qc` mentions the sync merge commit | met | `docs/skills.md:160` |
| #41: a test shows fenced lines in an Extension points part are not counted | met | `tests/skills-doc.test.sh` `fenced-part`; the round-2 reviewer reverted the fence rule in a scratch copy and it failed |
| #41: the guard's output order is identical across runs | met | `stable-order`; reverting the sort in a scratch copy fails it (reviewer) |
| #41: a skill name containing regex metacharacters is matched literally | met | `metachar-name` against skill `a.b` |
| #43: a test fails when a second-round `### Footprint` omits a path `overlap.sh --outside <N>` would print, without relying on a grep of the skill text | met | `tests/qc-verdict.test.sh` (`replan footprint omits a changed path` and the failed-check case) and `tests/overlap.test.sh` for `--base`/`--head`; see F11 for what the check wrongly includes |
| #43: reading `skills/plan/SKILL.md` from sub-step 2 through 4, no step requires `## Outcome` to be both written and still pending | met | `skills/plan/SKILL.md` step 10, read as an agent would (by me and by the reviewer): sub-step 1 removes the old block and runs `--outside`, sub-step 4 only moves the block |
| #43: with the issue on no board, `board.sh set` does not print "no project #N is on …" | met | `tests/board.test.sh` `no-board-message` |
| #43: a failed title read is not reported as a failed add; a failed removal's message includes the reason | met | `title-read-fails`, `undo-fails` |
| #43: a `tests/board.test.sh` case runs with `board.statuses` absent from the config and passes | met | `statuses-absent` |
| #43: the `undo-fails` case fails if `item-delete` is not called | met | `tests/board.test.sh:263` |
| #43: an issue on a project beyond the first 50 items is found; a failed write on it does not delete its card | met | `lookup` uses `gh api graphql --paginate` with `$endCursor`/`pageInfo`; `beyond-50` asserts the flag and the 60th-row failed write; the stub cannot page (F16) |
| #43: each of the five wording items reads correctly against the code | met | `CHANGELOG.md:43`, `lib/env.sh`, `skills/triage/SKILL.md:220`, `docs/handoff.md:302`, `docs/dossier.md:244` |
| #74: close's abandon exit ends with a closing block (finished: a command that can run with the lock gone; interrupted: `/codeo:close`; neither names `/codeo:init #<N>` or `/codeo:close --stash`) | met | `skills/close/SKILL.md` 663-676; `closing-exits` cases `abandon-finished` (now also `with no board`) and `abandon-interrupted` |
| #74: `docs/handoff.md` lists the abandon among close's exits and has rows for both abandon exits and `issue — Status unreadable`; the `init — no lock` row no longer names `lock.sh take local` unconditionally | met | `docs/handoff.md` exits bullet and rows 54-58 |
| #74: `tests/closing-exits.test.sh` has a case for each new abandon block, and a check that fails when the old unconditional sentences are put back in close step 17 and in the stash prose (shown to bite against a copy with the sentence restored) | met | the two mutations above now exit 1; `case_bites` restores each old sentence with its original line break; the reviewer also ran the guards against the real pre-#69 `skills/close/SKILL.md` and four cases failed |
| #74: `skills/plan/SKILL.md`'s host-task paragraph is consistent, its neutral list names single-quoted arguments, globs, `~` and `./script`, and `tests/plan-skill.test.sh` pins the changes | met | `skills/plan/SKILL.md:168-186`; pins shown to bite against `origin/main`'s copy |
| #74: `CHANGELOG.md` has an `## Unreleased` entry that says both branches of the host-task rule | met | `CHANGELOG.md:15`: neutral commands, and a command that cannot be neutral is asked about and labelled `Shell: <name>` |
| #74: every left minor is fixed or dismissed with a reason in `plan.md`, and step 17's unconditional lead and the empty-`step` guard are fixed | met | `plan.md`'s round-1 Self-Review and round-2 Notes; step 17's lead is conditioned; `case_init_no_lock` fails on an empty `step` result |
| #74: `bash tests/run.sh` passes | met | `bash tests/run.sh` prints `all cases passed`, exit 0 |

**Documentation.** `docs/skills.md` (`doctor`, `qc`, `close`), `docs/handoff.md`, `docs/dossier.md`, `lib/env.sh`, `skills/triage/SKILL.md`, `skills/qc/SKILL.md`, `skills/plan/SKILL.md`, `skills/close/SKILL.md`, `scripts/overlap.sh`'s header and `CHANGELOG.md` all say what the code now does, in present tense and with no issue numbers outside the changelog's own convention. `skills/qc/SKILL.md` step 6 and `scripts/qc-verdict.sh` now agree on first-round plans (non-blocking) and plans with a `### Round 2` or later (blocking).

**Independent review.** Reviewer on `opus` (`QC review:`), given the acceptance criteria alone. No Critical issue and one Important one (F11, which I reproduced above); it confirmed the guards fail when their behaviour is reverted, including against the real pre-#69 close skill, and that this branch's own footprint covers its diff.

**Round 1's findings.** F1 (blocking in round 1) — fixed by `eb399da`. F2 (blocking in round 1) — fixed by `eb399da`. F3 (blocking in round 1) — fixed by `c22f3ec`. F4, F5, F6, F7 and F9 were taken in round 2 (`5d7625d`, `7851d88`, `5a1306b`). F8 and F10 stay out of scope.

**Findings.**

- **F11 — blocking, `/codeo:plan`'s.** `scripts/qc-verdict.sh:121-143`: the footprint rule runs for every archive the diff adds, modifies or renames anything in, and compares the whole pull request's changed paths with that archive's footprint. A pull request for another issue that also touches an older re-planned archive (a typo fix in `done/7/qc.md`, say) therefore fails the required check on its own, unrelated code (reproduced above: exit 1, `round 2 footprint omits: c.txt`; the same change without touching the archive passes). The reviewer replayed the script over `main`'s merges: the pull requests that archived #36 (round 2) and #47 (round 4) would now fail, which are real gaps in plans written before the union rule, but any later pull request touching `done/36` or `done/47` with ordinary code fails too. There is no recovery short of editing an archive. Cause: the plan's Task 6 scoped the check to "an archive the diff touches", and the code does exactly that; the plan should scope it to the archive the pull request itself delivers, i.e. a `done/<N>/plan.md` the diff adds or renames (`--diff-filter=AR`), which is what `/codeo:close`'s archive commit produces, with a test for the touched-but-not-delivered case.
- **F12 — non-blocking, `/codeo:plan`'s.** `skills/close/SKILL.md:661-662` and the abandon-finished block: "Once the lock is gone the checkout holds nothing the branch lacks" is untrue after the engineer has had the unmerged remote branch deleted, when the local branch is the only copy; the block still relays step 17's host clean-up, which step 17 justifies with "everything in it is merged or on origin". The text should be conditioned on the branch being kept.
- **F13 — non-blocking, `/codeo:plan`'s.** `skills/qc/SKILL.md:161-164` says a footprint "can only be corrected by a new plan round" and sends every round-2 gap to `/codeo:plan`, while step 8 makes a finding `/codeo:implement`'s when the code strayed from the plan; when the implementer simply edited a file outside the plan, reverting it clears the gap. The two rules disagree and step 6 wins.
- **F14 — non-blocking, `/codeo:implement`'s.** `scripts/overlap.sh` (`changes()`): git errors are swallowed, so a failed diff gives an empty path list and the new check passes. Carried from round 1 (F7's second sentence); `qc-verdict` passes refs it resolved itself and CI fetches full history.
- **F15 — non-blocking, `/codeo:implement`'s.** `CHANGELOG.md:15` reads as if marking host tasks and the Windows condition began in this release; the wording says when the rule applies but not that the rule itself is older.
- Carried and recorded, not re-raised: F8 (`beyond-50` cannot page: the stub answers one canned reply) and F10 (`skills/init/SKILL.md:321,329` against `docs/handoff.md`'s `init — no lock` row) stay for `/codeo:triage`, as does the unanchored `^## Outcome` match in `qc-verdict.sh`. `qc` step 6 not saying how to detect a second round (look for a `### Round <n>` heading, n ≥ 2, in `plan.md`'s `## Outcome`) is a further non-blocking note.

**Routing.** One blocking finding, and it is the plan's: the code does what the plan said, and the plan scoped the required check too widely. The fix is small (`--diff-filter=AR` on the archive loop, or a check that `plan.md` is among the files the diff adds or renames, plus a case for a pull request that only touches an old archive and one that delivers its own); F12 and F13 can go in the same round. Nothing here was fixed.

**Verdict: back to `/codeo:plan`.**


### Round 3 — 2026-11-15

(send-back from implement.md round 3, answering this file's round 2)

**Commands and output (this pass).**

- `bash scripts/sync-main.sh --abort-on-conflict` → `the branch already contains origin/main`, exit 0. Nothing merged this round.
- `bash scripts/overlap.sh 97` → no output, exit 0. `bash scripts/overlap.sh --outside 97` → no output, exit 0.
- `git diff origin/main...HEAD --stat` → 27 files changed, 1707 insertions, 89 deletions.
- `bash scripts/scope.sh origin/main HEAD` → `suite.shell=true`; no `deploy=` line (no environment configured).
- Build: the `shell` suite's build command is `true` → exit 0.
- Suite: `bash tests/run.sh` → `all cases passed`, exit 0.
- Round 2's F11, re-run in the same scratch repo (base holds a re-planned `done/7`; the pull request appends a line to `done/7/qc.md` and adds `c.txt`): `bash scripts/qc-verdict.sh <base> <head>` → `qc-verdict: .codeo/done/7/qc.md: round 1 clear`, exit 0 (round 2: `round 2 footprint omits: c.txt`, exit 1).
- Round 1's two guards, on copies of the current `skills/close/SKILL.md`: step 17's old ending put back → `CLOSING_EXITS_ROOT=<copy> bash tests/closing-exits.test.sh close-step17-lead` prints `FAIL: close-step17-lead — has [End with the closing block: the goal is the loose ends found] …`, exit 1; the stash sentence put back with its original line break → `… stash-prose` exit 1; a copy of the pristine current skill → `all cases passed`. (My first attempt reused scratch copies built before round 3 and passed; they held a skill from an earlier round, so I rebuilt them on the current file and the guards fail as they should.)
- `bash scripts/overlap.sh --outside 97 --base no-such-ref --head HEAD` → `overlap: cannot resolve no-such-ref`, exit 1.
- `QC_SKILL=<origin/main's skills/qc/SKILL.md> bash tests/qc-skill.test.sh` → `5 case(s) failed` (the round-2 and round-3 pins and both still-says checks): the pins bite.
- Overlays: `overlay.sh qc invariants-extra` and `wiki-rules` both exit 3 (none). No invariants file, no wiki module, no environment.

**Acceptance criteria.**

| Criterion | Verdict | Settled by |
|---|---|---|
| #41: `docs/skills.md` `doctor` Reads lists the extension-points file, installed-plugins file, PATH checks and the `ci.requiredChecks` fallback | met | `docs/skills.md:266`, read against `scripts/doctor.sh` in round 1 and unchanged since |
| #41: `docs/skills.md` `qc` mentions the sync merge commit | met | `docs/skills.md:160` |
| #41: a test shows fenced lines in an Extension points part are not counted | met | `tests/skills-doc.test.sh` `fenced-part`; the round-3 reviewer reverted the rule in a scratch copy and it failed |
| #41: the guard's output order is identical across runs | met | `stable-order`; reverting the sort fails it (reviewer) |
| #41: a skill name containing regex metacharacters is matched literally | met | `metachar-name` (`a.b` against `axb/`); passes only with the literal match (reviewer) |
| #43: a test fails when a second-round `### Footprint` omits a path `overlap.sh --outside <N>` would print, without relying on a grep of the skill text | met | `tests/qc-verdict.test.sh` (`replan footprint omits a changed path`, `an archive renamed into place is checked`, the failed-check case) and `tests/overlap.test.sh`; the delivered-archive scope is tested on both sides |
| #43: reading `skills/plan/SKILL.md` from sub-step 2 through 4, no step requires `## Outcome` to be both written and still pending | met | `skills/plan/SKILL.md` step 10 as read by me and by two reviewers: sub-step 1 removes the old block and runs `--outside`, sub-step 4 only moves the block |
| #43: with the issue on no board, `board.sh set` does not print "no project #N is on …" | met | `tests/board.test.sh` `no-board-message` |
| #43: a failed title read is not reported as a failed add; a failed removal's message includes the reason | met | `title-read-fails`, `undo-fails` |
| #43: a `tests/board.test.sh` case runs with `board.statuses` absent from the config and passes | met | `statuses-absent` |
| #43: the `undo-fails` case fails if `item-delete` is not called | met | `tests/board.test.sh:263` |
| #43: an issue on a project beyond the first 50 items is found; a failed write on it does not delete its card | met | `lookup` uses `gh api graphql --paginate` with `$endCursor`/`pageInfo`; `beyond-50` asserts the flag and the failed write on the 60th row. The stub cannot page (F20), and the query reads the issue's own `projectItems` (see F16) |
| #43: each of the five wording items reads correctly against the code | met | `CHANGELOG.md:43`, `lib/env.sh`, `skills/triage/SKILL.md:220`, `docs/handoff.md:302`, `docs/dossier.md:244` |
| #74: close's abandon exit ends with a closing block (finished: a command that can run with the lock gone; interrupted: `/codeo:close`; neither names `/codeo:init #<N>` or `/codeo:close --stash`) | met | `skills/close/SKILL.md` abandon section; `closing-exits` cases `abandon-finished` and `abandon-interrupted` |
| #74: `docs/handoff.md` lists the abandon among close's exits and has rows for both abandon exits and `issue — Status unreadable`; the `init — no lock` row no longer names `lock.sh take local` unconditionally | met | `docs/handoff.md` exits bullet and rows 54-58 (but see F17 for the finished-abandon row's omission) |
| #74: `tests/closing-exits.test.sh` has a case for each new abandon block, and a check that fails when the old unconditional sentences are put back in close step 17 and in the stash prose (shown to bite against a copy with the sentence restored) | met | the two mutations above both exit 1; `case_bites` restores each old sentence with its original line break; the reviewer also ran them against the real pre-#69 skill |
| #74: `skills/plan/SKILL.md`'s host-task paragraph is consistent, its neutral list names single-quoted arguments, globs, `~` and `./script`, and `tests/plan-skill.test.sh` pins the changes | met | `skills/plan/SKILL.md:168-187`; pins shown to bite against `origin/main`'s copy |
| #74: `CHANGELOG.md` has an `## Unreleased` entry that says both branches of the host-task rule | met | `CHANGELOG.md:16`: neutral commands, and a command that cannot be neutral is asked about and labelled `Shell: <name>` |
| #74: every left minor is fixed or dismissed with a reason in `plan.md`, and step 17's unconditional lead and the empty-`step` guard are fixed | met | `plan.md`'s round-1 Self-Review and round-2 and round-3 Notes; step 17's lead is conditioned; `case_init_no_lock` fails on an empty `step` result |
| #74: `bash tests/run.sh` passes | met | `bash tests/run.sh` prints `all cases passed`, exit 0 |

**Documentation.** `docs/skills.md`, `docs/handoff.md`, `docs/dossier.md`, `lib/env.sh`, `skills/triage/SKILL.md`, `skills/qc/SKILL.md`, `skills/plan/SKILL.md`, `skills/close/SKILL.md`, `scripts/overlap.sh`'s and `scripts/qc-verdict.sh`'s headers and `CHANGELOG.md` say what the code now does, with two exceptions recorded as F16 and F17 (a changelog rationale and two summary lines that overstate). `skills/qc/SKILL.md` step 6 and `scripts/qc-verdict.sh` agree: non-blocking on a first-round plan, blocking from `### Round 2`, ownership by step 8's test.

**Independent review.** Reviewer on `opus` (`QC review:`), given the acceptance criteria alone. No Critical and no Important issue. It tried the required check in scratch repos on both sides (a pull request delivering its own re-planned archive through a send-back cycle fails by name; one that only edits an older archive passes), confirmed `overlap.sh`'s ref check and that no-flag and pair mode are unchanged, and put the old step 17 and stash sentences back with their original line breaks: both guards failed by name.

**Round 2's findings.** F11 (blocking in round 2) — fixed by `cc04ebf`. F12 — fixed by `837fd78`. F13 — fixed by `a3187d0`. F14 — fixed by `307b07e`. F15 — fixed by `2f7a37e`.

**Findings.**

- **F16 — non-blocking, `/codeo:plan`'s.** `CHANGELOG.md:16` says `board.sh set` "follows every page of an issue's project items, so an issue on a large board is found". `lookup` reads the issue's own `projectItems` (`scripts/board.sh:89-98`), about one item per project the issue is on; the size of a board never entered. Paging helps only an issue that sits on more than 50 projects. The criterion is met as worded, but the changelog's reason is untrue and reads as a large-board fix; it should say only that every page is read. The premise came from #43's wording, which the plan followed.
- **F17 — non-blocking, `/codeo:plan`'s.** `docs/handoff.md:391` (`abandon — finished`: "`/codeo:triage`, then the host's checkout clean-up") and `docs/skills.md:190` ("…then the host clean-up, an abandon that finished included") drop the exception round 3 added to `skills/close/SKILL.md`: after an abandon whose unmerged branch was deleted the checkout is the last copy and is not to be cleaned up casually. The skill, which an agent follows, is right; the two summaries overstate.
- **F18 — non-blocking, `/codeo:implement`'s.** `scripts/overlap.sh:52-59`: an empty `--base ""` or `--head ""` is treated as absent (I confirmed `--outside 97 --base ""` exits 0 and compares against the default base), so a caller passing an unset variable gets a different comparison instead of the "cannot resolve" error the header promises; the usage line also suggests the flags work without `--outside`.
- **F19 — non-blocking, `/codeo:implement`'s.** `tests/closing-exits.test.sh` `case_close_step17_lead` checks the old lead (`Report** that the workflow is finished`) on the unflattened step text; it bites today because that lead sat on one line, and a re-wrap would slip past.
- **F20 — non-blocking, `/codeo:implement`'s (carried as F8).** `tests/board.test.sh` `beyond-50` cannot page: the stub answers one canned reply, so only the `--paginate` flag bites and the per-page blank-row path is never exercised.
- **F21 — non-blocking, `/codeo:implement`'s (carried as F10).** `skills/init/SKILL.md:321,329` still says there is no lock after any `lock: TODO`; `docs/handoff.md`'s `init — no lock` row is right (`scripts/lock.sh` prints the volume-name TODO after writing the lock).
- Carried and recorded, not re-raised: the unanchored `^## Outcome` match in `qc-verdict.sh`; the comment above `touched` in `qc-verdict.sh` not saying only delivered archives are footprint-checked; round 2's `and not blocking by rule:` still-says check being line-based; hard-wrap breaks around one-line pins in the abandon text; the items listed in `implement.md`'s earlier rounds.

**Routing.** No blocking finding: every criterion is met, the build and the full suite pass, and the required check behaves correctly on both sides in the cases tried. F16 and F17 are untrue statements, small ones, and both belong to documentation a reader would trust; they do not break behaviour, and the skill an agent follows is right. They can be fixed in the pull request by one more round if the engineer wants (a changelog clause, and a clause on two summary lines), or filed with the others through `/codeo:triage` after the merge.

**Verdict: clear — forward to `/codeo:close`.**

## Log

- 2026-11-15 — qc round 1: build and suite pass, one criterion not met, three blocking findings, back to plan · cost: 10m · opus-5-5 511k in + 6.9M cached / 34k out · sonnet-5-5 395k in + 29k cached / 3k out
- 2026-11-15 — qc round 2: build and suite pass, all criteria met, one blocking finding (F11), back to plan · cost: 9m · opus-5-5 626k in + 4.8M cached / 28k out · sonnet-5-5 24k in + 520k cached / 2k out
- 2026-11-15 — qc round 3: build and suite pass, all criteria met, no blocking finding (F16-F21 non-blocking), clear · cost: 10m · opus-5-5 774k in + 5.5M cached / 33k out · sonnet-5-5 26k in + 634k cached / 2k out
