# Issue #116 — init

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/116 |
| Branch | `fix/follow-ups-70-71-104` |
| Updated | 2026-11-16 |

## Where this stands

Initialized: branch `fix/follow-ups-70-71-104` cut off `origin/main` at `35fcef4186a818c12b2e17886a6da8b333275ea1` and pushed. Next step: `/codeo:plan` in the issue's container.

## Questions

None.

## Outcome

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/116 — Follow-ups #70, #71, #104 and #107 left: Podman guard, cleanup override, live-signal edge cases, Backlog-option error, and test and wording fixes |
| State | open · labels `bug`, `documentation` |
| Branch | `fix/follow-ups-70-71-104` off `main` at `35fcef4186a818c12b2e17886a6da8b333275ea1` |
| Board | Ready → In progress |

**Problem.** Four archived workflows (#70, #71, #104, #107) left non-blocking findings for triage. They are grouped in one follow-up: the role guard misses Podman, `CODEO_CLEANUP_REMOVAL` is a test override in `cleanup.sh`'s production path, `live.sh`/`github.sh` have lock-pattern, timeout-wording, `ref delete` and lingering-signal edge cases, a board without a Backlog option fails every filing with no fix named, and a few tests, CHANGELOG bullets and skill sentences say less or more than the code does. None breaks a workflow today; each is either fixed or has its limit documented, `/codeo:plan` deciding which.

**Acceptance criteria** — verbatim from the issue, unchecked:
- [ ] Under a `/run/.containerenv` container, `role.sh` reports the role as it does for `/.dockerenv` (or the docs name the limit).
- [ ] `/codeo:cleanup` with `CODEO_CLEANUP_REMOVAL` exported outside tests does not change what it prints.
- [ ] The cleanup skill description, `docs/skills.md` and the plan/implement/qc/handoff sentence carry no project-specific container claim in generic text.
- [ ] `live.sh` accepts the same lock-issue pattern in `read_lock` and `list`; a test pins it.
- [ ] `github.sh ref delete` treats only `Reference does not exist` as already deleted; a 404 for a refused write is reported as a failure.
- [ ] The `CODEO_LIVE_PUSH_TIMEOUT` documentation (CHANGELOG, `live.sh` header) matches what `live.sh:155` bounds.
- [ ] A stashed or abandoned workflow's `live:` line clears, or the 15-minute lag is documented.
- [ ] The docs name `CODEO_MACHINE` as the way out of the same-volume-name collision.
- [ ] `board.sh` with no Backlog option prints a message that names the `board.statuses.backlog` fix.
- [ ] `skills/issue/SKILL.md` describes `set`'s one-line-per-project output.
- [ ] `CHANGELOG.md` states the `issue:<N>` fingerprint change and corrects the #107 `codeo-root.sh` bullet.
- [ ] `title_reports_a_failing_container_name_as_one_line` can fail for the behaviour it names, or its name says what it guards.
- [ ] The `rm -f -- ""` check output is recorded on #107.
- [ ] `bash tests/run.sh` passes and `CHANGELOG.md` records the change.

**Out of scope.** #104's web-session label (F3): settles with #112. #108's items (`overlap.sh`, `qc-verdict.sh` error handling and test guards). #103's triage judging of in-flight workflows.

**Open at intake.** None; the three intake questions (F3 → reference #112 only; F5, F7, F16 and J8 → fix or document, `/codeo:plan` decides; the `rm -f -- ""` check → an acceptance criterion) were answered before filing.

## Log

- 2026-11-16 — init dossier drafted for review
