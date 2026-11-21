# Issue — issue

| | |
|---|---|
| Request | "How can we make codeo plugin installable & hosted in a package manager so that I can install it one command? Also, update the README that provides full documentation from installing, updating, & using plugin from a developer point of view?" |
| Updated | 2026-11-21 |

## Where this stands

Drafting. Questions 1-4 are open.

## Questions

**Context found.** The repository is already a public Claude Code plugin marketplace (`.claude-plugin/marketplace.json`, plugin `codeo`, source `./`), so today an install takes two commands: `claude plugin marketplace add kbajpai/codeo` (optionally `@v1.0.7`) and `claude plugin install codeo@codeo`. codeo also needs the `superpowers` plugin (`doctor.sh` fails without it), installed the same way from `obra/superpowers-marketplace`, plus bash 4.3+, jq, git and gh. The only script that does all this is `.devcontainer/scripts/plugins.sh`, which serves codeo's own dev container and reads the pin from `.codeo/config.json`. `README.md` has no install, update or getting-started section: it covers the dev container, tests, the skill table, the dossier checker and replay, requirements and status.

1. **Which "package manager" do you mean?** (a) Claude Code's own plugin system, by listing codeo in a public plugin directory or the official marketplace so `/plugin install codeo` works without adding a marketplace first; (b) npm, e.g. `npx <name> install`; (c) Homebrew; (d) a one-line install script (`curl … | bash`) served from the repository; or a combination.
2. **What must the one command do?** Install codeo only, or codeo plus `superpowers`? Should it check (not install) bash, jq, git and gh? Which scope: user, project, or the engineer's choice? Install the latest release, or a version given on the command line?
3. **The README.** Is it for a developer adopting codeo in their own project (install, `/codeo:setup`, `/codeo:doctor`, a first issue through to merge, updating, uninstalling), with the contributor material (tests, the dossier checker, replay) moved to another page, or kept below it?
4. **One issue or two?** The package-manager route and the README can be filed together, or as two issues so the README can ship first, documenting today's two-command install.

## Outcome

## Log
