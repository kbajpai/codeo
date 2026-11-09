# Issue #47 — plan

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/47 |
| Branch | `fix/harden-dev-container-scripts-session` |
| Updated | 2026-11-09 |

## Where this stands

Round 1. The lock is held in this container (`codeo-47`). Read `init.md`, `issue.md`, the #44 and #45
plans, dossiers and QC findings, the three scripts under `.devcontainer/scripts/`, `.claude/settings.json`,
`devcontainer.json`, the Dockerfile and `tests/devcontainer.test.sh`. Ten of the thirteen criteria are
edge-case fixes whose shape the QC findings already dictate; three need a decision before the plan can be
drafted — Q1-Q3 below. Nothing is drafted past them.

## Questions

### Q1 — How do a running session and the VS Code window follow the lock?

**Why it matters:** criterion 10 wants the window title "written for the clone" to follow a lock taken or
released mid-session without a container restart, and the issue leaves "how an already-running session is
retitled" to this plan. Today `window-title.sh` writes `.vscode/settings.json` once per container start, and
`session-title.sh` prints nothing when the session already has *any* title — so neither the window nor an
open session changes when `/codeo:init` or `/codeo:close` runs. What retitles them decides which script
changes, what the `UserPromptSubmit` hook may write, and how `/rename` is told apart from the hook's own title.

**Options:**
- *The prompt hook owns both titles (my recommendation):* `session-title.sh` treats a `session_title` that is
  its own — one ending in ` · <first eight of this session's id>` — as replaceable: when the title
  `window-title.sh --print` now gives differs, it prints a new `sessionTitle`; a title of any other shape
  (`/rename`) is kept, as today. On every run it also calls `window-title.sh` (write mode) so the clone's
  `.vscode/settings.json` follows; `window-title.sh` gains an early exit when the stored `window.title` is
  already current, so a prompt costs one `jq` read and writes nothing unless the lock changed. VS Code applies
  a workspace-settings change live. Effect: the window and the session both read `[#47]` at the first prompt
  after the lock is taken, and `[home]` at the first prompt after `/codeo:close`. No change outside
  `.devcontainer/` and `.claude/`.
- *Only the window follows; a running session keeps its title:* the hook refreshes `.vscode/settings.json` as
  above but never replaces an existing session title. Simpler rule, no `/rename` heuristic; but a session
  opened before `/codeo:init` stays `codeo [home] · …` in the picker and in claude.ai/code until it is
  `/clear`ed, which is the state the issue reports as the gap.
- *A third hook on `PostToolUse` (matcher `Bash`):* retitles only after a tool call, which is when `lock.sh`
  or `close` actually runs, instead of on every prompt. Tighter, but a third registration in
  `.claude/settings.json`, a third stdin shape to parse, and the title still waits for the next tool call —
  no cheaper in practice than a `jq` read per prompt.
- *Hook `lock.sh` and `/codeo:close` in the plugin core:* out — `scripts/` ships to every project that uses
  codeo, and the dev container is this repository's own; every dev-container plan so far has kept the core
  untouched.

**Answer:**

### Q2 — Where does the persisted git identity live, and how does `git config --global` reach it?

**Why it matters:** criterion 13 wants a fresh container to find the identity in a `~/.config/git` volume.
Git reads two global files — `$XDG_CONFIG_HOME/git/config` (`~/.config/git/config`), then `~/.gitconfig`,
the later winning — but *writes* `--global` to `~/.gitconfig` whenever that file exists. In this container
`~/.gitconfig` exists and holds everything: the start script's `safe.directory`, `gh auth setup-git`'s
credential helpers, the helper VS Code injects, and the identity you typed by hand (the file is not a copy of
a host gitconfig: its sections are in the order those steps ran). So a volume at `~/.config/git` is read, but
nothing lands in it unless the writes are steered there. The choice decides whether `devcontainer.json`
gains an environment line, what the Dockerfile creates, and what the identity TODO tells you to type.

**Options:**
- *Volume `codeo-git` at `/home/dev/.config/git`, and `containerEnv.GIT_CONFIG_GLOBAL=/home/dev/.config/git/config`
  (my recommendation):* with that variable, git reads and writes exactly that one file as the global config
  and ignores `~/.gitconfig` altogether. Every `--global` write — the identity you type after the TODO, the
  start script's `safe.directory`, `gh auth setup-git`'s helpers — lands in the volume and is there for every
  later container. The Dockerfile creates `/home/dev/.config/git` owned by `dev`, exactly as it does for
  `.config/gh`, so an empty volume takes `dev`'s ownership. The TODO text stays `git config --global …`. Cost:
  a host `~/.gitconfig` VS Code may copy into the container is ignored (it is not supplying an identity today
  anyway), and the `gh_login_is_one_named_volume` test is rewritten for two volumes.
