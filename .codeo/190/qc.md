# Issue #190 — qc

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/190 |
| Branch | `docs/190-make-container-sandbox-setup-reusable` |
| Updated | 2026-11-26 |

## Where this stands

Round 1 is written and routed back to `/codeo:implement`: the full shell suite fails at HEAD, and the reviewer and this pass found five more blocking findings. Nothing is open; the routing needs no answer from the engineer.

## Questions

None.

## Notes

**Promised later work (no issue number yet; `/codeo:issue` is refused in an issue checkout, so file each with `/codeo:issue` in the home checkout):**
- One `codeo` host command per machine: every adopted project ships its own rendered `codeo` with its repository and `~/<codename>` baked in, and `.devcontainer/README.md` tells each project to install it as `~/.local/bin/codeo`, so a second project silently replaces the first. A per-project command name, or a project-neutral `codeo`, is a design choice.
- Let a project put its own toolchain into the sbx sandbox (already promised in `implement.md`).
- `sort -V` in `scripts/codeo-init.sh` is missing on macOS before 13 (the release lookup fails there with "no release found").

## Outcome

### Round 1 — 2026-11-26

**Pass.** `sync-main.sh --abort-on-conflict`: `sync-main: the branch already contains origin/main`. `overlap.sh 190`: nothing printed (exit 0). `overlap.sh --outside 190`: nothing printed (exit 0). `scope.sh origin/main HEAD` (73 files changed, 5295 insertions, 27 deletions): every changed path was unclassified, and it printed `suite.shell=true`; no `deploy=` line (no environment configured).

**Build.** The `shell` suite's `build` is `true`: exit 0.

**Tests.** The `shell` suite's `test` is `bash tests/run.sh` (225 s): exit 1,
```
=== FAIL: example.test.sh
FAIL: generate-web failed: generate-web: examples/csharp-angular/web/angular.json already exists; nothing was run
failed: example.test.sh
```
It is the only failing file of 60. Re-run alone: `bash tests/run.sh example` fails with the same line. Run alone: `containers`, `init`, `setup`, `doctor`, `devcontainer`, `readme`, `sandbox` and `agnostic` each end `all cases passed`, and `bash scripts/containers.sh --check` prints no `differs` line.

**Root cause (Phase 1 only).** `tests/example.test.sh:123` copies the whole example directory (`cp -R "$ex" "$d/examples/csharp-angular"`), then expects `scripts/generate-web.sh` to succeed on it (`:129`). The branch now contains the generated Angular app (`eda67ce`, `examples/csharp-angular/web/angular.json` and 20 more files), so the copy holds `web/angular.json` and the script correctly refuses ("already exists"). The test was written when `web/` held only `.gitkeep`; the plan had the engineer's host step commit the generated app (Task 7's host half), and nothing updated the test or the pages that say to run the script. The cause is the test's fixture, not the script.

**Acceptance criteria.**

