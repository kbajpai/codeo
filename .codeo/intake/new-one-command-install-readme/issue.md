# Issue — issue

## Questions

None open. Q1-Q4 answered (adopters first; one issue); Q5 and Q6 accepted by the engineer (Claude plugin system plus one install script; all four options kept: superpowers, prerequisite check, version, scope).

## Draft

Title: Install codeo with one command and document installing, updating and using it in the README
Labels: enhancement, documentation. Type: none (user-owned repo).

### Description

Make codeo installable on one machine with a single command, make adopting it in a project need no commands for that project's other engineers, and rewrite `README.md` as the full developer documentation for installing, updating, using and removing the plugin. Contributor material (the test runner, the dossier checker, the replay harness) moves out of the README to its own page.

### Motivation / Context

The repository is already a public Claude Code plugin marketplace (`.claude-plugin/marketplace.json`, plugin `codeo`, source `./`), so today an install takes two commands: `claude plugin marketplace add kbajpai/codeo` (optionally `@<tag>`) and `claude plugin install codeo@codeo`. codeo also needs the `superpowers` plugin (`scripts/doctor.sh` fails without it), installed the same way from `obra/superpowers-marketplace`, plus bash 4.3 or later, jq, git and gh. The only script that does these steps is `.devcontainer/scripts/plugins.sh`, which serves codeo's own dev container and reads its pin from `.codeo/config.json`; an adopter cannot use it. `README.md` has no install, update, getting-started or uninstall section: it covers the dev container, the tests, the skill table, the dossier checker and replay, the requirements and the status. A developer who wants to try codeo has to piece the steps together from `docs/` and the changelog.

The channel is Claude Code's own plugin system, because codeo is already a marketplace there. npm and Homebrew are not used: each would only wrap the same `claude plugin` calls and add a second release channel to keep in step, and Homebrew leaves out Windows and WSL users who have no brew.

### Key Requirements

- **One command per machine.** A single command, runnable from the README, installs codeo and `superpowers` and reports what it did. It installs codeo at the latest release by default and at a given release tag when one is passed. It installs at user scope by default and at project scope when asked, because two installed copies (user and project) have already caused version confusion in this project's release checks (#61, #75). It is safe to run again: what is already installed at the requested version is left alone.
- **Prerequisite check.** The same command checks bash 4.3 or later, jq, git and gh, names each one that is missing or too old, and never installs system packages.
- **Zero commands per project.** The README documents the `.claude/settings.json` snippet that declares the marketplace and enables `codeo@codeo`, so a project's other engineers are offered the install when they trust the folder, and says how a project pins a version.
- **README for a developer adopting codeo.** It covers, in order: what codeo is, the requirements, installing (the one command, the per-project snippet, a pinned version), setting a project up (`/codeo:setup`, `/codeo:doctor`), a first issue taken through to a merged pull request, the skills and the files they write, updating (and how to read the changelog's config-schema, shared-state and mid-workflow lines first), uninstalling, and troubleshooting the failures `/codeo:doctor` reports. Every command shown is one that was run.
- **Contributor material moved.** The test runner, the dossier checker and the replay harness leave `README.md` for a contributor page it links to, with their content unchanged.
- **Test.** The install command's behaviour (defaults, a given tag, scope, re-running, a missing prerequisite) has tests that run without network access to GitHub or a real `claude`, and the README's claims about the command are covered by a doc-consistency test, as other pages are.

### Acceptance Criteria
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

### Out of Scope

- Publishing codeo to npm, Homebrew or another package manager.
- Changing what the skills do, the plugin's version scheme, or the release checklist.
- Installing system packages (bash, jq, git, gh) or changing how the dev container installs plugins.

### Reference

- `.claude-plugin/marketplace.json`, `.claude-plugin/plugin.json`, `.claude/settings.json` (enables `codeo@codeo`), `.devcontainer/scripts/plugins.sh`, `scripts/doctor.sh` (the `superpowers` check), `README.md`, `docs/release-checklist.md`, `CHANGELOG.md`.
- #61 and #75: releases where a user-scope and a project-scope copy of `codeo@codeo` disagreed.
- Raised by the engineer through `/codeo:issue` on 2026-11-21.

### Open questions

- Whether codeo can be listed in a public or official Claude plugin directory so `/plugin install codeo` works without adding the marketplace first, and what that process requires. Nobody can answer this from the repository; it is not a criterion here.
- Where the one command lives and how it is fetched (a script in this repository served from `raw.githubusercontent.com`, or attached to each release): `/codeo:plan` decides.
