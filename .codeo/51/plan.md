# Issue #51 — plan

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/51 |
| Branch | `feat/seed-dev-container-git-identity` |
| Updated | 2026-11-14 |

## Where this stands

Explored the start script, its tests, the container config and the two other workflows in flight.
The change itself is small: step 5 of `.devcontainer/scripts/devcontainer-start.sh`, new cases in
`tests/devcontainer.test.sh`, a paragraph in `.devcontainer/README.md` and a changelog line.
Q1-Q3 are answered (wait for the file; a last task the engineer runs; #69 already merged as #72, so
no overlap). The plan was approved and written to `docs/plans/2026-11-14-seed-dev-container-git-identity.md`
(left unstaged for your review). Nothing is open; the next step is `/codeo:implement`.

## Questions

### Q1 — The host `~/.gitconfig` can arrive after the start script looks for it. What should step 5 do about that?

**Why it matters:** in this container (`codeo-51`, created today) the container started at
18:39:50, the start script took the lock at 18:40:03.1 and wrote the window title at 18:40:03.5,
and VS Code created `/home/dev/.gitconfig` at 18:40:04.4. So the copy runs alongside
`postCreateCommand`, not before it, and step 5 comes only a `gh auth status` call after the title
step. If step 5 reads the file once and it is not there yet, a fresh volume gets the TODO although
the host has an identity, which is the case the issue exists to remove. The suite cannot show this:
its cases put the file in place before the script runs. The answer decides whether step 5 stays a
few lines in the start script, gains a wait, or becomes its own script that other hooks also run.
**Options:**
- **A — wait briefly for the file (recommended).** When a value is still missing and
  `~/.gitconfig` does not exist, step 5 checks for it once a second for up to 10 seconds, then
  carries on. No wait at all when the volume already has both values (every container after the
  first) or when the file is already there. A container with no host file pays the 10 seconds
  once, at creation. The limit is a variable (`CODEO_GITCONFIG_WAIT`) so the tests set it to 0.
  Only this option makes the first start fill the identity without a second step.
- **B — seed again on later starts.** Seeding moves into its own script
  (`.devcontainer/scripts/git-identity.sh`), run by the start script and by `postStartCommand`,
  as `window-title.sh` is. No wait, but a lost race still prints the TODO on the first start and is
  only repaired at the next container start (or when the start script is re-run).
- **C — A and B together.**
- **D — read once, and let the TODO say to re-run the start script.** Smallest change; the race
  decides whether the first start works.

**Answer:**
A — wait briefly for the file (answered in the conversation).

### Q2 — Should the plan end with a check you run in a real container?

**Why it matters:** `tests/devcontainer.test.sh` runs the start script against a scratch home and
stub tools, which proves all five behaviours in the acceptance criteria but not Q1's timing, and
not that VS Code writes the file where the script reads it. Proving that needs a container created
on a `codeo-git` volume without an identity. That is yours to do: the volume is shared by every
container and holds your identity now, so the check means unsetting `user.name` and `user.email`
in it (or using a throwaway volume), creating a container from this branch and reading what the
start script prints. The answer adds a last task that prints the commands, stops and waits for
your output (the form #67's plan used), or leaves the suite as the whole proof.
**Options:** a last task you run, whose output `/codeo:qc` reads as evidence (recommended) · the
suite only.

**Answer:**
A last task you run, whose output `/codeo:qc` reads as evidence (recommendation accepted, answered in the conversation).

### Q3 — This plan and #69 both change `CHANGELOG.md` and `.devcontainer/README.md`. How should they be ordered?

**Why it matters:** #69 (branch `feat/fix-closing-blocks-that-name`, assignee kbajpai, step
`close`, pull request open) changes `CHANGELOG.md` and `.devcontainer/README.md`. This plan adds a
bullet under `CHANGELOG.md`'s *Unreleased* and a paragraph to `.devcontainer/README.md`'s *What the
start script does*. Both are additions in places #69 is also likely to have added to, so whichever
merges second resolves a small conflict. The answer decides whether the plan carries a
`sequenced:` line and waits for #69, or goes ahead.
**Options:**
- **proceed and coordinate (recommended)** — #69 is already at its pull request; this branch
  merges `main` once #69 lands and keeps both additions.
- **sequence after #69** — `/codeo:implement` does not start until #69 is merged.
- **re-scope** — leave `.devcontainer/README.md` out of this plan (`CHANGELOG.md` cannot be left
  out: the acceptance criteria require it).

**Answer:**
Proceed and coordinate (recommendation accepted), with a correction: #69 is done. It merged as #72
(`2a86915`, 2026-11-14 18:40), so there is nothing left to coordinate with; this branch merges
`origin/main` first and no `sequenced:` line is written.

## Notes

