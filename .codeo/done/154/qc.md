# Issue #154 — qc

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/154 |
| Branch | `fix/close-149-145-leftovers-codeo` |
| Updated | 2026-11-22 |

## Where this stands

Round 1 is written: clear, forward to `/codeo:close`. The build exits 0, the full `shell` suite passes, and all six acceptance criteria are met on this pass's own output, including the four mutations the criteria name, which this pass ran itself. The independent review (opus) found no Critical or Important finding. Five documentation findings (F1-F5) are non-blocking: one README sentence has a wrong reason and the flowchart is imprecise on two edges; the engineer may send them back to `/codeo:plan` instead. Next step: `/codeo:close`.

## Questions

None.

## Notes

None.

## Outcome

### Round 1 — 2026-11-22

**Sync and overlap.** `sync-main.sh --abort-on-conflict`: `sync-main: the branch already contains origin/main`. `overlap.sh 154`: no output (the five overlaps with #152 were raised as plan Q4, answered *proceed and coordinate*). `overlap.sh --outside 154`: no output, so the branch changed nothing outside its footprint.

**Scope.** `git diff origin/main...HEAD --stat`: 16 files, 530 insertions, 17 deletions (five of them under `.codeo/` and `docs/plans/`). `scope.sh origin/main HEAD`, quoted:

```
scope: suite shell needed for unclassified paths:
  .codeo/154/implement.md
  .codeo/154/init.md
  .codeo/154/issue.md
  .codeo/154/plan.md
  CHANGELOG.md
suite.shell=true
```

No `deploy=` line: no shared environment is configured, so this round has no `#### Environment` block.

**Build.** The `shell` suite's `build` is `true`: exit 0.

**Suite.** `bash tests/run.sh` (the suite's `test`), 54 test files: `all cases passed`, exit 0, 405 s. Every statement here is from this pass's own run.

**Mutations the criteria name, run in a separate worktree at HEAD (reverted after each):**

- F7: the base's line `((rc == 0)) || stop_started "$name" $started` put back in `container_check`: `FAIL t_rm_inspect_fails_stops_started_container: no docker stop: docker ps -a … docker start codeo-5 … rev-list --branches --not --remotes=origin|`.
- `skills/implement/SKILL.md`, the `overlap: skipping` sentence moved before "The step stops until it is answered": `FAIL: the overlap skipping sentence comes after the stop sentence — [The step stops until it is answered] does not come before [An `overlap: skipping #<M>'s changed paths` warning]`.
- The same move in `skills/close/SKILL.md`: the same `FAIL` line from `tests/close-skill.test.sh`.
- `tests/inflight.test.sh`, the `PATH="$t_wrap:$PATH"` wrapper removed from the #29 case: `FAIL: touched_reads_the_dossier_when_the_tip_date_does_not_parse — line: want substring [  touched:   2026-11-15 (plan.md Updated), 2 days ago] in [#29  feat/t29 …`.

**Acceptance criteria**

| Criterion | Verdict | Settled by |
|---|---|---|
| `no sandbox` and a missing clone get a README remedy that works, and the `end <N> --force` refusal names a command a `codeo` user can type | met | `.devcontainer/README.md` sandbox paragraph (`no sandbox`: nothing left to remove; missing clone: `sbx rm --force codeo-<N>`); `.devcontainer/codeo:580-583` prints `codeo: codeo rm <N> --force removes it anyway`; `t_rm_sandbox_no_branches_hint` (`tests/codeo-command.test.sh`). The wrong *reason* given for the missing clone is F3 |
| F7 reproduced and a refused `rm` with a failing `docker inspect` leaves a stopped container stopped | met | `t_rm_inspect_fails_stops_started_container`: fails against the base logic (mutation above), passes at HEAD; the fix is `.devcontainer/codeo:527` |
| The flowchart's removal-failure edges, the `--force` hint's conditions, the home-directory list and the CHANGELOG `CODEO_HOME` sentence match the code | met — with two imprecisions (F1, F2) | hint: `.devcontainer/codeo:587` (`! sbx=$(sbx_prog)`) against both READMEs; `open` of a container: `cmd_open` dies at `:362` before `ensure_home`; CHANGELOG: `abs_path_env CODEO_HOME always` in `main` (`:738`); flowchart edges against `cmd_rm` `:652-672` |
| `must_precede` in both skill tests pins both sentences, and a mutation of each fails | met | `tests/close-skill.test.sh:444`, `tests/implement-skill.test.sh:116`; the two mutations above |
| `skills/triage/SKILL.md` names step 1's branch bullet; the `inflight.sh` comments name the check that exits 0 or 4 with no output; the #29 case has a newer tip date and fails without the wrapper | met | `skills/triage/SKILL.md:319` with `must_contain` and `must_lack` in `tests/triage-skill.test.sh`; `scripts/inflight.sh` header and above `waits_of` (comment lines only); tip date 2026-11-16 against `Updated` 2026-11-15, and the wrapper mutation above |
| The full `bash tests/run.sh` passes | met | `all cases passed`, exit 0, this pass |

**Documentation check.** Pages the diff changes: `.devcontainer/README.md`, `.sbx/README.md`, `CHANGELOG.md`, `skills/triage/SKILL.md`; all four were named by the plan, and the plan says `docs/skills.md` moves no page. The READMEs and the skill are in the present tense, carry no issue numbers (`grep` for `#14x`/`#15x` in both READMEs: 0) and use no "now" or "no longer" in the added lines; the CHANGELOG bullet carries `(#154)` as that file does. The Mermaid chart keeps its node ids and quoted labels. No wiki module; no overlay rules (`invariants-extra`, `wiki-rules`: exit 3).

**Independent review** (opus, given the acceptance criteria and the diff only): no Critical or Important finding; five Minor findings, all documentation, "ready to merge with fixes (optional, documentation only)". It re-ran each criterion's mutation in its own worktree and each failed as above. Its F1-F5 below are its findings, each confirmed by this pass against the code line cited.

**Findings**

- **F1 — non-blocking — `/codeo:plan`'s.** `.devcontainer/README.md` flowchart, edge `G -- "docker rm -f failed (with --force, only while the container is still listed), …"`: with `--force`, `cmd_rm` also dies when the follow-up `docker ps -a` listing itself fails (`.devcontainer/codeo:658`: `listing=$(docker ps -a …) || die "could not remove container $name"`). The code did what the plan's Task 3 text says; the plan's wording omitted this. Fix: "only while the container is still listed or the listing fails".
- **F2 — non-blocking — `/codeo:plan`'s.** The `H` edge (`docker rm -f failed (with --force, only while …)`): `H` is reached only from "anything else, no --force", so the `--force` parenthesis describes a case that cannot happen. The plan's Task 3 said to give `H` the same parenthesis. Fix: drop it from `H`.
- **F3 — non-blocking — `/codeo:plan`'s.** `.devcontainer/README.md`, the sandbox paragraph: "running it again fails the same way, because the script stops before it reads `--force`". `cmd_end` reads `--force` first (`.sbx/codeo-sandbox.sh:372-376`); the missing-clone `die` at `:381` happens with or without it. The conclusion (`--force` does not help; `sbx rm --force codeo-<N>` is the way out) is right, only the stated reason is wrong, and the reason is the plan's wording. Fix: "because the script refuses a missing clone with or without `--force`".
- **F4 — non-blocking — `/codeo:plan`'s.** `.devcontainer/README.md`, the inspect paragraph: "A container `codeo` had to start for that read is stopped again". When `docker ps -a` itself fails, `started` stays 0 (`.devcontainer/codeo:517`), so a stopped container is started and left running; very rare. Fix: "a container `codeo` knows it started".
- **F5 — non-blocking — `/codeo:plan`'s.** Flowchart node `Q`'s label ("refuse: nothing removed; a container codeo started is stopped again") is also reached by the "no such container, no --force" edge, where nothing was started. Harmless; the label is the plan's.
- **F6 — non-blocking — `/codeo:implement`'s.** Cosmetic: the sandbox paragraph in `.devcontainer/README.md` is soft-wrapped at two points although the file keeps paragraphs on one line (the implementer did it to satisfy a `grep -c` in the plan); the last sentence of the CHANGELOG `## Unreleased` bullet is vague ("wording … are corrected"); the `inflight.sh` comments wrap early.

**Routing.** No blocking finding: every criterion is met on this pass's own output. F1-F5 sit in text the plan dictated and are recorded for `/codeo:triage` to collect from the archived dossier, or for a send-back to `/codeo:plan` if the engineer wants them fixed first (about three one-phrase edits). No issue was filed from this pass.

**Verdict: clear — forward to `/codeo:close`.**

## Log

- 2026-11-22 — round 1: build exit 0, `bash tests/run.sh` all cases passed, 6 of 6 criteria met, four mutations run and failing as stated, no blocking finding (F1-F6 non-blocking), clear, forward to /codeo:close · cost: 10m · opus-5-5 351k in + 3.5M cached / 17k out
