# Issue new-seed-git-identity — issue

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/51 |
| Branch | none (intake) |
| Updated | 2026-11-09 |

## Where this stands

Drafting. Problem restated: since #47 the dev container points `GIT_CONFIG_GLOBAL` at the `codeo-git`
volume, so git ignores the host `~/.gitconfig` VS Code copies in. A fresh volume has no
`user.name`/`user.email` and `devcontainer-start.sh` step 5 only prints a TODO telling the engineer to
run `git config --global` by hand. The issue asks the start script to seed the identity on first start.
Q1-Q4 answered; the draft below awaits approval. Related: #47 (closed), #40 (open, dev container follow-ups) — checked, neither
covers seeding.

## Questions

### Q1 — Where should the identity be seeded from?

**Why it matters:** decides the sources the start script reads and the order it tries them.
**Options:** the host `~/.gitconfig` VS Code copies in (`user.name`/`user.email` only) · `GIT_AUTHOR_NAME`/`GIT_AUTHOR_EMAIL` from the container environment · both, host file first · both, environment first.

**Answer:**
Both sources, host `~/.gitconfig` first, then `GIT_AUTHOR_NAME` / `GIT_AUTHOR_EMAIL` (accepted recommendation: the host file is the engineer's deliberate, persistent identity; the environment variables are a fallback for containers with no host config).

### Q2 — May seeding ever overwrite a value already in the volume file?

**Why it matters:** "only fill what is missing" is safe on every re-run; overwriting would clobber an identity the engineer set on purpose.
**Options:** fill only a missing `user.name` / `user.email`, each on its own · fill only when both are missing · always overwrite.

**Answer:**
Fill only a missing `user.name` / `user.email`, each on its own.

### Q3 — When no source has an identity, what should happen?

**Why it matters:** keeps or changes today's behaviour (a TODO printed at the end of the start script).
**Options:** keep the TODO as it is · keep it but name the sources that were tried · fail the start script.

**Answer:**
Keep the TODO, but name the sources that were tried.

### Q4 — Is anything else in scope?

**Why it matters:** the same shared volume could also carry other host git settings (e.g. `init.defaultBranch`, `pull.rebase`), but that widens the issue.
**Options:** identity only (`user.name`, `user.email`) · identity plus a short list you name · copy the whole host `~/.gitconfig` except credential helpers.

**Answer:**
Identity only (`user.name`, `user.email`). Recommendation accepted by the engineer: copying more host settings risks dragging in host-specific values (credential helpers, paths) and is a separate decision.

## Notes

Out of scope unless told otherwise: the container name (done separately), moving the identity out of
the volume, and any change under `scripts/`, `lib/`, `hooks/` or `skills/`. The start script's step 5 and
`tests/devcontainer.test.sh` (which already pins that `--global` writes to the volume file) are where
the work would land — named here only to locate the problem, not to design it.

## Outcome

_Pending — written at the hand-off._

## Draft

Title: Seed the dev container git identity from the host config or environment on first start
Issue Type: none (user-owned repository). Labels: enhancement

### Description

Seed the git identity into the `codeo-git` volume's config when the dev container starts, so a fresh container no longer needs `git config --global user.name` and `user.email` run by hand. `.devcontainer/scripts/devcontainer-start.sh` fills a missing `user.name` or `user.email` from the host's `~/.gitconfig` (which VS Code copies into the container), else from `GIT_AUTHOR_NAME` / `GIT_AUTHOR_EMAIL`.

### Motivation / Context

Since #47 the container sets `GIT_CONFIG_GLOBAL=/home/dev/.config/git/config`, a file on the shared `codeo-git` volume, so git ignores the copied host `~/.gitconfig`. A fresh volume therefore has no identity, and step 5 of the start script only prints a TODO. The engineer has to set it by hand once per volume, although the identity already exists on the host.

### Key Requirements

- On start, a missing `user.name` and a missing `user.email` are each filled on their own, from the first source that has a value: the host `~/.gitconfig` first, then `GIT_AUTHOR_NAME` / `GIT_AUTHOR_EMAIL`.
- A value already in the volume config is never overwritten, so the start script stays safe to re-run.
- Only `user.name` and `user.email` are seeded; no other host setting is copied.
- When a value is still missing after both sources, the existing TODO is kept and now names the sources that were tried.

### Acceptance Criteria
- [ ] With an empty volume config and an identity in the host `~/.gitconfig`, `git config --global user.name` and `user.email` return the host's values after the start script runs.
- [ ] With an empty volume config, no host identity, and `GIT_AUTHOR_NAME` / `GIT_AUTHOR_EMAIL` set, those values land in the volume config.
- [ ] With the host file and the environment both set, the host file's values win.
- [ ] A `user.name` or `user.email` already in the volume config is unchanged after a run, and a missing one beside it is still filled.
- [ ] With no source holding an identity, the TODO still appears and lists the sources that were tried.
- [ ] `tests/devcontainer.test.sh` covers each case above and the suite passes; `CHANGELOG.md` records the change.

### Out of Scope

- Copying any other host git setting (such as `init.defaultBranch` or `pull.rebase`), or the whole host `~/.gitconfig`.
- Moving the identity out of the volume, or changing `GIT_CONFIG_GLOBAL`.
- Naming the container (#50).
- Any change under `scripts/`, `lib/`, `hooks/` or `skills/`.

### Reference

- `.devcontainer/scripts/devcontainer-start.sh` (step 5, git identity) and `tests/devcontainer.test.sh`.
- Follow-up to #47 (closed), which introduced the `codeo-git` volume and `GIT_CONFIG_GLOBAL`; #40 (open) is a different scope.

## Log

- 2026-11-09 — Q1-Q4 raised
- 2026-11-09 — Q1-Q4 answered; draft recorded
