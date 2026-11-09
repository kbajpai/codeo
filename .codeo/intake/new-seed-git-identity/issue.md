# Issue new-seed-git-identity — issue

| | |
|---|---|
| Issue | not filed yet |
| Branch | none (intake) |
| Updated | 2026-11-09 |

## Where this stands

Drafting. Problem restated: since #47 the dev container points `GIT_CONFIG_GLOBAL` at the `codeo-git`
volume, so git ignores the host `~/.gitconfig` VS Code copies in. A fresh volume has no
`user.name`/`user.email` and `devcontainer-start.sh` step 5 only prints a TODO telling the engineer to
run `git config --global` by hand. The issue asks the start script to seed the identity on first start.
Blocked on Q1-Q4 below. Related: #47 (closed), #40 (open, dev container follow-ups) — checked, neither
covers seeding.

## Questions

### Q1 — Where should the identity be seeded from?

**Why it matters:** decides the sources the start script reads and the order it tries them.
**Options:** the host `~/.gitconfig` VS Code copies in (`user.name`/`user.email` only) · `GIT_AUTHOR_NAME`/`GIT_AUTHOR_EMAIL` from the container environment · both, host file first · both, environment first.

**Answer:**

### Q2 — May seeding ever overwrite a value already in the volume file?

**Why it matters:** "only fill what is missing" is safe on every re-run; overwriting would clobber an identity the engineer set on purpose.
**Options:** fill only a missing `user.name` / `user.email`, each on its own · fill only when both are missing · always overwrite.

**Answer:**

### Q3 — When no source has an identity, what should happen?

**Why it matters:** keeps or changes today's behaviour (a TODO printed at the end of the start script).
**Options:** keep the TODO as it is · keep it but name the sources that were tried · fail the start script.

**Answer:**

### Q4 — Is anything else in scope?

**Why it matters:** the same shared volume could also carry other host git settings (e.g. `init.defaultBranch`, `pull.rebase`), but that widens the issue.
**Options:** identity only (`user.name`, `user.email`) · identity plus a short list you name · copy the whole host `~/.gitconfig` except credential helpers.

**Answer:**

## Notes

Out of scope unless told otherwise: the container name (done separately), moving the identity out of
the volume, and any change under `scripts/`, `lib/`, `hooks/` or `skills/`. The start script's step 5 and
`tests/devcontainer.test.sh` (which already pins that `--global` writes to the volume file) are where
the work would land — named here only to locate the problem, not to design it.

## Outcome

_Pending — written at the hand-off._

## Log

- 2026-11-09 — Q1-Q4 raised
