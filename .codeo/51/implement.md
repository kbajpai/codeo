# Issue #51 — implement

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/51 |
| Branch | `feat/seed-dev-container-git-identity` |
| Updated | 2026-11-14 |

## Where this stands

Plan tasks 1-5 are done and committed (`8937dbc`, `e7e58f1`, `4c61919`, `6d79619`), and the whole `shell`
suite passes (`bash tests/run.sh`: `all cases passed`). Q1 is answered: part 1 of the real-container check
passed and part 2 was skipped. Nothing is open; the next step is `/codeo:qc`.

## Questions

### Q1 — What do the Task 5 checks print in a real container?

**Why it matters:** the suite proves the lookup order and the wait against stubs, not that VS Code's copy
of `~/.gitconfig` lands in time in a real container. If the container log shows the identity TODO although
the host has an identity, Task 3's wait is too short or the copy lands later than the script runs, and the
plan goes back to Task 3 (a re-plan, not a guess here). `/codeo:qc` reads your answer as the evidence for
the first acceptance criterion in a real container. The checks remove and restore your identity in the
shared `codeo-git` volume.

Run these in this container's terminal, one command at a time:

```
git config --global --unset user.name
git config --global --unset user.email
bash .devcontainer/scripts/devcontainer-start.sh
git config --global user.name
git config --file /home/dev/.gitconfig user.name
```

Expected: the script prints `devcontainer-start: git identity: user.name set from ~/.gitconfig` and the
same for `user.email`, with no `git identity` TODO; the last two commands print the same name.

Then unset both values again as above, run **Dev Containers: Rebuild Container** in VS Code, and when it
has started run **Dev Containers: Show Container Log**, and `git config --global user.email` in the new terminal.

Expected: the log holds both `git identity: ... set from ~/.gitconfig` lines and no `git identity` TODO;
the email printed is the host's. Paste the output of both parts, or say "skip" to leave the real-container
proof to review.

**Answer:**
Part 1 passed. Pasted by the engineer (answered in the conversation):

```
devcontainer-start: git identity: user.name set from ~/.gitconfig
devcontainer-start: git identity: user.email set from ~/.gitconfig
devcontainer-start: ready
$ git config --global user.name        -> Kunal Bajpai
$ git config --file /home/dev/.gitconfig user.name   -> Kunal Bajpai
```

Part 2 (rebuild the container with an empty identity) skipped, by the engineer's choice. The first-start
timing is therefore evidenced only by the stubbed wait cases and by this container's observed timing
(VS Code's copy appeared about a second after the start script began, within the 10-second wait).

## Notes

**Rulings** (deviations from the plan, and why):

- `sync-main.sh` merged `origin/main` (1 commit, #72) but exited 1 with `comm: file 2 is not in sorted
  order` while listing what else changed on main. The merge is committed (`d394c97`). The #72 files that
  matter here are `CHANGELOG.md` and `.devcontainer/README.md` and both merged without conflict; no work
  of this branch touches the other files of #72. The `comm` complaint is the script's own listing on this
  image's coreutils (Rust `comm`), not a merge failure; it is outside this plan, so not filed here.
- The plan's Task 2 said `start_copies_nothing_but_the_identity` would pass before the code. It failed
  red too, because with no seeding the volume file lacked `user.name` and `user.email`, which that case
  expects. It is a guard that passes once seeding exists, and does.
- The plan has `bash tests/run.sh` at the end of every task; it takes over two minutes here, so it was
  run after Task 1 and after Task 4, with `bash tests/devcontainer.test.sh` as the loop in between, and
  `shellcheck` on the start script. Both full runs passed.
- The plan's final step says "a single review of the whole branch"; this session ran the tasks itself and
  did not dispatch a fresh reviewer. The independent code review is `/codeo:qc`'s step.
- Code detail the plan left open: the loop's variable for the source label is `from`, not `source`
  (a bash builtin), and carries `# shellcheck disable=SC2088` because `'~/.gitconfig'` is a label.

## Outcome

Built from `docs/plans/2026-11-14-seed-dev-container-git-identity.md`, tasks 1-5.

- **Task 1** (`8937dbc`): `ds_run` in `tests/devcontainer.test.sh` unsets `GIT_AUTHOR_*`, passes `DS_AUTHOR_NAME` / `DS_AUTHOR_EMAIL` through, and sets `CODEO_GITCONFIG_WAIT` from `DS_GITCONFIG_WAIT` (default 0). `origin/main` (#72) was merged first by `sync-main.sh` (`d394c97`).
- **Task 2** (`e7e58f1`): step 5 of `.devcontainer/scripts/devcontainer-start.sh` fills each missing key from the host `~/.gitconfig`, then `GIT_AUTHOR_*`; the TODO names the missing keys and the sources tried. Eight cases cover criteria 1-5, the copy-nothing-else guard, an empty host value and a malformed host file.
- **Task 3** (`4c61919`): the wait for the host file, up to `CODEO_GITCONFIG_WAIT` seconds (default 10), only while a value is missing and the file is absent; two cases.
- **Task 4** (`6d79619`): `.devcontainer/README.md` (*What the start script does*), `CHANGELOG.md` (*Unreleased*) and the test file's header comment.
- **Task 5**: part 1 passed in this container; part 2 (rebuild) skipped by the engineer, see Q1.

**Documentation pages changed:** `.devcontainer/README.md` and `CHANGELOG.md`.
**Build result:** the `shell` suite's `build` is `true`; `bash tests/run.sh` passed (`all cases passed`) after Task 1 and after Task 4, and `shellcheck` is clean on the start script.
**Deviations from the plan:** the four rulings under `## Notes`, plus the skipped Task 5 part 2.
**Deployed revision:** none; there is no shared environment.

## Log

- 2026-11-14 — tasks 1-4 built; Q1 raised (Task 5, the engineer's real-container check) · cost: 8m · sonnet-5-5 36k in + 3.4M cached / 13k out
- 2026-11-14 — Q1 answered (part 1 passed, part 2 skipped); outcome written · cost: 13m · sonnet-5-5 39k in + 4M cached / 17k out
