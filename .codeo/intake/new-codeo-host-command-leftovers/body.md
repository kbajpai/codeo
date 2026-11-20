### Description

`codeo` (`.devcontainer/codeo`, the host command from #133) shipped with its QC findings recorded as non-blocking and 11 review threads on PR #136 left unresolved. Some of what is left can remove unsaved work or tell the user something false, and the command deletes containers, volumes and sandboxes. This issue collects what is still wrong so it is fixed or ruled out on purpose.

### Motivation / Context

`/codeo:triage` (run 10, 2026-11-20) found `.codeo/done/133/qc.md` rounds 1-5 ("No issue was filed for this pass") and 11 unresolved Copilot threads on PR #136. Read against `origin/main` on 2026-11-20:

- **Still present:** F29 (after any non-zero exit of `codeo-sandbox.sh end`, `rm` adds "to remove it anyway: sbx rm --force codeo-<N>", the one route that skips what `end --force` does, even when the refusal was over unpushed work); F30 (`rm <N> --container --force` with no container and no volume prints "removed container codeo-<N> but could not remove volume"); the first-use download writes one shared `$name.part` and the branch lookup one shared `.lookup.git.part`, so two concurrent first uses collide; the container check runs `git fetch origin` without `--prune`, so a deleted branch's remote-tracking ref can make unpushed work look pushed; `git status --porcelain` does not set untracked files explicitly, so `status.showUntrackedFiles=no` hides new files.
- **Reported, appear fixed on `origin/main`; confirm and drop in `/codeo:plan`:** F26 (`CODEO_SBX` ignored; `sbx_prog` now honours it, review thread …636750); pointing the lookup clone at the current `CODEO_REPO_URL` (thread …636595); `cat-file -e` in the branch lookup (F10, thread …636654).
- **Not re-checked, for `/codeo:plan`:** F19 (one listing failing while the other finds `codeo-<N>` skips the "both exist" rule; reproduced with docker down and sbx listing `codeo-5`, where `codeo rm 5` runs `codeo-sandbox.sh end 5`; also thread …636350); the write between the safety check and `docker rm -f` on a live container (thread …636391); a same-named volume behind a bind-mounted container (thread …636455); relative `CODEO_CONTEXT` / `CODEO_SBX_IMAGE` overrides resolved after `cd` (thread …636698); and the small findings F3, F4, F7, F8, F11, F12, F13, F20, F27, F28 (git progress lines on a first lookup, `--rebuild --rebuild` accepted, a failing ref listing read as "no branch holds", a raw `mkdir` error, `rm --container` on a missing container, a running container stopped again after a flaky `docker ps`, `paused`/`restarting` shown as `stopped`, a detached HEAD alone refusing `rm`, no mention that the container is already gone when the volume removal fails, an unvalidated branch name).
- **Wording** (folded in at the engineer's request): `--container|--sandbox` missing from the help text and README rows for `shell`, `open` and `rm` (F5, F16); the README does not say a failed listing warns on stderr, withholds the "no issue containers or sandboxes" line and exits 1 (F14); ".devcontainer/README.md:99" still says "It is all or nothing" (F15); the changelog describes review-round fixes as behaviour a release once had (F6, F31); overlong comments (F17); a stub comment says `cat-file -e` where it answers `rev-parse` (F22); "the exit status is the called script's" is untrue for `list`, container `rm`, `default` and `update` (F23); `~/codeo` collides with `git clone` of this repository in `~` (F21).

### Key Requirements

- `codeo rm` never removes a container, volume or sandbox on a check that could not run or that looks at stale or incomplete evidence, and never prints advice that skips its own safeguards or a claim that did not happen.
- When one of docker or sbx cannot list, a lookup by number does not guess the kind: the engineer is told and chooses.
- Two `codeo` commands started together on a fresh home directory do not corrupt each other's downloads or lookup clone.
- Every other finding listed above is either fixed or ruled out with a reason recorded in `/codeo:plan`'s dossier.
- The README, help text, comments and changelog say what the command does.

### Acceptance Criteria
- [ ] After a non-zero exit of `codeo-sandbox.sh end` the output points to `sbx rm --force` only when the refusal was not over unpushed or uncommitted work (F29).
- [ ] `rm <N> --container --force` with no container never says a container was removed (F30).
- [ ] With docker unable to list and sbx listing `codeo-<N>`, or the reverse, `codeo rm <N>` does not run until the engineer has named the kind (F19, thread …636350).
- [ ] The safety check does not report clean when a deleted branch's remote-tracking ref is the only evidence, and does not miss new files under `status.showUntrackedFiles=no`.
- [ ] A commit or file written to a running container between the safety check and its removal is not lost without `--force`, or the plan records why it cannot be prevented.
- [ ] Two first-use commands started together both succeed and leave an installed script and a lookup clone that are complete.
- [ ] Each of F3, F4, F7, F8, F11, F12, F13, F20, F27, F28 and review threads …636234, …636301, …636455, …636698 is fixed or ruled out with a reason in the plan dossier.
- [ ] F26 and threads …636595 and …636654 are confirmed fixed on `main` and dropped.
- [ ] The help text and both READMEs show `--container|--sandbox` on `shell`, `open` and `rm`, say that a failed listing warns on stderr and exits 1, and no longer say "all or nothing" where the moves can fail part-way; the changelog entry describes what the command does, not review rounds; the stale comments (F17, F22) and the exit-status sentence (F23) are corrected; the `~/codeo` collision (F21) is documented or avoided.
- [ ] The tests cover each behaviour changed above.

### Out of Scope

- Other findings of #133's QC outside `.devcontainer/codeo` and its READMEs and changelog entry (`codeo-sandbox.sh` and `codeo-container.sh` do not change).
- New commands or options beyond what the findings need.

### Reference

- `.codeo/done/133/qc.md` and `implement.md` on `origin/main`, rounds 1-5: F2-F32.
- Review threads on PR #136 (https://github.com/kbajpai/codeo/pull/136), ids 4629636234, 4629636301, 4629636350, 4629636391, 4629636455, 4629636491, 4629636540, 4629636595, 4629636654, 4629636698, 4629636750.
- #133 (closed), #131 and #125 for the sandbox side.
- `.codeo/intake/triage/2026-11-20.md`, Q1 and Q9.

### Open questions

- Whether the write between the safety check and removal can be prevented at all without stopping the container first.
- Whether the `~/codeo` collision is fixed by a different default directory or by documentation.
