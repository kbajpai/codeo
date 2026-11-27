# Issue #206 — plan

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/206 |
| Branch | `fix/206-codeo-cleanup-prints-codeo-rm` |
| Updated | 2026-11-27 |

## Where this stands

Round 2, after a send-back from `/codeo:qc` round 1 (`qc.md`: F1 and F2 blocking, F3 non-blocking and the plan's, F4-F7 non-blocking and `/codeo:implement`'s). The plan's premise that `intake.sh commit` only adds files is false, so two engineers' records can delete each other (root cause in `qc.md`). Q10-Q12 are open; nothing is drafted until they are answered. Round 1's plan, `docs/plans/2026-11-27-cleanup-removal-records-206.md`, is built and stays as history.

## Questions

### Q1 — Which leftover text in `command:` and `fallback:` makes the script refuse?

**Why it matters:** it decides which overlays stop working. The check runs once, before any issue is listed, on `command:` and `fallback:` after `{N}` and `{name}` are taken out; a hit ends the run with exit 1 and one line, `cleanup: the overlay's command: keeps a placeholder the script does not expand: {M}`, and nothing is printed.

- A `{word}` token only (letters, digits, `_`). `{M}`, `{n}` and `{issue}` are refused. `docker ps --format {{.Names}}` passes and prints its braces. The cost: `${HOME}` is refused too, so such an overlay writes `$HOME`.
- Any `{` or `}` at all. Simpler to state, and no printed line ever holds a brace. The cost: an overlay can never use a Go template or a shell brace.

Either way this project's overlay and the shipped template print no brace, and a test pins both. I recommend the `{word}` token.

**Options:** `{word}` token only (recommended) · any brace · no preference, you pick.

**Answer:**
`{word}` token only, as recommended. Given in the conversation: "go with your picks".

### Q2 — What shape is the removal record on the intake branch?

**Why it matters:** it decides whether `intake.sh` changes and how two engineers' records merge.

- One file per issue, `.codeo/intake/cleanup/removed/<N>.md` (the date and who recorded it). `intake.sh commit cleanup` already rebuilds on origin's tip and adds only the files this clone has, so two engineers recording different issues both keep their files with no change to `intake.sh`; the same issue recorded twice is one file, whichever push is last. `cleanup.sh` reads the file names from `origin/codeo/intake` after the fetch it already makes.
- One ledger file, `.codeo/intake/cleanup/removed.md`, one row per issue. It needs a union merge in `intake.sh` like the triage ledger's (`merge_ledger`), or the later push drops the earlier rows.
- Read the dated run records (`2026-11-27-2.md`). No new file, but those are prose the skill wrote, and parsing them is fragile.

I recommend one file per issue.

**Options:** one file per issue (recommended) · one ledger file with a merge · parse the dated records · no preference, you pick.

**Answer:**
One file per issue, as recommended. Given in the conversation: "go with your picks".

### Q3 — How does an engineer record a removal?

**Why it matters:** it decides whether the script gains a second mode and what the skill's new step says.

- `cleanup.sh record <N>…`, run by the skill when the engineer says which issues they removed ("I removed 34 36 39", or "all of the proven ones", for which the skill passes the numbers the script just printed as proven). The script refuses a number that is not under `.codeo/done/` on the base branch, writes the files and prints one line per issue; the skill then commits with `intake.sh commit cleanup`, as it does for the run record. It runs no proof: a record for an unproven issue hides nothing, because the issue is still listed as not proven (acceptance criterion 4).
- The skill writes the files itself, with no script change. The cost: the file name and body are built in the skill, which is what rule cleanup-04 keeps out of it for commands.

In both, a record means "removed on every host that had it", and the skill and docs say so; there is no undo command (a wrong record only hides a line, and the file can be dropped from the intake branch by hand). I recommend the script subcommand.

**Options:** `cleanup.sh record <N>…` (recommended) · the skill writes the files · no preference, you pick.

**Answer:**
`cleanup.sh record <N>…`, as recommended. Given in the conversation: "go with your picks".

