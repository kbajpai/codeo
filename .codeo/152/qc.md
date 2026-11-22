# Issue #152 — qc

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/152 |
| Branch | `feat/run-home-role-host-strict` |
| Updated | 2026-11-22 |

## Where this stands

Round 1 is written up under `## Outcome` and sent back to `/codeo:plan`: the suite passes and every acceptance criterion is met as the plan read it, but three blocking findings rest on plan decisions (a printed command that is not available everywhere and a false PowerShell claim, a tracker that defaults to the upstream repository, and a narrower "malformed table" than the issue asks for). Nothing is open.

## Questions

None.

## Notes

Evidence from this pass (nothing quoted from `implement.md`):
- `sync-main.sh --abort-on-conflict`: `the branch already contains origin/main`. `overlap.sh 152`: nothing printed. `overlap.sh --outside 152`: nothing printed (every changed path is inside the plan's footprint).
- `scope.sh origin/main HEAD`: `suite.shell=true` (`scope: suite shell needed for unclassified paths: .codeo/152/implement.md, .codeo/152/init.md, .codeo/152/plan.md, CHANGELOG.md, README.md`). No `deploy=` line, no shared environment configured: step 9 does not apply.
- Build, suite `shell`: `true` → exit 0.
- Test, suite `shell`: `bash tests/run.sh` → exit 0, last line `all cases passed` (55 test files, 6m57s).
- No invariants file and no `invariants-extra`/`wiki-rules` overlay (exit 3): the criteria and the reviewer are the standard.
- Documentation check: README.md, `.devcontainer/README.md`, `.sbx/README.md`, `CHANGELOG.md` and `docs/extension-points.md` were read against the code; findings F1, F4, F8, F9, F10 and F12 are documentation.
- Independent review (`QC review:` dispatch on the reviewer model, handed the acceptance criteria and the issue's requirements, not the implementer's account): verdict "With fixes", findings F1-F12 below. F2 and F3 were confirmed by reading `.devcontainer/codeo-track.sh` (`repo_slug` defaults to `kbajpai/codeo` when `CODEO_REPO_URL` is unset; `parse_body` state 2 accepts any `|` line as a row and `fmt_row` rewrites it).

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

## Log

- 2026-11-22 — qc round 1: build and suite passed, 10/10 criteria met as planned, F1-F3 blocking and plan-owned, F4-F12 non-blocking; sent back to /codeo:plan · cost: 13m · opus-5-5 479k in + 5M cached / 30k out · sonnet-5-5 366k in + 414k cached / 7k out
