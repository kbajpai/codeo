# Issue #151 — plan

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/151 |
| Branch | `docs/install-codeo-one-command-document` |
| Updated | 2026-11-21 |

## Where this stands

Q1-Q6 answered (all recommendations accepted, 2026-11-21). The plan is drafted in `.codeo/151/plan-draft.md` and awaits the engineer's approval; the footprint is checked against other workflows and committed after approval, and `## Outcome` is written after that.

## Questions

### Q1 — Where does the one command live, and how is it fetched?

**Why it matters:** it decides the URL the README shows, the file the plan adds, and whether `docs/release-checklist.md` changes (the issue puts changing the release checklist out of scope).
**Options:**
- `install.sh` at the repository root, fetched from `main` (recommended). The README command is `curl -fsSL https://raw.githubusercontent.com/kbajpai/codeo/main/install.sh | bash`, and `… | bash -s -- --version v1.0.7 --scope project` with options. This is how `codeo update` already fetches its files (#133). The script on `main` installs a release tag, never `main` itself. No release step changes. The README also shows the two-step form (download, read, run) for people who do not pipe to a shell.
- Attached to each GitHub Release, fetched from `releases/latest/download/install.sh`. The script then matches the release exactly, but every release needs a new upload step in `docs/release-checklist.md`, which is out of scope, and a release made without it breaks the README's command.
- No preference, you pick (I would take the first).

**Answer:**
`install.sh` at the repository root, fetched from `main`, as recommended (engineer, in the conversation, 2026-11-21: "I accept all your recommendations").

### Q2 — codeo is already installed at another version: does the same command replace it?

**Why it matters:** it decides whether the README's *Updating* section is "run the install command again", and whether the script needs the replace path and its tests.
**What is there now:** Claude Code keeps one `codeo` marketplace per machine, pinned to one tag. Adding it again at another tag fails, so changing the version means `claude plugin marketplace remove codeo` and adding it again, and the removal uninstalls codeo at every scope on that machine. `.devcontainer/scripts/plugins.sh` does this, and first checks that the new tag exists so a failed fetch does not leave the machine with no codeo.
**Options:**
- Replace, with or without a tag (recommended). A run that asks for a version other than the installed one (a given tag, or the latest release when none is given) checks the tag exists, replaces the marketplace, reinstalls codeo at user scope if it was there and at project scope in the current project if it was there, and prints `codeo v1.0.6 -> v1.0.7` with the changelog link. *Updating* is then the same command. The cost: a bare re-run can move codeo to a new release while a workflow is in flight, so the README says to read the changelog's three lines first.
- Replace only when a tag is given. A bare re-run with an older codeo installed changes nothing, prints that a newer release exists and the command that installs it, and exits 0. Safer mid-workflow, but "run without a tag installs the latest release" then holds only on a machine with no codeo.
- Never replace. Any other installed version is reported with the `claude plugin` commands to change it, and the script exits non-zero.

**Answer:**
Replace, with or without a tag, as recommended (engineer, in the conversation, 2026-11-21: "I accept all your recommendations").

### Q3 — Does project scope, and the README's `.claude/settings.json` snippet, cover `superpowers` too?

**Why it matters:** it decides what the snippet contains and what `--scope project` runs. The issue's wording names only the codeo marketplace and `codeo@codeo`.
**What is there now:** in the trial, `claude plugin marketplace add … --scope project` followed by `claude plugin install … --scope project` wrote exactly a committable snippet into the project's `.claude/settings.json`: `extraKnownMarketplaces` (with the tag as `ref`) and `enabledPlugins`. `claude plugin install --scope project` alone writes only `enabledPlugins`, which is not enough for a teammate's machine to find the marketplace.
**Options:**
- Both plugins (recommended). `--scope project` declares both marketplaces and enables both plugins in the project's `.claude/settings.json`, and the README's snippet is that file. A teammate who trusts the folder is offered both, and `/codeo:doctor`'s `superpowers` check passes for them. The codeo marketplace is always pinned to a tag (an unpinned one follows `main`, which is unreleased work); `superpowers` is not pinned.
- codeo only, as the issue words it. `superpowers` stays a per-machine install at user scope, and a teammate who only trusted the folder gets a failing `superpowers` check from `/codeo:doctor` until they run the one command.

**Answer:**
Both plugins, as recommended (engineer, in the conversation, 2026-11-21: "I accept all your recommendations").

### Q4 — What backs the README's *first workflow* section?

**Why it matters:** the criterion says each command in the README was run and its output matches. Shell commands (the installer, `claude plugin list`, `setup.sh`, `doctor.sh`) can show real output. The slash commands of a workflow cannot match word for word, so the plan has to say what the section shows and where it comes from. The answer decides whether there is a task for you on a new GitHub repository.
**Options:**
- A finished issue from this repository (recommended). The section lists the six steps in order, each with the command, what it asks of the engineer and the file it leaves (`.codeo/<N>/init.md`, the plan under `docs/plans/`, and so on), taken from a merged issue's archived dossier under `.codeo/done/`. No output blocks for slash commands. `/codeo:setup` and `/codeo:doctor` are run in a scratch directory in this container and their real output is shown, failures included, which also feeds *Troubleshooting*.
- A scratch repository taken through a whole workflow. You create a throwaway GitHub repository, and one small issue goes from `/codeo:setup` to a merged pull request there; the README quotes that run. It is the most faithful evidence and proves setup on a project that is not codeo, but it is an hour or more of your time on a real repository with a board and rulesets.

**Answer:**
A finished issue from this repository, as recommended (engineer, in the conversation, 2026-11-21: "I accept all your recommendations").

### Q5 — Where do you run the two checks that need a clean machine, and in which shell?

**Why it matters:** the lock says `host: container`, so a task you run yourself is marked `Runs on: the engineer's host` and its command is written for the shell you type in. Two criteria need a machine with no codeo: the one command installing both plugins, and Claude Code offering the install when a folder holding the snippet is trusted. The second is interactive, so only you can do it.
**What is there now:** `CLAUDE_CONFIG_DIR` pointed at an empty directory gives Claude Code a clean configuration (no plugins, no marketplaces) without touching the real one; the trial used it. An interactive session under it asks you to log in first. Until the branch merges, the script is fetched from the branch (`…/kbajpai/codeo/docs/install-codeo-one-command-document/install.sh`), while the README shows the `main` URL.
**Options:**
- In this issue's container (recommended). `/codeo:implement` runs the one command under an empty `CLAUDE_CONFIG_DIR` and records `claude plugin list`. You run the trust check in the container's terminal (bash): an empty folder holding the snippet, `claude` started under an empty `CLAUDE_CONFIG_DIR`, and you paste what it offers into the pull request. No shell question, since the container's shell is bash.
- On your own machine or another one. Say which shell you type in there (bash or zsh, PowerShell, cmd), and whether it already has codeo installed (the check then still needs an empty `CLAUDE_CONFIG_DIR`).

**Answer:**
In this issue's container, as recommended (engineer, in the conversation, 2026-11-21: "I accept all your recommendations").

### Q6 — The contributor page: `CONTRIBUTING.md` at the root, and does *Dev container* move too?

**Why it matters:** it decides the new file's path and which README sections leave. The issue names three sections to move (tests, dossier checker, replay) and says nothing about *Dev container*, which describes codeo's own containers (the clone URL is `kbajpai/codeo`) and is not something an adopter needs to install or use the plugin.
**Options:**
- `CONTRIBUTING.md` at the root, and *Dev container* moves with the three (recommended). GitHub links a root `CONTRIBUTING.md` from the repository page and from new pull requests. The three named sections are moved word for word; the *Dev container* paragraph follows them. The README keeps one line linking to the page.
- `CONTRIBUTING.md` at the root, *Dev container* stays in the README.
- `docs/contributing.md`, with either choice for *Dev container* (say which).

**Answer:**
`CONTRIBUTING.md` at the root, and *Dev container* moves with the three, as recommended (engineer, in the conversation, 2026-11-21: "I accept all your recommendations").

## Notes

**What the trial showed** (`claude` 2.1.325, an empty `CLAUDE_CONFIG_DIR`, real GitHub):

- `claude plugin marketplace add kbajpai/codeo@v1.0.6` then `claude plugin install codeo@codeo --scope user` installs 1.0.6 and writes `extraKnownMarketplaces` and `enabledPlugins` to the user's `settings.json`.
- Adding the marketplace again at `@v1.0.7` fails: `Cannot add marketplace "codeo": its source doesn't match its extraKnownMarketplaces entry`. `claude plugin update codeo@codeo` says 1.0.6 is the latest, because the marketplace is pinned. A project whose snippet pins another tag than the machine's marketplace will meet this error; it belongs in *Troubleshooting*.
- `claude plugin marketplace remove codeo`, run from `$HOME`, uninstalls codeo at every scope and leaves a project's `.claude/settings.json` untouched.
- `claude plugin list --json` gives `id`, `version`, `scope`, `enabled` and `projectPath` per installed copy, which is what the script reads to decide whether anything needs doing.

**Calls I am making unless you object** (they go into the draft under Global Constraints):

- The latest release is the highest `vX.Y.Z` tag from `git ls-remote --tags https://github.com/kbajpai/codeo`. It needs no GitHub login, and the tag ruleset lets only the owner create `v*` tags.
- The script checks `claude` as well as bash 4.3, jq, git and gh, and names every missing one in a single run. It is written so bash 3.2 (macOS's own) can parse it far enough to print the "bash is too old" line. It checks that gh exists, not that it is logged in: `/codeo:doctor` reports that.
- An installed `superpowers`, from any marketplace and at any version, is left alone. The README gives `claude plugin update` for it.
- No uninstall option. The README's *Uninstalling* section gives the `claude plugin uninstall` and `claude plugin marketplace remove` commands and says what stays in a project (`.codeo/`).
- On Windows the command is run in Git Bash or WSL, as codeo's scripts already require.
- One pull request (issue.md Q1-Q4).
- `scripts/doctor.sh` is not changed.

**Other workflows in flight.** #149 (`fix/close-non-blocking-findings-143`) and #138 (`fix/live-session-signal-does-not`) are both at `init` with nothing changed and no footprint yet, so there is nothing to compare. `init.md` expects #149 to edit `CHANGELOG.md`, which this plan also edits (one bullet under `## Unreleased`). `overlap.sh` is run once this plan's footprint is committed, and an overlap it prints becomes a question then.

`engineering:system-design` and `engineering:architecture` are not available as skills in this session; their structure is applied directly in the draft.

### Footprint

```
files:      install.sh, tests/install.test.sh, README.md, CONTRIBUTING.md, CHANGELOG.md, docs/plans/2026-11-21-install-one-command-151.md
wiki:       none
exclusive:  none
sequenced:  none
```

## Outcome

_Pending — written at the hand-off._

## Log

- 2026-11-21 — Q1-Q6 raised · cost: 3m · fable-5-2 89k in + 764k cached / 13k out
- 2026-11-21 — Q1-Q6 answered, plan drafted for review · cost: 9m · fable-5-2 + sonnet-5-5
