# Issue #67 — qc

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/67 |
| Branch | `feat/move-dev-container-image-ubuntu` |
| Updated | 2026-11-14 |

## Where this stands

Round 1 is written and clear. Nothing is open. Criteria 2 and 3 cannot be run in this container (no `docker`); they rest on the engineer's pasted Docker output in `implement.md` Q1, which this pass cites and did not reproduce.

## Questions

None.

## Notes

- Sync: `sync-main: the branch already contains origin/main`. No `also changed on main:` lines. `overlap.sh 67` and `overlap.sh --outside 67` printed nothing: no overlap with another workflow, and no changed path outside the plan's footprint.
- Scope: `bash scripts/scope.sh origin/main HEAD` printed `suite.shell=true` (`shell needed for unclassified paths`: the dossier files under `.codeo/67/` and `CHANGELOG.md`).
- Shared environment: none configured, so no environment step. No invariants document, no `wiki` module, and the `qc` overlays (`invariants-extra`, `wiki-rules`) exit 3: none.
- Reviewed head: `fafb3cd`. The reviewer was dispatched on `opus` with the criteria only, as `qc-06` requires.

## Outcome

### Round 1 — 2026-11-14

**Commands run and their output**

- Build: the `shell` suite's `build` is `true`; exit 0.
- Suite: `bash tests/run.sh` printed `all cases passed`, exit 0. The reviewer ran it again independently with the same result.
- `grep -v '^[[:space:]]*#' .devcontainer/Dockerfile | grep -m1 '^FROM '` printed `FROM ubuntu:26.04`.
- `grep -n "ubuntu:26.04\|dockerfile_is_ubuntu_2604" tests/devcontainer.test.sh` printed lines 111, 115 and 1644.
- `git grep -n -i -E '24\.04|2404|noble' -- .devcontainer tests` printed nothing, exit 1.
- `sed -n 1,12p CHANGELOG.md` shows `## Unreleased` at line 3, above `## v1.0.5`.
- `git grep -n -i -E 'ubuntu|dev container image' -- docs README.md ':!docs/plans'` printed nothing: no page outside the plan names the image.

**Criteria**

| Criterion | Verdict | Settled by |
|---|---|---|
| The first `FROM` in `.devcontainer/Dockerfile` is `ubuntu:26.04` | met | `.devcontainer/Dockerfile:6`, the grep above |
| `docker build` of `.devcontainer/Dockerfile` succeeds | untestable here — no `docker` in this container; the engineer's build on a Docker host finished (`implement.md` Q1) | engineer's pasted output, not reproduced here |
| In the built image `bash`, `git`, `jq`, `shellcheck`, `gh` and `claude --version` run, and `id dev` reports UID 1000 | untestable here — no `docker`; the engineer's run printed bash 5.3.9, git 2.53.0, jq 1.8.1, shellcheck 0.11.0, gh 2.104.0, Claude Code 2.1.325 and `uid=1000(dev)` (`implement.md` Q1) | engineer's pasted output, not reproduced here |
| `tests/devcontainer.test.sh` asserts `ubuntu:26.04` and passes, along with the rest of the `shell` suite | met | `tests/devcontainer.test.sh:115`; `bash tests/run.sh` printed `all cases passed`; the engineer's run of the suite inside the image also printed it (Q1) |
| No current file in `.devcontainer/` or the tests still names Ubuntu 24.04 | met | `git grep -n -i -E '24\.04\|2404\|noble' -- .devcontainer tests` printed nothing; the README paragraph says "the move to Ubuntu 26.04" |
| `CHANGELOG.md` has an `## Unreleased` entry for the change | met | `CHANGELOG.md:3` |

**Documentation check.** The plan names one page, `.devcontainer/README.md` (*Rebuilding*), and the diff changes it: line 38 says a container created before the move is still on the older image, to rebuild it once, and that the clone and the `codeo-gh` and `codeo-git` volumes are kept. The volumes claim is accurate (`.devcontainer/devcontainer.json` `mounts`, line 8). The plan's claim that no other page moves holds: the `git grep` above found no page naming the image or its version. No diagram applies.

**Findings** (the reviewer's; I found none of my own). The reviewer's verdict, quoted in plain text, was "Ready to merge: Yes", with no Critical and no Important findings.

- F1 (non-blocking) — `CHANGELOG.md:9` says "The tools … are unchanged". The same tools are installed, but at 26.04's versions (bash 5.3, Rust coreutils, jq 1.8.1, git 2.53, shellcheck 0.11, `sudo-rs` by default), which could change how someone's own shell work behaves in the container. Whose: `/codeo:implement`'s, wording only.
- F2 (non-blocking) — `.devcontainer/README.md:38` lists what a rebuild keeps but not what it loses: `~/.claude` is not on a volume, so `claude auth login` has to be done again and the plugins are reinstalled by `postCreateCommand`. True of every rebuild before this change, and the paragraph says nothing false. Whose: `/codeo:implement`'s, one sentence.
- F3 (non-blocking, cosmetic) — `CHANGELOG.md:5` reads `Shared state: unchanged`, where released entries read `unchanged from vX.Y.Z.`. Whoever cuts the next release rewrites the heading and this line.

None of the three sends the change back on its own. They are recorded, not fixed, and no further round is opened for them.

**Evidence not reproduced here.** Criteria 2 and 3, the in-image suite run, and the amd64-only build rest on the engineer's pasted Docker output. The in-image suite ran against a clone of the pushed branch at `19edb7e`, which holds all the code changes; the later commits are dossier files.

**Issues filed:** none.

**Verdict: clear — forward to `/codeo:close`.**

## Log

- 2026-11-14 — round 1: build, `shell` suite, criteria, documentation and footprint checked; opus review found nothing blocking; verdict clear · cost: 5m · opus-5-5 271k in + 1.5M cached / 8k out
