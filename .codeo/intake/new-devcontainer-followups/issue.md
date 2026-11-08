# Issue new-devcontainer-followups — issue

Filed from triage 2026-11-08 Q2, Q3, Q5, Q6 (`.codeo/intake/triage/2026-11-08.md`).

## Questions

### Q1 — Include Q6 (Claude login and plugins lost on rebuild)?
The plan chose this on purpose; the start script lists the TODO each time. **Recommended:** include it as an explicitly optional requirement (persisting `/home/dev/.claude` in a volume), so it is not lost but does not block the issue. Alternatives: leave it out (dismiss). **Answer:** _open_

### Q2 — One issue for Q2, Q3, Q5?
**Recommended:** yes — all are small follow-ups to #36 touching `.devcontainer/`, `lib/env.sh`. **Answer:** _open_

## Draft

**Title:** Dev container follow-ups: pin comparison, start-script fixes, and the `plugin` config key reference

**Type:** none · **Labels:** enhancement

### Description
Follow-ups from the QC of #36, none blocking:
- `plugins.sh` compares only `plugin.ref`; a changed `plugin.repo` with the same ref leaves the old codeo installed and the script prints success.
- `devcontainer-start.sh` adds a duplicate `git config --global --add safe.directory` entry every run (line 37) though its header says each step checks first; runs `claude auth status` inside the clone (line 72) though `plugins.sh` says `claude` never runs in a git repository; its bind-mount TODO suggests `sudo chown -R …`, the command the script avoids on rootless runtimes; a `cd ""` quirk if `git rev-parse --show-toplevel` fails; a comment about `>=` sits away from the `>=`.
- `devcontainer.json` sets `--cpus=2`, which makes Docker refuse to start the container on a host with fewer than 2 CPUs.
- The `plugin` top-level key in `.codeo/config.json` is missing from `lib/env.sh`'s key reference.
- (Optional) Claude Code's login and installed plugins live in `/home/dev/.claude`, outside a volume, so each rebuild needs `claude auth login` again.

### Motivation / Context
The dev container is how codeo is developed; these are the rough edges the reviews of #36 recorded and deferred.

### Key Requirements
- A changed `plugin.repo` (same ref) reinstalls codeo from the new repository.
- Re-running the start script does not add duplicate `safe.directory` entries.
- `claude` commands in the start script run outside the git clone.
- The bind-mount guidance no longer recommends a command that hands host files to a subordinate UID, and explains the user-namespace mapping.
- The container starts on a host with fewer than 2 CPUs or without cgroup limits.
- `lib/env.sh`'s key reference lists `plugin` (`repo`, `ref`).
- Optional: Claude's login and plugins persist across a rebuild.

### Acceptance Criteria
- [ ] A test changes `plugin.repo` with an unchanged ref and sees codeo replaced.
- [ ] Two runs of the start script leave one `safe.directory` entry.
- [ ] `git status` is clean after the start script's `claude` calls, which run from `$HOME`.
- [ ] The start script's non-owned bind-mount message contains no `sudo chown -R` advice.
- [ ] `devcontainer.json` no longer sets a CPU limit that fails on a 1-CPU host.
- [ ] `lib/env.sh` documents the `plugin` key.
- [ ] `tests/devcontainer.test.sh` covers the new behaviour.

### Out of Scope
Changes to the image, adding tools, or making the pin literal in the tests configurable.

### Reference
Triage 2026-11-08 Q2, Q3, Q5, Q6; qc.md for #36 (N1–N6, F3, F4) and implement.md for #36; PR #38.
