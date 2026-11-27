# Issue #195 — qc

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/195 |
| Branch | `feat/195-identify-acting-user-strictly-verify` |
| Updated | 2026-11-27 |

## Where this stands

Round 1 complete: **back to `/codeo:plan`.** Q1-Q3 (overlaps with #188, #204, #206) were answered *proceed and coordinate*. The build passes and the full `shell` suite shows only the two environmental failures that also fail on `origin/main`. The independent review found one blocking defect that is the plan's, not the code's: in a hosted web session the ownership checks never refuse anyone (plan Q2). Two acceptance criteria (B refused on A's branch; A's stale checkout refused) are not met there. Everything else is met.

## Questions

### Q1 — Overlap with #188 (`docs/188-close-177-qc-leftovers-utc`): proceed, sequence, or re-scope?

`overlap.sh 195` printed, for #188 (assignee `kbajpai`, step `plan (working)`):
`CHANGELOG.md`, `glob:CHANGELOG.md`, `glob:skills/close/SKILL.md`, `glob:tests/cleanup-skill.test.sh`,
`glob:tests/close-removal.test.sh`, `glob:tests/close-skill.test.sh`, `skills/close/SKILL.md`,
`tests/close-skill.test.sh`.

**Why it matters:** both change `skills/close/SKILL.md` and `tests/close-skill.test.sh` (this
branch: step 0's `lock.sh verify` paragraph, rule `close-15`, and the stash/abandon owner removal,
`close-16`), and both add a `CHANGELOG.md` `## Unreleased` bullet. #188 has written no code yet.
**Options:** proceed and coordinate · sequence after #188 · re-scope.
**Recommendation:** proceed and coordinate — this branch merges first; #188 re-checks its close
edits against `close-15`/`close-16` and the rule-inventory hash when it syncs at implement.

**Answer:**
Proceed and coordinate. (Engineer: "Go with your recommendations", 2026-11-27.)

### Q2 — Overlap with #204 (`chore/204-fix-codeo-close-opens-pr`): proceed, sequence, or re-scope?

`overlap.sh 195` printed, for #204 (assignee `kbajpai`, step `plan (working)`):
`CHANGELOG.md`, `README.md`, `docs/dossier.md`, `docs/handoff.md`, `docs/skills-inventory.md`,
`docs/skills.md`, `glob:CHANGELOG.md`, `glob:README.md`, `glob:docs/dossier.md`,
`glob:docs/handoff.md`, `glob:docs/skills-inventory.md`, `glob:docs/skills.md`,
`glob:skills/close/SKILL.md`, `glob:skills/init/SKILL.md`, `glob:tests/**`, `skills/close/SKILL.md`,
`skills/init/SKILL.md`, `tests/claim.test.sh`, `tests/close-skill.test.sh`,
`tests/fixtures/skills-inventory.rules.sha256`, `tests/github.test.sh`,
`tests/implement-skill.test.sh`, `tests/init-skill.test.sh`, `tests/inventory.test.sh`,
`tests/live-signal.test.sh`, `tests/live.test.sh`, `tests/lock-verify.test.sh`,
`tests/lock.test.sh`, `tests/plan-skill.test.sh`, `tests/qc-skill.test.sh`,
`tests/readme.test.sh`, `tests/skills-doc.test.sh`.

**Why it matters:** the widest overlap. Most of the test-file lines come from #204's `tests/**`
glob, not from files it has actually changed (it has changed only its plan). The real contact is
`skills/close/SKILL.md`, `skills/init/SKILL.md`, the docs pages, and — if #204 adds a rule —
`docs/skills-inventory.md`, the `want` map in `tests/inventory.test.sh` and the pinned
`tests/fixtures/skills-inventory.rules.sha256`, which every rule change regenerates.
**Options:** proceed and coordinate · sequence after #204 · re-scope.
**Recommendation:** proceed and coordinate — this branch merges first; #204 takes the new rule
ids (`init-11`, `close-15`, `close-16`, …) into its own numbering and regenerates the hash after
syncing.

**Answer:**
Proceed and coordinate. (Engineer: "Go with your recommendations", 2026-11-27.)

### Q3 — Overlap with #206 (`fix/206-codeo-cleanup-prints-codeo-rm`): proceed, sequence, or re-scope?

`overlap.sh 195` printed, for #206 (assignee `kbajpai`, step `plan (working)`, waiting on its
own `issue.md` Q1):
`CHANGELOG.md`, `README.md`, `docs/skills.md`, `glob:CHANGELOG.md`, `glob:README.md`,
`glob:docs/skills.md`, `glob:tests/cleanup-skill.test.sh`, `glob:tests/cleanup.test.sh`.