### Q4 — Does a recorded issue still get its `leftover` line?

**Why it matters:** a recorded issue can still have `codeo-live/<N>/<machine>` branches on origin; the record is about the container, and the branches are something the script sees for itself.

- Still printed: a recorded, proven issue prints no `proven` line but keeps its `leftover` line while the branches exist. The line goes away when the branches do.
- Dropped with the rest: a recorded issue prints nothing at all, and its live-signal branches stay on origin unlisted.

I recommend still printing it.

**Options:** still printed (recommended) · dropped · no preference, you pick.

**Answer:**
Still printed, as recommended. Given in the conversation: "go with your picks".

### Q5 — Does a run say how many recorded issues it left out?

**Why it matters:** without it a run that hides 64 issues looks the same as one that found none, and a wrong record is invisible.

- One line on stderr, exit 0: `cleanup: note: 64 issues with a recorded removal are not listed`. Stdout keeps its one format (`<N>` TAB kind TAB …), and the skill relays the note under the lists.
- Nothing is said.
- One stdout line per recorded issue, `<N>` TAB `removed`. Complete, but the list grows with every merge again, which is the fault being fixed.

I recommend the stderr note.

**Options:** stderr note (recommended) · nothing · one stdout line per issue · no preference, you pick.

**Answer:**
The stderr note, as recommended. Given in the conversation: "go with your picks".

### Q6 — #204 is in flight and its footprint overlaps this plan's. Proceed, sequence, or re-scope?

**Why it matters:** #204 (`chore/204-fix-codeo-close-opens-pr`, assignee kbajpai, step `init`, waiting on its own plan.md Q1-Q2) lists `docs/skills.md`, `docs/skills-inventory.md`, `README.md`, `CHANGELOG.md` and `glob:tests/**`. This plan changes the `## cleanup` section of `docs/skills.md`, the README's cleanup text, one `CHANGELOG.md` bullet, `tests/cleanup.test.sh`, `tests/cleanup-skill.test.sh` and `tests/readme.test.sh`, and `docs/skills-inventory.md` with `tests/inventory.test.sh` only if a new rule is added to the skill. The sections differ from #204's (close, triage, init), so a merge conflict is likely only in `CHANGELOG.md`'s Unreleased list.

**Options:** proceed and coordinate (recommended) · sequence after #204 · re-scope.

**Answer:**
Proceed and coordinate, as recommended. Given in the conversation: "go with your picks".

### Q7 — #195 is in flight and its footprint overlaps this plan's. Proceed, sequence, or re-scope?

**Why it matters:** #195 (`feat/195-identify-acting-user-strictly-verify`, assignee kbajpai, step `plan` done, waiting on `/codeo:implement`) lists `docs/skills.md`, `docs/skills-inventory.md`, `README.md`, `CHANGELOG.md` and `glob:tests/**`; it does not list `scripts/cleanup.sh`, `skills/cleanup/**` or `scripts/intake.sh`. The shared paths are the same as in Q6, in other sections; `CHANGELOG.md`'s Unreleased list is the likely conflict.

**Options:** proceed and coordinate (recommended) · sequence after #195 · re-scope.

**Answer:**
Proceed and coordinate, as recommended. Given in the conversation: "go with your picks".

### Q8 — #204 overlaps on `glob:CHANGELOG.md`, `glob:README.md` and `glob:docs/skills.md`: proceed, sequence, or re-scope?

**Why it matters:** this is Q6's decision, restated with the tokens `overlap.sh` printed for the committed footprint (Q6 named the paths without the `glob:` form, so the script did not count it as raised). #204 (`chore/204-fix-codeo-close-opens-pr`, assignee kbajpai, step `init`) and this plan both edit those three files, in different sections.

**Options:** proceed and coordinate (recommended) · sequence after #204 · re-scope.

**Answer:**
Proceed and coordinate, as Q6 was answered. Given in the conversation: "go with your picks" (the same decision as Q6, restated here only so the overlap check reads it).

