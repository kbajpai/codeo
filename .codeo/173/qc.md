# Issue #173 — qc

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/173 |
| Branch | `docs/173-close-161-leftovers-release-checklist` |
| Updated | 2026-11-25 |

## Where this stands

Round 1, resumed after Q1-Q3 (the #176 overlaps) were answered proceed and coordinate. The pass continues from step 2's diff and scope.

## Questions

### Q1 — #176 and `.devcontainer/codeo` overlap: proceed, sequence or re-scope?

`overlap.sh 173` printed `176	.devcontainer/codeo` and `176	glob:.devcontainer/codeo`. #176 is on branch `feat/176-support-sbx-issue-sandbox-macos`, assigned to kbajpai, at step `plan` (working). Its plan's footprint names `.devcontainer/codeo`. So far its branch has changed only its plan doc. This branch changes `stop_started` and the `container_check` header comment, about 10 lines in `.devcontainer/codeo:475-482` and `:516-518`.

**Why it matters:** both branches edit one script. Whichever merges second takes the other's change through `sync-main.sh`. A conflict comes only when both touch the same lines.

**Options:** *proceed and coordinate* (recommended: this change is small and done, while #176 has not started its code, so #176 picks it up at its next `sync-main.sh`) · *sequence after #176* · *re-scope*.

**Answer:**
Proceed and coordinate, as recommended. Given in the session on 2026-11-25 ("go with your picks") and recorded here.

### Q2 — #176 and `.devcontainer/README.md` overlap: proceed, sequence or re-scope?

`overlap.sh 173` printed `176	.devcontainer/README.md` and `176	glob:.devcontainer/README.md`. #176 is on branch `feat/176-support-sbx-issue-sandbox-macos`, assigned to kbajpai, at step `plan` (working). Its footprint names `.devcontainer/README.md`. This branch changes two paragraphs and the removal flowchart in the `codeo rm` section, about 6 lines.

**Why it matters:** same as Q1. #176 is about the sbx sandbox on macOS, so its README edits are likely in other sections.

**Options:** *proceed and coordinate* (recommended, as in Q1) · *sequence after #176* · *re-scope*.

**Answer:**
Proceed and coordinate, as recommended. Given in the session on 2026-11-25 ("go with your picks") and recorded here.

### Q3 — #176 and `CHANGELOG.md` overlap: proceed, sequence or re-scope?

`overlap.sh 173` printed `176	CHANGELOG.md` and `176	glob:CHANGELOG.md`. #176 is on branch `feat/176-support-sbx-issue-sandbox-macos`, assigned to kbajpai, at step `plan` (working). Its footprint names `CHANGELOG.md`. This branch adds three bullets under `## Unreleased` and corrects two released entries in place.

**Why it matters:** both branches will add `## Unreleased` bullets after the same line, which is a small textual conflict for whichever merges second.

**Options:** *proceed and coordinate* (recommended: the second to merge resolves it by keeping both bullets) · *sequence after #176* · *re-scope*.

**Answer:**
Proceed and coordinate, as recommended. Given in the session on 2026-11-25 ("go with your picks") and recorded here.

## Notes

Commands this pass ran so far:

- `role.sh --check qc`: exit 0.
- `sync-main.sh --abort-on-conflict`: `sync-main: the branch already contains origin/main`, exit 0.
- `overlap.sh 173`, exit 0:

  ```
  176	.devcontainer/README.md
  176	.devcontainer/codeo
  176	CHANGELOG.md
  176	glob:.devcontainer/README.md
  176	glob:.devcontainer/codeo
  176	glob:CHANGELOG.md
  ```

- `scope.sh origin/main HEAD`: `suite.shell=true`, with the unclassified paths `.claude/hooks/session-start.sh`, `.claude/settings.json`, `.codeo/173/*`, `CHANGELOG.md` and `CONTRIBUTING.md`.
- `overlap.sh --outside 173`: printed nothing, exit 0.
- Overlay sections `invariants-extra` and `wiki-rules`: exit 3 (none). No invariants file, no shared environment, no `wiki` module.

## Outcome

_Pending — written at the hand-off._

## Log

- 2026-11-25 — Q1-Q3 raised (overlaps with #176) · cost: 0m · opus-5-5 232k in + 282k cached / 629 out
