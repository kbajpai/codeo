# Issue #145 — qc

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/145 |
| Branch | `fix/close-102-126-122-leftovers` |
| Updated | 2026-11-21 |

## Where this stands

Round 1 is written: clear, forward to `/codeo:close`. The build and the full `shell` suite pass, every acceptance criterion is met, and the independent review (opus) found no Critical finding. One Important finding from it (F1, a wrong step number in new triage text) was classified non-blocking, because every criterion is met and the text names the right command; the engineer may send it back instead.

## Questions

None.

## Notes

No shared environment, no invariants file, no wiki module and no overlay rules are configured, so none of those checks apply. The `overlap.sh --outside 145` check printed nothing (every changed path is in the footprint).

## Outcome

### Round 1 — 2026-11-21

**Start of the round.** `bash scripts/sync-main.sh --abort-on-conflict`: `sync-main: the branch already contains origin/main` (no `also changed on main:` lines; #144 and #143 were merged in during `/codeo:implement`). `bash scripts/overlap.sh 145`: nothing printed.

**Diff.** `git diff origin/main...HEAD --stat`: 18 files changed, 521 insertions, 23 deletions — `scripts/doctor.sh`, `scripts/claim.sh`, `scripts/inflight.sh` (comments only), `skills/issue/SKILL.md`, `skills/triage/SKILL.md`, `docs/handoff.md`, `docs/skills.md`, `CHANGELOG.md`, five test files, the plan, and the `.codeo/145/` dossiers.

**Scope.** `bash scripts/scope.sh origin/main HEAD`:

```
scope: suite shell needed for unclassified paths:
  .codeo/145/implement.md
  .codeo/145/init.md
  .codeo/145/issue.md
  .codeo/145/plan.md
  CHANGELOG.md
suite.shell=true
```

**Build.** `shell` suite, `true`: exit 0.

**Suite.** `bash tests/run.sh` (the `shell` suite, whole; it has no `filter`): `all cases passed`, exit 0.

**Acceptance criteria**

| Criterion | Verdict | Settled by |
|---|---|---|
| A string `"true"` for `issue.priority` gives the same result in `skills/issue` and in `doctor.sh` | met | `skills/issue/SKILL.md:132` reads `'.issue.priority == true'`, as `scripts/doctor.sh:121` does; run here against a real config, `config.sh get '.issue.priority == true'` printed `true` for the boolean and `false` for `"true"`, `false`, `null` and an absent key; the skill's "anything else, or nothing" covers those. Pinned at `tests/issue-skill.test.sh` (step 5 pins) and `tests/doctor.test.sh`'s existing `"true"` case |
| An issue is never filed with two `priority:` labels | met | `skills/issue/SKILL.md:129` (no `priority:` label from the general pass) and the step 7 sentence "The call carries at most one `priority:` label"; pinned in `tests/issue-skill.test.sh` |
| The create command `doctor.sh` prints works when the plugin path contains a space | met | `scripts/doctor.sh:135` quotes the path; `doctor_priority_create_command_works_with_a_space_in_the_plugin_path` runs the printed command with `bash -c` from a copy named `my plugin` (reviewer confirmed it fails without the quotes) |
| `skills/issue/SKILL.md` step 6 says what happens when the engineer names a priority outside the four | met | `skills/issue/SKILL.md:152`, pinned |
| `claim.sh`'s header and the line-221 message give the same remedy, and neither mentions retitling for a branch `init` cut | met | header `scripts/claim.sh:43-45` and the message at `:221` both say rename or delete it on origin; `tests/claim.test.sh` asserts no "retitle" in that output and no "retitling is the right remedy" in the header |
| The line-211 message does not claim a hand push the code cannot show | met | `scripts/claim.sh:211` now ends `rename or delete it on origin`; `tests/claim.test.sh` asserts no "pushed by hand" |
| `skills/triage/SKILL.md` and `docs/handoff.md` describe `review — dossier archived` as `inflight.sh` prints it | met | `skills/triage/SKILL.md:317-320`, `docs/handoff.md:155-156` and `scripts/inflight.sh:17-19,236-237` all say the archive is not on the base branch yet, with no pull-request lookup (checked against `state_token=pr-open` in `inflight.sh`); see F1 for one wrong step number |
| `CHANGELOG.md` names the step `inflight.sh` actually prints | met | `CHANGELOG.md` "(or the step after the last one finished before the park)"; `grep -c 'step before the park' CHANGELOG.md` prints 0 |
| A test covers `touched_of` | met | `touched_reads_the_dossier_when_the_tip_date_does_not_parse` in `tests/inflight.test.sh`; the reviewer mutated `touched_of` and the case failed |
| The `waits_of` comment states that it steps past any `close` outcome no earlier rule took | met | `scripts/inflight.sh:240-242` and the header at `:19-22`, pinned in `tests/inflight.test.sh` |
| The *resume* behaviour on `unassigned:<N>` is stated in `skills/triage/SKILL.md` and matches what triage does | met | `skills/triage/SKILL.md:121-122`, `docs/skills.md:228`; consistent with step "Drop what is already decided", which drops only filed, dismissed, already-tracked and backlog items |
| `bash tests/run.sh` passes | met | `all cases passed`, exit 0 (above) |

**Documentation check.** The plan named `skills/issue/SKILL.md` and `docs/skills.md` (issue), `scripts/claim.sh`'s header, the `scripts/inflight.sh` comments and `docs/handoff.md`, `skills/triage/SKILL.md` and `docs/skills.md` (triage), and `CHANGELOG.md`; all are in the diff and describe the shipped behaviour in the present tense without issue numbers (the CHANGELOG bullet carries them, as that file does). A grep across `skills/`, `docs/` (not `docs/plans/`), `scripts/` and `tests/` finds no page still saying "names the pull request awaiting review", "or retitle", "pushed by hand" (outside the header's scoped use), "the step before the park" or "once `close` has opened its pull request"; the remaining hits are the new negative assertions. `docs/skills.md:34` ("Reads the repository's labels when `issue.priority` is on") is #102 F3, out of scope. No wiki module and no overlay rules.

