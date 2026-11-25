# codeo

codeo is an agent-workflow plugin for Claude Code. It is for engineers who work from GitHub issues: it carries a piece of work from issue to merged pull request through six steps (issue, init, plan, implement, QC and close), keeping a dossier of each step in the repository. It needs bash, `jq`, `git`, `gh` and `claude`, and a GitHub repository to work in. It is unrelated to SYSGO's CODEO IDE and to GoCodeo.

## Contents

- [Start here](#start-here)
- [Requirements](#requirements)
- [Installing](#installing)
- [Setting a project up](#setting-a-project-up)
- [Your first workflow](#your-first-workflow)
- [Configuration](#configuration)
- [Troubleshooting](#troubleshooting)
- [Updating](#updating)
- [Uninstalling](#uninstalling)
- [The skills](#the-skills)
- [More documentation](#more-documentation)
- [Contributing](#contributing)

## Start here

1. Run the one install command in [Installing](#installing) and watch it print an `install:` line for each step.
2. Restart Claude Code, so the new session lists the codeo commands.
3. In your project, run `/codeo:setup` and then `/codeo:doctor`, and see `.codeo/config.json` written and every check pass ([Setting a project up](#setting-a-project-up)).
4. File your first issue with `/codeo:issue` and see it created on GitHub.
5. Run the six steps for that issue, each handing off to the next ([Your first workflow](#your-first-workflow)).
6. Merge the pull request that `/codeo:close` opens, and see the workflow finish.
7. If something stops, find its message in [Troubleshooting](#troubleshooting).

## Requirements

- bash 4.3 or later
- `jq`
- `git`
- `gh`, the GitHub CLI; board use also needs `gh project`, which reads GraphQL, so the token must be allowed to use it
- `claude`, Claude Code

`install.sh` and `/codeo:doctor` both check all five tools. The installer checks them in one run and names every one that is missing or too old. It installs none of them: use your system's package manager, then run it again.

## Installing

One command installs codeo and the superpowers plugin it builds on, for you, in every project:

```bash
curl -fsSL https://raw.githubusercontent.com/kbajpai/codeo/main/install.sh | bash
```

It installs the latest release, which is the highest `vX.Y.Z` tag of the repository. Claude Code sessions that are already open need a restart to load the plugins. It prints one `install:` line per step, between the lines `claude` prints itself.

```
install: release v1.0.9
Adding marketplace…SSH not configured, cloning via HTTPS: https://github.com/obra/superpowers-marketplace.git
Refreshing marketplace cache (timeout: 120s)…
Cloning repository (timeout: 120s): https://github.com/obra/superpowers-marketplace.git
Clone complete, validating marketplace…
Cleaning up old marketplace cache…
✔ Successfully added marketplace: superpowers-marketplace (declared in user settings)
Installing plugin "superpowers@superpowers-marketplace"...✔ Successfully installed plugin: superpowers@superpowers-marketplace (scope: user)
install: superpowers installed (user scope)
Adding marketplace…SSH not configured, cloning via HTTPS: https://github.com/kbajpai/codeo.git
Refreshing marketplace cache (timeout: 120s)…
Cloning repository (timeout: 120s): https://github.com/kbajpai/codeo.git (ref: v1.0.9)
Clone complete, validating marketplace…
Cleaning up old marketplace cache…
✔ Successfully added marketplace: codeo (declared in user settings)
Installing plugin "codeo@codeo"...✔ Successfully installed plugin: codeo@codeo (scope: user)
install: codeo v1.0.9 installed (user scope)
install: done - codeo v1.0.9, user scope, superpowers 7.0.2
install: restart any Claude Code sessions already open to load the plugins
```

Run it again and nothing changes:

```
install: release v1.0.9
install: superpowers already installed (user scope), left alone
install: codeo v1.0.9 already installed (user scope)
install: nothing changed - codeo v1.0.9, user scope, superpowers 7.0.2
```

`claude plugin list` shows what is installed:

```
Installed plugins:

  ❯ codeo@codeo
    Version: 1.0.9
    Scope: user
    Status: ✔ enabled

  ❯ superpowers@superpowers-marketplace
    Version: 7.0.2
    Scope: user
    Status: ✔ enabled
```

### Options

`--version` installs a release other than the latest (`v1.0.8`, or `1.0.8`). The installer checks the tag exists before it changes anything. Asking for a different version than the one installed replaces it; [docs/updating.md](docs/updating.md) shows what that prints, including a downgrade:

```bash
curl -fsSL https://raw.githubusercontent.com/kbajpai/codeo/main/install.sh | bash -s -- --version v1.0.8
```

`--scope project` installs both plugins for one project instead of for you. Run it inside the project's git repository (any folder in it works); it writes the project's `.claude/settings.json`:

```bash
curl -fsSL https://raw.githubusercontent.com/kbajpai/codeo/main/install.sh | bash -s -- --scope project
```

```
install: release v1.0.9
Adding marketplace…SSH not configured, cloning via HTTPS: https://github.com/obra/superpowers-marketplace.git
Refreshing marketplace cache (timeout: 120s)…
Cloning repository (timeout: 120s): https://github.com/obra/superpowers-marketplace.git
Clone complete, validating marketplace…
Cleaning up old marketplace cache…
✔ Successfully added marketplace: superpowers-marketplace (declared in project settings)
Installing plugin "superpowers@superpowers-marketplace"...✔ Successfully installed plugin: superpowers@superpowers-marketplace (scope: project)
install: superpowers installed (project scope)
Adding marketplace…SSH not configured, cloning via HTTPS: https://github.com/kbajpai/codeo.git
Refreshing marketplace cache (timeout: 120s)…
Cloning repository (timeout: 120s): https://github.com/kbajpai/codeo.git (ref: v1.0.9)
Clone complete, validating marketplace…
Cleaning up old marketplace cache…
✔ Successfully added marketplace: codeo (declared in project settings)
Installing plugin "codeo@codeo"...✔ Successfully installed plugin: codeo@codeo (scope: project)
install: codeo v1.0.9 installed (project scope)
install: done - codeo v1.0.9, project scope, superpowers 7.0.2
install: restart any Claude Code sessions already open to load the plugins
```

Commit the file it wrote. This is its content (`jq -S . .claude/settings.json`), and you can write it by hand instead:

```json
{
  "enabledPlugins": {
    "codeo@codeo": true,
    "superpowers@superpowers-marketplace": true
  },
  "extraKnownMarketplaces": {
    "codeo": {
      "source": {
        "ref": "v1.0.9",
        "repo": "kbajpai/codeo",
        "source": "github"
      }
    },
    "superpowers-marketplace": {
      "source": {
        "repo": "obra/superpowers-marketplace",
        "source": "github"
      }
    }
  }
}
```

Updating, replacing and restoring are in [Updating](#updating).

## Setting a project up

Run these once, in the project's git repository, inside Claude Code, after installing the plugin. Each skill runs a script, and the script's own output is what the skill reports.

1. **Run `/codeo:setup`.** It creates `.codeo/` with a starter `config.json` (the schema, the repository's owner and name read from the `origin` remote, the base branch read from `origin/HEAD`, and empty `suites` and `resources`), a `.codeo/.gitignore` for the per-checkout files, and `docs/plans/`. A value it cannot read is written as `TODO-set-me` and named on stderr. It refuses to overwrite a `config.json` that exists. `--stack <name>` records a stack name. In a project cloned from a GitHub repository whose `origin` points at it, `setup` prints:

```
codeo: created .codeo/config.json for kbajpai/codeo (base main); run /codeo:doctor next
```

   That file reads:

```json
{
  "schema": 1,
  "repo": {
    "owner": "kbajpai",
    "name": "codeo"
  },
  "baseBranch": "main",
  "suites": [],
  "resources": []
}
```

2. **Edit `.codeo/config.json`.** Every key is in [Configuration](#configuration). The one thing most projects set first is `suites`, the build and test commands `/codeo:implement` and `/codeo:qc` run. A suite names itself and gives its commands:

```json
{
  "suites": [
    { "name": "app", "build": "npm run build", "test": "npm test" }
  ]
}
```

   `board`, `codename`, `plugin`, `models` and everything else optional are written by hand; setup leaves them out.

3. **Run `/codeo:doctor`.** It checks that everything the workflow needs is in place and reports every failure, not only the first. Fix what it reports (see [Troubleshooting](#troubleshooting)) and run it again until it ends clean. With a logged-in `gh` and superpowers installed it prints:

```
ok config: config.json is valid
ok schema: supported (plugin understands up to 1)
ok codename: not set
ok gh-auth: gh api user succeeded
ok gh-scopes: no board configured; the project scope is not needed
ok board: no board configured
ok ruleset: main requires: tests qc-verdict
ok suites: 0 suite(s), every build and test command resolves
ok deps: jq, git, bash 5.3.9(1)-release
ok overlays: none
ok superpowers: installed
```

Then commit `.codeo/` and `docs/plans/`; the config is shared by everyone who works on the project.

### Running on the host

The home role runs `/codeo:issue`, `/codeo:init`, `/codeo:triage` and `/codeo:cleanup` in a clone named `<codename>-home`. A project with its own role guard refuses a skill outside its checkout. The project needs a GitHub repository whose `origin` remote points at it; a project board is optional.

See [docs/home-checkout.md](docs/home-checkout.md) for the home checkout, the guard and the tracking comment, and [.devcontainer/README.md](.devcontainer/README.md) for the dev container.

## Your first workflow

A piece of work goes through six slash commands, one after the other. Each step owns one file under `.codeo/<N>/`, where `<N>` is the GitHub issue number. That file is the step's *dossier*: it records what the step decided, so the next step (and you, later) can read it. After the pull request merges, the whole folder moves to `.codeo/done/<N>/`.

The example is issue #143, which fixed leftovers from an earlier change. Its finished workflow is archived in this repository under `.codeo/done/143/`, so you can open the file each step wrote: [issue.md](.codeo/done/143/issue.md), [init.md](.codeo/done/143/init.md), [plan.md](.codeo/done/143/plan.md), [implement.md](.codeo/done/143/implement.md), [qc.md](.codeo/done/143/qc.md) and [close.md](.codeo/done/143/close.md). For the long detail of each skill, follow its link to [docs/skills.md](docs/skills.md).

```mermaid
flowchart LR
  I["/codeo:issue"] --> N["/codeo:init"]
  N --> P["/codeo:plan"]
  P --> M["/codeo:implement"]
  M --> Q["/codeo:qc"]
  Q -->|clear| C["/codeo:close"]
  Q -->|findings| M
  Q -->|plan is wrong| P
  C -->|review feedback or conflict| M
  C -->|"--stash, or PR closed unmerged"| S(["parked: back to Ready or Backlog"])
  C -->|merged| D(["archived in .codeo/done/N"])
```

### 1. /codeo:issue

- **Run:** `/codeo:issue <idea, bug, or problem to turn into an issue>`.
- **It asks:** numbered questions (the problem, what is out of scope, what done looks like, constraints) in a draft file, `.codeo/intake/new-<slug>/issue.md`. It shows you the finished draft in the conversation and files nothing on GitHub until you approve.
- **It writes:** `.codeo/intake/<N>/issue.md` on the project's `codeo/intake` branch only (the example: [issue.md](.codeo/done/143/issue.md)), and the GitHub issue itself. With a project board, the card goes to Backlog.
- **It commits:** `docs(codeo): issue dossier for #<N> — filed`.
- **Next:** `/codeo:init #<N>` when the issue is Ready (or the project has no board). Otherwise `/codeo:triage` first, then `/codeo:init #<N>`.

Details: [docs/skills.md#issue](docs/skills.md#issue).

### 2. /codeo:init

- **Run:** `/codeo:init <number>`. The number can be `42`, `#42` or the issue's URL.
- **It asks:** almost nothing. It stops for one review of `init.md` (approve, change or reject), and for an override if you are taking over someone else's claim. Its own question list normally reads `None.`
- **It writes:** [.codeo/<N>/init.md](.codeo/done/143/init.md): the issue, the branch, the state, and the acceptance criteria word for word. It also copies the approved draft to `.codeo/<N>/issue.md`. It cuts and pushes the branch (`<type>/<N>-<slug>`), moves the card to In progress and takes the workflow lock.
- **It commits:** `docs(codeo): init dossier for #<N>`.
- **Next:** `/codeo:plan`, usually in the same session.

Details: [docs/skills.md#init](docs/skills.md#init).

### 3. /codeo:plan

- **Run:** `/codeo:plan [optional: which part of the locked issue to plan]`.
- **It asks:** its questions go in the dossier, `.codeo/<N>/plan.md`, each with why it matters and the options. The run stops until you answer there; run the command again to continue. You then review the plan in the conversation.
- **It writes:** [.codeo/<N>/plan.md](.codeo/done/143/plan.md), the decisions. The plan itself goes under `docs/plans/` only after you approve it, and is left uncommitted for you to review. It never writes application code.
- **It commits:** only the dossier: `docs(codeo): plan dossier for #<N>`, or with a suffix such as `— Q1-Q9 raised` or `— footprint`.
- **Next:** review and commit the plan, then `/codeo:implement`.

Details: [docs/skills.md#plan](docs/skills.md#plan).

### 4. /codeo:implement

- **Run:** `/codeo:implement [optional: plan path or slug]`. With no argument it uses the plan `plan.md` names.
- **It asks:** only in the dossier, `.codeo/<N>/implement.md`, and only when the plan looks wrong or unclear. A design question goes back to `/codeo:plan`.
- **It writes:** [.codeo/<N>/implement.md](.codeo/done/143/implement.md), with an `## Outcome` of what was built and the commit for each task. The code is built task by task through the plan's superpowers skill. It builds each configured suite but does not run its tests.
- **It commits:** one commit per task, then `docs(codeo): implement dossier for #<N>`.
- **Next:** `/codeo:qc`.

Details: [docs/skills.md#implement](docs/skills.md#implement).

### 5. /codeo:qc

- **Run:** `/codeo:qc`. It checks the workflow that holds the lock.
- **It asks:** nothing in the conversation, unless a question must be answered in the dossier, `.codeo/<N>/qc.md`. It fixes nothing.
- **It writes:** [.codeo/<N>/qc.md](.codeo/done/143/qc.md): one `### Round` per pass, a table of the acceptance criteria, findings marked blocking or not, and a bold verdict with where to go next.
- **It commits:** `docs(codeo): qc dossier for #<N>` (`— round <n>` for a later pass).
- **Next:** `/codeo:close` when the verdict is clear. Otherwise `/codeo:implement` or `/codeo:plan`.

Details: [docs/skills.md#qc](docs/skills.md#qc).

### 6. /codeo:close

- **Run:** `/codeo:close [--stash]`. `--stash` parks the workflow instead of finishing it.
- **It asks:** whether to delete the remote branch, once, after the merge. It never merges: you merge the pull request on GitHub, then run the command again.
- **It writes:** [.codeo/<N>/close.md](.codeo/done/143/close.md). It opens the pull request, waits, proves the merge, releases every lease and the lock, and moves the dossier to `.codeo/done/<N>/`. A stash sends the card back to Ready. A pull request closed unmerged can be abandoned, which sends the card to Backlog.
- **It commits:** `docs(codeo): close dossier for #<N> — PR #<pr>`. Review feedback or a conflict with the base branch is another round (`— review feedback`) and goes back through `/codeo:implement` and `/codeo:qc`.
- **Next:** `/codeo:triage`, which looks for loose ends the work left behind.

Details: [docs/skills.md#close](docs/skills.md#close).

**Where each step runs.** `/codeo:issue` and `/codeo:init` run in a home checkout when the project has a role guard. `/codeo:plan`, `/codeo:implement`, `/codeo:qc` and `/codeo:close` run in the issue's own checkout, the one that holds the lock. A project with no role guard, such as one just set up with `/codeo:setup`, has no such split: `/codeo:init` switches this checkout to the issue's branch, takes the lock and hands off to `/codeo:plan` in the same session. See [docs/home-checkout.md](docs/home-checkout.md).

**The closing block, and running a step again.** Every step ends with the same three-part block, so you never have to work out what to type next:

```
---
**Done:** <what this run did, in plain words>
**Next goal:** <the one outcome to reach next, and the skill that gets there>
**Steps:**
1. <the exact command to run first>
2. <the action after it>
```

Run the command in Steps 1. A step that was interrupted can be run again: it works out where the workflow stands from its dossier and from GitHub, and carries on. If it does not, see [Troubleshooting](#troubleshooting).

## Configuration

_Written in Task 7._

## Troubleshooting

`/codeo:doctor` prints one `ok` or `fail` line per check and reports every failure. Each entry below is one check and the fix its own message gives. Paths in the messages below are your project's own.

**config.** `config.json not found at …/.codeo/config.json` means the project has no codeo state: run `/codeo:setup`. An `invalid JSON` message means the file does not parse; fix the file with `jq . .codeo/config.json`, which points at the error. A `schema … is newer than this plugin supports (1); update the plugin` message means the project was set up by a newer codeo: run the install command to get the latest release.

```
fail config: config.json not found at /home/you/app/.codeo/config.json
fail schema: no usable schema value
```

**schema.** `no usable schema value` follows an unreadable config; fix the config. `N is newer than this plugin supports` means the plugin is older than the project's config; run the install command.

```
fail config: config.json: schema 2 is newer than this plugin supports (1); update the plugin
fail schema: 2 is newer than this plugin supports (1)
```

**codename.** The optional `codename` must be lower-case letters, digits and single hyphens between them, starting with a letter, 2 to 30 characters. Change it in `.codeo/config.json`, or remove it.

```
fail codename: "Bad Name" is not valid: lower-case letters, digits and single hyphens between them, starting with a letter, 2-30 characters
```

**gh-auth.** `gh api user failed` means `gh` is not logged in or its token was rejected: run `gh auth login`. `gh is not installed` means install `gh`.

```
fail gh-auth: gh api user failed: HTTP/2.0 401 Unauthorized
```

**gh-scopes.** Checked only when the config has a board. `the token lacks the project scope; run 'gh auth refresh -s project'`: run that command.

**board.** `not readable: <numbers>` lists the board projects in `.codeo/config.json` (`board.projects`) that `gh project view` cannot open. Correct the number or the `board.owner`, and check `gh auth status` shows the `project` scope.

```
fail board: not readable: 9999
```

**priority-labels.** Checked only when `issue.priority` is `true`. `missing: …; create each with: …` prints the command that creates each missing label; run them. `cannot read the repository's labels` means `gh` could not read them: check `repo` in the config and your access.

**ruleset.** `<branch> does not require: <checks>` means the base branch's ruleset or branch protection lacks a required status check codeo relies on (`tests` and `qc-verdict`, or the names in `ci.requiredChecks`): add it to the ruleset in the repository's settings. `could not read rules for <owner>/<name>@<branch>` means the repository or branch in the config is wrong or `gh` cannot read it.

```
fail ruleset: main does not require: lint
```

**suites.** `not installed or unset: <suite>:<command>` means a suite's `build` or `test` command does not resolve on this machine: install the tool, or correct the command in `.codeo/config.json`.

```
fail suites: not installed or unset: api:make api:pytest
```

**deps.** `missing: …` names a tool `codeo` needs that is not installed (`jq`, `git`, or `bash>=4.3` with the version found): install it with your package manager.

**overlays.** Each `## <name>` heading in `.codeo/overlays/<skill>.md` must be an extension point of that skill, spelled `## <point>` with one space after the hashes, and used once. The message names the file, the heading and the points the skill has; rename or delete the section. `docs/extension-points.md` lists them.

**superpowers.** `not installed; install it with: claude plugin install superpowers@superpowers-marketplace`: run that command (or the install command, which installs it). A `cannot verify` result is `ok`: the file `claude` keeps of installed plugins was not readable.

```
fail superpowers: not installed; install it with: claude plugin install superpowers@superpowers-marketplace
```

**`its source doesn't match its extraKnownMarketplaces entry`.** Adding the codeo marketplace at a second tag by hand fails, because the marketplace is already added at the first:

```
$ claude plugin marketplace add kbajpai/codeo@v1.0.9
Adding marketplace…✘ Failed to add marketplace: Cannot add marketplace "codeo": its source doesn't match its extraKnownMarketplaces entry in user or managed settings; add it from the source that entry lists, or change the entry.
```

Run the install command instead, which removes the marketplace and adds it at the tag you ask for (the latest, or the one after `--version`).

**A hand-edited `ref` does not take effect.** After you edit `ref` under `extraKnownMarketplaces.codeo.source` in a project's `.claude/settings.json`, `install.sh --scope project` still installs what the machine's codeo marketplace holds: the installer reads the machine's pin, not the project's file. Run `claude plugin marketplace remove codeo` first (from outside any project, to leave every project's settings file alone; it drops codeo from every project on the machine, so restore each as shown in *Updating*), then `install.sh --scope project` in the project. The install rewrites `ref` to the latest release; to keep an older one, run `install.sh --scope project --version <tag>` instead.

## Updating

Run the install command again. With no `--version` it installs the latest release; if that differs from what you have, it replaces codeo, which uninstalls it at every scope on the machine and reinstalls it at the scope you asked for, and it names each project install it dropped. The walk-throughs, with the installer's output, are in [docs/updating.md](docs/updating.md): updating, what a replace drops, restoring a project or local install, when an update fails, updating superpowers, and moving a project's pin.

## Uninstalling

Uninstall codeo for you:

```
$ claude plugin uninstall codeo@codeo
✔ Successfully uninstalled plugin: codeo (scope: user)
```

Run in a project, the bare command acts on the copy you installed for yourself when there is one: with a user-scope copy and a project-scope install side by side, it uninstalls the user-scope copy and leaves the project's install in place:

```
$ cd /home/you/app
$ claude plugin uninstall codeo@codeo
✔ Successfully uninstalled plugin: codeo (scope: user)
```

When codeo is installed there at project scope and nowhere at user scope, `claude` refuses, and the scope must be named:

```
$ claude plugin uninstall codeo@codeo
✘ Failed to uninstall plugin "codeo@codeo": Plugin "codeo@codeo" is enabled at project scope (.claude/settings.json, shared with your team). To disable just for you: claude plugin disable codeo@codeo --scope local
```

`claude plugin uninstall codeo@codeo --scope project`, run in the project, uninstalls it and removes `codeo@codeo` from `enabledPlugins` in the project's `.claude/settings.json`; the `codeo` entry under `extraKnownMarketplaces` stays, so the marketplace is still declared.

To remove codeo and its marketplace together, which also uninstalls codeo at every scope on the machine:

```
$ claude plugin marketplace remove codeo
✔ Successfully removed marketplace: codeo
Also uninstalled 1 plugin from this marketplace:
  codeo@codeo
The removal also deletes their saved options, secrets and data where it can.
To use a plugin again, add the marketplace back and reinstall the plugin.
```

Every project-scope and local install is gone afterwards, whichever project you ran it from; the installer does the same on a replace and prints a restore command for each (see *Updating*). Run it from outside any project (`cd ~` first): then it leaves every project's `.claude/settings.json` alone. Run inside a project that declares codeo, it also removes `codeo@codeo` from that project's `enabledPlugins` and the `codeo` entry from its `extraKnownMarketplaces`, and the file shows as modified in `git status`.

superpowers is separate: `claude plugin uninstall superpowers@superpowers-marketplace` (add `--scope project` for a project-scope install).

What stays in each project that used codeo, unless you ran one of the commands above inside it:

- `.codeo/`, with the config and every dossier, committed to the project's repository
- `docs/plans/`, the plans
- `.claude/settings.json`, which still declares both marketplaces and plugins

To take codeo out of a project, delete `.codeo/` and `docs/plans/` (or keep the plans), and remove the `codeo` entries from `extraKnownMarketplaces` and `enabledPlugins` in `.claude/settings.json`, then commit.

## The skills

The six pipeline skills run in order inside one workflow, each owning one dossier file under `.codeo/<issue>/`; `triage` and `cleanup` run outside the workflow lock, between workflows, and a project's role guard (see [`.devcontainer/README.md`](.devcontainer/README.md#roles-and-the-guard)) keeps each skill in the checkout it belongs in; `setup` and `doctor` set a project up and check it. [`docs/skills.md`](docs/skills.md) describes each one: what it does, what it reads and writes, what it hands off to and never does, and its extension points.

| Skill | Purpose |
|-------|---------|
| [`/codeo:issue`](docs/skills.md#issue) | Turn a raw idea or finding into a well-formed GitHub issue through a question-and-answer pass |
| [`/codeo:init`](docs/skills.md#init) | Start work on a Ready issue: claim the branch, write its dossier, take the lock, hand off to plan |
| [`/codeo:plan`](docs/skills.md#plan) | Explore, ask, and document a change as a reference doc or implementation plan, and check its footprint against every other workflow in flight |
| [`/codeo:implement`](docs/skills.md#implement) | Execute the approved plan task by task through the superpowers execution skills, deploy to a shared environment under its lease when the plan needs it, build, and hand off to QC |
| [`/codeo:qc`](docs/skills.md#qc) | Check the build, the suites, the criteria, the documentation and an independent review, read what the environment runs, and route forward or back |
| [`/codeo:close`](docs/skills.md#close) | Open the pull request, wait for the merge, route review feedback back, verify the merge, clean up and release the lock; also the way to stash or abandon a workflow |
| [`/codeo:triage`](docs/skills.md#triage) | Find the loose ends development left behind and route them to issues |
| [`/codeo:cleanup`](docs/skills.md#cleanup) | Print the commands that remove finished issues' containers; it proves each one first and runs nothing |

[`/codeo:setup`](docs/skills.md#setup) writes `.codeo/` with a starter `config.json` and creates `docs/plans/`;
[`/codeo:doctor`](docs/skills.md#doctor) checks the whole set-up — config, GitHub login and scopes, board, branch ruleset, suites, dependencies, overlays and superpowers — and reports every failure.

A project shapes a skill without editing it through overlay files, `.codeo/overlays/<skill>.md`.
Each skill's extension points are listed in `docs/skills.md` and documented in
`docs/extension-points.md`, which also gives the file format. The dossier and hand-off protocols are
in `docs/dossier.md` and `docs/handoff.md`.

## More documentation

_Written in Task 8._

## Contributing

Working on codeo itself (the dev container, the tests, the dossier checker): see [`CONTRIBUTING.md`](CONTRIBUTING.md).
