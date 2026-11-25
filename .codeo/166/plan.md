# Issue #166 — plan

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/166 |
| Branch | `docs/close-157-leftovers-hosted-web` |
| Updated | 2026-11-24 |

## Where this stands

Q1-Q3 are answered (the picks). The plan is drafted at `.codeo/166/plan-draft.md` and awaits approval.

What I found (read at `5207e1e`):

- **F12.** `skills/close/SKILL.md:537` (step 17, default `host: web` bullet) says "nothing to remove: the hosted session is done once the engineer closes it". `live.sh sweep` returns at once when the host is web (`scripts/live.sh:240`), and `read_lock` makes the host web whenever `CLAUDE_CODE_REMOTE=true` (`:175`), so a `host: local` lock in a hosted session ends the same way with the `:543` bullet. `tests/close-skill.test.sh:222,225` pin only the two bullet labels.
- **The default bullets are not what this repository's sessions read.** `.codeo/overlays/close.md` has a `host-workflow` section, so `overlay.sh close host-workflow` exits 0 here and step 17 relays the overlay, whose last-but-one paragraph says "For any other host there is nothing to remove: say so" (pinned by `tests/close-removal.test.sh:21`). A fix made only inside the two default bullets would not reach a project with an overlay.
- **`live.sh` has no subcommand that prints a label or lists branches** (`beat`, `clear`, `sweep`, `fetch`, `list`). A web session can read origin's branches; it cannot delete one.
- **F13.** `skills/close/SKILL.md:3` and `docs/skills.md:185` say close "sweeps the issue's leftover live-signal branches" with no exception. `tests/live-signal.test.sh:232` pins that phrase in the `## close` section of `docs/skills.md`, so a reword has to keep it or move the pin.
- **F8.** `scripts/cleanup.sh:134` is `[[ $out == name ]] || leftover_proof "$n"`: an issue that passed the five finish proofs and failed only `name` gets `<N> failed name` and no `leftover` line. The fix is one line, with a new case in `tests/cleanup.test.sh` (a `set_overlay` body without `pattern:` makes `name` fail). The script header (`:7-13`), `skills/cleanup/SKILL.md` step 1 (`:46`), `docs/skills.md:252,258` and the #157 bullet under `CHANGELOG.md` `## Unreleased` all say "a proven issue", and rule `cleanup-02` says an issue that failed a proof gets no command: see Q2.
- The `shell` suite has no `filter`; each task's proof is `bash tests/run.sh <name>`, then the whole `bash tests/run.sh`.
- **In flight:** #161 (two branches, step `qc`, verdict clear, waits on `/codeo:close`) lists `CHANGELOG.md` and `tests/live-signal.test.sh`: see Q3. #163 (`fix/close-152-leftovers-cleanup-overlay`, kbajpai, step `init`) has no footprint and has changed nothing yet, so there is nothing to compare; its title suggests the cleanup overlay, which this plan does not edit.

My calls, stated so they can be corrected (not questions):

- One plan under `docs/plans/`, one pull request, no reference doc.
- **Step 17's new text sits outside the default bullets**, as a sentence that holds on the finished exit whatever the overlay printed, for a lock whose `host` is `web` and for any lock when `CLAUDE_CODE_REMOTE` is `true`. The `host: web` bullet is reworded so that it speaks of the checkout only. The `host: local` bullet keeps its text: it is true outside a hosted session, and the new sentence covers the hosted one.
- **This project's overlay line** becomes "For any other host there is no checkout to remove: say so", and the pin in `tests/close-removal.test.sh` follows. Without it a hosted close in this repository would still relay "nothing to remove".
- **F13:** both sentences gain the clause "(a hosted web session deletes none, since it cannot delete a branch)", the wording the CHANGELOG already uses; the pinned phrase stays.
- The new pins go in `tests/close-skill.test.sh` and `tests/cleanup.test.sh`, not `tests/live-signal.test.sh`, unless Q3 says otherwise.
- The `engineering` plugin is not installed here; no new component or technology choice is involved.

## Questions

### Q1 — F12, step 17 in a hosted web session: a fixed sentence with the command's form, or the exact command from a new `live.sh` subcommand?