**Independent review** (opus, given the acceptance criteria and the diff only): no Critical finding; one Important finding (F1) and two Minor ones; "With fixes".

**Findings**
- F1 — non-blocking, `/codeo:plan`'s. `skills/triage/SKILL.md:318` says "the state step 2 read with `pr list-for-branch`". Top-level step 2 is "Drop what is already decided" and reads no pull requests; the lookup is in step 1's "Parked work" branches bullet (lines 177-181, as line 132 says: "the branch bullet's `pr list-for-branch`"). The code does what the plan's Task 5 text says; the plan's wording ("the state step 2 read") took the sub-item number for the step number. The reviewer rated it Important; it is non-blocking here because every criterion holds and the sentence names the command, but it misdirects a reader, so the engineer may prefer to send it back. Fix: "the state step 1's branch bullet read with `pr list-for-branch`".
- F2 — non-blocking, `/codeo:implement`'s. `tests/inflight.test.sh` (the #29 case, about lines 991-1010): the tip commit date (2026-11-10) is older than the dossier's `Updated` row (2026-11-15), so the expected line reads the same whether the tip is skipped or read. The case catches an early return on an unparsable tip (confirmed by mutation) but would still pass if the wrapper stopped applying. Fix: give the tip a newer date than the dossier (`raw_dossier … 2026-11-16`).
- F3 — non-blocking, `/codeo:implement`'s. `scripts/inflight.sh` comments (header and above `waits_of`): "(a spent stash or abandon, or a live one whose `claim.sh --stash-live` check failed)" omits a check that exits 0 or 4 but prints nothing, which also falls through. The main clause, "any `close` outcome", is accurate.
- Minors the reviewer and the task reviews recorded: ragged line wraps in the `docs/handoff.md` and `inflight.sh` header edits; exact-string `grep -F` pins break on a re-wrap.

No issue was filed from this pass; F1-F3 are for `/codeo:triage` to collect from the archived dossier, or for a send-back if the engineer wants F1 fixed first.

**Verdict: clear — forward to `/codeo:close`.**

## Log

- 2026-11-21 — qc round 1: build exit 0, `bash tests/run.sh` all cases passed, all 12 criteria met, no blocking finding (F1-F3 non-blocking), clear, forward to /codeo:close · cost: 6m · opus-5-5 381k in + 3.8M cached / 16k out · sonnet-5-5 301k in + 1000k cached / 2k out