**Why it matters:** shared documentation pages and the changelog only; #206's code
(`scripts/cleanup.sh`, `skills/cleanup/SKILL.md`) does not meet this branch's.
**Options:** proceed and coordinate · sequence after #206 · re-scope.
**Recommendation:** proceed and coordinate — a line-level conflict in a doc page is the most it
can cause.

**Answer:**
Proceed and coordinate. (Engineer: "Go with your recommendations", 2026-11-27.)

## Notes

Step 2 so far (commands run this pass):

- `sync-main.sh --abort-on-conflict` → `sync-main: the branch already contains origin/main` (exit 0).
- `overlap.sh 195` → the lines quoted in Q1-Q3 (exit 0).
- `git diff origin/main...HEAD --stat` → 36 files changed, 1704 insertions(+), 78 deletions(-).
- `scope.sh origin/main HEAD` → `suite.shell=true` (exit 0; no `deploy=` line — no environment is configured).
- `overlap.sh --outside 195` → nothing printed (exit 0): every changed path is inside the footprint.
- `overlay.sh qc invariants-extra` → exit 3 (no further rules); `overlay.sh qc wiki-rules` → exit 3. No invariants file and no shared environment are configured.

Overlaps raised at step 2 (Q1-Q3) were answered *proceed and coordinate* for #188, #204 and #206:
this branch merges first and each of them re-checks its own edits when it syncs at
`/codeo:implement` step 2a. One thing for them to carry: the rule inventory (`docs/skills-inventory.md`,
the `want` map in `tests/inventory.test.sh`, the pinned hash) now holds `init-11`, `plan-10`,
`implement-11`, `qc-15`, `close-15` and `close-16`.

## Outcome

### Round 1 — 2026-11-27

**Commands run this pass, and their output.**