**Why it matters:** it decides whether this issue stays prose and test pins or adds code to `scripts/live.sh`, and whether the engineer reads a command they can paste or one with a placeholder.
**Options:**
- **A — a fixed sentence (my pick).** Step 17 says that the session's live-signal branch stays on origin because a hosted session cannot delete a branch, names `git push origin --delete codeo-live/<issue>/<machine>` with the lock's issue filled in and `<machine>` left as written, says it runs outside the web session, and says `/codeo:cleanup` prints the exact command once the issue is finished. No code. The sentence is said in every hosted close, also in the rare one whose branch is already gone. It matches the criterion's wording, which names the command with its placeholders.
- **B — a new `live.sh leftover` subcommand.** It lists the issue's `codeo-live/<issue>/*` branches on origin with the same name filter as `sweep` and prints one `git push origin --delete …` line, or nothing. Step 16 runs it before the lock goes and step 17 relays its output. The command is exact, and a failed sweep outside a web session is reported too. It adds a subcommand, its tests, and lines in `docs/handoff.md` and the CHANGELOG, and it is the larger change for a non-blocking finding.

**Answer:**
A — a fixed sentence in step 17, no new `live.sh` subcommand. (Engineer: "go with your picks", 2026-11-24; given in the conversation, recorded here.)

### Q2 — F8, a `leftover` line after `failed name`: reword rule `cleanup-02`, or leave it?

**Why it matters:** the third criterion makes `cleanup.sh` print a `leftover` command for an issue whose only failed proof is `name`. Rule `cleanup-02` in `skills/cleanup/SKILL.md` reads "A removal command is printed only for an issue the script proved. An issue that failed a proof gets no command, however finished it looks." Rewording a rule-marked paragraph also changes `docs/skills-inventory.md` and `tests/fixtures/skills-inventory.rules.sha256`.
**Options:**
- **A — reword the rule's second sentence (my pick).** It becomes: an issue that failed a proof gets no removal command, however finished it looks; the one command it can get is the `leftover` branch delete, and only when `name` is the proof that failed, since the five proofs that it is finished passed. The inventory line and the checksum follow. The skill then lists such an issue under Not proven and its line under Leftover web signal branches.
- **B — leave the rule as written.** Read "removal command" as the container command only, and change the step's prose around the rule, the script header and `docs/skills.md`. No inventory or checksum change, but the rule's second sentence then says "no command" beside a script that prints one.

**Answer:**
A — reword the second sentence of rule `cleanup-02`; the inventory line and checksum follow. (Engineer: "go with your picks", 2026-11-24; given in the conversation, recorded here.)

### Q3 — #161 lists `CHANGELOG.md`, which this plan edits: proceed, sequence, or re-scope?

**Why it matters:** #161 (branches `claude/ecstatic-mendel-n3qyzl` and `docs/documentation-leftovers-154-146-removal`, assignee kbajpai, step `qc`, verdict clear, waits on `/codeo:close`) has `CHANGELOG.md` in its footprint and its changed files. This plan edits one bullet there: the #157 line under `## Unreleased` that says `/codeo:cleanup` prints the delete command "for a proven issue's leftovers", which F8 widens to an issue that failed only `name`. #161 also lists `tests/live-signal.test.sh`, which this plan leaves alone by my call above. Whoever merges second rebases one section of one file.
**Options:** *proceed and coordinate* (my pick: #161 is one step from merging, and this edit is one clause in one bullet) · *sequence after #161* (this plan waits for #161 to merge) · *re-scope* (leave `CHANGELOG.md` out; the bullet then still says "a proven issue").

**Answer:**
Proceed and coordinate: whoever merges second rebases `CHANGELOG.md` and keeps both sides. (Engineer: "go with your picks", 2026-11-24; given in the conversation, recorded here.)

## Notes

### Footprint

```
files:      scripts/cleanup.sh, skills/cleanup/SKILL.md, skills/close/SKILL.md, docs/skills.md, docs/skills-inventory.md, .codeo/overlays/close.md, CHANGELOG.md, tests/cleanup.test.sh, tests/cleanup-skill.test.sh, tests/close-skill.test.sh, tests/close-removal.test.sh, tests/fixtures/skills-inventory.rules.sha256, docs/plans/2026-11-25-close-157-leftovers-166.md, .codeo/166/**
wiki:       none
exclusive:  none
sequenced:  none
```
None.

## Outcome

_Pending — written at the hand-off._

## Log

- 2026-11-24 — Q1-Q3 raised · cost: 1m · fable-5-2 82k in + 533k cached / 5k out
