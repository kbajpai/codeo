# Issue #179 — qc

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/179 |
| Branch | `docs/179-close-171-leftovers-readme-wording` |
| Updated | 2026-11-25 |

## Where this stands

Round 2 is written: round 1's blocking finding is fixed; one new blocking finding (G1, the README sends an abandoned issue to a fix that does not clear init's stop), three non-blocking. The verdict sends the change back to `/codeo:implement`. Next step: `/codeo:implement`.

## Questions

None.

## Notes

None.

## Outcome

### Round 1 — 2026-11-25

**Sync and scope.** `sync-main.sh --abort-on-conflict`: `merged origin/main (1 commit(s))` (`86b030c`, #176's sbx change; it touches none of this branch's files, and the script printed no `also changed on main:` line); the merge commit `0ede470` is on the branch. `overlap.sh 179`: nothing, exit 0. `overlap.sh --outside 179`: nothing, exit 0. `scope.sh origin/main HEAD`: `suite shell needed for unclassified paths: .codeo/179/implement.md, .codeo/179/init.md, .codeo/179/issue.md, .codeo/179/plan.md, README.md`, `suite.shell=true`, exit 0. No shared environment is configured, so there is no `deploy=` line and no environment step.

**Build.** `true` (suite `shell`): exit 0.

**Tests.** `bash tests/run.sh` (whole suite, this tree): `all cases passed`, exit 0. The same in a clean worktree (`git worktree add ../codeo-179-qc HEAD`, removed afterwards): `all cases passed`, exit 0.

**Criteria.**

| # | Criterion | Verdict | Settled by |
|---|---|---|---|
| 1 | The doctor-checks intro describes only what `scripts/doctor.sh` checks; the two non-doctor entries sit under their own heading | met — the twelve bold leads under `### Checks from /codeo:doctor` equal the twelve names `scripts/doctor.sh` reports; the two entries sit under `### Installing and the pin`, and the Troubleshooting intro says three groups | `troubleshooting-groups` check; grep of `doctor.sh` against the README leads |
| 2 | "Start here" step 6 says the workflow finishes on the second `/codeo:close` | met — README.md:27 | `start-here` check; reading |
| 3 | The lock entry separates what a fresh `/codeo:init` fixes from the reconcile-by-hand TODOs | met — README.md:437 against `scripts/lock.sh:80,101,111,121,163,168`; see F2 for two accuracy notes | `lock-entry` check; reviewer read `lock.sh` |
| 4 | A repeated heading's link resolves in `tests/readme.test.sh`, and the header names which path checks hold only because codeo uses itself | not met — the slug fix gives `x`, `x-1`, `x-2`, but the header names two of the four such paths (F1) | `slugs` self-check; header at `tests/readme.test.sh:5-7` against the backticked paths the check examines |
| 5 | `docs/updating.md` "Updating superpowers" says to restart open sessions | met — docs/updating.md:124 | `updating` check |
| 6 | `docs/handoff.md` and `docs/skills.md` give the same skill count | met — "Six pipeline skills" (handoff.md:3), "Six skills" (skills.md:5) | `skill-count` check |
| 7 | A page tells another project how to adopt the role guard | met — `docs/home-checkout.md` "Adopting the guard in your project", linked from README.md and `docs/extension-points.md`; see F3 | `adopting-guard` check and `links` check |
| 8 | "Setting a project up" renders as intended in a strict Markdown renderer | met — three `###` steps, fences at column 0, no indented line outside a fence (no renderer is installed here; the structure was read in CommonMark terms, and the reviewer agrees) | `setup-steps` check; reading |
| 9 | `bash tests/run.sh` passes, in a clean worktree too | met | the two runs above |

**Documentation check.** The five pages the plan names changed (`README.md`, `docs/home-checkout.md`, `docs/extension-points.md`, `docs/updating.md`, `docs/handoff.md`) and nothing else. The new prose is present tense with no issue number and no "now". The doctor group's names, the lock TODOs, the role guard's exits and the anchors `#issuerole-guard` and `#adopting-the-guard-in-your-project` were read against the code and resolve. Findings F2 and F3 are statements the pages make that are slightly untrue.

**Independent review (opus).** Quoted, not bold: no Critical; one Important; five Minor; assessment "With fixes". It verified the twelve doctor names, the lock wording, the exits, the anchors, the slug function and that no new check has a `pipefail` hazard.

**Findings.**

- **F1 — blocking, `/codeo:implement`'s.** `tests/readme.test.sh:5-7`: the header names `docs/plans/` and `.codeo/config.json` as the paths that resolve only because codeo uses itself. The `paths` check also resolves `.codeo/` and `.codeo/.gitignore` (both named in README.md's *Setting a project up* for a user's project) against this repository, so a new project that lacks them would pass. Criterion 4 asks the header to name which path checks hold only for that reason; two of four leaves it half met. The plan's own wording ("paths the README names for a user's project") covers all four, so the code fell short of the plan, not the reverse. Fix: add the two paths to the header comment.
- **F2 — non-blocking, `/codeo:implement`'s.** README.md:437 sends a TODO that says the issue "is stashed or abandoned" to `/codeo:init #<N>`. An abandoned issue's card goes to Backlog and `/codeo:init` gates on Ready, so it refuses until the card is moved. The TODO "no single init.md names branch … (found N)" also fires when several dossiers name the branch (`scripts/lock.sh:163`), which a fresh init does not fix. Worth one clause each, since the round is going back anyway.
- **F3 — non-blocking, `/codeo:implement`'s.** `docs/home-checkout.md` (*Adopting the guard in your project*): "The skill never reads its output beyond the exit and the one line" contradicts the list above it, which says to report what was printed on any other exit. Reword to "beyond the exit, and the one line on exit 1".
- **F4 — non-blocking.** README.md:27 "the workflow finishes on that second run" is the criterion's own wording and is true on the plain path; it is not true after a review send-back (more `/codeo:close` runs) or when the engineer accepts `/codeo:close`'s background watch. No change needed for the criterion.
- **F5 — non-blocking, `/codeo:implement`'s.** `tests/readme.test.sh`, `troubleshooting-groups`: it checks each bold lead under the doctor heading is a doctor check name, not that the group has all twelve, so an emptied group passes although the header says it is the twelve names.
- **F6 — non-blocking, `/codeo:implement`'s.** `tests/readme.test.sh`, `skill-count`: `sed -n 3p` and `sed -n 5p` pin line numbers; a line added above either sentence fails the check with a misleading message.

Issues filed by this pass: none.

**Verdict: back to `/codeo:implement`.** Fix F1 (add `.codeo/` and `.codeo/.gitignore` to the header's list); F2, F3, F5 and F6 are non-blocking and worth taking in the same round.

### Round 2 — 2026-11-25

**Sync and scope.** `sync-main.sh --abort-on-conflict`: `merged origin/main (1 commit(s))` (`7d753fc`, #173; of this branch's files it touches only `.devcontainer/README.md`, which this branch does not change); the merge commit is on the branch. `overlap.sh 179`: nothing, exit 0. `overlap.sh --outside 179`: nothing, exit 0. `scope.sh origin/main HEAD`: `suite shell needed for unclassified paths: .codeo/179/implement.md, .codeo/179/init.md, .codeo/179/issue.md, .codeo/179/plan.md, .codeo/179/qc.md, README.md`, `suite.shell=true`, exit 0. No shared environment is configured, so no `deploy=` line and no environment step.

**Build.** `true` (suite `shell`): exit 0.

**Tests.** `bash tests/run.sh` (whole suite, this tree): `all cases passed`, exit 0. The same in a clean worktree (`git worktree add ../codeo-179-qc HEAD`, removed afterwards): `all cases passed`, exit 0.

**Criteria.**

| # | Criterion | Verdict | Settled by |
|---|---|---|---|
| 1 | The doctor-checks intro describes only what `scripts/doctor.sh` checks; the two non-doctor entries sit under their own heading | met — twelve leads equal the twelve names in `scripts/doctor.sh`, now enforced both ways; the two entries sit under `### Installing and the pin` | `troubleshooting-groups` check; reviewer read `doctor.sh` |
| 2 | "Start here" step 6 says the workflow finishes on the second `/codeo:close` | met — README.md:27 | `start-here` check; `skills/close/SKILL.md` step 8 |
| 3 | The lock entry separates the TODOs a fresh `/codeo:init` fixes from the reconcile-by-hand ones | not met — the entry lists the "stashed or abandoned" TODO among those `/codeo:init #<N>` fixes, and says an abandoned issue waits only for its card to be Ready again; for an abandoned issue that is wrong (G1) | `lock-entry` check passes; README.md:437 against `skills/init/SKILL.md:121-126,183-193` and `skills/close/SKILL.md:684-711` |
| 4 | A repeated heading's link resolves in `tests/readme.test.sh`, and the header names which path checks hold only because codeo uses itself | met — `slugs` self-check gives `x`, `x-1`, `x-2`; the header names `.codeo/`, `.codeo/.gitignore`, `.codeo/config.json` and `docs/plans/` (F1 of round 1, fixed) | `slugs` self-check; header at `tests/readme.test.sh:5-8` |
| 5 | `docs/updating.md` "Updating superpowers" says to restart open sessions | met — docs/updating.md:124 | `updating` check |
| 6 | `docs/handoff.md` and `docs/skills.md` give the same skill count | met — "Six pipeline skills" / "Six skills form the pipeline" | `skill-count` check, now line-content based |
| 7 | A page tells another project how to adopt the role guard | met — `docs/home-checkout.md` "Adopting the guard in your project", with the exit sentence now matching the list above it | `adopting-guard` check; reviewer read the overlays and `role.sh` |
| 8 | "Setting a project up" renders as intended in a strict Markdown renderer | met — three `###` steps, unindented paragraphs, column-0 fences; no renderer is installed here, the structure was read in CommonMark terms and the reviewer agrees | `setup-steps` check; reading |
| 9 | `bash tests/run.sh` passes, in a clean worktree too | met | the two runs above |

**Documentation check.** Only `README.md` and `docs/home-checkout.md` changed since round 1. The new prose is present tense with no issue number and no "now". The doctor names, the lock TODOs, the exits and the anchors resolve against the code; the one untrue statement is G1.

**Independent review (opus).** Quoted, not bold: no Critical; one Important; three Minor; assessment "With fixes". It verified the twelve doctor names, the divergence and stale-local TODOs against `scripts/lock.sh:96-118`, the found-0 case, the skill count, the guard page against the overlays and `role.sh`, the CommonMark structure, the anchors and that the new checks cannot pass vacuously.

**Findings.**

- **F1 (blocking in round 1) — fixed by `6b5de95`.** The header now names all four paths.
- **F2 (non-blocking in round 1) — partly fixed by `6b5de95`.** The "found more than one" case is separated as asked; the abandoned-issue clause it added is wrong (G1). F3, F5 and F6 of round 1 are fixed by the same commit.
- **G1 — blocking, `/codeo:implement`'s.** README.md:437, lock entry, *Fix*: "For a TODO that says … the issue is stashed or abandoned, run `/codeo:init #<N>` (an abandoned issue's card is back in Backlog, so `/codeo:init` stops until the card is Ready again, as in "A card that is not Ready" below)." An abandoned issue does not wait for its card. While the abandoned branch is still on origin carrying its `init.md`, `/codeo:init` skips the Ready gate (`skills/init/SKILL.md:121-126`) and stops on `claim.sh` exit 4, `claim: #<N> was abandoned on <date>` (`skills/init/SKILL.md:183-193`); there are two ways on — the engineer says in so many words that they take the work up again (a resume), or deletes the old branch on origin and runs `/codeo:init` again, when the Ready gate applies. A stashed issue is resumed by `/codeo:init #<N>`. `skills/close/SKILL.md:709-710` adds that an abandoned workflow is not resumed. So the entry sends an abandoned-issue reader to a fix that does not clear the stop. Cause, by reading the two skills: round 1's F2 asked for the Backlog clause on the strength of the close step alone, and the gate's resume exception and the exit-4 stop were not read; the wording the implementer wrote follows that finding. Fix: say a stashed issue is resumed by `/codeo:init #<N>`, and that for an abandoned one `/codeo:init` stops with `claim: #<N> was abandoned …` and names the two ways on; no card step.
- **G2 — non-blocking, `/codeo:implement`'s.** README.md:437: the entry opens "do what it says" for a `lock: TODO …` line, but for "found more than one" the line's own advice ("run init for the issue") is the one the entry then says does not fix it. Say so ("despite what the line says") in the same sentence.
- **G3 — non-blocking, `/codeo:implement`'s.** `tests/readme.test.sh:5-8`: the header says the four paths are "which the README names"; `docs/updating.md` and `docs/home-checkout.md`, which the same check covers, name `.codeo/` and `.codeo/config.json` for a user's project too. The list is complete; only the attribution is narrow.
- **G4 — non-blocking.** `tests/readme.test.sh`, `setup-steps`: it catches a line that starts with a space, not a tab or a lazy continuation line. The section is correct today; the guard is the weaker part.

Issues filed by this pass: none.

**Verdict: back to `/codeo:implement`.** Fix G1; G2 and G3 are non-blocking and cheap in the same round.

## Log

- 2026-11-25 — qc round 1: build and suite pass here and in a clean worktree; one blocking finding (F1), five non-blocking; back to implement · cost: 9m · opus-5-5 293k in + 2.1M cached / 12k out · sonnet-5-5 223k in + 779k cached / 3k out
- 2026-11-25 — qc round 2: build and suite pass here and in a clean worktree; one blocking finding (G1), three non-blocking; back to implement · cost: 8m · opus-5-5 355k in + 2M cached / 13k out · sonnet-5-5 24k in + 589k cached / 865 out
