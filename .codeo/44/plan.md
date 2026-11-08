# Issue #44 — plan

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/44 |
| Branch | `feat/dev-container-defaults-remote-control` |
| Updated | 2026-11-08 |

## Where this stands

Round 1. Q1-Q5 are open; no plan is drafted. No other workflow is in flight, so there is no footprint overlap to raise.

What the code does today:

- `.devcontainer/Dockerfile` bakes **no** `~/.claude/settings.json`. The issue's note that the image sets the plugins and update channel is not what the file does: the plugins come from `.devcontainer/scripts/plugins.sh` (run by the start script), and `autoUpdatesChannel` is not written anywhere in `.devcontainer/`. The Dockerfile only keeps `settings.json` if the installer made one. Acceptance criterion 7 therefore holds as long as the new code *merges* into whatever file exists and never rewrites it.
- `remoteControlAtStartup` is a real boolean key in Claude Code 2.1.319, the version installed here (`strings` of the binary: "Start Remote Control bridge automatically each session"). The reference project's claim that it belongs in user-scope settings is not something I could confirm from the binary; I will confirm it in the first task with a real session, not assume it.
- `devcontainer.json` has only `postCreateCommand` (runs once, when the container is created). It sets no `window.title`; VS Code builds `codeo [Dev Container: codeo @ desktop-linux]` itself from `name`.
- `.codeo/active` is written by `/codeo:init` at its last step, long after `postCreateCommand` ran. So at creation there is never a lock, and the title written then would always be `codeo [home]`.
- `.gitignore` has no `.vscode/` line; `.vscode/` does not exist yet.
- `devcontainer-start.sh` already checks `claude auth status` (step 6) and turns a failure into a TODO; it does not check the three environment variables.
- `tests/devcontainer.test.sh` runs the start script in a scratch repo against stub executables, and pins `postCreateCommand` to exactly `bash .devcontainer/scripts/devcontainer-start.sh`.

## Questions

### Q1 — Where does `remoteControlAtStartup: true` get written: the image, or the start script?

**Why it matters:** the image is built once, so an image-time merge needs a rebuild to reach any container, and a Dockerfile `RUN jq …` is only testable by reading its text. The start script runs in every new container, can be re-run in an existing one (including this one, without a rebuild), and is already tested by behaviour against stubs.

**Options:**
- *The start script (my recommendation):* a new step merges `{"remoteControlAtStartup": true}` into `${CLAUDE_CONFIG_DIR:-$HOME/.claude}/settings.json` with `jq`, creating the file when absent and keeping every other key. Idempotent; a test seeds a settings file with plugins and `autoUpdatesChannel` and asserts they survive (criterion 7). Existing containers get it by re-running the script.
- *The Dockerfile, as the reference project does:* `RUN jq '. + {remoteControlAtStartup: true}'` after the Claude install. Matches the reference and the issue's wording ("baked into the image"). Needs a rebuild, and `~/.claude` is not in a volume so nothing else would overwrite it, but the test can only grep the Dockerfile.
- *Both:* belt and braces; the second half is dead weight.

**Answer:**

### Q2 — How is the window title kept right when the lock is taken after the container starts?

**Why it matters:** `/codeo:init` takes the lock (`.codeo/active`) minutes or days after `postCreateCommand` ran, and criterion 4 wants `codeo [#<N>]` once it exists. A script that runs only at creation can never write that. This very container is the example: it is titled `[home]` now and holds #44's lock.

**Options:**
- *A `postStartCommand` that re-runs only the title script (my recommendation):* `.devcontainer/scripts/window-title.sh` rewrites the title; it runs at creation (from the start script) and again each time the container starts, so a container restarted after `init` is retitled. Cheap and deterministic. The title does not change *in place* when the lock is taken mid-session; it follows at the next start or when the script is run by hand (`bash .devcontainer/scripts/window-title.sh`, which the start-script `ready` line can mention).
- *Also hook `lock.sh`:* make `/codeo:init` call the script after `lock.sh take`. Updates the title instantly, but it puts a dev-container concern into codeo's plugin scripts, which this issue's scope does not reach (anything for projects that use codeo is out of scope, and `lock.sh` is shared).
- *Creation only:* simplest, but the title stays `[home]` in every container that later takes a lock, which defeats the point of the issue.

**Answer:**

### Q3 — How is `.vscode/settings.json` kept out of `git status`?

**Why it matters:** criterion 6 says `git status` stays clean, and the title file is per clone. There is no `.vscode/` entry in `.gitignore`.

**Options:**
- *The clone's own exclude file (my recommendation):* the script appends `.vscode/settings.json` to `$(git rev-parse --git-path info/exclude)` if it is not already there. Per clone, nothing tracked changes, no PR noise, and it works in a `git worktree` (where `.git` is a file). A committed `.vscode/` file, should the project ever add one, would still show its changes (excluded files that are tracked are not hidden).
- *A line in the tracked `.gitignore`:* `.vscode/` for everyone. One more tracked change in this PR, and it hides `.vscode/` for people who do not use the dev container too.

**Answer:**

### Q4 — How do we prove "a session is listed in claude.ai/code" (criteria 1 and 2)?

**Why it matters:** `/codeo:qc` grades the criteria and the test suite cannot see claude.ai/code. A criterion with no proof is either skipped or fudged.

**Options:**
- *Test the setting, check the listing by hand (my recommendation):* `tests/devcontainer.test.sh` asserts that the key is written and survives a re-run; the two listing criteria are verified by you after a rebuild (or after re-running the start script here, then `/clear` in a new session) and the result goes in `qc.md` as a manual check. I will also run `claude` here to confirm the key behaves as the reference project says before writing the task.
- *Test the setting only and declare 1 and 2 unverifiable:* same tests, no manual step; `qc` would carry the two criteria as open.

**Answer:**

### Q5 — Which environment and login states raise a TODO?

**Why it matters:** criterion 3 lists `CLAUDE_CODE_OAUTH_TOKEN`, `ANTHROPIC_API_KEY`, `ANTHROPIC_BASE_URL` and "no claude.ai login". The existing step 6 only checks that `claude auth status` succeeds, which is also true for an API-key login that Remote Control does not accept.

**Options:**
- *Four TODO checks in the start script, no new file (my recommendation):* one TODO per variable that is set (naming the variable and saying Remote Control will not work while it is), and the existing login check extended so it is also a TODO when `claude auth status` reports an `authMethod` other than `claude.ai`. All TODOs stay non-fatal: the script still exits 0.
- *A separate `claude-login.sh`, as the reference project has:* the same checks in their own script the start script calls. Easier to test alone, one more file to maintain, and a second place that runs `claude`.

**Answer:**

## Notes

Calls I am making unless you say otherwise:

- One PR for the whole issue; no split.
- The title text comes from one script, `.devcontainer/scripts/window-title.sh`, which can print the text alone (`--print`: `codeo [home]` or `codeo [#<N>]`, the number read from the `issue:` line of `.codeo/active`, the name from `.codeo/config.json`'s `codename`). Issue #45 needs the same text for the session title, so it is a separate, callable piece.
- `window-title.sh` merges `window.title` into `.vscode/settings.json` with `jq`, creating the file and directory when absent and leaving every other key alone.
- Documentation: `CHANGELOG.md` gets an entry; the start script's and `devcontainer.json`'s header comments are updated. No page under `docs/` describes the dev container, so none moves.
- Nothing in `scripts/`, `lib/`, `hooks/` or `skills/` changes.

## Log

- 2026-11-08 — plan round 1: Q1-Q5 raised · cost: unavailable
