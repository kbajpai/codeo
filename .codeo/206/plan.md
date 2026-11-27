# Issue #206 — plan

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/206 |
| Branch | `fix/206-codeo-cleanup-prints-codeo-rm` |
| Updated | 2026-11-27 |

## Where this stands

Round 1. The code, tests, docs and the intake branch are read. Q1-Q7 are open; nothing is drafted until they are answered. One finding changes the size of the first fault: `scripts/cleanup.sh` already expands `{N}` in `command:` (line 104, shipped in v1.0.9 with #152; the issue's run used plugin 1.0.8). What is left of that fault is the refusal of a placeholder the script does not know (Q1) and a test that pins this project's own overlay.

## Questions

### Q1 — Which leftover text in `command:` and `fallback:` makes the script refuse?

**Why it matters:** it decides which overlays stop working. The check runs once, before any issue is listed, on `command:` and `fallback:` after `{N}` and `{name}` are taken out; a hit ends the run with exit 1 and one line, `cleanup: the overlay's command: keeps a placeholder the script does not expand: {M}`, and nothing is printed.

- A `{word}` token only (letters, digits, `_`). `{M}`, `{n}` and `{issue}` are refused. `docker ps --format {{.Names}}` passes and prints its braces. The cost: `${HOME}` is refused too, so such an overlay writes `$HOME`.
- Any `{` or `}` at all. Simpler to state, and no printed line ever holds a brace. The cost: an overlay can never use a Go template or a shell brace.

Either way this project's overlay and the shipped template print no brace, and a test pins both. I recommend the `{word}` token.

**Options:** `{word}` token only (recommended) · any brace · no preference, you pick.

**Answer:**

### Q2 — What shape is the removal record on the intake branch?

**Why it matters:** it decides whether `intake.sh` changes and how two engineers' records merge.

- One file per issue, `.codeo/intake/cleanup/removed/<N>.md` (the date and who recorded it). `intake.sh commit cleanup` already rebuilds on origin's tip and adds only the files this clone has, so two engineers recording different issues both keep their files with no change to `intake.sh`; the same issue recorded twice is one file, whichever push is last. `cleanup.sh` reads the file names from `origin/codeo/intake` after the fetch it already makes.
- One ledger file, `.codeo/intake/cleanup/removed.md`, one row per issue. It needs a union merge in `intake.sh` like the triage ledger's (`merge_ledger`), or the later push drops the earlier rows.
- Read the dated run records (`2026-11-27-2.md`). No new file, but those are prose the skill wrote, and parsing them is fragile.

I recommend one file per issue.

**Options:** one file per issue (recommended) · one ledger file with a merge · parse the dated records · no preference, you pick.

**Answer:**

### Q3 — How does an engineer record a removal?

**Why it matters:** it decides whether the script gains a second mode and what the skill's new step says.

- `cleanup.sh record <N>…`, run by the skill when the engineer says which issues they removed ("I removed 34 36 39", or "all of the proven ones", for which the skill passes the numbers the script just printed as proven). The script refuses a number that is not under `.codeo/done/` on the base branch, writes the files and prints one line per issue; the skill then commits with `intake.sh commit cleanup`, as it does for the run record. It runs no proof: a record for an unproven issue hides nothing, because the issue is still listed as not proven (acceptance criterion 4).
- The skill writes the files itself, with no script change. The cost: the file name and body are built in the skill, which is what rule cleanup-04 keeps out of it for commands.

In both, a record means "removed on every host that had it", and the skill and docs say so; there is no undo command (a wrong record only hides a line, and the file can be dropped from the intake branch by hand). I recommend the script subcommand.

**Options:** `cleanup.sh record <N>…` (recommended) · the skill writes the files · no preference, you pick.

**Answer:**

### Q4 — Does a recorded issue still get its `leftover` line?

**Why it matters:** a recorded issue can still have `codeo-live/<N>/<machine>` branches on origin; the record is about the container, and the branches are something the script sees for itself.

- Still printed: a recorded, proven issue prints no `proven` line but keeps its `leftover` line while the branches exist. The line goes away when the branches do.
- Dropped with the rest: a recorded issue prints nothing at all, and its live-signal branches stay on origin unlisted.

I recommend still printing it.

**Options:** still printed (recommended) · dropped · no preference, you pick.

**Answer:**

### Q5 — Does a run say how many recorded issues it left out?

**Why it matters:** without it a run that hides 64 issues looks the same as one that found none, and a wrong record is invisible.

- One line on stderr, exit 0: `cleanup: note: 64 issues with a recorded removal are not listed`. Stdout keeps its one format (`<N>` TAB kind TAB …), and the skill relays the note under the lists.
- Nothing is said.
- One stdout line per recorded issue, `<N>` TAB `removed`. Complete, but the list grows with every merge again, which is the fault being fixed.

I recommend the stderr note.

**Options:** stderr note (recommended) · nothing · one stdout line per issue · no preference, you pick.

**Answer:**

### Q6 — #204 is in flight and its footprint overlaps this plan's. Proceed, sequence, or re-scope?

**Why it matters:** #204 (`chore/204-fix-codeo-close-opens-pr`, assignee kbajpai, step `init`, waiting on its own plan.md Q1-Q2) lists `docs/skills.md`, `docs/skills-inventory.md`, `README.md`, `CHANGELOG.md` and `glob:tests/**`. This plan changes the `## cleanup` section of `docs/skills.md`, the README's cleanup text, one `CHANGELOG.md` bullet, `tests/cleanup.test.sh`, `tests/cleanup-skill.test.sh` and `tests/readme.test.sh`, and `docs/skills-inventory.md` with `tests/inventory.test.sh` only if a new rule is added to the skill. The sections differ from #204's (close, triage, init), so a merge conflict is likely only in `CHANGELOG.md`'s Unreleased list.

**Options:** proceed and coordinate (recommended) · sequence after #204 · re-scope.

**Answer:**

### Q7 — #195 is in flight and its footprint overlaps this plan's. Proceed, sequence, or re-scope?

**Why it matters:** #195 (`feat/195-identify-acting-user-strictly-verify`, assignee kbajpai, step `plan` done, waiting on `/codeo:implement`) lists `docs/skills.md`, `docs/skills-inventory.md`, `README.md`, `CHANGELOG.md` and `glob:tests/**`; it does not list `scripts/cleanup.sh`, `skills/cleanup/**` or `scripts/intake.sh`. The shared paths are the same as in Q6, in other sections; `CHANGELOG.md`'s Unreleased list is the likely conflict.

**Options:** proceed and coordinate (recommended) · sequence after #195 · re-scope.

**Answer:**

## Notes

- The intake branch has no removal record `cleanup.sh` can read yet. Once this ships and the pin is bumped, the 64 issues of `.codeo/intake/cleanup/2026-11-27-2.md` are recorded by the engineer through the new step; the pull request does not write to `codeo/intake`.
- Recorded issues still cost their proofs on every run (two GitHub reads each): acceptance criterion 4 needs the proofs to run before a record may hide a line.
- No overlay is set for `plan/plan-shape`, `plan/proof-of-done` or `plan/wiki-rules` (exit 3 each); no invariants document, no shared environment, no `wiki` module, no `resources[]`.

## Outcome

_Pending — written at the hand-off._

## Log

- 2026-11-27 — Q1-Q7 raised · cost: 2m · fable-5-2 87k in + 649k cached / 8k out
