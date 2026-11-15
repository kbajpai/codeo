# Issue #98 — plan

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/98 |
| Branch | `fix/fix-sync-main-sh-exiting` |
| Updated | 2026-11-15 |

## Where this stands

Round 1. Q1 (proceed and coordinate with #70) and Q2 (a byte-order `comm` wrapper in the test) are answered; nothing is open. The plan is drafted to `.codeo/98/plan-draft.md` and waits for the engineer's review.

## Questions

### Q1 — Overlap with #70 on `glob:CHANGELOG.md`, `glob:skills/**` and `glob:tests/**`: proceed and coordinate, sequence after #70, or re-scope?

**Why it matters:** #70 (branch `feat/guard-home-only-skills-against`, assignee kbajpai, step `plan`, plan approved and not yet implemented) lists `CHANGELOG.md`, `skills/**` and `tests/**` in its footprint. Its plan names three files this plan also changes:

- `skills/plan/SKILL.md`: #70 rewrites the `plan-03` paragraph (step 4); this plan changes the footprint paragraph in step 8 and one clause in step 10 sub-step 1. Different paragraphs, so git should merge them without a conflict.
- `tests/plan-skill.test.sh`: both add `must_contain` lines at the end of the list. Whichever merges second will probably get a small conflict there, resolved by keeping both sets of lines.
- `CHANGELOG.md`: both add a bullet under `## Unreleased`. Same resolution: keep both.

Nothing else overlaps: #70 does not touch `scripts/sync-main.sh`, `tests/sync-main.test.sh` or `docs/dossier.md`. *Proceed* means this plan's last task merges `origin/main` first and keeps every existing line; *sequence* means implementation here waits until #70 has merged; *re-scope* is not possible without dropping acceptance criteria (the CHANGELOG entry and the plan skill change are both required). #96 is also in flight, at `init` with no footprint and no changed files, so there is nothing to compare with yet.

**Options:** proceed and coordinate (recommended: #70 has not started implementing, and this fix is small enough to merge first) · sequence after #70 · re-scope.

**Answer:**
Proceed and coordinate. Go with the recommendation (engineer, in the conversation, 2026-11-15).

### Q2 — Should the new `sync-main.test.sh` case fail on the unfixed script everywhere, or only in the dev container?

**Why it matters:** the bug only shows with this container's coreutils (see Notes): its `comm` always compares byte by byte while its `sort` follows the locale. On GNU coreutils, which CI's `ubuntu-latest` most likely has, `sort` and `comm` agree under any locale, so a plain test of the unfixed script passes there. That decides what the test looks like and whether CI can ever catch this bug coming back.

**Options:**
- **(a) Real tools only.** The case runs `sync-main.sh` under `LC_ALL=en_US.UTF-8` on a merge touching `.codeo/x`, `.devcontainer/y` and `CHANGELOG.md`. It fails on the unfixed script in the dev container (criterion 3 is met there) and passes with or without the fix on a GNU machine. Simplest; CI cannot catch a regression.
- **(b) Pin `comm` to byte order in the test (recommended).** Same case, but the test puts a six-line `comm` wrapper first on `PATH` that runs the real `comm` under `LC_ALL=C`. That reproduces this container's behaviour on any coreutils, so the case fails on the unfixed script in CI too. The cost is that the test simulates the tool on GNU machines, and one more thing to read in the test file.

In both, a machine with no `en_US.UTF-8` locale installed cannot reproduce the ordering at all; the case would print one `skip:` line there and not count as a failure, unless you would rather it fail.

**Answer:**
(b) Pin `comm` to byte order in the test. Go with the recommendation (engineer, in the conversation, 2026-11-15).

## Notes

Read before drafting, so the plan does not re-ask it:

- **The cause (intake's open question from #92), reproduced here.** It is both: a comparison difference between the tools, which only shows under a non-C locale. This container has uutils coreutils 0.10.0 (Ubuntu 26.04, since #67). Its `sort` follows `LC_COLLATE`, so under `en_US.UTF-8` it puts `CHANGELOG.md` before `.codeo/…`; its `comm` compares bytes whatever the locale, sees `.codeo/…` after `CHANGELOG.md` as out of order, prints `comm: file 1 is not in sorted order` and exits 1. Running `comm` on the output of the same `sort` under `LC_ALL=en_US.UTF-8` fails; with `sort` under `LC_ALL=C` it passes, whatever locale `comm` runs in. Under `set -o pipefail` the `comm` exit ends `sync-main.sh:51-52` with 1, after the merge has already been made.
- **The fix I intend to plan:** run both `sort` calls and `comm` on line 51 under `LC_ALL=C`, on that line only. Byte order on both sides is right on every coreutils. Rejected: `export LC_ALL=C` at the top of the script as `overlap.sh` does (it would also change the locale `git merge` runs in, and the merge logic is out of scope); replacing `comm` with `grep -Fxf` (a larger change than the bug needs).
- **The `sequenced:` half.** `dossier-check.sh:339` already requires all four keys. `skills/plan/SKILL.md` step 8 names three keys and step 10 sub-step 1 says the `sequenced:` line is written only "when an overlap question was answered that way"; `docs/dossier.md:237` says the same. The plan changes those three places and leaves the checker alone.
- **Fixtures that already exist.** `tests/fixtures/dossiers/good-open-pending/plan.md` is a drafted footprint (under `## Notes`, outcome pending) with `sequenced:  none`, and it passes; `bad-footprint` lacks the key and is expected to print `lacks: sequenced`. My call: add no new fixture, and add `must_contain` cases to `tests/plan-skill.test.sh` for the new skill wording, plus one check that `docs/dossier.md` no longer carries the "only when" sentence. The plan will name the two fixtures as the evidence for criterion 8.
- Q2 follow-through, my call: with no `en_US.UTF-8` locale installed the new case prints one `skip:` line and does not fail (the answer to Q2 did not say otherwise). The fix and the wrapper were tried in a scratch copy: the unfixed script exits 1 with the three `comm:` warnings (with the wrapper, and also with this container's own `comm`); the fixed one exits 0 with three `also changed on main:` lines and an empty stderr.
- One pull request for both halves, as the issue consolidates them.
- The `shell` suite has no `filter`; the proof of a task is the whole `bash tests/run.sh`.
- No overlay section for `plan` (`plan-shape`, `proof-of-done`, `wiki-rules` all exit 3); no invariants document, no shared environment, no `wiki` module, no `resources[]`.
- `superpowers:brainstorming` was invoked before these questions, as the skill requires.

### Footprint

```
files:      scripts/sync-main.sh, tests/sync-main.test.sh, skills/plan/SKILL.md, docs/dossier.md, tests/plan-skill.test.sh, CHANGELOG.md, docs/plans/2026-11-15-sync-main-collation-and-sequenced-none.md
wiki:       none
exclusive:  none
sequenced:  none
```

## Outcome

_Pending — written at the hand-off._

## Log

- 2026-11-15 — Q1-Q2 raised (Q1: #70, glob:CHANGELOG.md, glob:skills/**, glob:tests/**) · cost: 2m · fable-5-2 72k in + 508k cached / 7k out
- 2026-11-15 — Q1-Q2 answered in the conversation (Q1: proceed and coordinate; Q2: b); plan drafted as .codeo/98/plan-draft.md, awaiting review · cost: unavailable, usage.sh not run before the review gate
