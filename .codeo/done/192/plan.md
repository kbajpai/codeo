# Issue #192 — plan

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/192 |
| Branch | `feat/192-guard-home-checkout-no-project` |
| Updated | 2026-11-26 |

## Where this stands

Round 1, done. Q1-Q5 are answered and the plan is approved: `docs/plans/2026-11-26-home-checkout-edit-guard-192.md`, left unstaged for review. Next step: `/codeo:implement`.

## Questions

### Q1 — Which override: an environment variable, or a marker file under `.codeo/`?

**Why it matters:** it decides who can lift the guard and for how long, and how many files the change touches.

- `CODEO_HOME_EDITS=allow` in the environment. It is read from the environment Claude Code was started in, so it is set by starting the session with it (`CODEO_HOME_EDITS=allow claude`) or in `.claude/settings.local.json`'s `env`. It lasts exactly one session, the agent cannot set it for itself from inside the session, and it adds nothing to `.codeo/`. The cost: a session already running has to be restarted to lift the guard.
- A git-ignored marker, `.codeo/home-edits`. It can be created mid-session (`! touch .codeo/home-edits`). The cost: it outlives the session until someone deletes it, the hook has to refuse the agent's own writes to it (an Edit is easy to refuse, a Bash write cannot be caught reliably, so "the guard never overrides itself" becomes best-effort), and it needs a third line in `.codeo/.gitignore`, which `scripts/setup.sh` and `docs/dossier.md` then change and which every project already set up lacks.

I recommend the environment variable.

**Options:** environment variable (recommended) · marker file · no preference, you pick.

**Answer:**
Environment variable, as recommended. Given in the conversation: "go with your picks".

### Q2 — How does the plugin's hook find the project's role check?

