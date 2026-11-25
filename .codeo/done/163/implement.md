# Issue #163 — implement

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/163 |
| Branch | `fix/close-152-leftovers-cleanup-overlay` |
| Updated | 2026-11-25 |

## Where this stands

Round 1 done: all five plan tasks are built, committed and reviewed; the build passes. Next step: `/codeo:qc`.

## Questions

### Q1 — `#166` and `glob:CHANGELOG.md`: proceed, sequence, or re-scope?

**Why it matters:** #166 (branch `docs/close-157-leftovers-hosted-web`, assignee kbajpai, step plan (working), waits on `/codeo:implement`) lists `CHANGELOG.md` in its footprint, and so does this plan. This plan adds a sentence and a bullet under `## Unreleased`; #166 will add its own bullets there. Whichever merges second rebases and keeps both sides; sequencing makes this issue wait for #166's plan, then its code.
**Options:** *proceed and coordinate* (my pick) · *sequence after #166* · *re-scope* (say what to leave out of `CHANGELOG.md`).

**Answer:**
Proceed and coordinate. (Engineer: "go with your picks", 2026-11-25; given in the conversation, recorded here.)

### Q2 — `#166` and `glob:docs/skills.md`: proceed, sequence, or re-scope?

**Why it matters:** #166 (branch `docs/close-157-leftovers-hosted-web`, assignee kbajpai, step plan (working), waits on `/codeo:implement`) lists `docs/skills.md` in its footprint, and so does this plan. This plan adds one sentence to the `/codeo:cleanup` section; #166 also edits `docs/skills.md` and `scripts/cleanup.sh`, whose cleanup behaviour that section describes. Whichever merges second rebases and keeps both sides; sequencing makes this issue wait for #166's plan, then its code.
**Options:** *proceed and coordinate* (my pick) · *sequence after #166* · *re-scope* (say what to leave out of `docs/skills.md`).

**Answer:**
Proceed and coordinate. (Engineer: "go with your picks", 2026-11-25; given in the conversation, recorded here.)

### Q3 — `#166` and `glob:tests/cleanup-skill.test.sh`: proceed, sequence, or re-scope?

**Why it matters:** #166 (branch `docs/close-157-leftovers-hosted-web`, assignee kbajpai, step plan (working), waits on `/codeo:implement`) lists `tests/cleanup-skill.test.sh` in its footprint, and so does this plan. This plan adds a `for needle` loop after the fallback assertion at `:97`; #166 changes `skills/cleanup/SKILL.md` and may edit the same file. Whichever merges second rebases and keeps both sides; sequencing makes this issue wait for #166's plan, then its code.
**Options:** *proceed and coordinate* (my pick) · *sequence after #166* · *re-scope* (say what to leave out of `tests/cleanup-skill.test.sh`).

**Answer:**
Proceed and coordinate. (Engineer: "go with your picks", 2026-11-25; given in the conversation, recorded here.)

### Q4 — `#166` and `glob:tests/close-removal.test.sh`: proceed, sequence, or re-scope?

**Why it matters:** #166 (branch `docs/close-157-leftovers-hosted-web`, assignee kbajpai, step plan (working), waits on `/codeo:implement`) lists `tests/close-removal.test.sh` in its footprint, and so does this plan. This plan adds four needles to the list at `:20`; #166 also edits `.codeo/overlays/close.md`, which that test reads, and `skills/close/SKILL.md`. Whichever merges second rebases and keeps both sides; sequencing makes this issue wait for #166's plan, then its code.
**Options:** *proceed and coordinate* (my pick) · *sequence after #166* · *re-scope* (say what to leave out of `tests/close-removal.test.sh`).

**Answer:**
Proceed and coordinate. (Engineer: "go with your picks", 2026-11-25; given in the conversation, recorded here.)

## Notes

None.

## Outcome

Built from `docs/plans/2026-11-25-close-152-leftovers-cleanup-overlay-163.md` (committed `50b2b80`). Every task had a sonnet implementer and a sonnet task review; one whole-branch review followed, with no Critical or Important finding.

| Task | What was built | Commit |
|---|---|---|
| 1 | `codeo-track.sh`: `new_tmp` sets `tmp_file` in the calling shell, so the `EXIT` trap removes it; case `no_temp_file_left` in `tests/track.test.sh` (failed before the fix with 3 files left, passes after; mutation shown) | `2983740` |
| 2 | Both overlays' by-hand fallback: adds `docker rmi codeo-dev:<name>`, says `mark` runs on the host that created the container and not inside one, names `bash codeo-sandbox.sh end <N>` for a sandbox; pins in `tests/cleanup-skill.test.sh` and `tests/close-removal.test.sh` | `4f3446b` |
| 3 | `CHANGELOG.md`: a pin at v1.0.8 or earlier prints `codeo rm {N}` as written and no fallback; one new bullet | `36286e5` |
| 4 | `README.md` F16-F19: a local container of that name is refused, the uses of `jq`, the guard wording and an example with #12, a "keeping it current" list; then the hooks' use of `jq` added after review | `9a8eb5f`, `b34ed1c` |
| 5 | `docs/skills.md`: the cleanup section names the overlay's fourth field and `fallback:` | `2af0260` |

**Documentation pages changed:** `CHANGELOG.md`, `README.md`, `docs/skills.md`.

**Build:** the `shell` suite's build command is `true`; it exits 0. After the merge below, `bash tests/run.sh` also ended `all cases passed` (run once to confirm the merged tree; grading it is `/codeo:qc`'s).

**Base branch:** `sync-main.sh` merged `origin/main` (#166's merge, `6b3fb6e`) into the branch with one conflict, `docs/skills.md`'s cleanup paragraph, resolved in `e70b600`: #166's wording ("no container command (one that failed only `name` still gets its leftover branch delete)") kept, and this issue's fourth-field sentence added after it. `CHANGELOG.md` and `.codeo/overlays/close.md` merged without conflict. `overlap.sh 163` printed nothing after the merge. Q1-Q4 (the #166 overlap) were answered *proceed and coordinate*.

**Deviations from the plan:**
- The plan said Task 4 ends with its commit; a review found the README's jq sentence omitted the hooks (`hooks/subagent-model.sh` exits 127 without `jq`, `hooks/live-signal.sh` exits 0 silently), so `b34ed1c` adds them, and changes "stop without it" to "stop without it, except the guard and the hooks".
- Task 1's failed-save sub-case exits 3 at the read and never reaches `save`; it stays with its rc assertion and adds no temp-file coverage (the three successful runs carry F15).

**Parked, not fixed (Minor):** the close overlay's sandbox clause reads as "; and (a sandbox is ended with …)" and omits "from the folder that holds the script", which the cleanup overlay's has (`.codeo/overlays/close.md`, the finished-close container paragraph); `tests/track.test.sh` unsets `TMPDIR` instead of restoring it after the new case.

No lease, no environment, no deployed revision: the project has no shared environment.

## Log

- 2026-11-25 — Q1-Q4 raised (overlap with #166) · cost: 1m · sonnet-5-5 12k in + 693k cached / 1k out

## Log

- 2026-11-25 — Q1-Q4 raised (overlap with #166) · cost: 1m · sonnet-5-5 12k in + 693k cached / 1k out
- 2026-11-25 — implemented: plan tasks 1-5 and one README fix, merged origin/main (#166) · cost: 67m · sonnet-5-5 640k in + 21.4M cached / 86k out
