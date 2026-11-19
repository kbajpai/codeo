# Issue #132 — plan

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/132 |
| Branch | `fix/fix-test-suite-gaps-left` |
| Updated | 2026-11-19 |

## Where this stands

Planned. Q1-Q3 answered, plan approved and saved; next step is `/codeo:implement`.
need no answer (see `## Notes`): the `role.test.sh` case is renamed, and the two
`close-skill.test.sh` pins each get a paragraph-scoped helper. #118 has merged (`9f14461`), so
the intake note "plan this after #118 merges" is satisfied.

## Questions

### Q1 — `tests/live.test.sh` is already fixed on `main` by #131: verify only, or add something?

**Why it matters:** half of this issue (criteria 4, 5 and 6) was done by #131's Task 2 (commit
`df2cdf9`), after #130 was filed. All three stamp assertions (`tests/live.test.sh:229`, `:236`,
`:374-379`) now read `git -C "$clone" rev-parse --path-format=absolute --git-path codeo-live-beat`,
and the `|| -e $stamp` half is gone. In this checkout, which has its own `.git/codeo-live-beat`,
`bash tests/live.test.sh` ends `all cases passed`. The answer decides whether the plan has a
`live.test.sh` task that edits the file, or one that only proves the three criteria and records it.
**Options:**
- **Verify only (recommended).** One task, no edit to `tests/live.test.sh`: run the file with the
  checkout's stamp present and with it moved aside (criterion 4), grep that no `--git-path` call
  lacks `--path-format=absolute` (criterion 5), and, in a scratch copy, break `live.sh` so the
  clone's stamp is written or left behind and confirm the "no lock", "base" and "clear" cases fail
  (criterion 6). The results go in `implement.md`. `tests/live.test.sh` leaves the footprint.
- **Verify and add a guard.** As above, plus a new case in `tests/live.test.sh` that fails when
  any `--git-path` call in the file lacks `--path-format=absolute`, so the defect cannot return
  unnoticed. One more test that reads its own source; the suite has a few of these already.

**Answer:**
Verify only (engineer, in the conversation, 2026-11-19: "Accept all your recommendations"; recorded here by the skill).

### Q2 — #116's criterion 13: strike it on #116, or post the output on #107 and tick it?

**Why it matters:** the criterion is "The `rm -f -- ""` check output is recorded on #107". You
dropped it at #116's plan Q4 and pasted the output anyway (`rc=0`, kept in
`.codeo/done/116/plan.md`). Either way a task in this plan writes to GitHub with `gh` on issues
that are closed: it edits #116's body (one checkbox line) and posts one comment. The answer decides
which issues that task writes to and what it says.
**Options:**
- **Post and tick (recommended).** Comment on #107 with the pasted terminal output
  (`rm -f -- ""; echo "rc=$?"` → `rc=0`, container terminal, 2026-11-16), then tick criterion 13
  in #116's body and comment on #116 with a link to the #107 comment. The criterion is then met as
  written, and the output sits where it was asked for.
- **Strike.** Rewrite the line in #116's body as `- [ ] ~~…~~ — dropped at plan Q4 (2026-11-16)`
  and comment on #116 with the reason and the `rc=0` output. Nothing is written to #107. This
  matches the decision as you made it then.
- **You do it by hand.** The plan carries no GitHub task; the criterion is recorded as yours, and
  `/codeo:qc` reads it from the issue once you have edited it.

**Answer:**
Post and tick (engineer, in the conversation, 2026-11-19: "Accept all your recommendations"; recorded here by the skill).

### Q3 — Does this change get a `CHANGELOG.md` bullet?