### Q9 — #195 overlaps on `glob:CHANGELOG.md`, `glob:README.md` and `glob:docs/skills.md`: proceed, sequence, or re-scope?

**Why it matters:** Q7's decision, restated the same way. #195 (`feat/195-identify-acting-user-strictly-verify`, assignee kbajpai, step `plan` done) and this plan both edit those three files, in different sections.

**Options:** proceed and coordinate (recommended) · sequence after #195 · re-scope.

**Answer:**
Proceed and coordinate, as Q7 was answered. Given in the conversation: "go with your picks" (the same decision as Q7, restated here only so the overlap check reads it).

### Q10 — How does `intake.sh commit` stop deleting files its clone lacks?

**Why it matters:** this is the blocking finding F1 in `qc.md`. `intake.sh`'s `build` runs `git add -f -- <dir>` on a tree it just read from origin's tip; with git 2.x a directory pathspec also stages the deletion of every file under it that the committing clone's working tree lacks (confirmed on git 2.53.0). So a commit replaces the directory with the committing clone's copy: records another engineer pushed since this clone last restored are deleted, and the retry after a refused push rebuilds from the same working tree and deletes them reliably. The comment at `scripts/intake.sh:176-177` says the code means "no -A". The choice sets which commands change and which files and tests the plan's footprint gains (`scripts/intake.sh`, `tests/intake.test.sh`).

- Add `--ignore-removal` to the `git add` in `build`, for every caller. A commit then adds and updates files and never deletes one unless `--drop` names it (rename and lease release already delete that way, before the add). It also stops a stale clone deleting the dated run records and triage records, which is the same bug today. The cost: a dossier file deleted from a working tree stays on the intake branch until someone drops it.
- The same flag only when `<dir>` is `cleanup`. The cost: a special case in a shared script, and the other directories keep the bug.
- Leave `build` alone and make `cleanup.sh record` and the skill's run-record commit restore from origin's tip immediately before every commit, with a restore inside `commit`'s retry loop. The cost: it is a race narrowed, not removed, between the restore and the push, and it moves intake logic into the cleanup skill.

I recommend the flag for every caller.

**Options:** flag for every caller (recommended) · flag for `cleanup` only · restore before each commit · no preference, you pick.

**Answer:**

### Q11 — Is there an undo for a recorded removal?

**Why it matters:** this is F2. `docs/skills.md` says to delete the file from `codeo/intake` by hand, and that does not hold: any clone that holds a copy adds it back at its next `intake.sh commit cleanup`, which the skill runs every time. Whichever way it goes decides whether the script gains a command and what the docs say.

- No undo command; the documentation says a wrong record is corrected by deleting `.codeo/intake/cleanup/removed/<N>.md` from the intake branch and from every clone that holds a copy, and that a clone still holding it adds it back. Smallest, and true.
- `cleanup.sh unrecord <N>…`, which removes the local file and commits it away with `--drop`. A stale clone can still bring the file back, so it is no more reliable than the by-hand removal, with more code to keep.

I recommend no undo command.

**Options:** no undo command (recommended) · `cleanup.sh unrecord` · no preference, you pick.

**Answer:**

### Q12 — Does the placeholder check look at the text the script prints?

**Why it matters:** this is F3 (non-blocking). The check removes `{N}` and `{name}` and then looks for leftovers, while the script prints the expanded text, so `command: rm {{N}}` passes the check and prints `rm {12}`, `{{N}name}` prints `{12name}`, and `name: x-{M}` with a permissive `pattern:` puts `{M}` into the printed command. `docs/extension-points.md` says any other `{word}` token stops the run, which is too strong for the check as written.

- Expand `name`, `command` and `fallback` once up front with a sample issue number (`1`) and look for `\{[A-Za-z0-9_]+\}` in that text. It covers all three cases above, `{{.Names}}` still passes, `${HOME}` is still refused, and the documented sentence becomes true. The cost: a few more lines in the check.
- Keep the check as built and narrow the sentence in `docs/extension-points.md` to what it does.

