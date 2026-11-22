# Issue #151 — init

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/151 |
| Branch | `docs/install-codeo-one-command-document` |
| Updated | 2026-11-21 |

## Where this stands

Initialized: branch `docs/install-codeo-one-command-document` cut off `origin/main` at `956a86f2ba32545a27785ca2ca618579059fae61` and pushed. Next step: `/codeo:plan` in the issue's container.

## Questions

None.

## Outcome

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/151 — Install codeo with one command and document installing, updating and using it in the README |
| State | open · labels `documentation`, `enhancement` |
| Branch | `docs/install-codeo-one-command-document` off `main` at `956a86f` |
| Board | Ready → In progress |

**Problem.** codeo is already a public Claude Code plugin marketplace, so installing it takes two commands and also needs `superpowers`, which only `.devcontainer/scripts/plugins.sh` (the dev container's, pin-driven) installs. `README.md` has no install, update, getting-started or uninstall section. The issue asks for one command per machine (codeo and `superpowers`, latest by default or a given tag, user scope by default or project scope, re-runnable, with a prerequisite check that never installs system packages), a documented per-project `.claude/settings.json` snippet, a README rewritten for developers adopting codeo, and the contributor material (tests, dossier checker, replay) moved to its own page.

**Acceptance criteria** — verbatim from the issue, unchecked:
- [ ] One command, shown in the README, installs codeo and `superpowers` on a machine that has neither, and `claude plugin list` then shows both enabled.
- [ ] Run again with codeo already installed at the requested version, the command changes nothing and says so.
- [ ] Run with a release tag, it installs that tag; run without one, it installs the latest release; the installed version is printed.
- [ ] The default scope is user; asking for project scope installs at project scope and the command says which scope it used.
- [ ] With bash older than 4.3, or jq, git or gh missing, the command names each missing or too-old prerequisite, installs no system package, and exits non-zero.
- [ ] A project that commits the README's `.claude/settings.json` snippet is offered the codeo install by Claude Code when its folder is trusted (shown on a clean machine, with the result recorded in the PR).
- [ ] `README.md` has sections for requirements, installing, project setup, a first workflow, the skills, updating, uninstalling and troubleshooting, and each command in them was run and its output matches.
- [ ] `README.md` no longer holds the test, dossier-checker or replay sections; the contributor page holds them unchanged and the README links to it.
- [ ] Tests cover the install command's behaviour listed above and run in `bash tests/run.sh`, which ends `all cases passed`; a test fails when the README's install command and the script disagree.
- [ ] `CHANGELOG.md` has an entry stating the config schema, whether the shared state changed, and whether it is safe to bump mid-workflow.

**Out of scope.** Publishing to npm, Homebrew or another package manager; changing what the skills do, the plugin's version scheme or the release checklist; installing system packages or changing how the dev container installs plugins.

**Open at intake.** Whether codeo can be listed in a public or official Claude plugin directory (not a criterion). Where the one command lives and how it is fetched (a script served from `raw.githubusercontent.com`, or attached to each release): `/codeo:plan` decides. Note: #149 and #138 are in flight (plan step); #149 edits `CHANGELOG.md` and the READMEs under `.devcontainer/`, #138 edits `docs/handoff.md`; `/codeo:plan` runs `overlap.sh` before settling its footprint.

## Log
- 2026-11-21 — initialized: branch docs/install-codeo-one-command-document off main at 956a86f · cost: 0m · sonnet-5-5 15k in + 703k cached / 3k out
