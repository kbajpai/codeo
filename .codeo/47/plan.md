# Issue #47 — plan

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/47 |
| Branch | `fix/harden-dev-container-scripts-session` |
| Updated | 2026-11-09 |

## Where this stands

Round 4, after a send-back from `/codeo:qc` round 3 (F16 blocking, F17-F23 non-blocking). F16 and F17 are
settled: `qc.md` Q1 and Q2 decided how the start script must change (restore only the `100755`-in-index direction
and name the files; run step 2b only on a clone on a Docker named volume). One thing needs a decision before the
round is drafted: Q6, which of the minor findings F18-F23 and the two deferred minors from `implement.md` round 3
this round folds in. Nothing is drafted past Q6.

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
The prompt hook owns both titles (the recommendation; answered in the conversation, 2026-11-09).

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
Volume `codeo-git` at `/home/dev/.config/git` (the recommendation, read as including
`containerEnv.GIT_CONFIG_GLOBAL=/home/dev/.config/git/config`; answered in the conversation, 2026-11-09).

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
One PR (the recommendation; answered in the conversation, 2026-11-09).

### Q4 — What should the start script do when it finds `core.fileMode=false`?

**Why it matters:** this is the second send-back on the same point (`qc.md` round 1 F1, round 2 F8), and
both fixes so far were probes of a *fresh* file, which say nothing about the files already checked out. A clone
has `core.fileMode=false` precisely when git could not trust the modes at clone time, so its tracked scripts
usually sit on disk without the executable bit while the index says `100755`. Round 2's probe passes on such a
tree (the filesystem honours the bit), flips the setting on, and `git status` at once shows every such script as
` M … mode change 100755 => 100644` — reproduced by `qc` in a scratch repo. Criterion 11 ("a script added in a
fresh container is staged with mode 100755 without `git update-index --chmod`") is only met with the setting
on, so what the script does next decides whether the criterion is met by the script or handed to you as a TODO.

**Options:**
- *Flip, then restore the index's modes (my recommendation):* after the two-way probe and
  `git config core.fileMode true`, read `git diff --summary` for `mode change` lines and `chmod` each listed
  file back to the mode the index records (`+x` for `100755`, `-x` for `100644`) — exactly what `git checkout`
  would have written had the setting been on; then confirm `git status --porcelain` lists no mode-only change.
  If any `chmod` fails, set the setting back to `false` and add a TODO naming the files. Pro: criterion 11 holds
  on every filesystem that honours the bit, and the tree is clean; a start script that already `chown -R`s the
  clone is in character touching modes. Con: it writes to tracked files' modes — only the ones that differ from
  the index, which with the setting off could neither be seen nor staged, so nothing of yours is lost.
- *Flip only when the tree is already clean:* flip, check `git diff --summary`; any `mode change` means set it
  back to `false` and a TODO listing the files and the two commands (the `chmod`s, then
  `git config core.fileMode true`). Pro: never touches a file. Con: in the realistic case the flip is undone
  every time and criterion 11 is met only after you run the TODO by hand.
- *Never flip:* a TODO naming the setting and the suite's `scripts_are_committed_executable` as the guard.
  Pro: simplest, no probe at all. Con: criterion 11 is met only where the clone already has the setting on —
  true for this container (`clone` on the `codeo-47` volume), false for whatever produced the `#45` container's
  clone, which is the case the criterion was written for.

**Answer:**
Accepted the recommendation (answered in the conversation, 2026-11-09): flip, then restore the index's modes.

### Q5 — `GIT_CONFIG_GLOBAL` makes git ignore `~/.gitconfig`: document it, or guard against what VS Code writes there?

**Why it matters:** `qc` round 2 F9. VS Code Dev Containers copies the host's `~/.gitconfig` into the container
and injects a credential helper that names a per-container path (`/tmp/vscode-remote-containers-<id>.js`).
With `GIT_CONFIG_GLOBAL` pointing into the shared `codeo-git` volume, the copy is ignored (host aliases and
signing settings stop applying), and if VS Code's injection uses `git config --global` it lands in the shared
file, where every other container would find a helper whose script does not exist. In this container the helper
sits in `/etc/gitconfig` too, so `gh`'s helper still serves GitHub either way; the expected harm is a stderr
message per credential call, not a failure. Neither the reviewer nor I could confirm what VS Code writes
without rebuilding.

**Options:**
- *Document, verify by hand after the rebuild, file a follow-up if it bites (my recommendation):* the changelog
  says the host `~/.gitconfig` no longer applies inside the container; the manual check after the rebuild reads
  `/home/dev/.config/git/config` and notes whether a VS Code helper landed there. Pro: no code written against an
  unverified behaviour. Con: a second container may print helper errors until the follow-up lands.
- *Document and prune:* the start script also removes any `credential.helper` whose value names a
  `/tmp/vscode-remote-containers-*.js` that does not exist on this machine. Pro: self-healing. Con: code (and a
  test with a fake stale helper) for a behaviour we have not seen.
- *Switch mechanisms:* drop `GIT_CONFIG_GLOBAL`; the start script writes `[include] path = ~/.config/git/config`
  into `~/.gitconfig` and the identity TODO says `git config --file ~/.config/git/config …`. Pro: the host copy
  and VS Code's helper keep working. Con: reopens plan Q2, an awkward TODO, and `safe.directory` and `gh`'s
  helper are per-container again.

**Answer:**
Accepted the recommendation (answered in the conversation, 2026-11-09): document it in the changelog, verify by
hand after the rebuild, file a follow-up if it bites.

### Q6 — Which of the round 3 minors (F18-F23, and the two deferred in `implement.md`) does round 4 fold in?

**Why it matters:** `qc.md` round 3 left it to you ("the engineer can say which"). Each one folded in is a task
with a test and a review; each one left stays recorded in `qc.md` as debt. The round already changes
`devcontainer-start.sh` step 2b (F16, F17), `tests/devcontainer.test.sh` and the `CHANGELOG.md` #47 line, so
anything that sits in those lines is nearly free; the two in `session-title.sh` are the only ones that open another
file. The findings: **F18** a forked or resumed session (new id) inherits `codeo [#N] · <old sid8>`, which the
own-title rule reads as a `/rename`, so it never follows the lock again and shows another session's id; **F19** the
rule does not compare the codename, so a `/rename` shaped `x [home] · <sid8>` is replaced; **F20** `issue: 44abc`
→ `[#44]` (deliberate, round 3); **F21** the settings merges keep the mode but not the owner or hard links (`mv`
swaps the inode); **F22** a non-regular `~/.claude/settings.json` (a directory, or a link to one) is skipped with no
TODO; **F23** the probe file and `git config` target the common git dir, wrong for a linked worktree on another
filesystem; plus, from `implement.md`: the second `git diff` listing in `restore_modes` reads a failure as empty
(`2>/dev/null`, no exit check), and the changelog line is missing a comma before "and writes through a symlink".

**Options:**
- *Fold in what the round already touches, plus the two title-rule fixes (my recommendation):* F18 and F19 as
  one task — the own-title rule becomes "no newline, exactly `<codename> [home|#digits] · <8 hex>`" (any session id
  in the suffix, so a fork inherits a title it may replace; the codename compared, so a rename of that shape is
  kept); F22 as one small task (an `add_todo` naming the file plus a test); the `git diff` exit check and the
  changelog comma inside the F16 and changelog tasks. Leave F20 (deliberate), F21 (preserving the inode means
  giving up the atomic `mv`, and `settings.json` owned by another user is not a case this container has) and F23
  (not this layout; a worktree-aware probe is a different feature). Pro: closes everything a user of this container
  could meet, in two extra small tasks. Con: round 4 edits `session-title.sh`, a third script.
- *Fold in only what the round already touches:* F16, F17, the `git diff` exit check and the comma; leave
  F18-F23 recorded. Pro: smallest round, two scripts. Con: a forked session keeps a stale title until someone files it.
- *Fold in all of F18-F23:* also F20 (tighten the lock parse to `intake.sh`'s form), F21 (write in place with
  `cat >` after a successful `jq` to a temp, losing atomicity) and F23 (probe in `git rev-parse --git-common-dir`
  vs the worktree). Pro: nothing left. Con: F20 reverses a round 3 decision, F21 trades atomicity for an edge case,
  F23 adds code for a layout this repository does not use.

**Answer:**
Accepted the recommendation (answered in the conversation, 2026-11-09): fold in F18+F19, F22, the `git diff` exit
check and the changelog comma; leave F20, F21 and F23 recorded.

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

### Footprint

```
files:      .devcontainer/scripts/devcontainer-start.sh, .devcontainer/scripts/session-title.sh, tests/devcontainer.test.sh, CHANGELOG.md, docs/plans/2026-11-09-dev-container-hardening.md
wiki:       none
exclusive:  none
sequenced:  none
```

## Outcome

**Plan:** `docs/plans/2026-11-09-dev-container-hardening.md` — approved 2026-11-09, left unstaged for the
engineer to commit. Shape: an executable plan under `docs/plans/` (ten TDD tasks, one commit each); no
reference doc, because no standing architectural decision outlives the work.

**Decisions** (Q1-Q3 answered in the conversation, recorded above):
- *Q1:* `session-title.sh` owns both titles. On every prompt it refreshes the window title through
  `window-title.sh` (a no-op when current) and replaces a session title it set itself — one ending in
  ` · <first eight of this session's id>` — when the lock changed; any other title (`/rename`) is kept.
  Rejected: window only; a `PostToolUse` hook; hooking `lock.sh` and `close` in the plugin core.
- *Q2:* volume `codeo-git` at `/home/dev/.config/git` with `containerEnv.GIT_CONFIG_GLOBAL` pointing at its
  `config`, so every `--global` write lands in the volume. Rejected: the volume alone (depends on whether
  `~/.gitconfig` exists first); an `include.path` volume.
- *Q3:* one PR. Rejected: two or three PRs.
- Without asking: the `claude auth login` check is skipped while `ANTHROPIC_API_KEY` or
  `CLAUDE_CODE_OAUTH_TOKEN` is set; the settings-merge code is duplicated in the two scripts, not shared;
  `core.fileMode` is probed and set by the start script and every `.devcontainer/scripts/*.sh` is pinned to
  mode 100755 by a suite case; the hook command is guarded in `.claude/settings.json`.

**Documentation moved:** `CHANGELOG.md` only (Task 10; rewords the #45 line and adds a #47 entry saying the
container must be rebuilt once for the volume). No page under `docs/` describes the dev container; no wiki.

**Intake questions resolved:** the one open at intake — how a running session is retitled — is Q1.

**Manual checks for the engineer** (named at the end of the plan, to go in `qc.md`): the identity survives a
rebuild and a second container; session and window titles follow `/codeo:init` and `/codeo:close`; a
`/rename` is kept. If Claude Code does not apply a `sessionTitle` to a session that already has one, that is
a send-back to this plan.

`overlap.sh 47` printed nothing; no exclusive resource is configured, so no lock was taken.

### Round 2

2026-11-09
(send-back from qc.md round 1)

**Plan:** `docs/plans/2026-11-09-dev-container-hardening.md`, `## Round 2` (Tasks 11-15), appended to the same
plan so the issue keeps one plan; approved 2026-11-09, left unstaged for the engineer to commit. Tasks 1-10 stand.
No question was raised: `qc.md` round 1 dictates every fix.

**What it answers.** F1 (blocking, the plan's): the `core.fileMode` probe only checked that `chmod u+x` made a
file executable, so a filesystem that reports every file as executable (a host checkout bind-mounted into the
container) passed it and `core.fileMode` was switched on, showing every tracked file as a mode change. The
probe now needs the bit to set *and* clear (Task 11). F2-F7, all non-blocking, are folded in rather than filed:
`safe.directory` added once (Task 12); the hook retitles only a title of its own shape, no newline and
`… [home|#N] · <sid8>` (Task 13); the lock line read like `intake.sh` does, and a read-only `info/exclude` leg
(Task 14); changelog wording for #45, #44 and #47, and a credential test that checks what it says (Task 15).

**Decisions without asking:** F3 takes the stricter shape rule, not just "reject newlines", so a rename that
happens to end in the session id is also kept; `git_global_writes_land_in_the_volume_file` stays, with a comment
that it pins the premise the volume design rests on; the `SC2016` info note on the test file's hook-command string
is left (it is on `main`).

**Documentation moved:** `CHANGELOG.md` only (Task 15); no page under `docs/`, no wiki module.

`overlap.sh 47` and `overlap.sh --outside 47` printed nothing; no exclusive resource, so no lock was taken.

### Round 3

2026-11-09
(send-back from qc.md round 2)

**Plan:** `docs/plans/2026-11-09-dev-container-hardening.md`, `## Round 3` (Tasks 16-20), appended to the same
plan so the issue keeps one plan; approved 2026-11-09, left unstaged for the engineer to commit. Tasks 1-15 stand.

**What it answers.** F8 (blocking, the plan's; Q4): the start script turned `core.fileMode` on over a tree whose
tracked scripts were `644` on disk but `100755` in the index, so `git status` showed every one as a mode change.
Round 2's probe tested a fresh file, which says nothing about the files already there. Task 16 keeps the probe,
then restores each tracked file's mode to the index's *before* setting `core.fileMode true`, and sets it only when
a second listing is empty; otherwise it stays `false` with one TODO naming the files left. F11 and F13 (Task 17):
a settings file holding `false`, `null` or several top-level values is classified correctly and left alone, and a
failed `readlink -f` gets its own TODO. F12 and F14 (Task 18): `window-title.sh` prints exactly one line per
failure and accepts a TAB after `issue:`. F15 (Task 19): three tests now pin what they claim. F9 and F10 (Task 20):
the changelog says the number is read from the lock, that tracked modes are restored, and that the host
`~/.gitconfig` no longer applies (Q5: documented, verified by hand after the rebuild, a follow-up only if it bites).

**Decisions without asking:** F14 keeps taking the leading digits of the lock line (looser than `intake.sh`, on
purpose: a title is cosmetic) and only the header sentence changes; the mode restore touches only entries whose old
and new modes are both `100644` or `100755`, so symlinks and submodules are left alone.

**Documentation moved:** `CHANGELOG.md` only (Task 20); no page under `docs/`, no wiki module.

**Manual checks for the engineer:** a clone with `core.fileMode false` and `644` scripts ends `true`, executable,
`git status` clean; with a `chmod`-protected file it stays `false` with a TODO; after the rebuild, read
`/home/dev/.config/git/config` for a VS Code credential helper naming `/tmp/vscode-remote-containers-*.js`.

`overlap.sh 47` printed nothing; no exclusive resource, so no lock was taken.

### Footprint

```
files:      .devcontainer/scripts/devcontainer-start.sh, .devcontainer/scripts/window-title.sh, tests/devcontainer.test.sh, CHANGELOG.md, docs/plans/2026-11-09-dev-container-hardening.md
wiki:       none
exclusive:  none
sequenced:  none
```

## Log

- 2026-11-09 — Q1-Q3 raised · cost: 5m · fable-5-1 78k in + 487k cached / 19k out
- 2026-11-09 — planned: docs/plans/2026-11-09-dev-container-hardening.md · cost: 134m · fable-5-1 97k in + 1.1M cached / 25k out · sonnet-5-5 169k in + 900k cached / 36k out · `engineering` plugin unavailable, its structure applied directly
- 2026-11-09 — planned (round 2, send-back from qc.md round 1): docs/plans/2026-11-09-dev-container-hardening.md · cost: 37m · fable-5-1 354k in + 1.5M cached / 13k out · sonnet-5-5 28k in + 737k cached / 2k out · `engineering` plugin unavailable, its structure applied directly
- 2026-11-09 — Q4-Q5 raised (round 3, send-back from qc.md round 2) · cost: 1m · fable-5-1 478k in + 525k cached / 7k out
- 2026-11-09 — planned (round 3, send-back from qc.md round 2): docs/plans/2026-11-09-dev-container-hardening.md · cost: 71m · fable-5-1 481k in + 1.5M cached / 9k out · sonnet-5-5 112k in + 2.3M cached / 9k out · `engineering` plugin unavailable, its structure applied directly
- 2026-11-09 — Q6 raised (round 4, send-back from qc.md round 3) · cost: 1m · fable-5-1 231k in + 778k cached / 5k out
