# Issue #70 — qc

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/70 |
| Branch | `feat/guard-home-only-skills-against` |
| Updated | 2026-11-15 |

## Where this stands

Round 2 done, routed back to `/codeo:plan`. Round 1's F1 and F2 are fixed and the suite is green with all eight criteria met; the independent review found two new blocking findings in the plan's wording (G1: the stale recovery advice would revive a stashed or abandoned workflow; G2: cleanup's caveat claims a record that does not exist, and cleanup does not prove the workflow ended). Nothing is open.

## Questions

None.

## Notes

Evidence from this pass (head `351c11b`, on a tree that already contains `origin/main`):

- `sync-main.sh --abort-on-conflict`: `sync-main: the branch already contains origin/main`. `overlap.sh 70`: nothing printed. `overlap.sh --outside 70`: `scripts/github.sh`.
- `scope.sh origin/main HEAD`: `suite.shell=true`, with the unclassified paths `.codeo/70/*.md`, `CHANGELOG.md`, `README.md` forcing the suite. No `deploy=` line: no environment is configured.
- Build (`shell` suite): `true`, exit 0. Test (`bash tests/run.sh`, all 45 test files): exit 0, output `all cases passed`.
- No invariants file, no `qc/invariants-extra` or `qc/wiki-rules` overlay (both exit 3), no `wiki` module, no shared environment.
- Independent review: opus, dispatched with the acceptance criteria only. It ran fifteen of the test files by hand, ran `role.sh` in this container (`issue:70`; `--check issue` refused with one line; `--check plan` and `--check close` passed; a missing or unknown skill exited 2), and traced the close report against this container's real lock (`host: container`, `volume: codeo-70`). Its verdict, in plain text: ready to merge with fixes, no Critical issue, two Important.
- Documentation check: every page the plan named is changed and describes the system in the present tense; a search of the added doc lines for issue numbers, "now", "no longer" and "used to" found none. The plan's claim that no other page moves holds.

## Outcome

### Round 1 — 2026-11-15

Checked at head `351c11b` after the sync above. Commands and their output are under `## Notes`.

| # | Criterion | Verdict | Settled by |
|---|---|---|---|
| 1 | Role script prints `home`, `issue:<N>`, `stale:<N>`; a test pins each case | met | `tests/role.test.sh` cases `home_on_main`, `issue_container`, `stale_on_main`, `stale_on_a_feature_branch`, `stale_unknown_issue`, `mismatch_*`; `.devcontainer/scripts/role.sh:53-93` |
| 2 | The four home-only skills stop outside the home container with one line naming the role, no override; a test fails if one stops declaring or calling the check | met | `tests/role-guard.test.sh` (`guarded=` array, rule paragraph, fetch call, overlay text, scratch self-check); `tests/role.test.sh` `--check` matrix; the one-line refusal shown by the reviewer's run |
| 3 | plan / implement / qc / close stop on a folder that does not match the lock; every skill stops in a stale container with a message naming the finished issue | met | `tests/role.test.sh` `mismatch_*` and the `finished` needle on both stale roles; `role.sh:73-93` (see F6 for the wording on a stashed workflow) |
| 4 | Hosted web session or plain local checkout: the four home-only skills run as today | met | `tests/role.test.sh` `no_dockerenv_is_unguarded`, `remote_is_unguarded`, `other_folders_are_unguarded`; the overlay-less default is "no guard" (`lib/extension-points.tsv`) |
| 5 | Close's final report contains the removal command from the lock's `volume:` line, says it runs on the host and to check `git status` first; a test pins the text | met | `tests/close-removal.test.sh` (overlay output needles `not inside this container`, `git status`, the command, `^codeo-[0-9]+$`); trace against this container's lock gives `docker rm -f codeo-70; docker volume rm codeo-70` (see F1 for the next step the report names) |
| 6 | `/codeo:cleanup` prints a command only for an issue passing all four proofs, lists the others with the failed proof and no command, never prints `codeo-home`, `codeo-gh`, `codeo-git` or a name outside the pattern; a test pins each | met | `tests/cleanup.test.sh` (each proof failing in turn, `codeo-home`/`codeo-gh`/`codeo-git` expansions, no pattern, no overlay); `tests/cleanup-skill.test.sh` runs this repository's overlay through the real script; `scripts/cleanup.sh:88-96` |
| 7 | `/codeo:cleanup` runs no Docker command; Dockerfile and devcontainer.json gain no engine, bind mount or secret | met | `tests/cleanup.test.sh` stub-docker case; `git diff --stat origin/main -- .devcontainer/Dockerfile .devcontainer/devcontainer.json` empty; `tests/devcontainer.test.sh` passes |
| 8 | Docs describe the new skill and roles; `CHANGELOG.md` has an Unreleased entry; `bash tests/run.sh` passes | met | `docs/skills.md`, `README.md`, `docs/skills-inventory.md`, `.devcontainer/README.md`, `CHANGELOG.md` read in this pass; the suite run above |

#### Findings

- **F1 — blocking, `/codeo:plan`'s.** After a finished close in a container, step 16 has deleted the lock, so the container's role is `stale:<N>`. `skills/close/SKILL.md:541-542` makes the closing block's first step `/codeo:triage` (and the project's close overlay names no other place), but `triage` is a home-only skill: the engineer's very first instruction is refused by the guard this change adds, in the container it is printed in. The plan said how `close` prints the removal commands and never considered where its own next step runs. Needed: the finished close names the home container for `/codeo:triage` (and `/codeo:cleanup`), in the project's overlay and, generically, "in the checkout the project's role check allows"; and a test that pins it.
- **F2 — blocking, `/codeo:plan`'s.** The sentence added to plan, implement, qc and `docs/handoff.md` ends "`/codeo:triage` finds recorded findings later" and says only "record the finding in this skill's own dossier" (`skills/plan/SKILL.md:113-115`, `skills/implement/SKILL.md:17-19`, `skills/qc/SKILL.md:506-508`). `/codeo:triage` scans only `.codeo/done/*/` on the base branch: `qc.md` non-blocking and out-of-scope items, `implement.md` deviations and plan gaps, and `## Outcome` or `## Notes` lines that promise later work with no issue number (`skills/triage/SKILL.md:97-103`). A finding recorded in any other form, or in `plan.md` anywhere else, is never found, and the sentence exists so a finding is not lost. Needed: name the form (a `## Notes` line promising later work, with no issue number) in each of the four places, and pin it in the three skill tests.
- **F3 — non-blocking.** The branch changes `scripts/github.sh`, which the plan's footprint does not list (`overlap.sh --outside 70`). The engineer approved the new `pr get` verb in the conversation and `implement.md` records it.
- **F4 — non-blocking, `/codeo:implement`'s.** `scripts/github.sh:241`: the usage `die` line lists `pr list-for-branch|view|reviews|…` without `get`, while the header lists it.
- **F5 — non-blocking.** `scripts/cleanup.sh:66`: a failed `github.sh issue view` reads as an empty state, so the issue is listed as `failed issue` with the `github:` error leaking onto stderr, where `pr get` stops the script. It still fails closed, but it is misleading.
- **F6 — non-blocking.** `role.sh:85-90`: the stale refusal says "is finished" for a workflow that was stashed (a stash also removes the lock), and for the "start script took no lock" case a lock skill is told to run in "that issue's container", the one it is already in; the useful advice there is re-running `bash .devcontainer/scripts/devcontainer-start.sh`.
- **F7 — non-blocking.** `.codeo/overlays/close.md`: the overlay replaces the host-by-host default entirely, so a close of this repository in a hosted session or a plain checkout would still relay "find the container with `docker ps` on the host". Start the section with "when the lock's host is `container`".
- **F8 — non-blocking.** A container whose branch was cut before this merges has no `role-guard` overlay and runs unguarded, today's finished containers included; no page says so.
- **F9 — non-blocking.** `role.sh:51` recognises a container only by `/.dockerenv`; under Podman (`/run/.containerenv`) the guard is silently off. The docs state `/.dockerenv` accurately.
- **F10 — non-blocking.** The overlays' role-guard text covers exits 0, 1 and 2 only; an exit 127 (script missing) leaves the model to guess. The fail-open choice for exit 2 was a recorded ruling and is not a finding.
- **F11 — non-blocking.** `scripts/cleanup.sh:41`: `CODEO_CLEANUP_REMOVAL` is a test override living in the production path; exported by accident it silently replaces the overlay's name, pattern and command.
- **F12 — non-blocking.** The generic `skills/cleanup/SKILL.md` description ("Home-container only"), the `docs/skills.md` cleanup section and the sentence in plan, implement, qc and `docs/handoff.md` ("in the home container") state a project-specific container fact in generic text; without the overlay the guard is absent and the skill runs anywhere.
- **F13 — non-blocking.** `skills/cleanup/SKILL.md:79`: in "step 2 `/codeo:init #<N>`" the `<N>` is the next issue, while elsewhere in that skill it is a finished one.
- Declined to judge (reviewer, plain text): the exemption of folders that are not `<codename>-home` or `<codename>-<digits>`, even with a lock that disagrees (deliberate, documented, needed by criterion 4); `stale:?` for a home folder on another branch; the fail-open exit 2; stashed and abandoned issues never listed by cleanup; the container name assumed equal to the volume name; fork PRs.

