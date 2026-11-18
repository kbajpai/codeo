# Issue #126 — plan

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/126 |
| Branch | `feat/put-issue-number-branch-name` |
| Updated | 2026-11-18 |

## Where this stands

Q1 and Q2 are answered (both A) and the plan is approved and written as `docs/plans/2026-11-18-numbered-branch-names-126.md` (unstaged). Blocked on Q3, an overlap with #131 and #133; `## Outcome` is written once it is answered.

## Questions

### Q1 — How does `/codeo:init` find a workflow on an old-style branch?

**Why it matters:** today `init` finds a resume only by the derived name: step 6 runs
`git ls-remote` on what `branch-name.sh <N>` prints, and step 3 stops on "this issue's dossier on a
branch of any other name" with the advice to restore the title. Once the script prints
`<type>/<N>-<slug>`, every workflow in flight (#126 itself, #131, #133) is on "a branch of any
other name", and the restore-the-title advice no longer leads anywhere. The answer decides which
script changes and what steps 3 and 6 of `skills/init/SKILL.md` say.

**Options:**

- **A — look the branch up by its dossier (recommended).** `init` asks
  `inflight.sh --branches` which branch carries `.codeo/<N>/`. When one does, that branch is the
  resume candidate whatever its name, and step 6's `--carries` / `--stash-live` checks run on it.
  The derived name is used only for a fresh claim. No change to `inflight.sh`; the change is in
  the skill text and its tests. This also makes a resume work after an issue is retitled, so the
  "restore the title, then run `init` again" instruction goes away.
- **B — try the new name, then the old one.** `branch-name.sh --legacy <N>` prints `<type>/<slug>`;
  `init` checks the numbered name first and the legacy name second. Smaller change to the skill
  text, but it adds a flag that exists only for the transition, a retitled issue still cannot
  resume, and the legacy name of one issue can still be another issue's old branch.
- No preference, you pick.

**Answer:**
A — look the branch up by its dossier. (Given in the conversation as "Q1 - A" on 2026-11-18, recorded here verbatim.)

### Q2 — What does `claim.sh --carries` say when the name is taken by another issue's branch?

**Why it matters:** this is the decision the issue left to the plan (`scripts/claim.sh:210`). With
the number in the name, two issues can no longer derive one name, so "#N's title derives the same
branch name as #M's — retitle #N … or wait for #M to close" describes a case that cannot arise
from the pipeline. A branch named `<type>/<N>-<slug>` that carries #M's dossier can still exist
if someone pushed it by hand. The answer decides whether that code path, its header comment and
the case at `tests/claim.test.sh:328` are reworded or removed.

**Options:**

- **A — keep the refusal, reword the remedy (recommended).** `--carries` still exits 2 when the
  branch carries another issue's dossier; the second line becomes "`<branch>` carries #M's
  dossier, not #N's — rename or delete it on origin". No retitle advice and no mention of titles.
  The test keeps its case with the new wording. The cost is one branch of code for a case only a
  hand-made branch reaches.
- **B — drop the separate reading.** Remove the `elif [[ -n $other ]]` branch; a branch carrying
  another issue's dossier then gets the existing last reading's remedy ("is not a pipeline
  branch — rename or delete it on origin, or retitle #N"), with its first line still naming #M's
  dossier. Less code, but the message calls a branch that carries a dossier "not a pipeline
  branch".
- No preference, you pick.

**Answer:**
A — keep the refusal, reword the remedy. (Given in the conversation as "Q2 - A" on 2026-11-18, recorded here verbatim.)

### Q3 — #131 and #133 also change `CHANGELOG.md`; #131 also changes `docs/handoff.md`. How do we coordinate?

**Why it matters:** overlap check (`overlap.sh 126`) printed `131 glob:CHANGELOG.md`, `131 glob:docs/handoff.md` and `133 glob:CHANGELOG.md`. #131 is `feat/make-sbx-sandbox-lock-follow` (assignee kbajpai, step plan, waiting on its implement.md Q1) and #133 is `feat/codeo-command-host-short-bash` (assignee kbajpai, step plan, waiting on `/codeo:implement`). Each adds a bullet to the top of `CHANGELOG.md`, and I would add a `## Unreleased` heading there; #131 edits the `branch:` example area of `docs/handoff.md` that my task 4 also edits (line 39). The conflicts are textual and small, but whichever branch merges second has to resolve them. `exclusive:` is none for all three, so nothing is locked.

**Options:** proceed and coordinate (each merge resolves its own `CHANGELOG.md` bullet and the one-line `handoff.md` hunk; recommended, since the edits are different lines) · sequence after #131 and #133 (this plan then writes `sequenced:`, and implement waits) · re-scope (drop the `handoff.md` example change and leave `feat/order-export` as it is, which removes the `docs/handoff.md` overlap but not the `CHANGELOG.md` ones).

**Answer:**

## Notes

### Footprint

```
files:      scripts/branch-name.sh, scripts/claim.sh, skills/init/SKILL.md, tests/branch-name.test.sh, tests/claim.test.sh, tests/init-skill.test.sh, docs/dossier.md, docs/handoff.md, CHANGELOG.md, docs/plans/2026-11-18-numbered-branch-names-126.md
wiki:       none
exclusive:  none
sequenced:  none
```

Decided without a question, because the issue already answers them:

- The slug rule is unchanged, including the exit 1 when no words are left in the title ("the type
  and the slug are derived as they are today"). A title of only stop words is still refused; the
  script does not fall back to `<type>/<N>`.
- One pull request.
- The example branch in `docs/dossier.md` and `docs/handoff.md` (`feat/order-export`, for the
  imaginary issue #12) becomes `feat/12-order-export`, so the docs show the shape `init` cuts.
- The other "retitle #N only for an issue reopened after its merge" remedies in `claim.sh` stay:
  a retitle still changes the slug, so it still gives a reopened issue a free name.

## Outcome

_Pending — written at the hand-off._

## Log

- 2026-11-18 — Q1-Q2 raised · cost: 1m · fable-5-2 67k in + 449k cached / 4k out
- 2026-11-18 — Q1-Q2 answered (both A), plan drafted and awaiting approval · cost: unavailable (mid-pass)
- 2026-11-18 — plan approved, written to docs/plans/2026-11-18-numbered-branch-names-126.md; Q3 raised (overlap with #131, #133) · cost: 5m · fable-5-2 83k in + 760k cached / 8k out · sonnet-5-5 108k in + 1.3M cached / 15k out