- `sync-main.sh --abort-on-conflict` → `sync-main: the branch already contains origin/main` (exit 0).
- `scope.sh origin/main HEAD` → `suite.shell=true` (exit 0; no `deploy=` line: no environment is configured).
- `overlap.sh --outside 195` → nothing printed (exit 0): every changed path is inside the plan's footprint.
- Build: the `shell` suite's `build` is `true` → exit 0.
- Suite: `bash tests/run.sh` (the suite's whole `test` command) →
  ```
  === FAIL: live.test.sh
  .../tests/live.test.sh: line 259: hostname: command not found
  === FAIL: sandbox.test.sh
  The following paths are ignored by one of your .gitignore files: .sbx
  failed: live.test.sh sandbox.test.sh
  ```
  every other test file printed `all cases passed`. Both failures are environmental and not this
  change's: on a detached worktree of `origin/main` (d934542) `bash tests/run.sh sandbox` fails the
  same way (`.sbx` ignored), and `bash tests/run.sh live` fails the same way
  (`hostname: command not found`). With a `hostname` shim on `PATH`, `bash tests/run.sh live` on this
  branch prints `all cases passed` (so the live-signal changes are exercised and pass), and the same
  shim passes it on `origin/main`.
- Documentation hygiene: added lines in `docs/handoff.md`, `docs/dossier.md`, `docs/skills.md`,
  `README.md` and `skills/*` carry no issue number; the one "no longer" (`docs/skills.md`, the lease
  put-back) describes a lease condition, not history. The three `resume_re` copies
  (`scripts/claim.sh:101`, `scripts/lock.sh:44`, `.devcontainer/scripts/role.sh:122`) are identical.
- Independent review (opus, `QC review:`), given the acceptance criteria and the diff without the
  dossiers or plan: Critical 1 (below), Important 1-2, Minor 1-6. Quoted in plain text: "With fixes".
  It also ran `bash tests/run.sh lock`, `github` and `claim`: all passed.

**Criteria.**

| Criterion | Verdict | Settled by |
|---|---|---|
| With `gh api user` failing and the variable set, `init` outside a web session refuses. | met | `tests/github.test.sh` case `user whoami (GET /user 403s, CODEO_GITHUB_LOGIN set, not a web session)` (exit 1, stdout empty); `skills/init/SKILL.md` rule `init-11` stops on that exit, pinned by `tests/init-skill.test.sh` (the refusal itself is prose a model follows) |
| With a Bot login, `init` refuses. | met | `tests/github.test.sh` `user whoami (Bot)`, `(Organization)`, empty type; `tests/lock.test.sh` `take, Bot login` (no lock); `init-11` as above |
| A normal `init` records the login in `init.md`, the lock and the live signal. | met | lock: `tests/lock.test.sh` (`user:    alice`); live signal: `tests/live.test.sh` (`user: alice`, variable ignored outside web) and `live-signal.test.sh`; `init.md`: `| Owner |` row written by `init` step 9 (prose), read back by `codeo_owner_of_init` (`tests/lock-verify.test.sh`) |
| Tests cover each case. | met | the cases above; the `init`-level ones are text pins of the skill, which is all prose allows |
| B running close, plan, implement or qc on A's branch is refused with one line naming the owner. | not met | refused for a verified login (`tests/lock-verify.test.sh` `B on A's branch`: exit 1, `belongs to alice`) and called at step 0 of the four skills (`plan-10`, `implement-11`, `qc-15`, `close-15`); **not refused in a hosted web session**: `scripts/lock.sh:93` `[[ $type != unverified ]] || return 0`, and `tests/lock-verify.test.sh:237` (`web, variable only, lock user equal`) passes with the pushed owner `alice` and the variable naming someone else — see F1 |
| A stale checkout of A after B resumed is refused. | not met | refused for a verified login (`tests/lock-verify.test.sh` `A's stale checkout after B resumed`, and the single-branch clone case); not refused in a hosted web session, same cause — F1 |
| The override works once and is recorded. | met | `tests/lock-verify.test.sh` `override on a refusal` (exit 0, one `override: bob over alice: "…"` line under `## Notes`), run again without it (exit 1), `override that was not needed` and `--override ""` record nothing |
| Stash by a non-owner does not remove the owner's assignment or move the card. | met | step 0's `lock.sh verify` refuses a non-owner before any stash step (`close-15`); `close-16` removes the recorded owner, never the caller (`tests/close-skill.test.sh`); `assignee-remove` without a login fails with no API call (`tests/github.test.sh`). A workflow begun before this change has no recorded owner, so its stash removes nobody — F2 |
| Tests cover each step. | met | per-step pins in `tests/plan-skill.test.sh`, `implement-skill`, `qc-skill`, `close-skill`, `init-skill` (text pins) and the script cases in `tests/lock-verify.test.sh` |

**Findings.**

- **F1 (blocking, `/codeo:plan`'s).** In a hosted web session the ownership checks never refuse
  anyone. `lock.sh take web` writes `user:` from `$CODEO_GITHUB_LOGIN`, and `verify` compares an
  `unverified` login only with that same lock line (`scripts/lock.sh:93`, and the web branch of
  `verify`); the init prose likewise lets an unverified login resume another engineer's workflow
  without an override (`skills/init/SKILL.md:93,107,204-207`). So the variable is exactly what
  satisfies the check, B passes on A's branch and A's stale web checkout passes after B resumed, and
  `docs/handoff.md:254` ("`CODEO_GITHUB_LOGIN` never satisfies `lock.sh verify`") says the opposite
  of what the code does. Cause: the code follows the plan's Q2 decision (compare an `unverified`
  login only with the lock's own `user:`) and that decision is what is wrong — it makes two
  acceptance criteria unreachable on a supported host and contradicts the issue's "never used to
  satisfy an ownership check". Direction for the plan, not a patch: an `unverified` login must still
  be compared with the owner and the assignees, to refuse on a mismatch only (a match keeps its "not
  independently verified" note), and the init prose and `handoff.md` follow.
- **F2 (non-blocking, `/codeo:plan`'s).** A stash or abandon of a workflow begun before this change
  leaves the assignee in place: `lock.sh owner` prints nothing for a dossier with no Owner row and
  old `by no login` resume lines, so `close-16` skips the removal and never removes the caller.
  `CHANGELOG.md`'s `Safe to bump mid-workflow: yes` is therefore not quite true for a legacy workflow
  stashed after the bump (it stays claimed). Rides along the re-plan: remove the verified caller
  when there is no recorded owner and `verify` passed without an override, or fall back to the
  assignees.
- **F3 (non-blocking, `/codeo:plan`'s).** A failed `assignee-add` after an `init` takeover leaves the
  old owner the only assignee, so every later `verify` for the new owner refuses with `is assigned
  to <old>`; nothing records why. Decide in the re-plan whether the resume-line owner wins, or init
  retries or records the failure.
- **F4 (non-blocking, `/codeo:implement`'s).** `docs/handoff.md:96` documents
  `(last resumed <date>, or claimed <date>)` and the code prints `(claimed)` with no date
  (`scripts/lock.sh:126-128`). Related cosmetic: the resume date at `scripts/lock.sh:123` can cite a
  legacy `by no login` line the owner regex rejected.
- **F5 (non-blocking, `/codeo:implement`'s).** `scripts/lock.sh:100-105` fetches `origin <branch>`
  then reads `FETCH_HEAD`; `live.sh beat` (background, every PostToolUse; fetch at `live.sh:260`)
  also rewrites `FETCH_HEAD`, so a concurrent beat can give a spurious "no dossier on origin's
  branch" refusal or a read of the wrong commit. Fetch into a private ref instead.
- **F6 (non-blocking, `/codeo:implement`'s).** The Owner-row parser (`lib/identity.sh:39`) is strict:
  `` | Owner | `alice` | `` (the backticked style of the `Branch` row beside it) makes the owner the
  literal `` `alice` `` and refuses the real owner; a padded `| Owner  | alice |` is ignored. Strip
  backticks and allow flexible whitespace.
- **F7 (non-blocking, `/codeo:implement`'s).** `docs/handoff.md:126-146`'s flowchart omits the web
  lock with no `user:` line and the legacy-lock passes, and `README.md:37` says "you must also be
  among the issue's assignees" without "when it has any".
- **F8 (non-blocking, `/codeo:implement`'s).** Test gaps: `tests/lock.test.sh:641` (`take,
  unresolved login`) does not set `CODEO_GITHUB_LOGIN`, so criterion 1's `take` leg is covered only
  through `github.sh`; the narrowed `--override` pin at `tests/qc-skill.test.sh:124-127` misses a
  command wrapped over two lines.

Pre-existing and not findings: `live.test.sh` (`hostname` missing here) and `sandbox.test.sh` (`.sbx`
gitignored) fail identically on `origin/main`. No issue was filed by this pass.

**Routing.** F1 is blocking and is the plan's: the code does what the plan says, and the plan's Q2 is
wrong. `/codeo:plan` re-decides web-session ownership (with F2 and F3 in the same round), then
`/codeo:implement` builds the round and fixes F4-F8.

**Verdict: back to `/codeo:plan`.**

## Log

- 2026-11-27 — Q1-Q3 raised (overlaps with #188, #204, #206 found at step 2) · cost: 1m · opus-5-5 337k in + 738k cached / 2k out
- 2026-11-27 — round 1: back to /codeo:plan (F1 blocking: web-session ownership, plan Q2) · cost: 20m · opus-5-5 483k in + 3.9M cached / 32k out · sonnet-5-5 42k in + 3.7M cached / 8k out
