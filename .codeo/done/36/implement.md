# Issue #36 — implement

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/36 |
| Branch | `feat/add-dev-container-so-codeo` |
| Updated | 2026-11-07 |

## Where this stands

Round 2 is built and reviewed: Tasks 7-10 of `docs/plans/2026-11-07-dev-container.md`, answering the two blocking findings of `qc.md` round 1. Ready for `/codeo:qc`.

## Questions

None.

## Outcome

**Built** (commits `a5a8742`..`f9af9f6`, each task reviewed by a fresh reviewer; Task 3 took one fix round):
- Task 1 — `.codeo/config.json`: `codename: codeo`, `plugin{repo: kbajpai/codeo, ref: v1.0.3}`, `.devcontainer/**` in the `shell` suite's paths; `tests/devcontainer.test.sh` with its shared helpers.
- Task 2 — `.devcontainer/devcontainer.json`: user `dev`, `--memory=4g --cpus=2`, the `codeo-gh` volume as the only mount, `postCreateCommand`.
- Task 3 — `.devcontainer/Dockerfile` on `ubuntu:24.04` with bash, jq, git, gh, shellcheck and Claude Code. The fix round made the Claude install step fail the build when the download fails (`&& claude --version`) and made the tool-presence test specific.
- Task 4 — `.devcontainer/scripts/plugins.sh` (superpowers, then codeo at the pin; keeps a working codeo when the pin cannot be fetched).
- Task 5 — `.devcontainer/scripts/devcontainer-start.sh` (takes ownership of a root-owned clone, runs `plugins.sh`, wires `gh` into git, lists the outstanding logins; always exits 0).
- Task 6 — `CHANGELOG.md` `Unreleased` line, and the end-to-end proof in a freshly built image.

**Documentation pages changed:** `CHANGELOG.md` only, as the plan says. No page under `docs/` moves; no wiki module.

**Build:** the `shell` suite's build command is `true`; exit 0. Beyond the build, Task 6 ran `bash tests/run.sh` on the host and as user `dev` inside the freshly built image (both `all cases passed`) and shellcheck over the scripts and the test file in the image (clean). QC owns the grading.

**Real-CLI checks the final reviewer ran in the image** (what stubs could hide): `claude plugin marketplace add kbajpai/codeo@v1.0.3` and `claude plugin install codeo@codeo --scope user` work; `known_marketplaces.json` holds `.codeo.source.ref`; `claude plugin list` prints `codeo@codeo`; `claude auth status` exits 1 when logged out; `v1.0.3` exists on GitHub.

**Deviations from the plan:** none of substance.
- Test case functions carry a `plugins_` / `start_` prefix that the brief's names lack.
- The start script's "what is left to do" list goes to stderr beside the TODOs; the plan did not name the stream.
- `tests/devcontainer.test.sh` is committed executable.