I recommend checking the expanded text.

**Options:** check the expanded text (recommended) · keep the check and narrow the documentation · no preference, you pick.

**Answer:**

## Notes

- The intake branch has no removal record `cleanup.sh` can read yet. Once this ships and the pin is bumped, the 64 issues of `.codeo/intake/cleanup/2026-11-27-2.md` are recorded by the engineer through the new step; the pull request does not write to `codeo/intake`.
- Recorded issues still cost their proofs on every run (two GitHub reads each): acceptance criterion 4 needs the proofs to run before a record may hide a line.
- No overlay is set for `plan/plan-shape`, `plan/proof-of-done` or `plan/wiki-rules` (exit 3 each); no invariants document, no shared environment, no `wiki` module, no `resources[]`.

## Outcome

**Plan:** `docs/plans/2026-11-27-cleanup-removal-records-206.md`, approved by the engineer and left unstaged. Shape: an executable plan under `docs/plans/` (five checkbox tasks, each proved by `bash tests/run.sh`, the `shell` suite having no `filter`); no separate reference doc.

**Decisions** (Q1-Q9, every recommendation taken: "go with your picks"):
- The `{N}` fault was already half fixed in v1.0.9. What is added is the refusal: `command:` and `fallback:` may hold only `{N}` and `{name}`, and any other `{word}` token (`${HOME}` too, not `{{.Names}}`) exits 1 with one `cleanup:` line. The fix lives in the script, not the overlay text. A test pins this project's overlay and the shipped template as brace-free (Q1).
- Removal records are one file per issue, `.codeo/intake/cleanup/removed/<N>.md`, on `codeo/intake`; `intake.sh` is unchanged because `intake.sh commit` already keeps other clones' files (Q2).
- `cleanup.sh record <N>…` writes them and never commits; the skill commits through `intake.sh`. It validates every number before writing any (Q3).
- A recorded issue hides only when every proof passes; a failed proof, or a failed `name`, still lists it. A recorded issue keeps its `leftover` line (Q4). A stderr note counts what was hidden (Q5).
- Overlap with #204 and #195 on `README.md`, `CHANGELOG.md` and `docs/skills.md`: proceed and coordinate (Q6-Q9).

**Rejected:** refusing any brace; a single ledger file with a merge in `intake.sh`; parsing the dated run records; the skill writing the files itself; dropping a recorded issue's leftover line; saying nothing about hidden issues; sequencing after #204 or #195.

**Documentation moved:** `docs/skills.md` (`## cleanup`), `docs/extension-points.md` (`cleanup/removal-command`), `README.md` (the `role stale` entry and the skills table row), `CHANGELOG.md` (one bullet and the `Shared state:` line). `.devcontainer/README.md`, `docs/container-templates.md` and `docs/skills-inventory.md` need no change; no rule marker is added.

**Intake questions resolved:** the one left to plan at intake, whether the placeholder fix lives in the script or the overlay text: the script (Q1).

### Footprint

```
files:      scripts/cleanup.sh, skills/cleanup/SKILL.md, docs/skills.md, docs/extension-points.md, README.md, CHANGELOG.md, tests/cleanup.test.sh, tests/cleanup-skill.test.sh, docs/plans/2026-11-27-cleanup-removal-records-206.md
wiki:       none
exclusive:  none
sequenced:  none
```

## Log

- 2026-11-27 — Q1-Q7 raised · cost: 2m · fable-5-2 87k in + 649k cached / 8k out
- 2026-11-27 — Q1-Q7 answered ("go with your picks"); draft written, footprint committed · cost: not recorded when written
- 2026-11-27 — planned: docs/plans/2026-11-27-cleanup-removal-records-206.md · cost: 8m · fable-5-2 103k in + 1M cached / 13k out · sonnet-5-5 135k in + 1.6M cached / 26k out
- 2026-11-27 — round 2 after a send-back from qc.md round 1: Q10-Q12 raised · cost: 1m · sonnet-5-5 658 in + 592k cached / 2k out