**Why it matters:** the change is tests only: one renamed case, two tightened pins, and (per Q1)
perhaps one guard. Nothing a user of codeo sees changes, and #132's criteria do not ask for a
bullet. #118, also tests and wording only, did add one. A bullet puts `CHANGELOG.md` in this
plan's footprint, where it overlaps three workflows in flight, all assigned to kbajpai: #102
(`feat/codeo-issue-assign-every-filed`, at `implement`, already changed the file), #108
(`feat/follow-ups-97-left-overlap`, at `plan`) and #122 (`feat/triage-s-flight-judging-103`, at
`qc`, clear, already changed the file). Without a bullet this plan overlaps nothing in flight.
**Options:**
- **No bullet (recommended).** Global Constraints says in one line that the change moves no
  documentation page and no changelog entry, so `/codeo:qc` reads it as deliberate.
- **One bullet, proceed and coordinate.** The bullet is the plan's last task, after
  `bash scripts/sync-main.sh`, keeping both sides on a conflict. I then raise the three overlaps
  as their own questions, as `overlap.sh` prints them.

**Answer:**
No bullet (engineer, in the conversation, 2026-11-19: "Accept all your recommendations"; recorded here by the skill).

## Notes

Decided from the code, no question needed:

- **`both_markers_are_guarded_the_same` (`tests/role.test.sh:221`) is renamed, not strengthened.**
  `role.sh:57` is unguarded only when *both* markers are absent, so a case that creates both can
  never fail when the `/run/.containerenv` check is removed. The criterion's second branch applies:
  the case gets a name and a comment that say what it does pin (both markers present is still
  guarded), and `containerenv_alone_is_guarded` stays the case that pins the Podman check.
- **The two pins at `tests/close-skill.test.sh:321-322` search one paragraph each.** A new helper
  takes the section, an anchor string unique to the paragraph and the needle; it flattens only
  the blank-line-delimited paragraph that holds the anchor. The stash anchor is in the paragraph
  at `skills/close/SKILL.md:632-640`, the abandon anchor in the one at `:668-680`.
  `skills/close/SKILL.md` itself does not change. The proof for criterion 3 is a mutation run
  against a scratch copy of the skill in which only the other paragraph carries the text.
- **Shape:** one plan under `docs/plans/`, one pull request, no reference doc. No invariants
  document, no shared environment, no wiki module. The `shell` suite has no `filter`, so each
  task's proof is its test file, then `bash tests/run.sh`.

## Outcome

**Plan:** `docs/plans/2026-11-19-test-suite-gaps-132.md` (unstaged, awaiting the engineer's commit). Shape: one executable plan under `docs/plans/`, five tasks, no reference doc.

**Decisions.**
- `tests/live.test.sh` is not edited: #131 (`df2cdf9`) already made the three stamp assertions absolute. Task 3 proves criteria 4, 5 and 6 and reports them (Q1, verify only). Rejected: adding a guard case that reads the file's own source.
- `both_markers_are_guarded_the_same` is renamed `both_markers_present_is_guarded` with a comment; `containerenv_alone_is_guarded` stays the case that pins the Podman check. Rejected: strengthening it, since a case with both markers cannot fail on the `/run/.containerenv` check alone.
- The stash and abandon pins use a new `paragraph_contains_flat` helper that requires exactly one matching paragraph; `skills/close/SKILL.md` is unchanged.
- #116's criterion 13 is met as written: the `rc=0` output is posted on #107, the checkbox is ticked in #116's body, and #116 gets a linking comment (Q2). Rejected: striking it, or leaving it to the engineer.
- No `CHANGELOG.md` bullet (Q3), which also keeps the plan clear of #102, #108 and #122.

**Documentation moved:** none (no page under `docs/`, no wiki module).

**Intake questions resolved here:** none; intake left none open.

### Footprint

```
files:      tests/role.test.sh, tests/close-skill.test.sh, docs/plans/2026-11-19-test-suite-gaps-132.md
wiki:       none
exclusive:  none
sequenced:  none
```

## Log

- 2026-11-19 — Q1-Q3 raised · cost: 1m · fable-5-2 64k in + 461k cached / 5k out
- 2026-11-19 — planned: docs/plans/2026-11-19-test-suite-gaps-132.md · cost: 129m · fable-5-2 82k in + 766k cached / 9k out · sonnet-5-5 192k in + 619k cached / 14k out
