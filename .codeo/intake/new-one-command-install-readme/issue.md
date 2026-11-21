# Issue — issue

| | |
|---|---|
| Request | "How can we make codeo plugin installable & hosted in a package manager so that I can install it one command? Also, update the README that provides full documentation from installing, updating, & using plugin from a developer point of view?" |
| Updated | 2026-11-21 |

## Where this stands

Drafting. Q3 and Q4 answered; Q1 and Q2 are open, with a recommendation and trade-offs given (Q5, Q6).

## Questions

**Context found.** The repository is already a public Claude Code plugin marketplace (`.claude-plugin/marketplace.json`, plugin `codeo`, source `./`), so today an install takes two commands: `claude plugin marketplace add kbajpai/codeo` (optionally `@v1.0.7`) and `claude plugin install codeo@codeo`. codeo also needs the `superpowers` plugin (`doctor.sh` fails without it), installed the same way from `obra/superpowers-marketplace`, plus bash 4.3+, jq, git and gh. The only script that does all this is `.devcontainer/scripts/plugins.sh`, which serves codeo's own dev container and reads the pin from `.codeo/config.json`. `README.md` has no install, update or getting-started section: it covers the dev container, tests, the skill table, the dossier checker and replay, requirements and status.

1. **Which "package manager" do you mean?** (a) Claude Code's own plugin system, by listing codeo in a public plugin directory or the official marketplace so `/plugin install codeo` works without adding a marketplace first; (b) npm, e.g. `npx <name> install`; (c) Homebrew; (d) a one-line install script (`curl … | bash`) served from the repository; or a combination.
2. **What must the one command do?** Install codeo only, or codeo plus `superpowers`? Should it check (not install) bash, jq, git and gh? Which scope: user, project, or the engineer's choice? Install the latest release, or a version given on the command line?
3. **The README.** Is it for a developer adopting codeo in their own project (install, `/codeo:setup`, `/codeo:doctor`, a first issue through to merge, updating, uninstalling), with the contributor material (tests, the dossier checker, replay) moved to another page, or kept below it?
4. **One issue or two?** The package-manager route and the README can be filed together, or as two issues so the README can ship first, documenting today's two-command install.

5. **Q1 follow-up — recommendation asked for.** Recommended: Claude Code's own plugin system as the channel (it is already a marketplace). A project adopting codeo declares the marketplace and enables the plugin in its committed `.claude/settings.json`, so its engineers are offered the install when they trust the folder. On top of that, one install script for a single machine runs the `marketplace add` and `install` steps for codeo and superpowers and checks the prerequisites. Listing codeo in a public or official Claude plugin directory is worth pursuing, but its process is outside this repository's control: it is an open question, not a criterion. npm and Homebrew are not recommended: each would only wrap `claude plugin` calls, adds a second release channel to keep in step, and Homebrew does not cover Windows or WSL users without brew. Answer: open.
6. **Q2 follow-up — trade-offs asked for.** (a) Also install superpowers: pro, codeo does not work without it (`doctor` fails); con, codeo then installs a third-party plugin from another marketplace, whose version codeo does not pin. (b) Check prerequisites: pro, a missing `jq` or an old bash otherwise fails later inside a skill; con, little, provided it reports and never installs system packages. (c) Pick a version: pro, matches the `plugin.ref` pin projects already use and makes a rollback possible; con, one more argument, so the default should be the latest release. (d) Choose scope: pro, a project scope keeps codeo out of unrelated repositories; con, two installed copies (user and project) have already caused version confusion in this project's release checks (#61, #75), so the default should be user scope. Answer: open.

**Answered.** Q3: adopters first, with tests, the dossier checker and replay moved to a contributor page. Q4: one issue.

## Outcome

## Log