**Why it matters:** `role.sh` is the project's file, not the plugin's (`.devcontainer/scripts/role.sh`; #190 has `/codeo:setup --containers` write it there for other projects). The hook is the plugin's and runs in every project, so it needs a rule for finding the check, and that rule is what "a project that does not use the home role is not affected" rests on.

- Fixed path: the hook runs `<project root>/.devcontainer/scripts/role.sh` when that file exists and does nothing when it does not. No config key, and it works at once here and in every project #190's templates set up. The cost: a project that wrote its own check at another path gets no edit guard.
- A config key, for example `guard.role` in `.codeo/config.json`, holding the command that prints the role. Any layout works. The cost: a new key to document and for `/codeo:doctor` to check, #190's templates would have to write it (their `.codeo/config.json` handling is outside this issue's footprint), and this repository needs it set too.
- Both: the key when set, else the fixed path.

I recommend the fixed path; a key can be added later without breaking it.

**Options:** fixed path (recommended) · config key · both · no preference, you pick.

**Answer:**
Fixed path, as recommended. Given in the conversation: "go with your picks".

### Q3 — Which Bash commands are refused: git writes only, or shell file writes too?

**Why it matters:** it sets the size of the hook and of its test, and how often it refuses something harmless. A hook sees the command as a string; it cannot run it to see what it changes.

- Git writes only, matched as words of the command: `git commit`, `git push`, `git checkout -b`/`-B`, `git switch -c`/`-C`, and `merge`, `rebase`, `cherry-pick`, `revert`, `am`, `apply`, `reset`, `stash`, `tag`, `add`, `rm`, `mv`, `restore`. Not caught: a file changed through the shell (`sed -i`, `>` redirection, `rm`, `mv`, `cp`). Such a change sits uncommitted in home, because the commit and the push that would carry it anywhere are refused, and the Edit and Write tools are refused outright.
- Shell file writes as well, by pattern (`sed -i`, `tee`, redirection to a path in the project, `rm`, `mv`, `cp`). It closes more of the gap but never all of it (`python -c`, a script), and it refuses harmless commands such as a redirect to a scratch file whose path the pattern misreads.

Either way these stay allowed, because `/codeo:init` runs them in home (see `## Notes`): `git worktree add`/`remove`, `git branch -D`, `git fetch`, `git pull --ff-only`, a `git commit` whose staged paths are all under `.codeo/`, and anything run as a script (`bash …/claim.sh`, `intake.sh`).

I recommend git writes only.

**Options:** git writes only (recommended) · git writes and shell file writes · no preference, you pick.

**Answer:**
Git writes only, as recommended. Given in the conversation: "go with your picks".

### Q4 — #190 is in flight and touches files this plan will change. Proceed, sequence, or re-scope?

**Why it matters:** #190 (branch `docs/190-make-container-sandbox-setup-reusable`, assignee kbajpai, step qc, round 3 sent back to `/codeo:implement`) has changed `docs/home-checkout.md`, `README.md` and `CHANGELOG.md`, and its footprint lists `.devcontainer/**`. This plan adds a section to `docs/home-checkout.md`, a troubleshooting entry and a hook mention to `README.md`, a `CHANGELOG.md` entry, and a paragraph to `.devcontainer/README.md`. It changes no script under `.devcontainer/`. The edits are in different paragraphs, so a merge conflict is unlikely except in `CHANGELOG.md`'s unreleased block, but #190 rewrites *Adopting the guard in your project* in `docs/home-checkout.md` to say `role.sh` is shipped, and this plan's text about where the hook finds `role.sh` (Q2) should read correctly after that rewrite. Sequencing after #190 means writing against its text; proceeding means writing against today's and reconciling at whichever merges second.

- `docs/home-checkout.md`
- `README.md`
- `CHANGELOG.md`
- `glob:.devcontainer/**`

**Options:** proceed and coordinate (recommended: the code and tests do not overlap, and the docs differ by paragraph) · sequence after #190 · re-scope (leave the docs #190 touches to a follow-up issue).

**Answer:**
Proceed and coordinate, as recommended. Given in the conversation: "go with your picks".

### Q5 — The footprint check names #190's overlap in its own tokens: proceed and coordinate?

**Why it matters:** Q4 already put this to you in prose, and you chose *proceed and coordinate*, but `overlap.sh` only counts a pair as raised when a question quotes `#M` and its printed token, and Q4 wrote the paths bare. It now prints two lines for #190 (branch `docs/190-make-container-sandbox-setup-reusable`, assignee kbajpai, step qc, round 3 sent back to `/codeo:implement`): `glob:CHANGELOG.md` and `glob:docs/home-checkout.md`. Both are files this plan edits (a new `## Unreleased` bullet, a new `## The edit guard` section) and #190 has changed them too. Your answer decides whether the plan stays as drafted (proceed), is built after #190 merges (the footprint then says `sequenced: after #190`), or drops those two files (re-scope).

- #190 `glob:CHANGELOG.md`
- #190 `glob:docs/home-checkout.md`

**Options:** proceed and coordinate (recommended: Q4's answer, and the edits are in different places) · sequence after #190 · re-scope.

**Answer:**
Proceed and coordinate, as recommended. Given in the conversation: "go with your pick".

## Notes

**What was found.**

- `hooks/hooks.json` already carries one `PreToolUse` hook (`hooks/subagent-model.sh`, matcher `Agent|Task`). It is the pattern to follow: read the hook JSON on stdin, take the project from its `cwd`, print a `permissionDecision: "deny"` with a one-line reason, and stay silent to allow. `tests/subagent-model.test.sh` is the test pattern: scratch repositories, the hook fed the JSON a session would send.
- `role.sh [dir]` with no `--check` prints the role in one line, so the hook can be built on it without changing it or copying its logic. `tests/role.test.sh` shows how to make a scratch clone play each role (`CODEO_DOCKERENV`, the folder name, the lock file, `CLAUDE_CODE_REMOTE`).
- `/codeo:init` in home is not read-only. It runs `git worktree add --no-track <scratch> -b <branch> origin/<base>`, writes `.codeo/<N>/` in that scratch worktree, commits there, pushes through `claim.sh`, then `git worktree remove` and `git branch -D`. The scratch worktree is outside the repository and holds no lock, so `role.sh` calls it `stray`. The guard therefore cannot simply refuse every commit in a `stray` checkout: it allows a commit whose staged paths are all under `.codeo/`, and an Edit or Write of a path under `.codeo/` in any role. `/codeo:issue` and `/codeo:triage` write only under `.codeo/intake/` and commit through `intake.sh`.

**Calls made without asking; say so if any is wrong.**

- The guarded roles are the three the issue names: `home`, `stale:?` and `stray`. `stale:<N>` and `mismatch:…` (a container with no lock or the wrong folder) are left alone, as are `issue:<N>` and `unguarded`.
- The role is judged for the checkout that holds the file (for Edit, Write and NotebookEdit) or that the command addresses (the hook JSON's `cwd`, or the directory a `git -C <dir>` or a leading `cd <dir> &&` names), not for the session as a whole. A file outside any git repository (the scratchpad) is never refused.
- The hook fails open. A missing `role.sh`, a missing `jq`, a role check that exits non-zero, or a `cwd` outside a repository allows the call and prints nothing, as `hooks/live-signal.sh` does: a broken guard must not stop a session.
- The refusal is one line: the role, why, the three steps (`/codeo:issue`, `codeo issue <N>`, work there) and the override from Q1.
- No skill and no overlay changes, and `role.sh` is not changed.
- The guard takes effect in a project when its pinned plugin version carries the hook, so in this repository's own home checkout that is after the next release and pin bump, not at the merge. The plan says so in the changelog entry.
- Output shape: a plan under `docs/plans/`, with a new section in the existing reference doc `docs/home-checkout.md` as its documentation task. No separate reference doc.

## Outcome

| | |
|---|---|
| Plan | `docs/plans/2026-11-26-home-checkout-edit-guard-192.md` (unstaged, awaiting review and commit) |
| Shape | an executable plan under `docs/plans/`, four tasks; the documentation change is a new `## The edit guard` section of the existing `docs/home-checkout.md`, no separate reference doc |

**Decisions** (Q1-Q5 answered "go with your picks"):
- Override is `CODEO_HOME_EDITS=allow` in Claude Code's own environment (Q1). Rejected: a git-ignored `.codeo/` marker, which outlives the session, cannot be protected against the agent's own Bash writes, and needs a third line in every project's `.codeo/.gitignore`.
- The hook runs the checkout's own `.devcontainer/scripts/role.sh`, found at that fixed path; no such file means no guard (Q2). Rejected for now: a `.codeo/config.json` key, which can be added later without breaking this.
- Bash is guarded for git writes only, matched on segments that start with `git` (Q3). Rejected: pattern-matching shell file writes (`sed -i`, redirection), which never closes the gap and refuses harmless commands.
- #190 overlaps on `CHANGELOG.md` and `docs/home-checkout.md`: proceed and coordinate (Q4, Q5). Rejected: sequencing after #190, re-scoping.
- Guarded roles are `home`, `stale:?`, `stray`; the hook fails open on any error; `role.sh` and the skills are unchanged.
- `/codeo:init` runs in home by cutting its branch in a scratch worktree (role `stray`) and committing `.codeo/` there, so `.codeo/` paths, `git worktree`, `fetch`, `pull`, `branch`, plain `checkout`/`switch` and all scripts stay allowed, and `git add`/`commit` pass when every path is under `.codeo/`.

**Documentation pages the plan changes:** `docs/home-checkout.md` (new section with a Mermaid flowchart) and `CHANGELOG.md` (a new `## Unreleased` bullet). No wiki module.

**Intake questions resolved:** the override mechanism left open at intake (Q1).

**Reach:** the guard applies to a project once its pinned plugin carries the hook, so this repository's home checkout has it after the next release and pin bump.

### Footprint

```
files:      hooks/home-guard.sh, hooks/hooks.json, tests/home-guard.test.sh, docs/home-checkout.md, CHANGELOG.md, docs/plans/2026-11-26-home-checkout-edit-guard-192.md
wiki:       none
exclusive:  none
sequenced:  none
```

## Log

- 2026-11-26 — Q1-Q4 raised · cost: 2m · fable-5-2 95k in + 1.1M cached / 7k out
- 2026-11-26 — Q5 raised (overlap with #190, in the tokens `overlap.sh` reads) · cost: 31m · fable-5-2 104k in + 1.5M cached / 13k out · sonnet-5-5 139k in + 2M cached / 27k out
- 2026-11-26 — planned: docs/plans/2026-11-26-home-checkout-edit-guard-192.md · cost: 31m · fable-5-2 104k in + 1.5M cached / 13k out · sonnet-5-5 139k in + 2M cached / 27k out · the optional `engineering:system-design` and `engineering:architecture` skills were not listed, so their structure was applied directly
