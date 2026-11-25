# Issue #170 — qc

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/170 |
| Branch | `docs/docs-say-codeo-host-command` |
| Updated | 2026-11-25 |

## Where this stands

Round 1 written: clear, one non-blocking finding. Next step: `/codeo:close`.

## Questions

None.

## Notes

- F1 is a wording slip older than this change that the new parenthetical now sits on; it promises later work and is left for `/codeo:triage` to collect. No `/codeo:issue` was filed.

## Outcome

### Round 1 — 2026-11-25

**Commands and output**

- `sync-main.sh --abort-on-conflict`: `the branch already contains origin/main`. `overlap.sh 170`: nothing, exit 0. `overlap.sh --outside 170`: nothing, exit 0, so the diff stays inside the footprint.
- `git diff origin/main...HEAD --stat`: 9 files, 375 insertions, 2 deletions: `README.md`, `docs/home-checkout.md`, `.devcontainer/README.md`, `tests/readme.test.sh`, the plan, and the four `.codeo/170/` dossiers.
- `scope.sh origin/main HEAD`: `suite.shell=true`, with the dossiers and `README.md` as the unclassified paths that make it so. No `deploy=` line: no shared environment is configured.
- Build (`true`, suite `shell`): exit 0.
- Suite (`bash tests/run.sh`, whole, not parallel): `all cases passed`, exit 0. `bash tests/readme.test.sh`, run again by hand: `all cases passed`.
- Own checks: `grep -c flock install.sh` prints 0; `README.md:72` is inside `## Installing`; the headings `## Installing the \`codeo\` command` (`.devcontainer/README.md:94`) and `### The keychain over SSH on macOS` (`:136`) exist; `brew install flock` is in `docs/home-checkout.md:22` and `.devcontainer/README.md:96`; the unlock command and the error text are in `.devcontainer/README.md` only.

**Acceptance criteria**

| Criterion | Verdict | Settled by |
|---|---|---|
| README.md, in or next to *Installing*, has one line saying `install.sh` installs the plugins and not the `codeo` command, with a link to the `.devcontainer/README.md` section that has its install line | met | `README.md:72`; `tests/readme.test.sh` `host-command` and `links` |
| The README's macOS paragraph names `brew install flock` | met — the paragraph is in `docs/home-checkout.md:22` since #171 (plan Q6) | `docs/home-checkout.md:22`; `host-command` |
| A documented macOS note gives the keychain error text and the `security -v unlock-keychain` command | met | `.devcontainer/README.md:136-144`; `host-command` |
| Every command and link the changes name exists and is spelled as in the repo | met | the existing `links` and `paths` checks pass; `.devcontainer/codeo:159` calls `flock`; `.sbx/README.md:7` says sandboxes are never macOS |
| `bash tests/run.sh` passes (any doc-pin tests updated with the wording) | met | `all cases passed`, exit 0; the pin is the new `host-command` check |

**Documentation check.** The plan names three pages and the diff changes all three. Each is present tense, with no issue number and no "now" or "no longer" in the added lines. The plan's claim that `docs/updating.md` and the other pages say nothing about either subject holds (`grep` for `flock` and `keychain` finds them only in the three pages). No invariants file and no documentation overlay are configured.

**Independent review** (`opus`, handed the criteria and the diff only): no Critical or Important findings; it checked each claim against `install.sh`, `.devcontainer/codeo`, `.devcontainer/codeo-container.sh` and `.sbx/README.md`, and tested a throwaway copy where removing a required string made the new check fail with its own line. Its assessment, quoted: ready to merge.

**Findings**

- F1 (non-blocking) — `docs/home-checkout.md:22`: the sentence says "`install.sh` and the `codeo` command need bash 4.3 or later ... and `flock`", but `install.sh` never uses `flock`; only `codeo` does (`.devcontainer/codeo:159`). The wrong claim about `install.sh` is older than this change, but the new "(`brew install flock`)" sits on it, so a macOS reader may think the plugin installer needs `flock`. Whose: the plan's, a one-word wording gap that does not change what the code does. A fix is to say "the `codeo` command needs `flock`". The implement review's two Minor notes (the host sentence's wording and the `host-command` check looking for `brew install flock` anywhere in `.devcontainer/README.md`) are recorded in `implement.md` and not raised again.

Blocking findings: none. No `/codeo:issue` filed. No shared environment, so no lease, deploy or release.

**Verdict: clear — forward to `/codeo:close`.**

## Log

- 2026-11-25 — round 1: clear, F1 non-blocking · cost: 4m · opus-5-5 270k in + 1.5M cached / 7k out · sonnet-5-5 25k in + 967k cached / 790 out
