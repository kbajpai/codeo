# Issue #145 — init

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/145 |
| Branch | `fix/close-102-126-122-leftovers` |
| Updated | 2026-11-21 |

## Where this stands

Initialized: branch `fix/close-102-126-122-leftovers` cut off `origin/main` at `2e02100a256de327d5f85d51d57db98a98672da1` and pushed. Next step: `/codeo:plan` in the issue's container.

## Questions

None.

## Outcome

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/145 — Close the #102, #126 and #122 leftovers: priority-setting disagreements, stale `claim.sh` text, and triage's `review — dossier archived` label |
| State | open · labels `bug` |
| Branch | `fix/close-102-126-122-leftovers` off `main` at `2e02100` |
| Board | Ready → In progress |

**Problem.** Three QC passes left non-blocking findings that were never filed. #102: `doctor.sh` and `skills/issue` disagree on what turns `issue.priority` on (a string `"true"`), a second `priority:` label can be added, and `doctor.sh` prints its plugin path unquoted. #126: `claim.sh`'s header and its line-221 message still say "retitle" after the issue number moved into the branch name, and one stated cause can be false. #122: triage's docs say `review — dossier archived` means a PR awaiting review while `inflight.sh` prints it for archived dossiers with no PR or a closed-unmerged one; a changelog line, an untested `touched_of`, a `waits_of` comment, and the unassigned-resume re-ask are also off.

**Acceptance criteria** — verbatim from the issue, unchecked:
- [ ] A string `"true"` for `issue.priority` gives the same result in `skills/issue` and in `doctor.sh`.
- [ ] An issue is never filed with two `priority:` labels.
- [ ] The create command `doctor.sh` prints works when the plugin path contains a space.
- [ ] `skills/issue/SKILL.md` step 6 says what happens when the engineer names a priority outside the four.
- [ ] `claim.sh`'s header and the line-221 message give the same remedy, and neither mentions retitling for a branch `init` cut.
- [ ] The line-211 message does not claim a hand push the code cannot show.
- [ ] `skills/triage/SKILL.md` and `docs/handoff.md` describe `review — dossier archived` as `inflight.sh` prints it, or `inflight.sh` stops printing it for an archived dossier with no PR or a PR closed unmerged.
- [ ] `CHANGELOG.md` names the step `inflight.sh` actually prints.
- [ ] A test covers `touched_of`.
- [ ] The `waits_of` comment states that it steps past any `close` outcome no earlier rule took.
- [ ] The *resume* behaviour on `unassigned:<N>` is stated in `skills/triage/SKILL.md` and matches what triage does.
- [ ] `bash tests/run.sh` passes.

**Out of scope.** #126 F4 (old-style-branch transition gap) and F5 (hard-coded `.codeo/<N>`); #102 F3 and F4; #131's leftovers.

**Open at intake.** #122 F4: the QC cites `scripts/inflight.sh:285` and a comment that is not found on `origin/main`; the behaviour is in `waits_of`, so `/codeo:plan` should locate it. #122 F5: the QC says "Arguably intended; the skill does not say so", so `/codeo:plan` picks between stopping the re-ask on *resume* and documenting it.
Overlap to plan around: #144 (in flight, `fix/close-108-leftovers-overlap-sh`) also edits `docs/handoff.md` and `scripts/inflight.sh`; this issue edits both too, and `skills/triage/SKILL.md`. `/codeo:plan` runs `overlap.sh` and should sequence behind #144.

## Log
- 2026-11-21 — initialized: branch fix/close-102-126-122-leftovers off main at 2e02100 · cost: 11m · sonnet-5-5 15k in + 658k cached / 3k out