| # | Criterion | Verdict | Settled by |
|---|---|---|---|
| 1 | The audit list is recorded and none of the assumptions remains hardcoded in a script or default the template ships | not met — `templates/containers/.codeo/overlays/init.md:5` still says the home checkout is "the clone on `main`", a hardcoded base branch in a shipped seed, although the audit lists the base branch as fixed | `docs/container-templates.md` (the audit); `templates/containers/.codeo/overlays/init.md:5` |
| 2 | `/codeo:setup --containers` in another project writes a working dev container and sbx sandbox setup with the project's URL and names | not met — without `--codename` the rendered scripts name containers `<repo>-<N>` wrongly (F3), the plugin is not installed in the container (F4) and the overlays point at READMEs the project does not have (F5) | reviewer reproductions t1; `scripts/setup.sh`, `scripts/containers.sh:45`, `.devcontainer/scripts/container-name.sh:31` |
| 3 | A test sets up a throwaway project with another owner and codename and asserts no shipped script or default still names `kbajpai/codeo` or `codeo-<N>` | met | `tests/containers.test.sh`: `another_project_gets_its_own_names`, `no_shipped_file_names_codeo_where_the_project_belongs` (passed in `bash tests/run.sh containers`) |
| 4 | The C# + Angular example builds its image, and an issue container or sandbox starts and runs the project's build and test commands | untestable here — this container has no Docker or `sbx`; the engineer's host run (image 11 of 11 steps, `suite: api ok`, `suite: web ok`, `suite: k8s ok` in `shopdemo-1`, and the sandbox's missing toolchain) is recorded in `implement.md` under `## Notes`, and is not evidence from this pass | `implement.md` (the engineer's host output) |
| 5 | README and `.devcontainer/README.md` describe both adoption paths, and every command in them was run | not met — the documented `generate-web.sh` step now refuses on a checkout that ships `web/` (F2), and the `curl … | bash` line cannot be run before a release | `docs/container-templates.md`, `README.md`, `.devcontainer/README.md` |
| 6 | `bash tests/run.sh` passes and codeo's own containers behave as before | not met — the suite fails (F1); `containers.sh --check` is clean | `bash tests/run.sh` output above |
| 7 | `scripts/codeo-init.sh --yes` in a non-codeo clone with another codename produces a config, the container and sandbox files with the project's names and a passing doctor | met — with the plan's stated exception that doctor's `ruleset` check fails on a new repository; the host run showed every other check `ok` | `tests/init.test.sh`: `an_unattended_run_adopts_another_project` (passed in `bash tests/run.sh init`); host run in `implement.md` |
| 8 | The wizard fails with a stated reason, creating nothing, when there is no `origin`, `gh` is logged out or `gh` cannot see the repository, and no create call is ever made | met | `tests/init.test.sh`: `refuses_without_an_origin`, `refuses_when_gh_is_not_logged_in`, `refuses_a_repository_gh_cannot_see_and_creates_nothing` |
| 9 | Rerunning the wizard keeps an existing config and never overwrites a seed file | met | `tests/init.test.sh`: `a_rerun_keeps_the_config`; `tests/containers.test.sh`: `a_second_run_skips_and_never_overwrites_seeds`, `a_seed_overlay_is_never_overwritten` |
| 10 | codeo's own checked-in container files equal what the templates render for codeo's config, checked by a test | met | `tests/containers.test.sh`: `codeos_own_files_match_their_templates`, `codeos_own_overlays_equal_the_render`, `codeos_dockerfile_equals_the_template_outside_the_toolchain_section`, `codeos_devcontainer_json_equals_the_template_but_the_extensions` |

**Documentation.** The change moves `README.md`, `.devcontainer/README.md`, `.sbx/README.md`, `docs/container-templates.md`, `docs/home-checkout.md`, `docs/skills.md` and `CHANGELOG.md`; the plan named each, and no page it named was left untouched. Findings: `docs/container-templates.md` step 3 and `examples/csharp-angular/scripts/host-run.sh`'s header still say to run `generate-web.sh` ("`web/` generated first"), which refuses now that the example ships `web/` (F2); the shipped overlays name `.devcontainer/README.md` and `.sbx/README.md`, which a project does not receive (F5). A scan of the added lines of those pages for "now", "no longer" and issue numbers found none. The project has no `wiki-rules` or invariants overlay, so the conventions of the pages under `docs/` are the standard.

**Independent review** (`QC review:`, opus, given the criteria and the diff only). Its verdict, in plain text: Ready to merge? With fixes — the suite fails at HEAD because of the committed `web/`; `/codeo:setup --containers` does not yet produce a working container setup for another project; issues 1-4 before merge, 5 and 6 in the same pass.