- *The same volume, no environment variable:* the Dockerfile also ships an empty `/home/dev/.config/git/config`
  so that, when nothing has created `~/.gitconfig` yet, git's own rule writes `--global` to the XDG file. It
  holds only if nothing writes `~/.gitconfig` first — VS Code's credential-helper step and a copied host
  gitconfig both can — so whether the identity persists depends on start-up ordering. Fragile.
- *A volume at a path of its own (say `/home/dev/.config/git-identity`), included from `~/.gitconfig`:* the
  start script writes `include.path` into `~/.gitconfig` and the TODO tells you to write the identity with
  `git config --file <that path> …`. Deterministic too, but a second config file to explain, a TODO that no
  longer reads as plain `git config --global`, and `safe.directory` and the credential helpers still lost
  per container.

**Answer:**

### Q3 — One pull request, or split the bundle?

**Why it matters:** `init.md` notes the issue is large (the #44 hardening, the git-identity volume, the #45
follow-ups) and that the plan may propose splitting. A split means `/codeo:issue` files the parts as new
issues and this plan narrows to what remains; one PR means one plan with its tasks grouped so each commit
reviews on its own.

**Options:**
- *One PR, tasks grouped by theme (my recommendation):* (1) `devcontainer-start.sh` — the `claude auth login`
  advice, the settings merge's `[]`/symlink/mode/`.tmp` fixes, the `core.fileMode` probe; (2) `window-title.sh`
  and `session-title.sh` — `info/exclude` failure, `#44` lock line, the same merge fixes, the header line on
  JSONC, mode 100755, the newline-safe stdin read, the hook-shape rule from Q1, the guarded hook command in
  `.claude/settings.json`; (3) `devcontainer.json` and the Dockerfile — the git volume from Q2; (4) tests and
  changelog. All thirteen criteria sit in the same four scripts and two config files, and every one is proved
  by `bash tests/run.sh devcontainer`; a reviewer reads one diff of roughly 150 changed lines.
- *Two PRs:* this one keeps the hardening and the hook fixes; the git-identity volume and the lock-following
  titles become a new issue. Two workflows, two containers, two reviews for work that touches the same test
  file and the same scripts.
- *Three PRs, one per source issue (#44 fixes, #45 fixes, volume):* cleanest history, most overhead; the #44
  and #45 fixes edit the same `window-title.sh`, so the second PR would rebase over the first.

**Answer:**

## Notes

Decisions this plan makes without asking, stated so they can be rejected:

- The `claude auth login` TODO and its `need_login` entry are skipped when `CLAUDE_CODE_OAUTH_TOKEN` or
  `ANTHROPIC_API_KEY` is set — the two credential variables criterion 1 names. `ANTHROPIC_BASE_URL` alone
  does not change `authMethod`, so it keeps only its own "unset it" TODO.
- The settings-merge fix is the same in both scripts and stays self-contained in each (the test harness
  copies the scripts into scratch repos one by one): resolve the target through `readlink -f` so a symlink
  is written through, not replaced; `jq` into a `mktemp` beside the target; a non-object result (`[]`) is
  "not a JSON object", a parse failure "not valid JSON"; copy the original's mode onto the temp file
  (`chmod --reference`), or `0644` when there was no original; `mv`, and on any failure remove the temp
  file before reporting.
- `core.fileMode`: the start script probes the clone (a temp file under `.git`, `chmod +x`, test `-x`) and
  sets `core.fileMode true` on the clone when the bit sticks, saying so; it leaves a filesystem that drops
  the bit alone with a TODO. A new suite case pins mode `100755` in the index for every
  `.devcontainer/scripts/*.sh`, which covers criterion 6 and any script added later.
- The guarded hook command in `.claude/settings.json` becomes
  `f="${CLAUDE_PROJECT_DIR}/.devcontainer/scripts/session-title.sh"; [ -f "$f" ] && bash "$f" || true`;
  the test extracts the command with `jq`, runs it with `bash -c` in a scratch repo without the script, and
  wants exit 0 and no output (criterion 8).
- `session-title.sh` reads its three stdin fields NUL-separated (`jq -j … join("\u0000")` into
  `read -r -d ''`), so a `session_title` beginning with a newline stays a non-empty title (criterion 9); the
  "one line" assertion counts with `grep -c ''`; the registration test compares objects, not key order.
- The #45 changelog line is reworded from "every Claude Code session is titled" to "a session without a
  title is titled" — the qc:45 F2 wording.
- `inflight.sh --except 47`: no other workflow in flight, so the draft footprint overlaps nothing.
- The `engineering` plugin (`system-design`, `architecture`) is not installed here; its Options Considered
  structure is applied directly in the plan's table, as the #44 and #45 plans did.

## Outcome

_Pending — written at the hand-off._

## Log

- 2026-11-09 — Q1-Q3 raised · cost: 5m · fable-5-1 78k in + 487k cached / 19k out
