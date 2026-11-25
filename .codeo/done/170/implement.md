# Issue #170 — implement

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/170 |
| Branch | `docs/docs-say-codeo-host-command` |
| Updated | 2026-11-25 |

## Where this stands

Round 1 built: all three tasks of `docs/plans/2026-11-25-codeo-host-command-docs-170.md` are committed on the branch; the build is clean. Next step: `/codeo:qc`.

## Questions

None.

## Notes

- The plan file was committed at the engineer's yes (`ef0a351`, then its round-2 rewrite). The first `/codeo:implement` call stopped at step 2a: the base merge brought in #171, which made round 1 of the plan stale, so the plan was reworked (plan.md round 2) before any task ran.

## Outcome

Built the plan's three tasks through `superpowers:subagent-driven-development`, every dispatch on sonnet; each task passed its own spec-and-quality review with no findings, and the whole-branch review found no Critical or Important findings.

- **Task 1** (`7a88f6f`): `tests/readme.test.sh` gains the `host-command` check, seven assertions, shown failing first (seven `FAIL host-command:` lines).
- **Task 2** (`e111707`): `README.md` gains one paragraph in *Installing* saying `install.sh` installs the plugins and not the `codeo` command, linking `.devcontainer/README.md#installing-the-codeo-command`; `docs/home-checkout.md`'s macOS paragraph names `brew install flock` and points to the keychain note.
- **Task 3** (`91f6f54`): `.devcontainer/README.md`'s host sentence says Linux or macOS (sandboxes Linux and WSL2 only) and `brew install flock`; new `### The keychain over SSH on macOS` quotes the error text and `security -v unlock-keychain ~/Library/Keychains/login.keychain-db`, naming `codeo home` only.

**Documentation pages changed:** `README.md`, `docs/home-checkout.md`, `.devcontainer/README.md`.

**Build result:** the shell suite's build is `true` and exits 0. The full suite, which belongs to `/codeo:qc`, was also run by the implementers and the final reviewer: `bash tests/run.sh` printed `all cases passed`.

**Deviations from the plan:** none. Two Minor observations from the final review were left as they are: the host sentence says "Linux or macOS" while the macOS requirements (Homebrew bash, `flock`) are on the neighbouring pages, and the `host-command` check looks for `brew install flock` anywhere in `.devcontainer/README.md`, not only in the Installing section.

No shared environment is configured, so there is no lease or deploy. No `/codeo:issue` was filed.

## Log

- 2026-11-25 — round 1 built: Tasks 1-3 complete · cost: 19m · sonnet-5-5 259k in + 7.7M cached / 29k out
