# Issue #70 — qc

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/70 |
| Branch | `feat/guard-home-only-skills-against` |
| Updated | 2026-11-15 |

## Where this stands

Round 1 done, routed back to `/codeo:plan`. The code meets all eight acceptance criteria and the whole suite passes; two blocking findings are in the plan, not the code (F1, F2), and both are small text changes to skills and an overlay. Nothing is open.

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

## Log

- 2026-11-15 — qc round 1: build and suite green, 8 of 8 criteria met, 2 blocking plan findings, routed back to plan · cost: 7m · opus-5-5 494k in + 5M cached / 30k out · sonnet-5-5 36k in + 1.6M cached / 7k out
