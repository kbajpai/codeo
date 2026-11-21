# Issue #143 — init

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/143 |
| Branch | `fix/codeo-host-command-close-leftovers` |
| Updated | 2026-11-21 |

## Where this stands

Initialized: branch `fix/codeo-host-command-close-leftovers` cut off `origin/main` at `2e02100a256de327d5f85d51d57db98a98672da1` and pushed. Next step: `/codeo:plan` in the issue's container.

## Questions

None.

## Outcome

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/143 — `codeo` host command: close the leftovers from #133 (unsafe or false `rm` output, concurrent first use, and wording) |
| State | open · labels `bug` |
| Branch | `fix/codeo-host-command-close-leftovers` off `main` at `2e02100` |
| Board | Ready → In progress |

**Problem.** `codeo` (`.devcontainer/codeo`, #133) shipped with non-blocking QC findings and 11 unresolved review threads on PR #136. Some can remove unsaved work or print something false, and the command deletes containers, volumes and sandboxes. The issue collects what is still wrong so each item is fixed or ruled out on purpose: unsafe `rm` decisions (F19, stale refs, hidden untracked files, a write between check and removal), false output (F29, F30), colliding first-use downloads, and wording in help, READMEs, comments and changelog.

**Acceptance criteria** — verbatim from the issue, unchecked:
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

**Out of scope.** Other findings of #133's QC outside `.devcontainer/codeo` and its READMEs and changelog entry (`codeo-sandbox.sh` and `codeo-container.sh` do not change); new commands or options beyond what the findings need.

**Open at intake.** Whether the write between the safety check and removal can be prevented at all without stopping the container first. Whether the `~/codeo` collision is fixed by a different default directory or by documentation. Also: F26, threads …636595 and …636654 appear already fixed on `main` and are to be confirmed in `/codeo:plan`.

## Log
- 2026-11-21 — initialized: branch fix/codeo-host-command-close-leftovers off main at 2e02100 · cost: 1m · sonnet-5-5 103k in + 664k cached / 3k out
