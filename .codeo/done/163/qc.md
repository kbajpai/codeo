# Issue #163 — qc

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/163 |
| Branch | `fix/close-152-leftovers-cleanup-overlay` |
| Updated | 2026-11-25 |

## Where this stands

Round 1 is written: build and suite pass, all five criteria are met, no blocking finding, six non-blocking findings recorded. Verdict: clear, forward to `/codeo:close`. Nothing is open.

## Questions

None.

## Notes

Later work, promised and not yet filed (`/codeo:issue` is for a home checkout; `/codeo:triage` collects it): the documentation accuracy findings F1-F6 below, and the two parked minors from `implement.md` (the close overlay's clumsy sandbox clause; `tests/track.test.sh` unsetting `TMPDIR` rather than restoring it).

## Outcome

### Round 1 — 2026-11-25

Base: `sync-main.sh --abort-on-conflict` printed `the branch already contains origin/main` (exit 0), so there is no `also changed on` line. `overlap.sh 163` and `overlap.sh --outside 163` printed nothing (exit 0): no overlap with another workflow, and every changed path is inside the footprint. Range under review: `6b3fb6e..c0542ed`, 14 files, 428 insertions, 15 deletions; nine product files and the dossier and plan.

`scope.sh origin/main HEAD` printed:

```
scope: suite shell needed for unclassified paths:
  .codeo/163/implement.md
  .codeo/163/init.md
  .codeo/163/issue.md
  .codeo/163/plan.md
  CHANGELOG.md
  README.md
suite.shell=true
```

There is no `deploy=` line and no shared environment, so nothing in step 9 applies.

**Build.** The `shell` suite's build command is `true`: exit 0.

**Suite.** `bash tests/run.sh` (the `shell` suite, whole): `all cases passed`, exit 0.

**Acceptance criteria**

| Criterion | Verdict | Settled by |
|---|---|---|
| Run against the pinned plugin and the new `cleanup.sh`, `/codeo:cleanup` prints `{N}` replaced, or the CHANGELOG names the release | met — by the CHANGELOG branch: `CHANGELOG.md` (the `/codeo:cleanup` bullet) says a pin at v1.0.8 or earlier prints `codeo rm {N}` as written and no fallback, and names v1.0.9; the repository's `scripts/cleanup.sh:104-109` expands `{N}`, the pinned `scripts/cleanup.sh:93-106` expands only `{name}` (read directly) | `CHANGELOG.md`, the two `cleanup.sh` files |
| The by-hand fallback in both overlays removes the image it marks, says where `mark` runs, names a command that ends a sandbox | met — `.codeo/overlays/cleanup.md:12` and `.codeo/overlays/close.md:11` run `docker rmi codeo-dev:<name>` before marking the image, say `mark` runs on the host that created the container and not inside a container, and name `bash codeo-sandbox.sh end <N>` | `tests/cleanup-skill.test.sh` (six needles), `tests/close-removal.test.sh` (four needles) |
| After `codeo-track.sh add` and `mark`, no `codeo-track.*` file remains in `$TMPDIR` | met — `new_tmp` sets `tmp_file` in the calling shell (`.devcontainer/codeo-track.sh:54-55,138-139`); the reviewer ran the new case against the base script: it failed with `files left in TMPDIR: want [0] got [3]` and passes at head | `tests/track.test.sh` case `no_temp_file_left` |
| `README.md`: local container refused (F16), every use of `jq` (F17), guard wording and example (F18), keeping current (F19) | met — F16 `README.md:256`; F17 `README.md:199`, run with `jq` off `PATH` by the reviewer: `subagent-model.sh` exits 127, `live-signal.sh` exits 0, `config.sh` dies with `config.json: invalid JSON`; F18 no "no longer", example uses #12; F19 the "Keeping it current" list (`claude update`, `gh auth status`/`login`, `install.sh`, `codeo update`, `git pull`). Accuracy gaps in F16 and F17's wording are F1-F3 below, non-blocking | `README.md`; `grep -c 152 README.md` is 0 |
| `docs/skills.md`'s `/codeo:cleanup` section names the fourth field and `fallback:` | met — `docs/skills.md:252`; its claims match `scripts/cleanup.sh:130-132` and `skills/cleanup/SKILL.md:46`; the anchor `extension-points.md#cleanupremoval-command` exists | `docs/skills.md`, `bash tests/run.sh skills` inside the suite |

**Documentation check.** The pages the plan named (`CHANGELOG.md`, `README.md`, `docs/skills.md`) were changed; `docs/extension-points.md` already described the fourth field and was correctly left alone. The README and `docs/skills.md` additions are in the present tense with no issue number outside the invented example (#12). The plan names no wiki page and none is configured. No diagram changed.

**Independent review** (opus, `QC review:`; given the acceptance criteria and the diff, not the dossier). Its assessment, quoted in plain text: Ready to merge — with fixes; no Critical or Important issue; all five criteria met. It verified the leak fix by running the new test against the base script, and the README's `jq` claims by running the scripts with `jq` off `PATH`.

**Findings.** All are `/codeo:implement`'s (the code and text do not do what the plan said or say something untrue of the code), none blocks the merge, and none was fixed here.

- **F1 — non-blocking, `/codeo:implement`'s.** `README.md:256` says a container of that name already on this host is refused whatever `--yes` says, in a sentence about creating "a container or sandbox". For a sandbox that is not so: `track_confirm` (`.sbx/codeo-sandbox.sh:41-52`, read directly) passes `--local "a container codeo-<N> exists on this host"` and the tracker asks even with no active row. The unchanged `CHANGELOG.md:15` ("or a local container of its name, is listed and asked about") is true only of the sandbox script. Fix: one clause saying which script asks and which refuses.
- **F2 — non-blocking, `/codeo:implement`'s.** `README.md:199` says `install.sh` and `/codeo:doctor` report a missing `jq` first. `install.sh` does; `/codeo:doctor` run with `jq` off `PATH` prints `fail config: config.json: invalid JSON …` first and reaches `deps` later (read directly). Fix: say it also reports `deps: missing: jq`.
- **F3 — non-blocking, `/codeo:implement`'s.** `README.md:199` says `live-signal.sh` "exits 0 silently, reading the `cwd` as empty"; with a lock present it still starts `live.sh`, which sources `lib/env.sh` and fails, so no live signal is published. The practical effect is unsaid.
- **F4 — non-blocking, `/codeo:implement`'s.** `.codeo/overlays/cleanup.md:12`: "marks its row itself" holds only when `codeo-track.sh` sits beside `codeo-sandbox.sh` (`codeo-sandbox.sh:25-33`); otherwise it prints a `note:` and records nothing.
- **F5 — non-blocking, `/codeo:implement`'s.** `.codeo/overlays/cleanup.md:12` and `close.md:11` put the `git status` precondition after the three removal commands, though it must come before them: the clone is in the volume being removed.
- **F6 — non-blocking, `/codeo:implement`'s.** `CHANGELOG.md:20` calls the README's example "an invented example issue"; the issue number #152 was real and the fault was a fictional table that reused it.

Parked from `implement.md`, also non-blocking: the close overlay's sandbox clause reads "; and (a sandbox …)" and omits "from the folder that holds the script"; `tests/track.test.sh` unsets `TMPDIR` rather than restoring it after the new case.

No issue was filed by this pass.

**Verdict: clear — forward to `/codeo:close`.**

## Log

- 2026-11-25 — qc round 1: build and suite passed, 5/5 criteria met, F1-F6 non-blocking and recorded; clear, forward to /codeo:close · cost: 7m · opus-5-5 367k in + 3.1M cached / 18k out · sonnet-5-5 34k in + 1.2M cached / 2k out