**Findings** (each answers *blocking or not* and *whose it is*):
- **F1 — blocking, `/codeo:implement`'s.** The full shell suite fails: `tests/example.test.sh:123-129` (`generate_web_names_a_pinned_cli_and_refuses_an_existing_app`) copies the committed `web/` and then expects `generate-web.sh` to run. Cause above. The fix is in the test's fixture (clear the copied `web/` before the case).
- **F2 — blocking, `/codeo:implement`'s.** Pages say to run `generate-web.sh` once, and `host-run.sh`'s header and its `web/ not generated` guard say `web/` must be generated first, but the branch ships the generated app, so the documented step refuses (`docs/container-templates.md` step 3 and its example list, `.devcontainer/README.md`'s example paragraph, `host-run.sh:14,127`). They must say that `web/` ships generated and when `generate-web.sh` applies (regenerating).
- **F3 — blocking, `/codeo:implement`'s.** `/codeo:setup --containers` without `--codename` writes no `codename` to the config; `containers.sh:45` renders with the repository name, but the copied `.devcontainer/scripts/container-name.sh:31` falls back to the clone folder's basename, which in an issue container is `<repo>-<N>`, so `container-name.sh --docker` prints `shop-3-home`, `folder-check.sh` and `role.sh` judge the wrong role (reviewer reproduction t1). The README's `codename` row now documents the two defaults instead of removing the inconsistency. The plan's goal (criterion 2) is not met and the fix stays in `scripts/setup.sh` / `scripts/containers.sh`: write `codename` (the derived repository name, as the wizard does) whenever `--containers` is given, or refuse when it is absent. A plan-level reading (the plan specified the default) was considered; the fix is a few lines inside the plan's files, so it routes to implement.
- **F4 — blocking, `/codeo:implement`'s.** `/codeo:setup --containers` writes no plugin pin (only `codeo-init.sh` writes `plugin.repo` and `plugin.ref`, lines 160-171), so the container's `plugins.sh` reports "codeo is not installed", `devcontainer-start.sh` takes no lock, and `/codeo:doctor` still prints `ok containers: managed scripts match the templates` (reviewer reproduction t1). Either `setup.sh --containers` writes the pin, or doctor's `containers` check fails when `.devcontainer/` exists and the pin is absent.
- **F5 — blocking, `/codeo:implement`'s.** The shipped overlays and scripts send an adopter to `.devcontainer/README.md` and `.sbx/README.md` ("the file the download line in `.devcontainer/README.md` saves", "`.devcontainer/README.md` says how"; `templates/containers/.codeo/overlays/init.md:33,35`, `close.md`; the messages of `folder-check.sh` and `role.sh`), and `containers.sh` ships neither README. Ship a short seed README for each directory, or point the text at the plugin's documentation (`docs/container-templates.md`).
- **F6 — blocking, `/codeo:implement`'s.** The same init overlay hardcodes the base branch (`templates/containers/.codeo/overlays/init.md:5`, "the clone on `main`"); a project whose base branch is `develop` is told something untrue, and `docs/container-templates.md`'s audit says the base branch is fixed. Use `@BASE_BRANCH@` and check the other seeds for the same.
- **F7 — non-blocking, `/codeo:implement`'s, take it in the same round.** `scripts/codeo-init.sh:135` writes the install step's stderr to the predictable `"${TMPDIR:-/tmp}/codeo-init.err.$$"`, a pre-plantable symlink target in a shared directory; use `mktemp`, as `containers.sh` does.
- **F8 — non-blocking, `/codeo:implement`'s.** A clone of an empty repository has no `origin/HEAD`, so `setup.sh` writes `baseBranch: TODO-set-me`, which passes `containers.sh`'s branch pattern and is rendered into the files (`base_ref=TODO-set-me`); the wizard prints `init: ok config` and drops setup's note. `containers.sh` should refuse `TODO-set-me`; the wizard could read `default_branch` from its existing `gh api repos/…` call. `host-run.sh` avoids it by setting `origin/HEAD`.
- **F9 — non-blocking, `/codeo:implement`'s.** Wizard messages: `init: ok containers: … written` prints even when every file was skipped; `init: skip containers: env is none` prints when env is `containers` but the config step failed; on a rerun with an existing config an explicit `--codename` or the codename answer is silently ignored; the wizard still adds `--suite` entries and the plugin pin to an existing config (the README does not say so).
- **F10 — non-blocking, `/codeo:implement`'s.** Test gaps: `an_unattended_run_adopts_another_project` ends in `|| true` and never checks doctor's result or `codeo-<N>` and the overlays, and `a_rerun_keeps_the_config` does not rerun with `--env containers` over an edited seed.
- **F11 — non-blocking, `/codeo:triage`.** Doctor's `containers` check reports every missing managed file as `differs`, so a project that keeps only one of `.devcontainer/` or `.sbx/` always fails it; the plugin pin's `plugin.repo` comes from `CODEO_PLUGIN_REPO` while the tag lookup uses `CODEO_PLUGIN_URL`, and `--version` is not checked against `vX.Y.Z`.
- **F12 — non-blocking, `/codeo:plan`'s (promised, see Notes).** One `codeo` host command per machine.
- **F13 — non-blocking, `/codeo:triage`.** `sort -V` on macOS before 13.
- **F14 — non-blocking, pre-existing, not a finding of this change.** `flock` is missing on stock macOS (already in `.devcontainer/codeo`, unchanged by this diff); the reviewer set it aside.

**Routing.** Back to `/codeo:implement` for F1-F6 (and F7-F10 in the same round where cheap). A full pass starts again from step 0 of this skill on the new diff. The host run in `implement.md` stands only as the engineer's evidence for criterion 4; after the fixes to `setup.sh`, the containers and the overlays a clean re-run of `host-run.sh` is advisable, because those files are what the example's image and wizard use.

**Verdict: back to `/codeo:implement`.**

## Log

- 2026-11-26 — round 1: build passed, suite failed (`example.test.sh`), six blocking findings, routed back to implement · cost: 13m · opus-5-5 659k in + 8.7M cached / 29k out
