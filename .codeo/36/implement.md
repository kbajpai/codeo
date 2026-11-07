# Issue #36 — implement

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/36 |
| Branch | `feat/add-dev-container-so-codeo` |
| Updated | 2026-11-07 |

## Where this stands

All six tasks of `docs/plans/2026-11-07-dev-container.md` are built and reviewed. Ready for `/codeo:qc`.

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

**Deployed revision:** not applicable; no shared environment is configured.

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

## Log

- 2026-11-07 — implemented: 6 tasks, 7 commits (a5a8742..f9af9f6), 1 fix round (Task 3); final whole-branch review clean · cost: 36m · sonnet-5-5 567k in + 16.1M cached / 95k out