**Left for the engineer** (the plan's Task 6, step 5; cannot be run from here):
- (a) With the Dev Containers extension and no `codeo-gh` volume, run *Dev Containers: Clone Repository in Named Container Volume…* on this branch; the build must complete with no folder or volume created beforehand.
- (b) In that container run `gh auth login`, `gh auth refresh -s project`, `gh auth status` (shows `project`); rebuild the container; `gh auth status` still shows it. Then `bash .devcontainer/scripts/devcontainer-start.sh` ends `ready` after `claude auth login`, and `/codeo:doctor` reports every line `ok`. In a fresh container with no logins, `doctor.sh` printed `ok` for config, schema, codename, suites, deps and overlays and `fail` for gh-auth, gh-scopes, board and ruleset, which is expected until the login.

**Non-blocking findings recorded by the reviews** (for `/codeo:qc` and `/codeo:triage` to weigh; none blocks):
- The git-identity TODO is not mutation-resistant: no case sets only `user.name` or only `user.email` (`devcontainer-start.sh` step 5, `tests/devcontainer.test.sh`).
- `cd ""` quirk if `git rev-parse --show-toplevel` fails (`devcontainer-start.sh` step 2); the later `plugins.sh` call still produces a TODO.
- The `setup-git` failure and chown failure TODOs have no case.
- `tests/devcontainer.test.sh` pins `plugin.ref == "v1.0.3"`, so every pin bump needs a test edit (the plan specified the literal).
- `--memory=4g --cpus=2` can stop a container starting on a host without cgroup limits; `chown -R` of the clone's parent can change host ownership of a bind-mounted checkout whose UID differs from `dev`'s (low risk: VS Code aligns the UID first).
- Claude Code's own login is per container and does not survive a rebuild (by design; the start script lists the TODO each time).

### Round 2

2026-11-07
(after plan.md round 2)

**Built** (commits `45c06f0`, `a32340d`, `84a527f`, `879701c`; each task reviewed by a fresh reviewer, all approved first time; one fix wave after the final review):
- Task 7 (F1, F6) — `plugins.sh` reads `.codeo/config.json` by absolute path and runs every `claude plugin ...` call from `$HOME` through `claude_out`, so a pin bump no longer rewrites the tracked `.claude/settings.json`; `has_plugin` compares whole whitespace-split words, so `codeo@codeo-fork` is not codeo. The test stub now models the real CLI side effect.
- Task 8 (F2, F8, F9) — `devcontainer-start.sh` always sets `safe.directory`; it chowns the clone itself (never its parent), and only when the clone is not the user's and its mount is a named volume (`/proc/self/mountinfo`, longest mount point wins, field 4 `.../volumes/<name>/_data`); otherwise a TODO and no `sudo`. The login TODO is the one-step `gh auth login -s project`. New cases: named volume, bind mount, longest mount, own clone, identity with only one of name or email, `setup-git` failure. A failing `git config --global --add safe.directory` is itself a TODO rather than an abort (beyond the brief).
- Task 9 (F5, F7, F9) — `Dockerfile` `ENV` lines use `/home/${USERNAME}`, the `/workspaces` line and its misleading comment are gone, the sudo comment now names the named-volume chown; the pin test asserts a well-formed ref, not the literal `v1.0.3`.
- Task 10 — proof only, no commit (below).
- Fix wave `879701c` (from the final review's two cheap hardenings of the never-chown-a-bind-mount property) — the clone path is resolved with `pwd -P`, and the last of two mountinfo lines at one mount point wins (`>=`); three cases (`start_last_mount_at_the_same_point_wins`, `start_mount_prefix_needs_a_path_boundary`, `start_resolves_symlinks_before_matching`), each mutation-checked in a copy except the boundary case, which guards existing logic.

**Documentation pages changed:** none, as the plan says; `CHANGELOG.md`'s existing line still describes the change.

**Build:** the `shell` suite's build command is `true`; exit 0. `bash tests/run.sh` passed on the host after each task and, as user `dev`, in the image rebuilt with `--no-cache`; shellcheck in the image over the scripts and the test file is clean. QC owns the grading.

**Proof against the real CLI and real mounts (Task 10)**, in the rebuilt image:
- F1: a scratch repo committing this repo's `.claude/settings.json`; `plugins.sh` installs codeo at `v1.0.2`, the pin moves to `v1.0.3`, `plugins.sh` runs again: both exit 0, `git status --porcelain` prints nothing, `settings.json` still enables `codeo@codeo`, `known_marketplaces.json` holds `v1.0.3`, and a third run is a no-op.
- F2, named volume: a volume holding a copy of the repo owned by root; the start script as `dev` leaves `/workspaces/x` owned by `dev`, exits 0 and lists the three logins in order (`gh auth login -s project`, `claude auth login`, the script again).
- F2, bind mount: a copy of the repo (never this checkout) owned by uid 4242 on the host, bind-mounted; the script prints the `not on a Docker volume` TODO, exits 0, and the host ownership stays 4242.
- `doctor.sh` in a fresh container: `ok` for config, schema, codename, suites, deps, overlays and superpowers (`cannot verify`); `fail` for gh-auth, gh-scopes, board and ruleset only because nothing is logged in.

**Deviations from the plan:** none of substance. Task 10's step 3 ran as the plan's draft was finally written (copies only). `plugins_matches_whole_plugin_names` also pre-seeds the marketplace at the pin, so only `has_plugin` decides (without it the ref mismatch reinstalled codeo and the test passed vacuously).

**Left for the engineer** (unchanged from round 1): (a) the VS Code clone-in-volume build on a machine with no `codeo-gh` volume; (b) `gh auth login -s project`, `gh auth status` shows `project`, rebuild, still shows it; then `claude auth login`, the start script ends `ready`, `/codeo:doctor` is all `ok`. Not run from here: both need VS Code or a real GitHub login.

**Non-blocking findings recorded by the reviews** (none blocks; for `/codeo:qc` and `/codeo:triage`): `plugins.sh` `for word in $list` is unquoted and can glob in the repo root (fail-safe); the `done < "$info" 2>/dev/null` redirect does not silence a missing mountinfo (fail-safe, a stray stderr line); a bind mount whose path contains a space is escaped `\040` in mountinfo and never matches; no test pins optional fields before the `-` separator or a `/` mount; `tests/devcontainer.test.sh`'s `ds_safe_dir_set` ends in `| grep -q` under `pipefail` (tiny input); the symlink case assumes the scratch directory is already a physical path; `devcontainer-start.sh` still runs `plugins.sh` after a failed `cd` (round 1, untouched).

## Log

- 2026-11-07 — implemented: 6 tasks, 7 commits (a5a8742..f9af9f6), 1 fix round (Task 3); final whole-branch review clean · cost: 36m · sonnet-5-5 567k in + 16.1M cached / 95k out
- 2026-11-07 — implemented (round 2): 4 tasks (7-10), 4 commits (45c06f0..879701c), 1 fix wave after the final review · cost: 22m · sonnet-5-5 411k in + 10.9M cached / 73k out
