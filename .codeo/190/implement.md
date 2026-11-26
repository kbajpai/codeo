# Issue #190 — implement

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/190 |
| Branch | `docs/190-make-container-sandbox-setup-reusable` |
| Updated | 2026-11-26 |

## Where this stands

Round 1. Tasks 1-11 are done and reviewed, and so is the in-checkout half of Task 12 (the `host-run.sh` script and its refusal test). The branch builds (`shell` suite `build` is `true`) and `bash tests/run.sh` ended `all cases passed` on the branch before the last fix wave (the wave's own suite run also ended `all cases passed`). Nothing in this dossier is open.

Not done, because this container has no Docker, `sbx`, .NET, Node or `kubectl`: the plan's host steps. They are the engineer's to run (commands below), and `/codeo:qc` cannot settle criteria 4, 5 and 7's real-run part until their output is pasted here.

## Questions

None.

## Notes

**Host steps still to run (the engineer, on their own host).** Prerequisites: Docker, `gh` logged in, `jq`, bash 4.3 or newer for doctor's `deps` check, and an empty **public** throwaway GitHub repository (`<owner>/<repo>`):
1. From a checkout of this branch with Node installed: `bash examples/csharp-angular/scripts/generate-web.sh`, then commit the generated `examples/csharp-angular/web/` (Task 7's host half).
2. `bash examples/csharp-angular/scripts/host-run.sh <owner>/<repo>` (Task 12 step 2-3). Expected: its last lines are `host-run: ok issue container shopdemo-1 ran the suites api web k8s` and doctor's output with no `fail` line except the host-dependent ones the script lists. Paste the output below.
3. In a fresh clone of that repository, in a terminal, run `bash <path to this checkout>/scripts/codeo-init.sh --env containers` and check it asks its questions on the terminal and ends with `init: ok` lines. The `curl | bash` form fetches the newest release tag, which predates this change, so it can only be exercised after this work is released; until then this run stands in for it. Paste the `init:` lines; the README transcript block is added from them.
4. Task 13 step 1: in the throwaway clone, `bash codeo-sandbox.sh issue 1 <branch>` (the file the wizard wrote under `.sbx/`), `bash codeo-sandbox.sh shell 1`, then inside it `bash scripts/run-suites.sh`; expect `suite: api ok`, `suite: web ok`, `suite: k8s ok`; then `bash codeo-sandbox.sh end 1`.
Removal commands for what `host-run.sh` creates are printed by the script; it removes nothing itself. A re-run needs a fresh empty repository and `shopdemo-1` removed first.

**Deferred Minor findings from task reviews (not fixed; for `/codeo:qc` and `/codeo:triage`):** Task 1: the prefix-codename and dots tests are regression guards more than failing-first tests, the branch regex allows `..`, one long comment line in `containers.sh`. Task 2: three overlay tests depend on the order of `tests/containers.test.sh`'s runner loop, and `no_shipped_file_names_codeo_where_the_project_belongs` is listed twice (predates this plan). Task 4: the self-fetch temp directory is left behind after `exec`. Task 5: the wording guard matches an exact phrase. Task 6: `doctor`'s suites check resolves only each command's first word; Docker's apt codename for Ubuntu 26.04, Playwright's `--with-deps` on 26.04, `~/.dotnet` state as root are unverified. Task 7: a partial `ng new` leaves output in `web/`, thin argument assertions, check order. Task 9: path A with a repository name that is not a valid codename now derives one or states why it cannot (fixed); the README transcript block waits for the host run. Task 10: the image-pin sentence is appended to an existing paragraph. Task 11: the v1.0.10 changelog bullet for #179 still says `role.sh` "is not shipped" (a released entry, correct for its release); `cleanup.md` carries `## removal-command`, not host-workflow text. Task 12: bsdtar may add AppleDouble files to the copied tree; `--no-audit`/`--no-fund` are not asserted. Final review: on a rerun with an existing config the wizard still validates the derived codename; the plugin pin's `plugin.repo` comes from `CODEO_PLUGIN_REPO` while its tag lookup uses `CODEO_PLUGIN_URL`.

## Outcome

**What was built** (21 commits on top of the first slice `c361707`, `82b44e6`…`5a4525e`):
- **Task 1** — `@BASE_BRANCH@` (`baseBranch`, default `main`) rendered into the `codeo` host command's download URL and `codeo-container.sh`'s base ref; validation before any write; the shipped-names scan now covers every rendered project. The audit found only those two literals to fix.
- **Task 2** — eight seed templates, `templates/containers/.codeo/overlays/*.md` (a `## role-guard` section each; host-workflow text for `init` and `close`; `cleanup` carries its `## removal-command`), written when absent and never overwritten; codeo's own overlays equal the render.
- **Task 3** — codeo's own `.devcontainer/Dockerfile` is the template plus a `shellcheck` RUN in the toolchain section; tests hold both seeds equal outside the parts a project owns.
- **Task 4** — `scripts/codeo-init.sh` fetches its own release when run alone (`CODEO_PLUGIN_URL`), prompts through `/dev/tty` only when stdin is a pipe.
- **Task 5** — `tests/setup.test.sh` guards the setup skill's `--codename`, `--containers` and never-creates-a-repository wording (`skills/setup/SKILL.md` itself unchanged by this plan).
- **Tasks 6-7** — `examples/csharp-angular/`: Dockerfile toolchain (.NET 10, Node 22, Playwright Chromium behind a `--no-sandbox` wrapper as `CHROME_BIN`, Docker CLI, `kubectl`), `codeo-suites.json` (api, web, k8s), the API under `api/` with `Api.slnx`, Kubernetes manifests, `scripts/run-suites.sh`, `scripts/generate-web.sh`.
- **Task 12 (in-checkout half)** — `scripts/host-run.sh` and its refusal test.
- **Final fix wave** — the wizard derives a valid codename from the repository name or stops before writing with the reason; the `--suite` build-colon limit is stated; usage errors for options with no value; the plugin pin uses `CODEO_PLUGIN_URL` and filters tags.

**Documentation changed:** `docs/container-templates.md` (new), `README.md` (*Adopting codeo with containers*, the `codename` row, *More documentation*), `.devcontainer/README.md` (*Using this in another project*), `.sbx/README.md`, `docs/home-checkout.md` (*Adopting the guard in your project*), `docs/skills.md` (`## setup`), `CHANGELOG.md` (`## Unreleased`); `tests/readme.test.sh` gained `adopting-paths` and `adopting-guard-ships` and the new page is among the pages it checks. The plan's "documentation moved" list is covered; `docs/skills-inventory.md` is unchanged, as the plan said.

**Build result:** the `shell` suite's `build` is `true` and exits 0. `bash tests/run.sh` ended `all cases passed`; `bash scripts/containers.sh --check` exits 0; `bash scripts/doctor.sh` prints no `fail` line.

**Deviations from the plan and why:**
- Task 6: the API is `api/Api/` + `api/Api.Tests/` with `api/Api.slnx`, not a nested test project, because `dotnet test api` resolves to the one project or solution directly in `api/` and would otherwise never run the test.
- Task 7: Chromium's sandbox is unavailable in a container, so `CHROME_BIN` points at a wrapper that adds `--no-sandbox`; no Karma launcher is generated.
- Task 12: the web suite's build installs its dependencies first (`ng new --skip-install` writes no lockfile, so `npm install`, not `npm ci`); the wizard step of `host-run.sh` accepts `ruleset`, `deps`, `superpowers` and `suites: not installed or unset` as host-dependent doctor failures and prints which occurred. The plan named only `ruleset`.
- Task 9: the README's *Adopting codeo with containers* carries no `init:` transcript yet; it is added from the host run (open item above). Task 12's host steps and Task 13's sandbox run are pending, as described under *Where this stands*.
- `docs/container-templates.md`'s example section and `.devcontainer/README.md` name `host-run.sh` (a follow-up `cc5b7b4`, not a plan task).

**Rulings I made** (each with what it costs if wrong):
1. Task 9's transcript waits for the host run; costs one follow-up round.
2. Task 12/13 host steps are handed to the engineer and reported as pending; costs a second `implement` round once the output is pasted.
3. Task 7: `CHROME_BIN` is a no-sandbox wrapper instead of a Karma launcher; if wrong the web suite fails on the host, which the Task 12 run shows.
4. Task 8: the forward link from `docs/container-templates.md` to the README section was kept and Task 9 made it true; if wrong, a dangling claim until Task 9 (it landed).
5. Task 12: the four host-dependent doctor failures are accepted and printed; the web build installs its dependencies; if wrong, `host-run.sh` reports a false FAIL or admits an unexpected `fail` line.
6. Final review: a `--suite` build command cannot contain a colon (documented, not changed); the default codename is derived from the repository name (lower-case, `.`/`_`/space to `-`) or refused with the reason before anything is written.

**Plan call to check (`/codeo:qc`):** the plan's own call that a fresh repository shows `fail ruleset` in doctor is stated in the README for hosts that have the project's toolchain and the plugins installed; the host run is where it is recorded.

## Log

- 2026-11-26 — implemented: Tasks 1-11 and the in-checkout half of Task 12 through subagent rounds on sonnet (every implementer, reviewer and fix round), 21 commits; host steps pending · cost: 68m · sonnet-5-5 1.7M in + 58M cached / 322k out
