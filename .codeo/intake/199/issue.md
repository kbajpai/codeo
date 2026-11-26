# Issue #199 — issue

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/199 |
| Branch | none |
| Updated | 2026-11-26 |

## Where this stands

Filed as #199.

## Problem as restated

Multi-user safety gap found by a read-only audit of the whole repository (scripts, skills, containers, repo policy); details in the draft below. Parent tracker: #194.

## Questions

None open. The engineer chose to file all twelve groups, then asked to merge them into fewer issues.

## Draft

**Title:** Give containers, sandboxes and volumes an owner, and close the low-severity container gaps

**Type:** none (user-owned repository). **Labels:** enhancement, priority label as filed.

#### Description
Give containers, sandboxes and their volumes an owner, so `shell`, `rm` and `home` act only on the caller's own and credentials are not shared across users on one Docker host.

#### Motivation / Context
Applies when several engineers share one Docker daemon. Every container mounts the same `codeo-gh` and `codeo-git` volumes (`.devcontainer/codeo-container.sh:119`, `devcontainer.json:9-10`), so everyone shares one GitHub login and the last `gh auth login` wins; the start script never overwrites an existing git identity (`devcontainer-start.sh:372-408`), so a second user's commits are authored as the first (C1). Names are bare `codeo-<N>`, `codeo-home`, volume `codeo-<N>` and image `codeo-dev:codeo-<N>` with no repo or user prefix and no ownership label; `codeo rm` restarts a running container to re-read it (`.devcontainer/codeo:551`) and `--force` skips all checks (C2). `docker run -v codeo-N:/workspaces` reuses a leftover volume, which also holds the Claude login (C3). Cleanup prints removals for everyone's finished issues and the `docker rm -f` fallback skips the unpushed-work check (B12).

#### Key Requirements
- Names, volumes and images carry the repo and a per-user component, plus an owner label.
- `shell`, `rm`, `home` and cleanup act only on containers carrying the caller's label; acting on another's needs an explicit override.
- `rm` never restarts a container it is going to refuse to remove.
- A leftover volume is reused only when its repo, branch and owner match.
- `gh` and git identity volumes are per user.

- Downloads (container tools, Claude installer, base images) are pinned and checksum- or signature-verified; mutable tags are replaced (C9).
- The role guard overrides (`CLAUDE_CODE_REMOTE`, `CODEO_DOCKERENV`, `CODEO_CONTAINERENV`) are documented as trust boundaries and not honoured to lift a refusal outside the cases they exist for (C10).
- Repo identity is compared; the default `kbajpai/codeo` and hard-coded `base_ref=main` are removed (C11).
- The `rm` restart and `--rebuild` race windows are closed (C12); the sandbox `check_name` refuses instead of warning (C13); hooks that fail open say so in their output (C14).

#### Acceptance Criteria
- [ ] Two users and two repos on one host get distinct names and volumes.
- [ ] `rm` of another user's container is refused without restarting it.
- [ ] A leftover volume of a different owner or repo is not reused.
- [ ] The fallback removal in cleanup checks for unpushed work.
- [ ] Tests cover each case.

#### Out of Scope
Hardening the sandbox image or download verification (separate low-priority issue).

#### Reference
Parent #194. Audit findings C1-C14, B12.
