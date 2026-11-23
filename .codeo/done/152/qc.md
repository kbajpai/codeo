# Issue #152 — qc

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/152 |
| Branch | `feat/run-home-role-host-strict` |
| Updated | 2026-11-23 |

## Where this stands

Round 2 is written up under `## Outcome`: the build and the full suite pass, every acceptance criterion is met, the three round-1 blocking findings (F1-F3) are fixed, and nothing blocking is left. Eight non-blocking findings (F13-F20) are recorded, four the plan's and four the implementation's, for `/codeo:triage` or a follow-up. The verdict is clear and the next step is `/codeo:close`. Nothing is open.

## Questions

None.

## Notes

Evidence from round 2 (nothing quoted from `implement.md`; round 1's notes are in the Round 1 section below):
- `role.sh --check qc`: exit 0. `sync-main.sh --abort-on-conflict`: `the branch already contains origin/main`. `overlap.sh 152`: nothing printed. `overlap.sh --outside 152`: nothing printed.
- `scope.sh origin/main HEAD`: `suite.shell=true` (`scope: suite shell needed for unclassified paths: .codeo/152/implement.md, .codeo/152/init.md, .codeo/152/plan.md, .codeo/152/qc.md, CHANGELOG.md, README.md`). No `deploy=` line, no shared environment configured: step 9 does not apply.
- Build, suite `shell`: `true` -> exit 0. Test, suite `shell`: `bash tests/run.sh` -> exit 0, last line `all cases passed` (408s).
- No invariants file and no `invariants-extra` or `wiki-rules` overlay (both exit 3): the criteria and the reviewer are the standard.
- Independent review (`QC review:` dispatch on opus, handed the issue's criteria and the diff, told not to read `.codeo/152/` or the plan): verdict "With fixes", no Critical finding, two Important and nine Minor. It ran nine test files (role, track, cleanup, sandbox, codeo-command, cmd-mode, close-removal, cleanup-skill, init-overlay), all passing. I re-read the code behind each finding; each finding says what I confirmed and what I did not.

Later work, promised and not yet filed (the role check refuses `/codeo:issue` in this checkout; file with `/codeo:issue` in a home checkout, or let `/codeo:triage` collect it): the by-hand removal fallback text in `.codeo/overlays/cleanup.md` and `.codeo/overlays/close.md` (F14); a note that the cleanup overlay's `{N}` needs a plugin release (F13); the temporary-file leak in `codeo-track.sh` (F15); the README corrections F16-F18; documenting upkeep and the sandbox classification (F19, F20).

## Outcome

### Round 1 — 2026-11-22

Commands run: `sync-main.sh --abort-on-conflict`, `overlap.sh 152`, `overlap.sh --outside 152`, `scope.sh origin/main HEAD`, suite `shell` build `true` (exit 0) and test `bash tests/run.sh` (exit 0, `all cases passed`), as under `## Notes`.

| Criterion | Verdict | Settled by |
|---|---|---|
| `role.sh --check` allows `issue`, `init`, `triage`, `cleanup` only in a home checkout and refuses each in an issue checkout, one line; a test covers every skill in every role | met | `tests/role.test.sh` `check_matrix` (every skill, every role, host and container); `.devcontainer/scripts/role.sh:85-92` |
| refuses `plan`, `implement`, `qc`, `close` in home, host or container; a host checkout that is neither is refused | met | `role.sh:88-90`, `stray` at `:66-67`; `tests/role.test.sh` `host_stray`, `host_home_off_base` and the home matrix |
| `home` for a host clone named `<codename>-home`, no lock, base branch, no Docker | met | `role.sh:60-61`; `tests/role.test.sh` `host_home` runs with no docker on PATH |
| `/codeo:init <N>` posts exactly one tracking comment; a second run or a resume edits it | met — the tracker is idempotent and the init overlay calls it after the claim push (prose, pinned by `tests/init-overlay.test.sh`); see F3 and F9 | `tests/track.test.sh` `add_creates_once`, `add_edits_existing`; `.codeo/overlays/init.md` |
| a container, sandbox, image and volume created for the issue each appear as a row with the host's hostname and a UTC time | met — for the script routes only; a container opened through VS Code is not recorded, see F4 | `tests/cmd-mode.test.sh`, `tests/sandbox.test.sh`, `tests/track.test.sh` `host_and_times` |
| after the printed removal, rows are `removed` with a UTC time, a branch deleted at close is `deleted`, an unremoved item stays `active` | met — through `codeo rm`; see F1 and F8 | `tests/codeo-command.test.sh` (marks after each removal, none when refused), `tests/sandbox.test.sh` (`end` marks), `tests/close-removal.test.sh`, `tests/cleanup-skill.test.sh` |
| creating a container or sandbox for an issue with an `active` row or a local `codeo-<N>` warns and needs confirmation; opening does not warn | met | `tests/cmd-mode.test.sh`, `tests/sandbox.test.sh`, `tests/track.test.sh` `confirm_*` |
| `gh` unavailable when a script records a row does not fail the creation; the script prints the row | met | `tests/track.test.sh` `gh_missing_and_failing`; callers `|| true` (`tests/cmd-mode.test.sh`, `tests/sandbox.test.sh`) |
| the README documents the host home, the guard, the tracking comment and Linux, macOS, Windows/WSL; `codeo-home` stays documented as supported | met — with documentation defects F1, F4, F12 | `README.md` "The home checkout", `.devcontainer/README.md`, `.sbx/README.md` |
| existing tests still pass | met | `bash tests/run.sh` → exit 0, `all cases passed` |

#### Findings

- **F1 — blocking, `/codeo:plan`'s.** `.codeo/overlays/close.md:11`, `.devcontainer/README.md:162` and the `CHANGELOG.md` bullet say the printed `codeo rm <N>` "runs unmodified in PowerShell and in bash". It cannot: `codeo` is a bash script that needs Linux (or WSL2) with bash 4.3, `curl`, `git` and `flock` (`.devcontainer/README.md:88`). The engineers on the VS Code route and on the bare `codeo-container.sh` route have no `codeo` installed at all, so the printed command is one they do not have, where the old `docker rm -f …; docker volume rm …` ran everywhere Docker does: a regression for `codeo-home` users. Root cause: the plan (Global Constraints, Q4) chose `codeo rm {N}` as the only printed command and asserted PowerShell-safety, and the code and overlays follow the plan. Remedy for the plan: either print the docker removal as a fallback beside `codeo rm <N>` (which also needs the removal to be recorded by another route), or state that `codeo` must be installed and drop the PowerShell claim.
- **F2 — blocking, `/codeo:plan`'s.** `.devcontainer/codeo-track.sh:34` (`repo_slug`) defaults to `https://github.com/kbajpai/codeo.git` when `CODEO_REPO_URL` is unset, and nothing sets it where the overlays run the tracker (the home checkout for `/codeo:init`, the issue container for `/codeo:close`). In a fork `/codeo:init N` would post a tracking comment on the upstream repository's issue N, and close's `mark … deleted` would silently find nothing. Root cause: the plan's Q3 decision said "owner/repo from `CODEO_REPO_URL`", which holds for the host scripts and not for the overlay callers. Remedy for the plan: take the slug from `.codeo/config.json` (`repo.owner`/`repo.name`) or `git remote get-url origin` when `CODEO_REPO_URL` is unset, falling back to the default only for the downloaded host scripts.
- **F3 — blocking, `/codeo:plan`'s.** `codeo-track.sh:79-82` (`parse_body` state 2) treats any `|…` line as a row and `fmt_row` rewrites it: `| container | foo |` is rewritten as ``| container | `foo` | | | | |`` and an 8-cell row loses its last two cells on the next `add`. The issue says a malformed table is reported, not overwritten; the plan defined malformed as "marker but no recognisable header" and the code matches that definition. Remedy for the plan: a row is malformed unless it has exactly six cells, a known kind and a known status; then `fail_record` and leave the comment untouched.
- **F4 — non-blocking, `/codeo:plan`'s.** A container opened through the VS Code "Clone Repository in Named Container Volume" route (the first hand-off route the init overlay prints) is never recorded and gets no duplicate warning; and `.devcontainer/README.md:36`'s download line fetches only `codeo-container.sh`, never saying to fetch `codeo-track.sh` beside it (`.sbx/README.md:122` does), so the bare-script route records nothing and its note says "codeo update fetches it". The plan should either record that route or say in the README and the init overlay that it is not tracked, and add the `curl` line for `codeo-track.sh`.
- **F5 — non-blocking, `/codeo:implement`'s.** `codeo-container.sh` `ensure_container` calls `confirm` on `--rebuild`, so a container's own `active` row makes a non-interactive rebuild stop without `--yes`; a rebuild replaces a container and does not duplicate one.
- **F6 — non-blocking, `/codeo:implement`'s.** `codeo-track.sh:174,184`: `mark` prints nothing when no row matched or no comment exists, so a host name that changed since creation leaves a row `active` unseen.
- **F7 — non-blocking, `/codeo:implement`'s.** The rebuild path marks `codeo-dev:codeo-<N>` `removed` right after `docker rm -f`, which does not remove images.
- **F8 — non-blocking, `/codeo:plan`'s.** The `CHANGELOG.md` upgrade step ("run `codeo update`") does not make an old installed `codeo` fetch the tracker, and the container path of `codeo rm` never calls `ensure_home`, so the first removal after an upgrade can go unrecorded; the plan should say run it twice or have `cmd_rm` fetch the tracker.
- **F9 — non-blocking, `/codeo:implement`'s.** `.devcontainer/README.md:224` and `README.md` say the comment is "found by its first line"; `codeo-track.sh:61` matches the marker anywhere in any comment body.
- **F10 — non-blocking, `/codeo:implement`'s.** `.devcontainer/README.md:227` says `mark` sets the `active` row's status; for non-branch kinds only rows on this host change.
- **F11 — non-blocking, `/codeo:implement`'s.** `codeo-sandbox.sh` confirms after the host clone, so a refusal leaves a new `./codeo-<N>` clone (reused by the next run). Recorded before in `implement.md` as a ruling.
- **F12 — non-blocking, `/codeo:implement`'s.** The top-level README's macOS paragraph says `codeo` needs bash 4.3 and omits `flock`.

No issue was filed from this pass. Findings F1-F3 are blocking and rest on plan decisions, so the round goes back to `/codeo:plan`; F4 and F8 should be settled in the same plan round, and F5-F7, F9-F12 are small enough to ride along with the fixes.

**Verdict: back to `/codeo:plan`.**

### Round 2 — 2026-11-23

Commands run: `role.sh --check qc` (exit 0), `sync-main.sh --abort-on-conflict`, `overlap.sh 152`, `overlap.sh --outside 152`, `scope.sh origin/main HEAD`, suite `shell` build `true` (exit 0) and test `bash tests/run.sh` (exit 0, `all cases passed`, 408s), as under `## Notes`. No `also changed on main:` lines: the branch already contained `origin/main`. The whole pass was re-run from step 0 on `b50841b`.

| Criterion | Verdict | Settled by |
|---|---|---|
| `role.sh --check` allows `issue`, `init`, `triage`, `cleanup` only in a home checkout and refuses each in an issue checkout, one line; a test covers every skill in every role | met | `tests/role.test.sh` `check_matrix`; the reviewer ran it |
| refuses `plan`, `implement`, `qc`, `close` in home, host or container; a host checkout that is neither is refused | met | `.devcontainer/scripts/role.sh`, `tests/role.test.sh` `host_stray`, `host_home_off_base` |
| `home` for a host clone named `<codename>-home`, no lock, base branch, no Docker | met | `tests/role.test.sh` `host_home` (no docker on PATH) |
| `/codeo:init <N>` posts exactly one tracking comment; a second run or a resume edits it | met — the tracker is idempotent and `.codeo/overlays/init.md` calls it after the claim push; the simultaneous-first-creation race is documented, see F20 | `tests/track.test.sh` (`add_creates_once`, `add_edits_existing`), `tests/init-overlay.test.sh` |
| a container, sandbox, image and volume each appear as a row with the host's hostname and a UTC time | met for the script routes; a VS Code-opened container records the branch row only, and the README says so | `tests/cmd-mode.test.sh`, `tests/sandbox.test.sh`, `tests/track.test.sh` |
| after the printed removal the rows are `removed`, a branch deleted at close is `deleted`, an unremoved item stays `active` | met through `codeo rm`; the by-hand fallback's text misleads, see F14 | `tests/codeo-command.test.sh`, `tests/sandbox.test.sh`, `tests/close-removal.test.sh`, `tests/cleanup-skill.test.sh` |
| creating a container or sandbox with an `active` row or a local `codeo-<N>` warns and needs confirmation; opening does not | met — the README's wording of the local-container case is wrong, see F16 | `tests/cmd-mode.test.sh`, `tests/sandbox.test.sh`, `tests/track.test.sh` `confirm_*` |
| `gh` unavailable does not fail the creation; the script prints the row | met | `tests/track.test.sh` `gh_missing_and_failing`; callers use `|| true` |
| the README documents the host home, the guard, the tracking comment and Linux, macOS, Windows/WSL; `codeo-home` stays documented as supported | met, with documentation gaps F17-F19 | `README.md` "The home checkout", `.devcontainer/README.md`, `.sbx/README.md` |
| existing tests still pass | met | `bash tests/run.sh` -> exit 0, `all cases passed` |

Round 1's blocking findings, recapped as history:
- F1 (blocking in round 1) — fixed: `codeo rm <N>` is printed with a docker fallback sentence beside it, and no PowerShell claim remains (`grep -rni powershell` over the overlays, READMEs, CHANGELOG, `docs/` and `skills/` finds only `skills/plan/SKILL.md` and an unrelated `docs/dev-environment-sbx-evaluation.md` line, neither written by this change). The fallback text itself has defects, see F14.
- F2 (blocking in round 1) — fixed: `repo_slug` in `.devcontainer/codeo-track.sh` takes `CODEO_REPO_URL`, then the checkout's `origin`, then the upstream default (read at lines 33-47); `tests/track.test.sh` runs its cases with `CODEO_REPO_URL` unset (`run_cwd`).
- F3 (blocking in round 1) — fixed: a malformed row is refused in one `track:` line and nothing is written; the reviewer confirmed it, and CRLF bodies from the web UI, by experiment.
- F4-F12 (non-blocking in round 1) — each is addressed in the diff (the VS Code route documented, `mark` prints a note when it matches nothing, rebuild no longer confirms or marks the image, `codeo rm` fetches a missing tracker, the sandbox confirms before the clone, the marker-anywhere and host-scoping wording, the macOS `flock` note); the suite passes and the reviewer found none of them open.

Documentation check: README.md, `.devcontainer/README.md`, `.sbx/README.md`, `CHANGELOG.md` and `docs/extension-points.md` (fourth field and `fallback:` described) were read against the code. `docs/skills.md`'s cleanup section does not mention the `fallback:` line or the fourth field; nothing there is false, so it is not a finding. F16-F19 are documentation.

#### Findings

- **F13 — non-blocking, `/codeo:plan`'s.** `.codeo/overlays/cleanup.md:11` prints `codeo rm {N}` and relies on `scripts/cleanup.sh` expanding `{N}` in `command:`. The `origin/main` version of `cleanup.sh` (read directly) expands only `{name}` there, and the project pins the plugin at `ref` `v1.0.8`. Until a release carrying this branch's `cleanup.sh` is installed, `/codeo:cleanup` prints `codeo rm {N}` literally and drops the `fallback:` line, and the CHANGELOG does not say so. Root cause: the plan changed an overlay and the script that reads it in one change without naming the release that makes them agree. Non-blocking: the window closes with the project's own release.
- **F14 — non-blocking, `/codeo:plan`'s.** The by-hand fallback (`.codeo/overlays/cleanup.md:12`, `.codeo/overlays/close.md:11`) tells the engineer to mark the image `codeo-dev:<name>` `removed` although its two docker commands never remove an image, so the comment would show a `removed` image that still exists (read directly). It does not say where to run `bash .devcontainer/codeo-track.sh mark …`: a container row's Host is the machine that ran `codeo-container.sh`, `mark` changes only rows whose Host equals `hostname` (`codeo-track.sh:187`), and the issue container runs with `--hostname <name>` (`codeo-container.sh:118`), so run inside a container it prints its no-match note and changes nothing. It also names `docker rm` for a sandbox, which does not end one (reviewer's claim from `.sbx/README.md`; not re-read). The text follows plan Q8, which fixed the sentence's shape but not its content.
- **F15 — non-blocking, `/codeo:implement`'s.** `.devcontainer/codeo-track.sh:54,137`: `save` calls `f=$(new_tmp)`, so `tmp_files+=("$f")` runs in the command substitution's subshell and the `EXIT` trap never removes the file; each `add` or `mark` leaves a `codeo-track.XXXXXX` file holding the comment body in `$TMPDIR`. Confirmed by reading the code; the reviewer counted 348 left by the test runs.
- **F16 — non-blocking, `/codeo:implement`'s.** `README.md:248` says a local container of that name "lists them and asks before it creates another"; `codeo-container.sh:92-93` warns and refuses outright. `.devcontainer/README.md` describes it correctly.
- **F17 — non-blocking, `/codeo:implement`'s.** `README.md:199` says `jq` is needed for `baseBranch` and the guard falls back to `main` without it. `container-name.sh:30-31` also reads the codename with `jq` and falls back to the folder name, so without `jq` a `codeo-home` folder gives the codename `codeo-home` and the home clone can read as `stray`. Plausible from the code read; not run.
- **F18 — non-blocking, `/codeo:implement`'s.** `README.md:219` says "A host checkout is no longer `unguarded`", which describes the change rather than the system; the example comment at `README.md:227` uses this issue's number and the branch `feat/152-example`.
- **F19 — non-blocking, `/codeo:plan`'s.** The criterion says "install and upkeep"; the README's host-home section covers the clone (`git pull`) and the plugin through `install.sh`, and says nothing about keeping Claude Code or the `gh` login current.
- **F20 — non-blocking, `/codeo:plan`'s.** Reviewer-reported minors, not re-run: macOS `hostname` follows the network, so a container removed on another network leaves rows `active`; the image row is written only when this run built the image, so a failed `docker run` after a build leaves the image untracked; a sandbox has no container marker and reads as a host checkout, so a finished sandbox is `stray` with a message that does not explain it, and no page says how a sandbox is classified; two simultaneous first creations can leave two tracking comments (documented in the README).

No issue was filed from this pass: the role check refuses `/codeo:issue` here, so the later work is promised under `## Notes`. All eight findings are non-blocking and none sends the change back.

**Verdict: clear — forward to `/codeo:close`.**

## Log

- 2026-11-22 — qc round 1: build and suite passed, 10/10 criteria met as planned, F1-F3 blocking and plan-owned, F4-F12 non-blocking; sent back to /codeo:plan · cost: 13m · opus-5-5 479k in + 5M cached / 30k out · sonnet-5-5 366k in + 414k cached / 7k out
- 2026-11-23 — qc round 2: build and suite passed, 10/10 criteria met, round-1 F1-F3 fixed, F13-F20 non-blocking and recorded; clear, forward to /codeo:close · cost: 9m · opus-5-5 251k in + 4.4M cached / 35k out · sonnet-5-5 131k in + 818k cached / 6k out
