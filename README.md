# codeo

codeo is an agent-workflow plugin for Claude Code: it carries a piece of work from issue to merged pull request through six steps: issue, init, plan, implement, QC and close. It is unrelated to SYSGO's CODEO IDE and to GoCodeo.

## Requirements

- bash 4.3 or later
- `jq`
- `git`
- `gh`, the GitHub CLI; board use also needs `gh project`, which reads GraphQL, so the token must be allowed to use it
- `claude`, Claude Code

The installer checks for all five in one run and names every one that is missing or too old. It installs none of them: use your system's package manager, then run it again.

## Installing

One command installs the latest release of codeo and of the superpowers plugin it builds on, for you, in every project:

```bash
curl -fsSL https://raw.githubusercontent.com/kbajpai/codeo/main/install.sh | bash
```

The latest release is the highest `vX.Y.Z` tag of the repository. It prints one `install:` line per step, between the lines `claude` prints itself. Claude Code sessions that are already open need a restart to load the plugins.

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

Two options follow `bash -s --`. `--version` picks a release other than the latest (`v1.0.8`, or `1.0.8`); the installer checks the tag exists before it changes anything, and a run that asks for a different version than the one installed replaces it (its output is in [docs/updating.md](docs/updating.md)):

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

`ref` pins the codeo release the project uses; write the newest release tag, which `git ls-remote --tags --refs https://github.com/kbajpai/codeo 'v*'` lists. A teammate who opens the folder in Claude Code and trusts it is offered both plugins. A later run that replaces codeo on your machine drops this project's install (see *Updating*). To move the project to another release, change `ref` (see *Updating*).

## Setting a project up

Two slash commands, run once in the project's repository, in Claude Code:

1. `/codeo:setup` creates `.codeo/` with a starter `config.json` (the schema, the repository's owner and name read from the `origin` remote, the base branch read from `origin/HEAD`, and empty `suites` and `resources`), a `.codeo/.gitignore` for the per-checkout files, and `docs/plans/`. A value it cannot read is written as `TODO-set-me` and named on stderr. It refuses to overwrite a `config.json` that exists. `--stack <name>` records a stack name.
2. `/codeo:doctor` checks that everything the workflow needs is in place and reports every failure, not only the first. Fix what it reports (see *Troubleshooting*) and run it again until it ends clean.

Both skills run a script, and the script's own output is what the skill reports. In a project cloned from a GitHub repository whose `origin` points at it, `setup` prints:

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

and `doctor` with a logged-in `gh` and superpowers installed prints:

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

Commit `.codeo/` and `docs/plans/`; the config is shared by everyone who works on the project. The `suites` array holds the build and test commands `/codeo:implement` and `/codeo:qc` run; `/codeo:doctor` fails a suite whose command does not resolve.

### Running on the host

The home role runs `/codeo:issue`, `/codeo:init`, `/codeo:triage` and `/codeo:cleanup` in a clone named `<codename>-home`. A project with its own role guard refuses a skill outside its checkout.

See [docs/home-checkout.md](docs/home-checkout.md) for the home checkout, the guard and the tracking comment, and [.devcontainer/README.md](.devcontainer/README.md) for the dev container.

## Your first workflow

A piece of work goes through six slash commands in order. Each one owns one file under `.codeo/<N>/`, where `<N>` is the GitHub issue number, and the file records what the step decided, so the next step (and you, later) can read it. The example is a finished workflow, whose files are archived under `.codeo/done/<N>/` once the pull request merges: an issue that fixed three leftovers from earlier changes, archived in this repository under `.codeo/done/143/` (its `init.md`, `plan.md`, `implement.md`, `qc.md` and `close.md` and the `issue.md` the engineer approved), so the files each step below describes can be opened.

1. **`/codeo:issue`** turns a raw idea, bug or finding into a GitHub issue. It asks you questions until the problem, the requirements and the acceptance criteria are clear, shows you a draft, and files it only when you approve. The draft is kept in `.codeo/intake/<N>/issue.md` on the project's intake branch. It stands alone and hands off to nobody.
2. **`/codeo:init`** starts work on an issue that is ready (on the project board's Ready column, when the project has a board). Name the issue number. It claims the number, cuts and pushes a branch off the base branch, moves the card to In progress, takes the workflow lock, and writes `.codeo/<N>/init.md`: the issue, the branch, the state and the acceptance criteria copied word for word. It asks you nothing beyond the number; its question list reads `None`.
3. **`/codeo:plan`** explores the code and writes down how to make the change. It puts its questions to you in `.codeo/<N>/plan.md`, each with why it matters, what exists now and the options, and a recommendation; you answer them (in the example, all nine as recommended), then review the plan. The plan itself is saved under `docs/plans/` only once you approve it, and `plan.md` records the decisions. Nothing is written to the application's code.
4. **`/codeo:implement`** builds the approved plan task by task, through the superpowers skills, committing each task, and confirms the change builds. It asks you only when the plan looks wrong or stale. It writes `.codeo/<N>/implement.md`: what was built, with the commit for each task.
5. **`/codeo:qc`** checks the result without fixing anything: the build, the configured test suites, each acceptance criterion, an independent code review, and what the project's shared environment runs, if it has one. It writes `.codeo/<N>/qc.md` with a verdict and sends you forward to a pull request or back to `/codeo:implement` or `/codeo:plan`.
6. **`/codeo:close`** opens the pull request and waits. You review and merge it; `close` never merges. Review feedback or a conflict with the base branch goes back through `/codeo:implement` and `/codeo:qc`. After the merge it proves the merge, asks before deleting the remote branch, releases every lease and the lock, and moves the dossier to `.codeo/done/<N>/`. It writes `.codeo/<N>/close.md`.

Run the next command when a step hands off; each says which one. `/codeo:close` is also how you stash a workflow to come back to, or abandon one whose pull request was closed unmerged. A step that is interrupted can be run again: it works out where the workflow stands from the dossier and GitHub.

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

## Contributing

Working on codeo itself (the dev container, the tests, the dossier checker): see [`CONTRIBUTING.md`](CONTRIBUTING.md).
