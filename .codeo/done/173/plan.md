# Issue #173 — plan

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/173 |
| Branch | `docs/173-close-161-leftovers-release-checklist` |
| Updated | 2026-11-25 |

## Where this stands

Round 2, planned: Q4-Q5 answered and the outcome written. The plan is at `docs/plans/2026-11-25-close-161-leftovers-173-round-2.md`, awaiting the engineer's commit, then `/codeo:implement`.

## Questions

### Q1 — When `docker stop` fails after a refusal, does `codeo rm` say so, or is it only documented?

**Why it matters:** it decides whether `.devcontainer/codeo` changes. Today `stop_started` (`.devcontainer/codeo:477-480`) discards a failing `docker stop`, so a refused `codeo rm` can leave a container it started running and print nothing about it. The issue's key requirement reads "never leaves a container `codeo` started running without saying so", and intake Q2 left the choice to this step.

**Options:**
- **report (recommended)** — `stop_started` prints one line on stderr when the stop fails, `codeo: could not stop codeo-<N> again; it is left running`, before the refusal's own line. The exit status and the refusal text do not change (stderr, because `container_check`'s stdout is the captured report). A new case in `tests/codeo-command.test.sh` makes the `docker stop` stub fail and pins the line; the README paragraph and the v1.0.9 #154 bullet then say "stops it again, and says so when the stop fails". About five lines of code.
- **document only** — no code change; the README and the #154 bullet say a failing stop is ignored and the container may be left running, and a test pins that silence. Cheaper, but it meets the acceptance criterion while missing the key requirement's "without saying so".
- **fail harder** — a failed stop changes the exit status or the message of the refusal. I would not: the command already exits non-zero on a refusal, and "Redesigning the `codeo rm` check" is out of scope.

**Answer:**
Report it, as recommended. Given in the session's question dialog on 2026-11-25 and recorded here.

### Q2 — Should the install hook stop running on `clear` and `compact`, or should the page say it runs there?

**Why it matters:** it decides whether `.claude/settings.json` changes and what `tests/live-signal.test.sh` asserts about the second `SessionStart` group. The group has no `matcher` today, so the hook runs on every `SessionStart` source; with the plugins present it exits at the skip check, without them it runs `install.sh` (up to the 300-second timeout) in the middle of a `/clear` or a compaction.

**Options:**
- **add a matcher (recommended)** — give the group `"matcher": "startup|resume|fork"`, the same value the session-title group beside it carries, so one file has one spelling. The test asserts the matcher.
- **`startup` only** — the narrowest: a resumed or forked cloud session whose plugins went missing is not repaired until the next new session.
- **leave it and document it** — no settings change; the page says the hook also runs on `clear` and `compact` and is a no-op there once both plugins are installed.

