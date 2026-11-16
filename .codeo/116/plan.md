# Issue #116 — plan

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/116 |
| Branch | `fix/follow-ups-70-71-104` |
| Updated | 2026-11-16 |

## Where this stands

Planned. Q1-Q5 are answered, the engineer approved the draft, and the plan is written to `docs/plans/2026-11-16-follow-ups-70-71-104-107.md` (unstaged, for review). The footprint is recorded and `overlap.sh 116` prints nothing new (#113 was raised as Q5). Nothing is open; the next step is to review and commit the plan, then `/codeo:implement`. Every finding in the issue was read against the code as it is on this branch, and each still holds; the calls the draft will carry are under `## Notes`.

## Questions

### Q1 — `/codeo:cleanup` lists every archived issue (J8): document the limit, or filter the list?

**Why it matters:** documenting is two sentences (the cleanup skill and `docs/skills.md`) and no script change. Filtering changes `scripts/cleanup.sh` and its tests, and needs a rule for "already dealt with" that the script can prove without running a container command, which it never does. The only record available is `.codeo/intake/cleanup/<date>.md`, which says a command was *printed*, never that it was run.
**Options:**
- **(a) Document (recommended).** The list covers every issue under `.codeo/done/` on the base branch, whether or not it ever had a container, and grows with each merge; a command for a container that is already gone fails harmlessly on the host. No behaviour change.
- **(b) Filter on the cleanup records.** An issue listed as proven in an earlier `.codeo/intake/cleanup/` record is left out unless `cleanup.sh --all` is given. Shorter list; an issue whose command was printed but never run drops out of sight.
- **(c) Drop J8 from this change** and leave it in the archive for a later issue.

**Answer:**
(a) Document (engineer, in the conversation, 2026-11-16: "recommended for all"; recorded here by the skill).

### Q2 — `SessionEnd`'s 10-second timeout is shorter than a worst-case `clear` (F7): raise it, or document it?

**Why it matters:** `live.sh clear` can take 8 s for the push `--delete` plus 8 s for the REST delete; the hook is killed at 10 s, so the REST delete may never finish and the signal then only expires (15 minutes). Raising the timeout is one number in `hooks/hooks.json` and a test pin, and costs a session that ends while origin hangs up to 16 s instead of 10. Documenting changes one sentence in `docs/handoff.md` and the `live.sh` header and leaves the numbers alone.
**Options:**
- **(a) Raise the `SessionEnd` hook's timeout to 20 (recommended).** Both deletes get their full bound; the `beat` hooks stay at 10 (they return at once).
- **(b) Keep 10 and document** that a `clear` cut short leaves the signal to expire.

**Answer:**
(a) Raise the `SessionEnd` timeout to 20 (engineer, in the conversation, 2026-11-16: "recommended for all"; recorded here by the skill).

### Q3 — A `beat` in the future counts as age 0 (F5): cap it, or document it?

**Why it matters:** today a planted or badly-skewed far-future `beat` reads as live until someone deletes the ref. A cap is one comparison in `live.sh list` and one test case; the existing case `list_treats_a_future_beat_as_age_0` stays for a small skew. Documenting adds one sentence and leaves the behaviour.
**Options:**
- **(a) Cap at the TTL (recommended).** A `beat` up to `CODEO_LIVE_TTL_SECONDS` ahead of the reader's clock still counts as age 0; one further ahead is skipped like any malformed signal. A writer whose clock runs up to 15 minutes fast still shows as live, and a crashed one then reads as live for at most twice the TTL.
- **(b) Document only:** the page says the expiry holds only when the clocks agree.

**Answer:**
(a) Cap at the TTL (engineer, in the conversation, 2026-11-16: "recommended for all"; recorded here by the skill).

### Q4 — What does `rm -f -- ""; echo "rc=$?"` print in a container terminal?

**Why it matters:** the criterion "the `rm -f -- ""` check output is recorded on #107" needs the literal output, and this session cannot produce it: the environment's safety check refuses an empty `rm` operand, as it did for #107's implementer and reviewer. With the output pasted here, the plan's last task posts it as a comment on #107 and that criterion is met. Left empty, the plan cannot meet the criterion and I will ask again.
**Options:** none. Run it in a terminal of this container (bash) and paste everything it prints, the `rc=` line included.

**Answer:**
Dropped from this change; the output was pasted anyway and is recorded below (engineer, in the conversation, 2026-11-16: "drop the rm criterion and draft the plan"; recorded here by the skill).

### Q5 — #113 names three of the same files: proceed and coordinate, sequence after #113, or re-scope?

**Why it matters:** #113 (`feat/cmd-mode-start-use-home`, assignee kbajpai, step `plan (working)`) overlaps this plan's draft footprint. `overlap.sh 116` prints, for #113: `glob:.devcontainer/README.md`, `glob:CHANGELOG.md` and `glob:tests/devcontainer.test.sh`. Its branch has already changed `tests/devcontainer.test.sh`. Here, `CHANGELOG.md` gets one new bullet and three corrected sentences; `.devcontainer/README.md` gets one sentence (the guard also recognises `/run/.containerenv`); `tests/devcontainer.test.sh` gets a comment on one case (`title_reports_a_failing_container_name_as_one_line`) and no new case. Each is a small, local edit, so the branch that merges second resolves by keeping both sides.
**Options:**
- **Proceed and coordinate (recommended).** This plan edits those three files once each, in its last tasks, after merging `origin/main`.
- **Sequence after #113.** This plan waits for #113 to merge before it is built.
- **Re-scope.** Drop the Podman guard's README sentence and the title-test comment from this change; `CHANGELOG.md` cannot be dropped, the issue requires the entry.

**Answer:**
Proceed and coordinate (engineer, in the conversation, 2026-11-16: "recommended for all"; recorded here by the skill).

### Q4 — answer, recorded by the skill

The engineer (conversation, 2026-11-16): "drop the rm criterion and draft the plan", and pasted from a container terminal:

```
dev@65b0af50fc72:/workspaces/codeo-116$ rm -f -- ""; echo "rc=$?"
rc=0
```

So the criterion "The `rm -f -- ""` check output is recorded on #107" is **dropped from this change** at the engineer's say-so: no task posts to #107. The output above is kept here only.

## Notes

**Calls the draft will carry, for you to overrule at the review gate.** Each is the fix rather than the documented limit unless it says otherwise.

- **Podman (J6).** `role.sh` treats the clone as inside a container when `/.dockerenv` *or* `/run/.containerenv` exists. `CODEO_DOCKERENV` keeps overriding the first path; a new `CODEO_CONTAINERENV` overrides the second, so `tests/role.test.sh` can point both at scratch files. `.devcontainer/README.md` states both markers.
- **`CODEO_CLEANUP_REMOVAL` (J7).** Removed from `scripts/cleanup.sh`: the overlay body comes only from `overlay.sh cleanup removal-command`. `tests/cleanup.test.sh` and `tests/cleanup-skill.test.sh` write `.codeo/overlays/cleanup.md` in their scratch project instead, and one new case exports the variable and proves the output does not change.
- **Generic "home container" wording (F12).** The cleanup skill's description, the two `docs/skills.md` sentences and the sentence in `skills/plan`, `skills/implement`, `skills/qc` and `docs/handoff.md` say "the checkout the project's host workflow names for it", the phrase #70's Task 11 already put in `skills/close`. The project-specific fact stays in `.codeo/overlays/` and `.devcontainer/README.md`.
- **Lock pattern (F10).** `read_lock` uses `^[1-9][0-9]{0,8}$`, as `list` does; a case pins that a lock issue of `0` or `0104` publishes nothing.
- **`ref delete` (F14).** Only `Reference does not exist` counts as already deleted; any other failure, a bare `Not Found` included, is `ref delete <ref>: DELETE failed`.
- **`CODEO_LIVE_PUSH_TIMEOUT` wording (F13).** `CHANGELOG.md`, the `live.sh` header and `docs/handoff.md` say it bounds each git push or fetch, the login lookup, and the REST fallback as a whole.
- **Stale `live:` line after a stash or abandon (F15).** `skills/close/SKILL.md` runs `live.sh clear` just before it deletes `.codeo/active`, at all three exits (finished, stash, abandon); `docs/handoff.md` says so and its sequence diagram gains the step.
- **`CODEO_MACHINE` (F16).** Documented in `docs/handoff.md`: two containers with the same volume name on one issue share a ref; set `CODEO_MACHINE` in one of them.
- **Missing Backlog option (F8).** `board.sh`'s `no synced project has the option …` line ends by naming the fix: map the board's own option name under `board.statuses.<key>` in `.codeo/config.json` (`board.statuses.backlog` for a filing).
- **`set` prints one line per project (F7 of #71).** `skills/issue/SKILL.md` says so and says to quote each.
- **`CHANGELOG.md`.** States the `issue:<N>` fingerprint change in the #71 bullet, corrects the #107 `codeo-root.sh` sentence (the cases pin the empty and `false` handling; only the backslash handling changed), and gains this change's own bullet.
- **`title_reports_a_failing_container_name_as_one_line` (F3 of #107).** The name is about the one-line message, and the `wt_err` equality can fail for that; the plan proves it by mutation (dropping the join in `window-title.sh`) and adds a comment that the two `.vscode` assertions guard only a reordering. No rename.
- **Out of scope, as the issue says:** #104's web-session label (#112), #108's items, #103's triage judging.

**Shape.** One plan under `docs/plans/`, one pull request; no reference doc. `plan-shape`, `proof-of-done` and `wiki-rules` have no overlay here (exit 3), no invariants document, no shared environment, no `wiki` module, no exclusive resources. The `shell` suite has no `filter`, so each task's proof is the test file it touches and then `bash tests/run.sh`.

## Outcome

**Plan:** `docs/plans/2026-11-16-follow-ups-70-71-104-107.md` (unstaged, for the engineer to review and commit). **Shape:** one executable plan under `docs/plans/`, ten tasks, one pull request; no reference doc, no diagram beyond the one `docs/handoff.md` already has.

**Decisions** (Q1-Q3 and Q5 "recommended for all", engineer, 2026-11-16):
- Q1: the `/codeo:cleanup` list limit (J8) is documented, not filtered. Rejected: filtering on the cleanup records (an issue whose command was printed but never run would drop out of sight); dropping J8.
- Q2: the `SessionEnd` hook's timeout is raised to 20 s (F7). Rejected: keeping 10 and documenting.
- Q3: a `beat` more than the TTL ahead of the reader's clock is skipped (F5). Rejected: documenting only.
- Q4: the criterion "the `rm -f -- ""` output is recorded on #107" is dropped from this change at the engineer's say-so. The output they pasted (`rc=0`) is kept in this dossier only; no task posts to #107, and `/codeo:qc` reads the criterion as dropped.
- Q5: proceed and coordinate with #113; `.devcontainer/README.md`, `CHANGELOG.md` and `tests/devcontainer.test.sh` are each edited once, in Task 10, after `sync-main.sh`.
- Calls without a question: Podman is fixed (`CODEO_CONTAINERENV`), not documented; `CODEO_CLEANUP_REMOVAL` is removed from `cleanup.sh`; the generic wording is "the checkout the project's role check allows"; `ref delete` counts only `Reference does not exist`; `/codeo:close` clears the live signal in the same command that deletes the lock, at all three exits; the Backlog error names `board.statuses.backlog`; the title test keeps its name and gains a comment, proved by mutation.

**Documentation the plan changes:** `docs/skills.md` (the `cleanup` and `close` sections), `docs/handoff.md` (the live-signal bullet and diagram, the issue-filing sentence), `.devcontainer/README.md` (the guard line) and `CHANGELOG.md`. No wiki module.

**Intake questions resolved here:** F5, F7, F16 and J8 (fix or document) are settled as above; F3 stays with #112. No issue filed from this skill; the optional `engineering` skills were not used (no new component or technology choice).

### Footprint

```
files:      .devcontainer/scripts/role.sh, .devcontainer/README.md, scripts/cleanup.sh, scripts/live.sh, scripts/github.sh, scripts/board.sh, hooks/hooks.json, skills/cleanup/SKILL.md, skills/close/SKILL.md, skills/issue/SKILL.md, skills/plan/SKILL.md, skills/implement/SKILL.md, skills/qc/SKILL.md, docs/skills.md, docs/handoff.md, CHANGELOG.md, tests/role.test.sh, tests/cleanup.test.sh, tests/cleanup-skill.test.sh, tests/live.test.sh, tests/live-signal.test.sh, tests/github.test.sh, tests/board.test.sh, tests/devcontainer.test.sh, tests/close-skill.test.sh, tests/issue-skill.test.sh, tests/plan-skill.test.sh, tests/implement-skill.test.sh, tests/qc-skill.test.sh, docs/plans/2026-11-16-follow-ups-70-71-104-107.md
wiki:       none
exclusive:  none
```

## Log

- 2026-11-16 — explored, Q1-Q5 raised, draft footprint recorded under Notes · cost: 3m · fable-5-2 118k in + 853k cached / 16k out
- 2026-11-16 — Q1-Q3 and Q5 recorded from the engineer's conversation answer; Q4 still open, stopped · cost: unavailable (no draft work this round)
- 2026-11-16 — Q4 criterion dropped by the engineer and its output recorded; draft written to .codeo/116/plan-draft.md (10 tasks), awaiting approval · cost: unavailable (mid-turn)
- 2026-11-16 — planned: docs/plans/2026-11-16-follow-ups-70-71-104-107.md · cost: 592m · fable-5-2 140k in + 355k cached / 846 out · sonnet-5-5 329k in + 2.3M cached / 30k out