No issue was filed by this pass. F3-F13 are non-blocking; `/codeo:plan` may fold the cheap ones into the corrected plan or leave them for `/codeo:triage`.

Routing: the code does what the plan says and the suite passes, but the plan left out where `close`'s next step runs (F1) and what makes a refused finding findable (F2); both need a task in a corrected plan, with their tests.

**Verdict: back to `/codeo:plan`.**

### Round 2 — 2026-11-15

Checked at head `3fd4688`, after round 2 of the build (`b40172e` to `0252bf7`) on top of a merge of `origin/main`.

**Commands and output.**
- `sync-main.sh --abort-on-conflict`: `sync-main: the branch already contains origin/main`. `overlap.sh 70`: nothing printed. `overlap.sh --outside 70`: nothing printed (the footprint now lists `scripts/github.sh`; round 1's F3 is closed).
- `scope.sh origin/main HEAD`: `suite.shell=true`; the unclassified paths `.codeo/70/*.md`, `CHANGELOG.md` and `README.md` force the suite. No `deploy=` line: no environment is configured.
- Build (`shell` suite): `true`, exit 0. Test (`bash tests/run.sh`, all 45 test files): exit 0, output `all cases passed`.
- No invariants file, no `qc/invariants-extra` or `qc/wiki-rules` overlay (both exit 3), no `wiki` module, no shared environment.
- Independent review: opus, given the acceptance criteria only. It ran nine test files by hand (role, role-guard, cleanup, cleanup-skill, close-removal, github, inventory, devcontainer, agnostic) and read all three passes of the diff. Its verdict, in plain text: ready to merge with fixes, no Critical issue, two Important.
- Round 1's two blocking findings, re-checked here: F1 (blocking in round 1) — fixed by `b40172e`: the finished closing block in `skills/close/SKILL.md:542-545` names the checkout the project's host workflow gives for `/codeo:triage`, and `.codeo/overlays/close.md` names the home container. F2 (blocking in round 1) — fixed by `fda7a3e`: the `## Notes` form is in `skills/plan`, `skills/implement`, `skills/qc` and `docs/handoff.md`, once each.
- Documentation check: every page the plan named is changed and written in the present tense; the round-2 additions contain no issue numbers or history words (the one hit for "no longer" is a quotation of the extension-points text, not history).

| # | Criterion | Verdict | Settled by |
|---|---|---|---|
| 1 | Role script prints `home`, `issue:<N>`, `stale:<N>`; a test pins each case | met | `tests/role.test.sh` cases `home_on_main`, `issue_container`, `stale_on_main`, `stale_on_a_feature_branch`, `stale_unknown_issue`, `mismatch_*`; `.devcontainer/scripts/role.sh` |
| 2 | The four home-only skills stop outside the home container with one line naming the role, no override; a test fails if one stops declaring or calling the check | met | `tests/role-guard.test.sh` (`guarded=` array, rule paragraph, fetch call, overlay text incl. the new exit sentence, scratch self-check); `tests/role.test.sh` `--check` matrix |
| 3 | plan / implement / qc / close stop on a folder that does not match the lock; every skill stops in a stale container with a message naming the finished issue | met | `tests/role.test.sh` `mismatch_*` and the stale needles (`finished`, `stashed or abandoned`, `devcontainer-start.sh`, `home container`); see G1 for the recovery advice |
| 4 | Hosted web session or plain local checkout: the four home-only skills run as today | met | `tests/role.test.sh` `no_dockerenv_is_unguarded`, `remote_is_unguarded`, `other_folders_are_unguarded`; no overlay means no guard (`lib/extension-points.tsv`) |
| 5 | Close's final report contains the removal command from the lock's `volume:` line, says it runs on the host and to check `git status` first; a test pins the text | met | `tests/close-removal.test.sh` (overlay output needles: the command, `^codeo-[0-9]+$`, `not inside this container`, `git status`, the home-container sentence); trace against this container's lock gives `docker rm -f codeo-70; docker volume rm codeo-70` |
| 6 | `/codeo:cleanup` prints a command only for an issue passing all four proofs, lists the others with the failed proof and no command, never prints a name outside the pattern; a test pins each | met | `tests/cleanup.test.sh` (each proof failing in turn, unreadable issue, single-branch clone, `&` in a name, the three reserved names, no pattern, no overlay); `tests/cleanup-skill.test.sh` runs this repository's overlay through the real script; see G2 and G8 |
| 7 | `/codeo:cleanup` runs no Docker command; Dockerfile and devcontainer.json gain no engine, bind mount or secret | met | `tests/cleanup.test.sh` stub-docker case; `git diff --stat origin/main -- .devcontainer/Dockerfile .devcontainer/devcontainer.json` empty; `tests/devcontainer.test.sh` passes |
| 8 | Docs describe the new skill and roles; `CHANGELOG.md` has an Unreleased entry; `bash tests/run.sh` passes | met | `docs/skills.md`, `README.md`, `docs/skills-inventory.md`, `.devcontainer/README.md`, `CHANGELOG.md` read in this pass; the suite run above |

#### Findings

- **G1 — blocking, `/codeo:plan`'s.** The stale refusal for a lock skill (`.devcontainer/scripts/role.sh:79-83`, mirrored in the `stale` row of `.devcontainer/README.md`) says "if this is still issue #N's container, re-run `bash .devcontainer/scripts/devcontainer-start.sh` to take the lock". After a stash or an abandon, `/codeo:close` moves the dossier back to `.codeo/<N>/` and the lock is gone, so that container is `stale:<N>` and is still the issue's container: following the advice runs `lock.sh take container`, which binds a parked workflow from the `init.md` that names the branch (`scripts/lock.sh`, read in this pass: it checks no stash or abandon round). The workflow is then bound with no claim, no assignee and no board move, `claim.sh --stash-live` still reads it as parked, and an abandoned workflow that `/codeo:init` refuses to resume is revived. Round 2's Task 14 dictated this wording; the stash case it set out to cover is the one it gets wrong. Needed: for a lock skill in `stale:<N>`, the way back is `/codeo:init #<N>` in the home container (it runs the resume gate); re-running the start script is only for a container whose lock file was lost with the workflow still live, and the message must not offer it for a stashed or abandoned one. Pin the corrected advice in `tests/role.test.sh` and in the README row.
- **G2 — blocking, `/codeo:plan`'s.** `skills/cleanup/SKILL.md:66-67` tells the engineer the commands "rely on `close.md` having recorded a clean tree with the tip equal to the pull request's head". No such record exists where cleanup looks: it reads `close.md` from `origin/<base>`, the copy archived when the pull request opened, and the post-merge tree and tip check (`skills/close/SKILL.md:425-430`) never reaches the base branch; `scripts/cleanup.sh:60-80` reads only the `#<pr> <url>` line. The sentence was written from the issue's own Key Requirements; it is untrue, and it is printed on every run next to a "proven" list. A related hole the reviewer showed: a pull request merged on GitHub with branch deletion automatic passes all four proofs even when `/codeo:close` was never re-run in the container, so its lock and its leases on the intake branch are still held, and removing the volume hides that. Needed: correct the caveat to what is true (the proofs read `origin` only; whether the clone was left clean after the merge is not recorded anywhere cleanup can read), and decide with the engineer whether `cleanup.sh` also proves the workflow ended, for example that `intake.sh lease list --tsv` shows no lease held by the issue (a held lease → not proven).
- **G3 — non-blocking.** `.codeo/overlays/close.md`: on a stash or an abandon, `skills/close/SKILL.md` relays the host workflow "as step 17 does", and the overlay's sentence making `/codeo:triage` in the home container "the closing block's first step" conflicts with the stash exit's own first step. Limit that sentence to the finished exit.
- **G4 — non-blocking.** `skills/cleanup/SKILL.md:89` says the skill "never touches any branch" while step 3 commits and pushes `codeo/intake`: say "any branch other than `codeo/intake`".
- **G5 — non-blocking.** `skills/close/SKILL.md:536-537` still says "everything in it is merged or on origin, so nothing is lost either way" beside the new "run `git status` first: unpushed work is lost with the volume"; reconcile the two.
- **G6 — non-blocking.** `docs/handoff.md:383` names `/codeo:init #<N>` as cleanup's next goal while the skill and its test use `#<M>`.
- **G7 — non-blocking.** `scripts/cleanup.sh:70`: a pull request whose `head_ref` is `null` (or empty) makes the branch proof test `refs/remotes/origin/null`, which never exists, so the proof passes. A pull request from a fork passes the same way. Treat an empty or `null` ref as a failed `branch` proof.
- **G8 — non-blocking.** Round 1's F9 (Podman), F11 (`CODEO_CLEANUP_REMOVAL` in the production path) and F12 (generic text saying "home container": the reviewer lists the same lines again in `skills/plan`, `skills/implement`, `skills/qc`, `docs/handoff.md`, `docs/skills.md` and the cleanup description) stand as recorded in round 1 and were left for `/codeo:triage` by the engineer's answer to plan Q7; they are not raised again.
- Declined to judge (reviewer, plain text): the fail-open on a role-check exit 2 or any other exit (a recorded ruling); `/codeo:doctor` and `/codeo:setup` not refusing in a stale container (plan Q5); the close command using the `volume:` name as the container name (the criterion mandates it); a lock in the home clone reading as `mismatch`; resuming a stashed issue needing a new volume (predates this change); `CODEO_STATE_DIR` outside the project root (shared with `lock.sh`).

No issue was filed by this pass. Routing: both blocking findings are in the plan's wording (Task 14's recovery text, and the cleanup caveat the issue dictated), not in code that departs from it, so the plan owns them; G3-G7 are small and can ride the same round.

**Verdict: back to `/codeo:plan`.**

## Log

- 2026-11-15 — qc round 1: build and suite green, 8 of 8 criteria met, 2 blocking plan findings, routed back to plan · cost: 7m · opus-5-5 494k in + 5M cached / 30k out · sonnet-5-5 36k in + 1.6M cached / 7k out
- 2026-11-15 — qc round 2: build and suite green, 8 of 8 criteria met, round 1's F1 and F2 fixed, 2 new blocking plan findings (G1 stale recovery advice, G2 cleanup caveat and workflow-ended proof), routed back to plan · cost: 7m · opus-5-5 607k in + 4.4M cached / 26k out · sonnet-5-5 28k in + 3.1M cached / 8k out