Either way the skip check itself is fixed (that part of the criterion has no "or"): it reads `claude plugin list --json` with `jq`, as `install.sh` does, skips only when `codeo@codeo` and some `superpowers@*` are both installed *and enabled* at user scope, and otherwise runs `install.sh`, which enables a disabled one. A new test case runs the hook against a stubbed `claude` for: both present, `superpowers` from another marketplace, codeo disabled, one missing, and `CLAUDE_CODE_REMOTE` unset. My call, unless you object: the hook is described in `CONTRIBUTING.md` (it is this repository's own session setup, not something the plugin ships to adopters), with a `CHANGELOG.md` bullet under `## Unreleased`.

**Answer:**
`"matcher": "startup|resume|fork"`, as recommended. Given in the session's question dialog on 2026-11-25 and recorded here. No objection was raised to describing the hook in `CONTRIBUTING.md`.

### Q3 — In a hosted session, do `/codeo:*` commands load in the same session the hook installs them in?

**Why it matters:** the hook's comment says it installs the plugins "so /codeo:* commands load", and `README.md:48` says sessions already open need a restart. QC recorded this (F8) as "plausible, not verified at runtime", and I cannot verify it here: this session runs in a container, not a hosted one. The answer is the sentence the comment and `CONTRIBUTING.md` will carry.

**Options:**
- **you have seen it: they load in the same session** — the comment and the page say a `SessionStart` hook finishes before the session lists its commands, so the first session has them; the README's restart sentence is narrowed to sessions that were open *before* the install.
- **you have seen it: they load only in the next session** — the comment and the page say the first hosted session of a fresh environment installs the plugins and the commands appear from the next session (or after a resume).
- **not known, word it without the claim (my pick if you have not seen either)** — the comment says only what the hook does ("installs both plugins when either is missing or disabled") and points at the README; the page says that if `/codeo:*` commands are not listed after the hook ran, start a new session. Both texts then agree and neither asserts what nobody checked.
- **verify first** — the plan gains a task you run in a fresh hosted session (`Runs on:` a web session) and the wording follows its result; the work waits for that run.

**Answer:**
Not known; word it without the claim. Given in the session's question dialog on 2026-11-25 and recorded here.

### Q4 — #177 and `CHANGELOG.md` overlap: proceed, sequence or re-scope?

`overlap.sh 173` printed `177	CHANGELOG.md` and `177	glob:CHANGELOG.md`. #177 is on branch `docs/177-close-163-166-168-leftovers`, assigned to kbajpai, at step `init` (its plan dossier is written and it waits for `/codeo:plan`'s outcome; its branch has changed no file yet beyond `.codeo/177/`). Its footprint names `CHANGELOG.md`. Round 2 of this plan edits the v1.0.8 `Shared state:` line and the first `(#173)` bullet under `## Unreleased`; round 1 already added three bullets there. #176 (`feat/176-support-sbx-issue-sandbox-macos`, step `qc`) also names `CHANGELOG.md`; that overlap was answered *proceed and coordinate* in qc.md Q3.

**Why it matters:** three branches add `## Unreleased` bullets after the same line; whichever merges later resolves a small textual conflict by keeping every bullet.

**Options:** *proceed and coordinate* (recommended: the edits are bullets and one released line, and #177 has written no code yet) · *sequence after #177* · *re-scope*.

**Answer:**
Proceed and coordinate, as recommended. Given in the session on 2026-11-25 ("go with your picks") and recorded here.

### Q5 — #177 and `docs/release-checklist.md` overlap: proceed, sequence or re-scope?

`overlap.sh 173` printed `177	docs/release-checklist.md` and `177	glob:docs/release-checklist.md`. #177 is on branch `docs/177-close-163-166-168-leftovers`, assigned to kbajpai, at step `init`. Its footprint names `docs/release-checklist.md`. This branch already rewrote step 6 in round 1 (three groups) and round 2 extends those groups with `docs/updating.md` and the `v1.0.9;x` stub.

**Why it matters:** if #177 edits step 6 (rather than another step), the later merge conflicts on those lines. #177's plan is not merged and its text on this file is not visible from its branch yet.

**Options:** *proceed and coordinate* (recommended: say in the pull request that step 6 changed, and let #177 sync before it edits that step) · *sequence after #177* · *re-scope*.

**Answer:**
Proceed and coordinate, as recommended. Given in the session on 2026-11-25 ("go with your picks") and recorded here.

## Notes

**Decided without a question** (say so under any answer if one is wrong):

- **Shape.** One plan under `docs/plans/`, one pull request; no reference doc, since nothing here is a standing decision. No overlay sets a plan shape, so it follows `docs/plans/2026-11-24-documentation-leftovers-154-146-161.md`.
- **Released changelog sections are corrected in place.** The #154 bullet now sits under `## v1.0.9` (`CHANGELOG.md:27`) and the `## Outcome` sentence in the v1.0.8 `Shared state:` line (`:33`); both shipped since the issue was written. They are edited where they stand, and a `## Unreleased` bullet says they were corrected, as v1.0.8's #108 bullet did for v1.0.7. The GitHub release notes and the tags are not touched, as in #161.
- **The v1.0.8 line's correction**, checked against the tags: at v1.0.7 `dossier-check.sh` matched the heading or the heading plus a space (`$3 == name || index($3, name " ") == 1`), so only `## Outcome notes` stopped counting there; `inflight.sh` and `qc-verdict.sh` had `/^## Outcome/`, so `## Outcomes` and `## Outcome notes` both stopped counting there.
- **Release checklist step 6**, from `tests/install.test.sh` and `README.md` today: the `v1.0.9` examples and stubs move to the release being cut; the `--version v1.0.8` example (`README.md:101-104`), the `v1.0.8 -> v1.0.9` replace line (`:534`) and the older-tag stubs (`v1.0.8`) move to the one before it; the ordering stubs (`v1.0.5`, `v1.0.10`, `v1.0.9.1`, `v2.0.0-rc1`, `v9.9.9`) do not move. The implementer confirms each group against the test before writing the sentence.
- **README flowchart and paragraph** (`.devcontainer/README.md:197, 214-216`): "was running" becomes "not started by `codeo` as far as it knows (running, or `docker ps -a` failed)", and "A container that `codeo` started itself is read once" becomes "knows it started", since with no listing `started` stays 0 and the container is restarted and read twice.
- **Proof of done** for every task is the `shell` suite (`bash tests/run.sh`; it has no single-test filter).

## Outcome

| | |
|---|---|
| Plan | `docs/plans/2026-11-25-close-161-leftovers-173.md` (unstaged, awaiting the engineer's commit) |
| Shape | A plan under `docs/plans/`, six tasks, one pull request; no reference doc, since nothing here is a standing decision. Follows `docs/plans/2026-11-24-documentation-leftovers-154-146-161.md`. |

**Decisions.**
- **Q1 — report a failed stop.** `stop_started` prints `codeo: could not stop codeo-<N> again; it is left running` on stderr; exit statuses and refusal lines unchanged. Rejected: document the silence only (misses "without saying so"); change the exit status or message (out of scope: redesigning the check).
- **Q2 — matcher `startup|resume|fork`** on the install hook's `SessionStart` group, the value the session-title group beside it carries. Rejected: `startup` only; leave it and document it. The skip check is rewritten to read `claude plugin list --json` as `install.sh` does: skip only when `codeo@codeo` and some `superpowers@*` are installed and enabled at user scope; any read failure runs `install.sh`.
- **Q3 — no claim on when `/codeo:*` commands load** in a hosted session; the hook comment says what the hook does and `CONTRIBUTING.md` says to start a new session if the commands are not listed. Rejected: asserting same-session or next-session loading (neither verified); a hosted-session verification task.
- **Without a question.** The released v1.0.9 #154 bullet and the v1.0.8 `Shared state:` line are corrected in place, named under `## Unreleased`; release notes and tags untouched. The hook is described in `CONTRIBUTING.md`, not the adopter README.

**Documentation pages the plan changes:** `.devcontainer/README.md` (removal flowchart, two paragraphs), `CONTRIBUTING.md` (new `## Hosted sessions`), `CHANGELOG.md`, `docs/release-checklist.md` (step 6).

**Intake questions resolved here:** init's open item F8 (whether `/codeo:*` commands load in the same session) is not verified and is worded around, per Q3; `issue.md` Q2 (documentation-only fix acceptable?) is answered by Q1 above: the code reports.

### Round 2 — 2026-11-25

(send-back from qc.md round 1)

**Plan.** `docs/plans/2026-11-25-close-161-leftovers-173-round-2.md` (unstaged, awaiting the engineer's commit): five tasks on the same branch and pull request. Round 1's plan file is not edited. Shape as in round 1, a plan under `docs/plans/` with no reference doc.

**Findings answered.** F1 and F2 are blocking and the plan's. F3-F7 are non-blocking; the round takes F3-F7 too, except F5's choice below, so one more pass does not have to.
- **F2 — `--force` printed a false line.** Chosen: gate the line. `container_check` takes `--quiet-stop`, which `cmd_rm` passes under `--force`, and `stop_started` prints only without it; the stop itself is unchanged, so `--force` stops and removes exactly what it did. Rejected: skipping the stop under `--force` (changes what `--force` does and borders on the out-of-scope redesign of the check); rewording the line so it is true on both paths (loses the half that matters on a refusal, which Q1 of round 1 chose). A new case pins `--force` with a failing stop after a cannot-check and after a dirty read (Task 1); the `container_check` header comment is rewritten (F6, Task 1).
- **F1 — the v1.0.8 `Shared state:` line.** Names each read of `dossier-check.sh` separately: its section reads never counted `## Outcomes` and no longer count `## Outcome notes`, and its `finished-qc-clear` read no longer counts either. The plan's step 1 checks each against the `v1.0.7` and `v1.0.8` tags with `grep -F` (Task 2). The `## Unreleased` bullet says a `--force` removal prints no such line.
- **F3, F7 — release checklist step 6.** `docs/updating.md` joins both "move" groups and the refused stub `v1.0.9;x` joins "do not move" (Task 4).
- **F4 — README.** One sentence says the line is printed on any refusal of a container `codeo` started, and one says `--force` prints none (Task 3).
- **F5 — hook comment.** Rewords "as install.sh reads it" to say the list is parsed as `install.sh` parses it and any enabled `superpowers@*` entry counts. Rejected: making the hook judge only the first entry as `install.sh` does, since the hook then would install where an enabled `superpowers` already exists (Task 3).

**Documentation pages the plan changes:** `.devcontainer/README.md` (the "A refusal removes nothing" paragraph), `CHANGELOG.md` (the v1.0.8 `Shared state:` line and one `## Unreleased` bullet), `docs/release-checklist.md` (step 6). No page under `docs/` other than the checklist describes `stop_started`.

**Questions resolved this round.** Q4 and Q5 (the overlaps with #177 on `CHANGELOG.md` and `docs/release-checklist.md`): *proceed and coordinate*; `sequenced:` stays `none`. #176's overlap on the same files was answered in `qc.md` round 1.

### Footprint

```
files:      .devcontainer/codeo, .devcontainer/README.md, .claude/hooks/session-start.sh, .claude/settings.json, tests/codeo-command.test.sh, tests/session-start-hook.test.sh, tests/live-signal.test.sh, CONTRIBUTING.md, CHANGELOG.md, docs/release-checklist.md, docs/plans/2026-11-25-close-161-leftovers-173.md, docs/plans/2026-11-25-close-161-leftovers-173-round-2.md, .codeo/173/**
wiki:       none
exclusive:  none
sequenced:  none
```

## Log

- 2026-11-25 — Q1-Q3 raised · cost: 1m · fable-5-2 72k in + 382k cached / 4k out
- 2026-11-25 — planned: docs/plans/2026-11-25-close-161-leftovers-173.md · cost: 12m · fable-5-2 53k in + 925k cached / 18k out · sonnet-5-5 135k in + 185k cached / 1k out
- 2026-11-25 — round 2 draft approved; Q4-Q5 raised (overlaps with #177) · cost: 5m · fable-5-2 299k in + 974k cached / 14k out · sonnet-5-5 27k in + 1.2M cached / 2k out
- 2026-11-25 — planned round 2: docs/plans/2026-11-25-close-161-leftovers-173-round-2.md · cost: 27m · fable-5-2 299k in + 974k cached / 14k out · sonnet-5-5 30k in + 2.2M cached / 5k out
