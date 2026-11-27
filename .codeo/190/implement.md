# Issue #190 — implement

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/190 |
| Branch | `docs/190-make-container-sandbox-setup-reusable` |
| Updated | 2026-11-26 |

## Where this stands

Round 8 (send-back from `qc.md` round 7) is done: the blocking finding M1 (the README's remedy for a repository with no `origin/HEAD` did not work) and the cheap M3-M5 are fixed (see `### Round 8` under *Outcome*). The branch builds (`shell` suite `build` is `true`); nothing in this dossier is open. No host step is needed.

Round 7 (send-back from `qc.md` round 6) is done: the blocking finding L1 (the README's sample run named an empty repository) and the cheap L2-L7 are fixed (see `### Round 7` under *Outcome*). The branch builds (`shell` suite `build` is `true`); nothing in this dossier is open. No host step is needed.

Round 6 (send-back from `qc.md` round 5) is done: the blocking finding K1 (the doctor `containers` check missing from the README and `docs/skills.md`) and the cheap K4-K6 are fixed (see `### Round 6` under *Outcome*). The branch builds (`shell` suite `build` is `true`); nothing in this dossier is open. No host step is needed.

Round 5 (send-back from `qc.md` round 4) is done: the two blocking findings J1-J2 and the cheap ones J4-J13 (except J3) are fixed (see `### Round 5` under *Outcome*). The branch builds (`shell` suite `build` is `true`); nothing in this dossier is open. No host step is needed.

Round 4 (send-back from `qc.md` round 3) is built and reviewed: H1-H8 are fixed in five commits (`5c475e8`, `011974d`, `b8d523b`, `d5d4c21`, and the earlier round 3 ones stand), and the `shell` build passes. The round's outcome is not written: at the start of this check `overlap.sh 190` printed #192's overlaps on `CHANGELOG.md` and `docs/home-checkout.md`, which stop the step until Q1 and Q2 are answered (see *Questions*).

Round 3 (send-back from `qc.md` round 2) is done: the four blocking findings G1-G4 and the cheap non-blocking ones (G6, G8-G11) are fixed (see `### Round 3` under *Outcome*). The branch builds (`shell` suite `build` is `true`); nothing in this dossier is open. No host step is needed: the round changed wizard and setup behaviour, shipped text and pages, not the example's image.

Round 2 (send-back from `qc.md` round 1) is done: the six blocking findings and four non-blocking ones are fixed (see `### Round 2` under *Outcome*). The branch builds (`shell` suite `build` is `true`); nothing in this dossier is open. The engineer's clean `host-run.sh` re-run on a fresh empty repository passed (under *Outcome*, round 2).

Round 1. Tasks 1-11 are done and reviewed, and so is the in-checkout half of Task 12 (the `host-run.sh` script and its refusal test). The branch builds (`shell` suite `build` is `true`) and `bash tests/run.sh` ended `all cases passed` on the branch before the last fix wave (the wave's own suite run also ended `all cases passed`). Nothing in this dossier is open.

The engineer ran the host steps on a Linux host on 2026-11-26 (results under *Notes*). Done there: the example image builds (11 of 11 steps on Ubuntu 26.04); in an issue container the api (1 test), web (2 tests) and k8s suites all pass; the sandbox starts and clones the branch; the wizard asks its questions on the terminal when its stdin is a pipe. Found there and fixed: `host-run.sh` built the wrong image because the engineer's shell exports `CODEO_CONTEXT` (it now unsets the `CODEO_*` overrides and checks the toolchain before the suites). Found and documented: a sandbox runs Docker's pinned image, not the project's Dockerfile, so it has no .NET, Node or `kubectl`. The clean end-to-end run of the fixed `host-run.sh` on a fresh empty repository passed (below). The README's `init:` transcript block is added from that run (`215ff29`). Still open: `curl | bash` after a release, and a follow-up issue for a sandbox toolchain (below).

## Questions

### Q1 — #192 overlaps this branch on `CHANGELOG.md`. Proceed, sequence or re-scope?

`overlap.sh 190` printed, at this round's start, `192	CHANGELOG.md` and `192	glob:CHANGELOG.md`. #192 is on branch `feat/192-guard-home-checkout-no-project`, assigned to `kbajpai`, at the step `plan (working)` (it is waiting on `/codeo:implement`; its container `codeo-192` was live 11 minutes ago). Its footprint names `CHANGELOG.md`; this branch changes `CHANGELOG.md` too (the `## Unreleased` bullet for the container setup, written in round 1 and unchanged since).

**Why it matters:** both branches add to `## Unreleased`, so whichever merges second takes a textual conflict on that section. "Sequence after #192" holds this round's hand-off to `/codeo:qc` and the merge until #192 is merged; "proceed and coordinate" carries on and leaves the second merge to resolve two bullets side by side; "re-scope" would take this branch's changelog bullet out (the plan names `CHANGELOG.md` among the pages it moves, so that costs a plan change).
**Options:** proceed and coordinate · sequence after #192 · re-scope.
*Recommendation:* proceed and coordinate. #192 has not started implementing, this branch is much further along, and the conflict is two bullets under one heading that the later merge resolves in a minute; sequencing would hold a finished change for work that has not begun.

**Answer:**
Proceed and coordinate (engineer, "go with your picks", in the conversation, 2026-11-26; recorded here by the skill).

### Q2 — #192 overlaps this branch on `docs/home-checkout.md`. Proceed, sequence or re-scope?

`overlap.sh 190` printed `192	docs/home-checkout.md` and `192	glob:docs/home-checkout.md`; #192 is on branch `feat/192-guard-home-checkout-no-project`, assigned to `kbajpai`, at the step `plan (working)`. Its footprint names `docs/home-checkout.md` (it adds a hook, `hooks/home-guard.sh`, and documents it there); this branch rewrote the page's *Adopting the guard in your project* section (round 1).

**Why it matters:** the two edits are in different sections today, but #192 will describe a guard against edits in the home checkout, which is the same "home checkout" this branch's section says is named `<codename>-home`; a later merge may need the two descriptions reconciled, not just textually merged.
**Options:** proceed and coordinate · sequence after #192 · re-scope.
*Recommendation:* proceed and coordinate, and let #192's plan read this branch's *Adopting the guard in your project* section before it describes the guard.

**Answer:**
Proceed and coordinate (engineer, "go with your picks", in the conversation, 2026-11-26; recorded here by the skill).

## Notes

**Host results (the engineer's host, Linux, Docker, `sbx`; 2026-11-26; throwaway repository `kbajpai/rodeo`, codename `shopdemo`).**
- `host-run.sh` first run: the neutral image built, the wizard step, commit and push of `main` and `host-run/1` passed; the issue container started but its image held no toolchain (same image ID as codeo's own dev image), so `dotnet: command not found` failed the api suite. Cause: the engineer's shell exports `CODEO_CONTEXT=/home/kbajpai/Source/codeo/.devcontainer`, which makes `codeo-container.sh` build from that local folder instead of the Git URL. The GitHub copy of `.devcontainer/Dockerfile` at `host-run/1` was the example's. Fixed by `87b5c8a` and `20bed17`.
- `docker build` of `https://github.com/kbajpai/rodeo.git#host-run/1:.devcontainer`: 11 of 11 steps passed (.NET 10, Node 22, Playwright Chromium, Docker CLI, `kubectl`, Claude Code).
- In the issue container `shopdemo-1` (started from the work clone): `suite: api ok` (1 test passed, .NET 10), `suite: web ok` (`npm install`, `ng build`, `ng test`: 2 of 2 SUCCESS in Chrome Headless 159 through the no-sandbox wrapper), `suite: k8s ok` (`kubectl kustomize` rendered two Services and two Deployments). Run by hand, not by the script's own final step.
- Sandbox (`bash .sbx/codeo-sandbox.sh issue 1 host-run/1`): created from Docker's pinned image, cloned the branch, ran the start script; `bash scripts/run-suites.sh` inside it failed `dotnet: command not found` because the sandbox has no project toolchain. `bash .sbx/codeo-sandbox.sh end 1` removed it. Documented in `.sbx/README.md` (`a2c20da`).
- Wizard from a pipe: `printf '' | bash scripts/codeo-init.sh --skip-install` in a clone of `rodeo` asked its three questions and `Add a test suite` on the terminal, kept the config, and doctor ended with every check `ok` except `fail ruleset: main does not require: tests qc-verdict` (a new repository has no ruleset). Note: with an existing config the wizard still asks the codename, install-scope and environment questions (the config's codename was `shopdemo`; the question offered `rodeo`).
- A stray `codeo-1` container run by mistake from the codeo checkout was removed; the tracker found no active `codeo-1` rows on issue #1.
- Clean end-to-end run of the fixed `host-run.sh` (`bash examples/csharp-angular/scripts/host-run.sh kbajpai/rodeo`, a new empty public repository, `CODEO_CONTEXT` still exported in the shell): it printed `host-run: note: ignoring CODEO_CONTEXT`, then `ok neutral image builds` (the neutral template image, 6 steps), `ok work clone`, `ok example copied`, the wizard (`init: ok preflight`, `ok config`, `ok suite: api|web|k8s`, `ok config: plugin pin v1.0.10`, `ok containers: .devcontainer/ and .sbx/ written`) with doctor showing only `fail ruleset`, `ok wizard adopted the containers`, `ok committed and pushed main and host-run/1`, the issue image built from `https://github.com/kbajpai/rodeo.git#host-run/1:.devcontainer` (11 of 11 steps), `ok issue container toolchain`, `suite: api ok`, `suite: web ok`, `suite: k8s ok`, and `host-run: ok issue container shopdemo-1 ran the suites api web k8s`, then doctor (only `fail ruleset`) and the cleanup commands; nothing was removed. The generated Angular app (`examples/csharp-angular/web/`, 21 files) is committed to the branch (`eda67ce`).
- Still unverified: `curl | bash` (needs a release; the lone script fetches the newest release tag).

**Promised later work (no issue number yet):** let a project put its own toolchain into the sbx sandbox (the sandbox runs only Docker's pinned `docker.io/sbx/claude` image; `.sbx/claude-image` must be a digest of it). To be filed with `/codeo:issue` in the home checkout.

**Host steps as planned (the engineer, on their own host; run as the results above show, and re-run clean after round 2).** Prerequisites: Docker, `gh` logged in, `jq`, bash 4.3 or newer for doctor's `deps` check, and an empty **public** throwaway GitHub repository (`<owner>/<repo>`):
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
- Task 9: the README's *Adopting codeo with containers* carries the wizard's real `init:` lines from the host run (`215ff29`). The host steps ran on 2026-11-26 (results under *Notes*); the sandbox run showed the sandbox has no project toolchain, which is documented.
- `docs/container-templates.md`'s example section and `.devcontainer/README.md` name `host-run.sh` (a follow-up `cc5b7b4`, not a plan task).
- After the engineer's host run: `host-run.sh` unsets the `CODEO_*` overrides and checks the toolchain in the container before the suites (`87b5c8a`, `20bed17`), and `.sbx/README.md`, `docs/container-templates.md`, `README.md` and `CHANGELOG.md` say the sandbox runs Docker's pinned image without the project's toolchain (`a2c20da`). Neither was a plan task.

**Rulings I made** (each with what it costs if wrong):
1. Task 9's transcript waits for the host run; costs one follow-up round.
2. Task 12/13 host steps are handed to the engineer and reported as pending; costs a second `implement` round once the output is pasted.
3. Task 7: `CHROME_BIN` is a no-sandbox wrapper instead of a Karma launcher; if wrong the web suite fails on the host, which the Task 12 run shows.
4. Task 8: the forward link from `docs/container-templates.md` to the README section was kept and Task 9 made it true; if wrong, a dangling claim until Task 9 (it landed).
5. Task 12: the four host-dependent doctor failures are accepted and printed; the web build installs its dependencies; if wrong, `host-run.sh` reports a false FAIL or admits an unexpected `fail` line.
6. Final review: a `--suite` build command cannot contain a colon (documented, not changed); the default codename is derived from the repository name (lower-case, `.`/`_`/space to `-`) or refused with the reason before anything is written.

**Plan call to check (`/codeo:qc`):** the plan's own call that a fresh repository shows `fail ruleset` in doctor is stated in the README for hosts that have the project's toolchain and the plugins installed; the host run is where it is recorded.

### Round 2 — 2026-11-26
(send-back from qc.md round 1)

**What was built** (four commits on top of round 1: `7925696`, `f5debad`, `7073173`, `e86257f`; each task was reviewed, three needed a fix round):
- **F1** — `tests/example.test.sh`: `generate_web_names_a_pinned_cli_and_refuses_an_existing_app` starts from an emptied copy of `web/` (dotfiles included), so it again covers a run on an empty `web/` and the refusal on an existing `angular.json`.
- **F2** — `docs/container-templates.md`, `.devcontainer/README.md`, `examples/csharp-angular/scripts/host-run.sh` (header and guard) and `generate-web.sh` (comment) say the example ships its generated Angular app and that `generate-web.sh` regenerates it; the numbered steps are renumbered.
- **F3** — `scripts/setup.sh` writes `codename` whenever `--containers` is given and none is in the config (the repository name normalised by one shared function, `lib/codename.sh`, also used by `codeo-init.sh`), fails before writing when none can be derived, and adds a missing codename to an existing config; `scripts/containers.sh` refuses a config without one and no longer defaults to the repository name. The README's `codename` row states one rule.
- **F4** — `setup.sh --containers` writes `plugin.repo` and `plugin.ref` (newest `vX.Y.Z` release; soft failure with one line when none is found); `/codeo:doctor`'s `containers` check fails when the container scripts exist and the pin is absent.
- **F5** — the shipped overlays and managed scripts no longer name `.devcontainer/README.md` or `.sbx/README.md` (a project does not receive them): they name the scripts a project has (`bash .devcontainer/codeo-container.sh …`) and, for the sandbox, the folder the script runs from (`codeo issue <N> <branch> --sandbox`, or `codeo-sandbox.sh` in a folder outside the project clone).
- **F6** — `templates/containers/.codeo/overlays/init.md` uses `@BASE_BRANCH@`; the audit table in `docs/container-templates.md` lists it; a test renders an overlay for `develop`.
- **F7** — the install step's stderr goes to a `mktemp` file.
- **F8** — `containers.sh` refuses `TODO-set-me` for `baseBranch`, `repo.owner` and `repo.name`; the wizard prints `init: fail config: baseBranch is TODO-set-me (…)` and skips containers.
- **F9** — the wizard prints `init: ok containers: <n> written, <m> kept` from `containers.sh`'s own lines, prints `init: skip codename: …` when a rerun's answer differs from the kept config, and the README and the script header say a rerun adds only `--suite` entries and the plugin pin to a kept config.
- **F10** — `tests/init.test.sh`: the unattended run asserts doctor's only `fail` is `ruleset`, no `kbajpai` or `codeo-<N>` in the project's container and overlay files, and the codename in the config; the rerun case keeps an edited Dockerfile and overlay under `--env containers`.

**Build result:** the `shell` suite's `build` is `true`: exit 0. For information, `bash tests/run.sh` ended `all cases passed` on this tree, `bash scripts/containers.sh --check` prints no `differs`, and `bash scripts/doctor.sh` prints no `fail`; grading is `/codeo:qc`'s.

**Documentation pages changed this round:** `README.md` (the `codename` row, the Adopting section: rerun behaviour and the transcript lead-in), `docs/container-templates.md`, `.devcontainer/README.md`, `docs/skills.md`, `CHANGELOG.md` is unchanged.

**Deviations and rulings (each with what it costs if wrong):**
1. F3 was classified implement's although the plan specified "codename, else the repository name"; the plan's goal (criterion 2) requires matching names, and the fix stays in the plan's files. `containers.sh` now refuses a config with no codename instead of defaulting; a project that relied on the old default must run `setup.sh --containers` once. Costs: one extra step for a hand-written config.
2. F4: the pin is written by `setup.sh` (soft failure offline) and enforced by doctor, rather than only one of the two. Costs: `setup.sh --containers` does a `git ls-remote` against the plugin repository.
3. F5: READMEs are not shipped; the text was reworded. Costs: no per-project README for the container commands.
4. The README transcript's `init: ok containers:` line was first edited by hand to `23 written, 0 kept`; the engineer's clean re-run then printed `22 written, 1 kept` (the example's Dockerfile was already in place), and the README now shows that run's output verbatim (`d1cc0d8`).
5. The 'Linux host' in that lead-in comes from the engineer's prompts and tracker rows.

**Footprint gap, for `/codeo:qc` and the engineer:** `overlap.sh --outside 190` now prints `lib/codename.sh`, `tests/close-removal.test.sh`, `tests/doctor.test.sh`, `tests/folder-check.test.sh`, `tests/init-overlay.test.sh` and `tests/role.test.sh`. They are needed by the change (the shared derivation library and the tests that pin the reworded messages), and `plan.md`'s footprint, which this skill does not edit, left them out. On a first-round plan this is not blocking; a send-back to `/codeo:plan` would add them.

**Deferred Minor findings from this round's reviews (not fixed):** `generate-web.sh`'s header comment wraps unevenly; `docs/container-templates.md` says "To regenerate `web/` first" after the copy instruction; `codeo_derive_codename` and the `[a-z]` patterns are locale-dependent (non-ASCII names pass under a UTF-8 glibc locale); `setup.sh` prints "pinned the plugin"/"wrote codename" without checking that `jq` and `mv` succeeded and can leave `config.json.new` behind; `--containers` alone on invalid JSON says `cannot derive a codename from ''`; `write_pin` treats an empty-string `plugin` as present while doctor treats it as absent; the wizard's `skip containers: baseBranch is not set` prints even when env is none; the wizard's fetch preamble keeps its own copy of the release lookup (the library is not on disk before the clone); the init overlay's fallback names `codeo-sandbox.sh` without saying `codeo-track.sh` must sit beside it; the wizard's `skip codename` line prints on every rerun without `--codename` where the derived default differs; `overlays_name_the_base_branch` was not seen failing on its own.

**Host re-run (the engineer, 2026-11-26, after round 2):** `bash examples/csharp-angular/scripts/host-run.sh kbajpai/rodeo2` on a new empty public repository, with `CODEO_CONTEXT` still exported: `host-run: note: ignoring CODEO_CONTEXT`; `ok neutral image builds`; the wizard (`init: ok containers: 22 written, 1 kept`, doctor with only `fail ruleset`); `ok committed and pushed main and host-run/1`; the issue image built from the Git URL (11 of 11 steps); `ok issue container toolchain`; `suite: api ok` (1 test), `suite: web ok` (2 of 2 SUCCESS), `suite: k8s ok`; `host-run: ok issue container shopdemo-1 ran the suites api web k8s`. Everything it created was removed. This is evidence for `/codeo:qc` that round 2's changes still pass the example end to end.

### Round 3 — 2026-11-26
(send-back from qc.md round 2)

**What was built** (three commits on top of round 2: `04ff584`, `46ab55b`, `c41b6cd`; each reviewed, the docs one needed a fix round):
- **G1** — `scripts/codeo-init.sh` writes the derived or given codename into a kept config that has none (atomic temp file and `mv`; a failed write prints no success line), with the same derivation and failure lines as for a new config; `containers.sh`'s hint is `run setup.sh --containers (it adds one), or set codename in .codeo/config.json`; `setup.sh --codename <name> --containers` on an existing codename-less config writes the codename, is a no-op when it already names the same one, and refuses `config.json already names '<x>'` for a different one.
- **G3** — `setup.sh --containers` and the wizard print where the home checkout lives: the helper `codeo_home_lines` (in `lib/codename.sh`) says a home checkout is a clone whose folder is named `<codename>-home`, and, only when the folder differs, to rename or re-clone it; the adoption pages say the same, and what `role.sh` decides (on the host a clone is home with that folder name, no lock and the base branch; no lock in another folder reads `stray`; `<codename>-home` off the base branch reads `stale:?`; a container in another folder is unguarded).
- **G2** — the README adoption section, `docs/container-templates.md` and `.devcontainer/README.md` state that the repository must be public (the image build's Git URL, the container's clone and the `codeo` command's raw downloads use no credentials; the `codeo issue` branch lookup uses the host's `git`), name the workarounds the code gives (`CODEO_CONTEXT` for the image build only, `CODEO_RAW_URL`, `CODEO_REPO_URL`, scripts pre-placed in `CODEO_HOME`) and say that a private repository's container still fails and that codeo has no authenticated fetch.
- **G4** — every command a project runs reads `bash <plugin>/scripts/containers.sh`, with `<plugin>` explained once per page.
- **G6** — `setup.sh --containers` on an existing config refuses `repo.owner` or `repo.name` of `TODO-set-me` before deriving a codename, writing nothing.
- **G8, G9** — the close overlay's stash and abandon pointers say `codeo help` lists `codeo rm`; the init overlay leads with `codeo issue <N> <branch> --container` and `codeo shell <N>`, with `bash .devcontainer/codeo-container.sh …` as the fallback from a host clone; codeo's own overlays are re-rendered and equal.
- **G10** — `CODEO_HOME` is named in the three adoption pages.
- **G11** — `no_shipped_file_names_codeo_where_the_project_belongs` renders its own project, asserts a non-empty file list, and scans for a leaked `~/codeo` and the titles `codeo [home]` / `codeo [#N]`.

**Build result:** the `shell` suite's `build` is `true`: exit 0. For information, `bash scripts/containers.sh --check` prints no `differs` and `bash scripts/doctor.sh` prints no `fail`; the implementers' own full runs of `bash tests/run.sh` ended `all cases passed` for the first two commits; grading is `/codeo:qc`'s.

**Documentation pages changed this round:** `README.md`, `docs/container-templates.md`, `.devcontainer/README.md`, and the overlay templates under `templates/containers/.codeo/overlays/` with codeo's own copies.

**Deviations and rulings (each with what it costs if wrong):**
1. The public-repository requirement is stated in prose on the three pages, not as a row of the audit table, because the table's two kinds (Placeholder, Intentionally codeo's) do not describe repository visibility; the table gained a Placeholder row for the `<codename>-home` folder name. Costs: the audit table alone does not list visibility.
2. G11 turned up a real leak the earlier audit missed: the `codeo-container.sh` template hardcoded the window titles `codeo [home]` and `codeo [#N]`; they are now `@CODENAME@ [home]` and `@CODENAME@ [#$1]` (codeo's own checked-in file renders to the same text). One allowed exception is documented in the test: the header comment of `.devcontainer/scripts/session-title.sh`.
3. The wizard also writes a missing codename for `--env none` (a plain rerun over a codename-less config edits it); the header says so. Costs: a rerun without containers still changes the config.
4. G5 (one `codeo` command per machine), G7 (pin the rendering plugin's own version) and G12 (the footprint gap) are not fixed here; they are `/codeo:plan`'s or a follow-up issue (`qc.md` `## Notes`).

**Footprint gap still open (`/codeo:plan`'s):** `overlap.sh --outside 190` prints `lib/codename.sh`, `tests/close-removal.test.sh`, `tests/doctor.test.sh`, `tests/folder-check.test.sh`, `tests/init-overlay.test.sh` and `tests/role.test.sh`; `plan.md`'s footprint, which this skill does not edit, omits them.

**Deferred Minor findings from this round's reviews (not fixed):** with an invalid-JSON config the wizard's plugin-pin step can leave `.codeo/config.json.new` behind (no data loss, the original stays intact); the jq/`mv` failure branches of the wizard and `setup.sh` are not exercised by a test; the G11 leak scan's `~/codeo` pattern does not catch `$HOME/codeo` or an absolute `/home/x/codeo`; `codeo_home_lines` prints an empty folder name for a project at `/`; four rewritten sentences start with a capital "On" after a colon; `docs/container-templates.md:36` says "only when its folder has this name", which is loose but not false; the README's adoption bullets and the reference page repeat the same long paragraph in several places (a maintenance risk).

### Round 4 — 2026-11-26
(send-back from qc.md round 3)

**What was built** (four commits on top of round 3: `5c475e8`, `011974d`, `b8d523b`, `d5d4c21`; each reviewed, two needed a fix round):
- **H1** — the pages say one `codeo` command serves one project per machine: an audit-table row in `docs/container-templates.md`, a condition in the README's adoption section and a paragraph next to the install line in `.devcontainer/README.md`; renaming the installed file to `~/.local/bin/<codename>` is the documented way to keep two projects (checked against `cmd_update` and `home_dir` in the command: `update` replaces the file it runs as, the home comes from `CODEO_HOME` or `~/<codename>`).
- **H2** — the README's adoption section carries the project's `codeo` install line and links `.devcontainer/README.md#using-this-in-another-project`; "the install line below" is true.
- **H3** — a project that already has `.devcontainer/Dockerfile`, `devcontainer.json` or `.codeo/overlays/*.md` keeps them; `setup.sh` and the wizard print one note when a seed was kept (counted from `containers: skip` lines for the seed paths), and `docs/container-templates.md` lists what a kept seed must keep (the `dev` user, gh and Claude Code, `runArgs --name=${containerWorkspaceFolderBasename}` and the volumes, the `## role-guard` and `## host-workflow` overlay sections).
- **H4** — the README says the `curl … | bash` command fetches the newest release and works from the first release that ships `scripts/codeo-init.sh`; until then run `bash <plugin>/scripts/codeo-init.sh --env containers`.
- **H5** — the pin writers fill only the missing key (`lib/codename.sh`: `codeo_pin_missing`, `codeo_pin_fill`, `codeo_pin_url`), used by `setup.sh`, the wizard and doctor; the release for a missing ref is looked up in the repository the config names (`CODEO_PLUGIN_URL` wins when set; `CODEO_PLUGIN_BASE` is the testable prefix); doctor names only the missing key; a `plugin.repo` that is not `owner/name` is refused.
- **H6** — the wizard prints `init: fail suite: <name>: could not write .codeo/config.json` and goes on to the next suite.
- **H7** — the README lists every question the wizard asks.
- **H8** — `no_shipped_file_names_codeo_where_the_project_belongs` is registered once.
- Also: `setup.sh` and the wizard stop with one line when `.codeo/config.json` is not a JSON object (the wizard before it writes or installs anything, nothing printed by jq, the file byte-identical).

**Build result:** the `shell` suite's `build` is `true`: exit 0. For information, `bash scripts/containers.sh --check` prints no `differs` and `bash scripts/doctor.sh` prints no `fail`; the implementers' own full runs of `bash tests/run.sh` ended `all cases passed`; grading is `/codeo:qc`'s.

**Documentation pages changed this round:** `README.md`, `docs/container-templates.md`, `.devcontainer/README.md`.

**Overlap with #192** (`feat/192-guard-home-checkout-no-project`, plan step): `overlap.sh 190` printed `192	CHANGELOG.md` and `192	docs/home-checkout.md` at the end of this round; Q1 and Q2 were answered *proceed and coordinate* (engineer, 2026-11-26). Nothing of #192's was touched; this round did not change `CHANGELOG.md` or `docs/home-checkout.md`.

**Deviations and rulings (each with what it costs if wrong):**
1. H9 (the example's `k8s` suite runs `kubectl kustomize k8s` as both build and test) was not taken: the two commands were verified on the engineer's host, and changing them without a host re-run would break that evidence. Costs: the `k8s` suite's test only proves the manifests render.
2. When the newest release cannot be found, neither pin key is written even if `plugin.repo` is also missing; doctor still fails the incomplete pin. Costs: `setup.sh --containers` offline leaves the pin to the engineer.
3. The wizard stops right after the preflight line on a bad config, so it prints one line and no doctor output. Costs: less output on a broken config.
4. H1 is documentation only: the launcher keeps its fixed name; a per-project command name or a refusal on a repository mismatch is `/codeo:plan`'s (`qc.md` `## Notes`).

**Footprint gap still open (`/codeo:plan`'s):** `overlap.sh --outside 190` prints `lib/codename.sh`, `tests/close-removal.test.sh`, `tests/doctor.test.sh`, `tests/folder-check.test.sh`, `tests/init-overlay.test.sh` and `tests/role.test.sh`.

**Deferred Minor findings from this round's reviews (not fixed):** `docs/container-templates.md` says a seed needs "a dev user with UID 1000" though only the Dockerfile's `ARG USER_UID=1000` fixes the number (conservative); `codeo_pin_url`'s dot-only segments such as `a/..` pass the `plugin.repo` pattern and just fail the lookup; the wizard's guard uses `-e` where later steps use `-f`; `codeo_pin_missing` prints nothing on an invalid config in the code paths that do not check validity first; a `CODEO_PLUGIN_BASE` with a trailing slash yields `base//owner/name.git`; the seed note prints on every rerun of an unmodified project; `.devcontainer/README.md`'s "`codeo update` from it" does not say it means `codeo update` run through the other project's command.

### Round 5 — 2026-11-27
(send-back from qc.md round 4)

**What was built** (four commits on top of round 4: `d8a4dd9`, `d210e9d`, `83f1e8f`, `7953b3f`; each reviewed, two needed a fix round):
- **J1** — the README's adoption section says the transcript block is that run's output up to the `containers` line and doctor's lines, and that the wizard also prints `init: note:` lines that are not in the block (the kept-seed note and the home-checkout lines after the `containers` line; the private-repository note after the preflight line), named from the code; the "one line per step" sentence and the header comment of `scripts/codeo-init.sh` mention the notes.
- **J2** — `docs/skills.md`'s setup section says `--containers`, alone or with `--codename <name>`, works over an existing config (adds a missing codename and plugin pin, writes the container files), that `--codename <other>` is refused when the config already names a different codename, and that plain `setup.sh`, `--stack` and `--codename` without `--containers` still refuse over an existing config.
- **J4** — setup and the wizard say `is not a JSON object` for valid JSON that is not an object and `is not valid JSON` when jq cannot parse it, one line, nothing written.
- **J5** — the messages name files a project has (`/codeo:setup --containers`, doctor's refresh hint with the real plugin path, `docs/container-templates.md` in the codeo plugin); each adoption page says how to find `<plugin>` (`bash .devcontainer/scripts/codeo-root.sh`, `CODEO_ROOT`, the registry's `installPath` for `codeo@codeo`, and that it fails without `scripts/lock.sh`).
- **J6** — a rerun says `the derived codename '<x>' is ignored` when nobody answered or flagged one.
- **J7** — over an existing config, setup and the wizard (with `--env containers`) check `baseBranch` (the `TODO-set-me` marker and the branch-name pattern, one shared function in `lib/codename.sh` that `scripts/containers.sh` now also calls) before any write, with containers.sh's message; an empty or absent `baseBranch` still defaults to `main`; `run_containers` prints nothing for empty output.
- **J8** — `--version` must look like `vX.Y.Z` (both parsers, exit 2).
- **J9, J13** — the audit row names the three places the plugin's default source appears; the CHANGELOG bullet says managed scripts and overlays are rendered from the same templates and the Dockerfile and `devcontainer.json` equal them outside the toolchain section and one extension.
- **J10** — the kept-seed note names the sections each overlay needs.
- **J11** — the wizard reads `.private`/`.visibility` from its existing `gh api` call and prints one `init: note:` for a private repository (a note, not a refusal); the README and `docs/container-templates.md` say so.
- **J12** — `codeo_pin_fill` says so on stderr when it replaces a `plugin` value that is not an object.

**Build result:** the `shell` suite's `build` is `true`: exit 0. For information, `bash scripts/containers.sh --check` prints no `differs` and `bash scripts/doctor.sh` prints no `fail`; the implementer's own full runs of `bash tests/run.sh` ended `all cases passed`; grading is `/codeo:qc`'s.

**Documentation pages changed this round:** `README.md`, `docs/skills.md`, `docs/container-templates.md`, `.devcontainer/README.md`, and one clause of `CHANGELOG.md`.

**Overlap with #192:** it is now at the step `implement (working)`; `overlap.sh 190` printed nothing at the end of this round (the pairs on `CHANGELOG.md` and `docs/home-checkout.md` were answered as Q1 and Q2: *proceed and coordinate*). This round touched one clause of `CHANGELOG.md` and nothing in `docs/home-checkout.md`.

**Deviations and rulings (each with what it costs if wrong):**
1. J3 (the wizard exits 1 on a fresh adoption because doctor's `ruleset` check fails on a new repository) was not changed: it is the plan's stated exception. Costs: CI treats a fresh adoption as a failure.
2. The wizard's `baseBranch` check applies when a config exists and `--env containers` is given; an `--env none` rerun over a `TODO-set-me` config is not stopped (it writes no container file). Costs: a stale marker survives until containers are added.
3. The README transcript block was not re-captured (a host re-run is the engineer's to do if a verbatim block with the notes is wanted).
4. In `scripts/containers.sh` the `baseBranch` refusal now precedes the owner, name and codename refusals, so a config with several bad values reports `baseBranch` first.

**Footprint gap still open (`/codeo:plan`'s):** `overlap.sh --outside 190` prints `lib/codename.sh`, `tests/close-removal.test.sh`, `tests/doctor.test.sh`, `tests/folder-check.test.sh`, `tests/init-overlay.test.sh` and `tests/role.test.sh`.

**Deferred Minor findings from this round's reviews (not fixed):** the header comment at `lib/codename.sh:17` still says `codeo_base_error` refuses only `TODO-set-me`; an empty config file is reported as `is not a JSON object` (jq parses empty input) and a directory as `is not valid JSON`; the J11 note prints with a plain `echo`, not through `say`; `codeo_base_error` ignores a jq failure that cannot happen after the shape check; the `<plugin>` lookup sentence relies on the script's registry lookup, not a run against a real registry; the engineer's host runs predate J4-J12, so the example's image build and the wizard against a real repository were not re-run after this round.

### Round 6 — 2026-11-27
(send-back from qc.md round 5)

**What was built** (one commit on top of round 5: `f23bf6f`; the implementer ran on sonnet and the diff was read before this outcome):
- **K1** — the README's *Checks from /codeo:doctor* group has a **containers.** entry covering both causes (managed scripts that differ from the templates, fixed with `containers.sh --force`; a missing `plugin.repo` or `plugin.ref`, fixed with `/codeo:setup --containers` or by setting both) and a sample line; the "does not check" sentence no longer lists `plugin`, and says the pin is checked for a project that has container scripts; the check counts in the README (the doctor transcript note and the skills table) and in `docs/skills.md` (Purpose, the checks sentence, Reads) say eleven checks plus `priority-labels` and `containers` in the projects they apply to; `tests/readme.test.sh` pins `containers` among thirteen names.
- **K4** — doctor's pin message says "the container scripts are present" (the check also triggers on `.sbx/codeo-sandbox.sh` alone); the two assertions in `tests/doctor.test.sh` match.
- **K5** — the README says the home-checkout note prints when the containers step ran and the config has a codename.
- **K6** — `.devcontainer/scripts/plugins.sh`'s header says "the project's issue containers need" (it has no template copy; `containers.sh --check` is clean); the rename note says "to run the home skills (/codeo:issue, /codeo:init, /codeo:triage, /codeo:cleanup) here" in `lib/codename.sh`, `tests/containers.test.sh`, `tests/init.test.sh` and the README.

**Build result:** the `shell` suite's `build` is `true`: exit 0. For information, the implementer ran `containers`, `doctor`, `readme`, `init`, `skills-doc`, `setup` and `role`, each ending `all cases passed`, and `bash scripts/containers.sh --check` prints no `differs`; grading is `/codeo:qc`'s.

**Documentation pages changed this round:** `README.md`, `docs/skills.md`.

**Overlap with #192:** `overlap.sh 190` printed nothing at the start of this round; nothing this round touches `CHANGELOG.md` or `docs/home-checkout.md`.

**Left for `/codeo:triage` or a later round (non-blocking, not taken):** K2 (the wizard and `setup --containers` derive the codename from different sources when the kept config's `repo.name` differs from origin), K3 (a few refusals still come after the pin is written), K7 (the wizard asks "Codename" at a terminal when the kept config already names one, then ignores the answer), K8 (`containers.sh --force` writes through a symlink at a managed path). The footprint gap in `plan.md` stays `/codeo:plan`'s. No host step is needed.

### Round 7 — 2026-11-27
(send-back from qc.md round 6)

**What was built** (one commit on top of round 6: `10fae4b`; the implementer ran on sonnet and the diff was read against `scripts/codeo-init.sh` and `scripts/doctor.sh` before this outcome):
- **L1** — the README's sample run is described as the output of a clone of a repository with one commit on `main` and `origin/HEAD` set; one added sentence says a repository with no commit yet has no `origin/HEAD`, quotes what the wizard prints then (`init: fail config: baseBranch is TODO-set-me (the clone has no origin/HEAD: …)` and `init: skip containers: baseBranch is not set`, both checked against `scripts/codeo-init.sh`) and gives the fix (`git remote set-head origin <base>` after the first push, or `baseBranch` in `.codeo/config.json`).
- **L2, L4** — the README's **containers.** entry lists three causes (drift, a managed script that is missing, a missing pin, and a config the templates cannot be rendered from, with the form of its line), and `docs/skills.md`'s doctor section says the check also fails when the config cannot be rendered. The third cause's example line comes from the QC review's reproduction; it was not re-run in a scratch project here.
- **L3** — doctor's pin message ends "set it" for one missing key and "set them" for two; `tests/doctor.test.sh` has a one-key assertion beside the two-key ones.
- **L5** — the README's check list names the eleven always-run checks only.
- **L6** — the `codename` row says `scripts/containers.sh` refuses a config without a codename and that `container-name.sh` and `role.sh` fall back to the clone's folder name.
- **L7** — the three pages say `~/<codename>` (the repository's name made to fit the rule, unless it is set).

**Build result:** the `shell` suite's `build` is `true`: exit 0. For information, the implementer ran `readme`, `doctor`, `containers`, `skills-doc`, `init` and `example`, each ending `all cases passed`, and `bash scripts/containers.sh --check` prints no `differs`; grading is `/codeo:qc`'s.

**Documentation pages changed this round:** `README.md`, `docs/skills.md`, `docs/container-templates.md`, `.devcontainer/README.md`.

**Overlap with #192:** `overlap.sh 190` printed nothing at the start of this round; nothing this round touches `CHANGELOG.md` or `docs/home-checkout.md`.

**Left for `/codeo:triage` or a later round (non-blocking, not taken):** L8 (a fresh `setup.sh --containers` in a clone without `origin/HEAD` writes the config before `containers.sh` refuses; K3 again), L9 (an invalid `--codename` stops the wizard though the kept config names a codename, and the wizard asks for a codename it ignores; K7 again), and K2 and K8 from round 5. The footprint gap in `plan.md` stays `/codeo:plan`'s. No host step is needed; the README's sample block is still the engineer's host capture and was not re-run.

### Round 8 — 2026-11-27
(send-back from qc.md round 7)

**What was built** (one commit on top of round 7: `e264dbf`; the implementer ran on sonnet and the diff was read against `lib/codename.sh` and `scripts/codeo-init.sh` before this outcome):
- **M1** — the README's remedy for a repository with no `origin/HEAD` is the one that works: the first run has already written `.codeo/config.json` with `baseBranch` set to `TODO-set-me`, a rerun keeps it and stops with `init: fail config: config.json: baseBranch is TODO-set-me; set baseBranch in .codeo/config.json to the repository's base branch` (the text of `codeo_base_error`, `lib/codename.sh:106`), so the page says to set `baseBranch` in the config and run the wizard again, and that `git remote set-head origin <base>` before the first run avoids the failure. `tests/init.test.sh`'s `a_clone_without_origin_head_does_not_say_ok_and_skips_the_containers` now also reruns, checks that message, sets `baseBranch` to `main` with `jq`, reruns again and checks the container files are written (the documented remedy, run). No other page stated the wrong remedy.
- **M3** — the sample's conditions name `dotnet`, `npm` and `kubectl` on the host's `PATH` and the installed superpowers plugin, and say doctor prints `fail suites` and `fail superpowers` lines without them.
- **M4** — "or running `codeo update` from it" is removed from the one-`codeo`-per-machine passages in `README.md`, `.devcontainer/README.md` and `docs/container-templates.md`; they say installing another project's command at that path replaces the first, and that `codeo update` replaces the file it runs as.
- **M5** — the audit row says `codeo-container.sh` and `codeo-sandbox.sh` clone the repository and `codeo-track.sh` derives the slug for its `gh` comment calls.

**Build result:** the `shell` suite's `build` is `true`: exit 0. For information, the implementer ran `readme`, `init`, `containers`, `skills-doc`, `doctor` and `example`, each ending `all cases passed`, and `bash scripts/containers.sh --check` prints no `differs`; grading is `/codeo:qc`'s.

**Documentation pages changed this round:** `README.md`, `.devcontainer/README.md`, `docs/container-templates.md`.

**Overlap with #192:** `overlap.sh 190` printed nothing at the start of this round; nothing this round touches `CHANGELOG.md` or `docs/home-checkout.md`.

**Left for `/codeo:triage` (non-blocking, not taken):** M2 (a rerun fails with `cannot derive a codename from '<repo>'` when the repository name gives no codename although the kept config has one; the same family as K2, K3, K7, L8 and L9: how the wizard and `setup --containers` treat an existing config), M6 (doctor's refresh hint can name the temporary release clone when the wizard ran through `curl … | bash`), and K8. The footprint gap in `plan.md` stays `/codeo:plan`'s. No host step is needed.

## Log

- 2026-11-26 — implemented: Tasks 1-11 and the in-checkout half of Task 12 through subagent rounds on sonnet (every implementer, reviewer and fix round), 21 commits; host steps pending · cost: 68m · sonnet-5-5 1.7M in + 58M cached / 322k out
- 2026-11-26 — host results recorded; host-run hardening and sandbox documentation added after the engineer's run · cost: 124m · sonnet-5-5 1.9M in + 75.8M cached / 386k out
- 2026-11-26 — round 2 (send-back from qc round 1): F1-F10 fixed in four commits, each task reviewed on sonnet · cost: 34m · sonnet-5-5 563k in + 23.8M cached / 96k out
- 2026-11-26 — round 3 (send-back from qc round 2): G1-G4 and G6, G8-G11 fixed in three commits, each task reviewed on sonnet · cost: 20m · sonnet-5-5 417k in + 33.6M cached / 82k out
- 2026-11-26 — round 4 (send-back from qc round 3): H1-H8 fixed in four commits, each task reviewed on sonnet; overlap questions Q1-Q2 answered · cost: 73m · sonnet-5-5 499k in + 27.4M cached / 90k out
- 2026-11-27 — round 5 (send-back from qc round 4): J1-J2 and J4-J13 fixed in four commits, each task reviewed on sonnet · cost: 16m · sonnet-5-5 320k in + 18.7M cached / 61k out
- 2026-11-27 — round 6 (send-back from qc round 5): K1 and K4-K6 fixed in one commit, reviewed by reading the diff · cost: 2m · sonnet-5-5 89k in + 1.4M cached / 11k out
- 2026-11-27 — round 7 (send-back from qc round 6): L1-L7 fixed in one commit, reviewed by reading the diff against the code · cost: 2m · sonnet-5-5 74k in + 1.2M cached / 10k out
- 2026-11-27 — round 8 (send-back from qc round 7): M1 and M3-M5 fixed in one commit, reviewed by reading the diff against the code · cost: 2m · sonnet-5-5 73k in + 1.4M cached / 10k out