**What is there today.** Step 5 (`devcontainer-start.sh` lines 241-245) reads `git config
user.email` and `user.name` and adds one TODO when either is empty. `devcontainer.json` sets
`GIT_CONFIG_GLOBAL=/home/dev/.config/git/config` on the `codeo-git` volume, so `git config
--global` reads and writes the volume file. VS Code writes the host's config to `$HOME/.gitconfig`
as a plain file regardless of `GIT_CONFIG_GLOBAL` (seen here: it holds `user.name`, `user.email`,
`safe.directory` and the `filter.lfs.*` keys). `devcontainer.json` carries no `localEnv`, and a
test forbids it, so `GIT_AUTHOR_NAME` / `GIT_AUTHOR_EMAIL` reach the container only when the
engineer's own tooling sets them.

**The tests.** `ds_run` already gives each case its own `HOME` (`$ds_dir/home`) and its own global
config file (`$ds_dir/gitconfig`), so a case writes `$ds_dir/home/.gitconfig` for the host file and
passes `GIT_AUTHOR_*` through `DS_SET` or the environment. `ds_run` does not clear `GIT_AUTHOR_*`
today; it has to, or a developer's own environment would change the results. Two existing cases
assert the identity TODO (`start_todo_when_nothing_is_set_up`,
`start_identity_todo_when_only_one_is_set`) and keep passing as long as the TODO still contains
"git identity".

**Other workflows.** #69 overlaps (Q3). #52 (`feat/run-codeo-latest-claude-models`) is only at
`init`: it has no footprint yet and its branch has changed nothing, so there is nothing to compare,
which is not the same as knowing it will not touch these files.

**Calls I am making, stated so they can be corrected:**

- A value is "missing" when `git config --global --get` returns nothing or an empty string. A
  source "has" a value only when it is non-empty.
- The host file is read with `git config --file "$HOME/.gitconfig" --get user.name` (and
  `user.email`), which reads those two keys and nothing else and does not follow `[include]`
  lines, since an include path from the host would not resolve in the container.
- Each fill is reported on stdout, naming the key and the source but not the value:
  `devcontainer-start: git identity: user.name set from ~/.gitconfig`.
- The TODO keeps the words "git identity", names which of `user.name` / `user.email` is still
  missing and lists the sources tried (`~/.gitconfig`, then `GIT_AUTHOR_NAME` /
  `GIT_AUTHOR_EMAIL`), and still ends with the `git config --global` commands to run.
- The TODO still fires on the effective identity (as today, a repository-level identity counts),
  while seeding looks only at the volume file.
- One pull request. The output is a plan under `docs/plans/`, with no separate reference doc: no
  technology or architecture choice is being made. The documentation page that moves is
  `.devcontainer/README.md` (*What the start script does*).
- No overlay text exists for `plan-shape`, `proof-of-done` or `wiki-rules`, so the generic shapes
  apply. The `shell` suite has no `filter`, so each task's proof is `bash tests/run.sh`, with
  `bash tests/devcontainer.test.sh` as the quick loop.
## Outcome

Plan: `docs/plans/2026-11-14-seed-dev-container-git-identity.md`, a scoped, executable plan (step 5
shape: no standing decision, so no reference doc under `docs/`). Left unstaged for review.

**Decisions.**
- Step 5 of `devcontainer-start.sh` fills each of `user.name` / `user.email` on its own, only when
  the volume file lacks it, from `~/.gitconfig` first and then `GIT_AUTHOR_*`; empty or malformed
  sources count as no value; a seeded value is never printed.
- Q1 = A: it waits up to `CODEO_GITCONFIG_WAIT` seconds (default 10) for VS Code's copy of the host
  file, only when a value is missing and the file is absent. Rejected: seeding again on later starts
  through its own script (B, C) and a single read with a re-run hint (D). The wait is needed because
  in this container the copy landed about a second after `postCreateCommand` began.
- Q2: the last task is the engineer's, run in a real container; `/codeo:qc` reads the pasted output.
- Q3: no overlap. #69 merged as #72, so the branch merges `origin/main` first and no `sequenced:` is
  written; `overlap.sh 51` printed nothing. #52 is at `init` with no footprint yet.
- Tasks: 1 hermetic harness, 2 seed cases and code, 3 the wait, 4 documentation, 5 the engineer's check.

**Documentation the plan changes:** `.devcontainer/README.md` (*What the start script does*) and
`CHANGELOG.md` (*Unreleased*); no wiki module; no page under `docs/` describes this step.

**Intake questions resolved here:** none; intake left none open.

### Footprint

```
files:      .devcontainer/scripts/devcontainer-start.sh, tests/devcontainer.test.sh, .devcontainer/README.md, CHANGELOG.md, docs/plans/2026-11-14-seed-dev-container-git-identity.md
wiki:       none
exclusive:  none
```

## Log

- 2026-11-14 — Q1-Q3 raised · cost: 2m · fable-5-2 91k in + 400k cached / 5k out
- 2026-11-14 — Q1-Q3 answered; draft written to .codeo/51/plan-draft.md for review · cost: unavailable until the hand-off
- 2026-11-14 — planned: docs/plans/2026-11-14-seed-dev-container-git-identity.md · cost: 17m · fable-5-2 101k in + 760k cached / 12k out · sonnet-5-5 126k in + 1.5M cached / 21k out
