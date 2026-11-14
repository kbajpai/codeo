# Issue #67 — implement

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/67 |
| Branch | `feat/move-dev-container-image-ubuntu` |
| Updated | 2026-11-14 |

## Where this stands

Tasks 1 and 2 of `docs/plans/2026-11-14-ubuntu-2604-dev-container.md` are done, reviewed (task reviews and the whole-branch review all clean) and pushed: `ceb38d3` (test re-pinned, Dockerfile on `ubuntu:26.04`) and `a58fc7e` (README *Rebuilding* paragraph, changelog `## Unreleased`). The configured build (`true`) exits 0. Task 3, the engineer's (this container has no `docker`), is done and its output is under Q1. Nothing is open and nothing is deployed: no shared environment is configured.

## Questions

### Q1 — What did Task 3's build and in-image checks print on your Docker host?

**Why it matters:** acceptance criteria 2 and 3 (`docker build` succeeds; the tools run and `id dev` is UID 1000) and the in-image `shell` suite (plan Q2) can only be proved on a host with Docker. Without the output `/codeo:qc` marks them not yet checkable; with it, a failure becomes a new task here (a script fix "only where 26.04 requires it") rather than a surprise at QC.
**How:** from a checkout of this branch on that host, run the three commands in Task 3 of the plan (`docker build`, the tools check, the suite inside the image) and paste each one's output under **Answer:**. Each is expected to exit 0; the tools check should print `os: 26.04`, a version line per tool, `uid=1000(dev)`, `ubuntu: gone`, `sudo: ok`, `LANG=en_US.UTF-8` and `en_US.utf8`; the suite should print `all cases passed`.

**Answer:**
Run on the engineer's Docker host, pasted in the conversation:
- `docker build -t codeo-dev-2604 -f .devcontainer/Dockerfile .devcontainer` finished (base `ubuntu:26.04@sha256:065aa862…`; the apt install, `userdel -r ubuntu`/`useradd` and Claude Code installer steps all ran).
- Tools check printed `os: 26.04`, bash 5.3.9, git 2.53.0, jq 1.8.1, shellcheck 0.11.0, gh 2.104.0, Claude Code 2.1.325, `uid=1000(dev) gid=1000(dev)`, `ubuntu: gone`, `sudo: ok`, `LANG=en_US.UTF-8`, `en_US.utf8`.
- Suite inside the image: the first form (a read-only mount of the Windows checkout) failed with `docker: invalid reference format` before reaching the image — PowerShell expanded `$PWD` to `D:\Source\codeo`, an invalid volume spec. Re-run as `docker run --rm codeo-dev-2604 bash -c 'git clone --depth 1 --branch feat/move-dev-container-image-ubuntu https://github.com/kbajpai/codeo /tmp/w && cd /tmp/w && bash tests/run.sh'`, it printed `all cases passed`.

## Notes

- Task 1 review: spec compliant, no findings. Its one ⚠️ (that `userdel -r ubuntu` and the apt list work on a real 26.04 image) is what Task 3 checks; the plan's Notes record that the published base layer still has `ubuntu` at UID 1000.
- Whole-branch review: criteria 1, 4, 5, 6 met in this checkout; 2, 3 and the in-image suite left to Task 3, as planned. No findings. Concrete residual risks it named, all covered by Task 3: `sudo` installing a working binary on 26.04 (whose default is `sudo-rs`), Rust coreutils and bash 5.3 changing script behaviour.
- No rulings were made. No deviation from the plan. No out-of-scope work filed.

## Outcome

Plan: `docs/plans/2026-11-14-ubuntu-2604-dev-container.md`, all three tasks done.

**Built:**
- Task 1 (`ceb38d3`): `tests/devcontainer.test.sh` re-pinned — case renamed `dockerfile_is_ubuntu_2604_with_the_tools`, asserting `FROM ubuntu:26.04`, red first with the one expected `FAIL` line — then `.devcontainer/Dockerfile` moved: `FROM ubuntu:26.04` and its two version comments. Nothing else in the Dockerfile changed.
- Task 2 (`a58fc7e`): a paragraph in `.devcontainer/README.md` under *Rebuilding* (a container built before the move stays on the older image until rebuilt; the clone and the `codeo-gh` and `codeo-git` volumes are kept), and a `CHANGELOG.md` `## Unreleased` entry.
- Task 3 (engineer, on a Docker host): the image builds, the tools and the `dev` user check out, and the `shell` suite passes inside it (Q1).

**Documentation pages changed:** `.devcontainer/README.md` only.

**Build result:** the configured `shell` build is `true`, exit 0. Suites were not run here beyond each task's own proof — `bash tests/run.sh` passed after Tasks 1 and 2 — and are `/codeo:qc`'s to grade.

**Reviews:** both task reviews and the whole-branch review found nothing. Their one open point, that `userdel -r ubuntu`, the apt list and `sudo` work on a real 26.04 image, is answered by Task 3.

**Deviations from the plan:** none. Two notes on Task 3 as run: the suite-in-image command was run as a clone of the pushed branch tip (`19edb7e`, which holds every change above) rather than as the plan's read-only mount, because that command is not valid in PowerShell; and the image was built and checked on amd64 only. No rulings were made, no out-of-scope work was filed, and nothing was deployed.

**For `/codeo:qc`:** criteria 2 and 3 and the in-image suite are evidenced by Q1's pasted output, not by anything runnable here.

## Log

- 2026-11-14 — Tasks 1-2 implemented and reviewed; Task 3 waiting on Q1 · cost: 9m · sonnet-5-5 201k in + 4.6M cached / 18k out
- 2026-11-14 — Q1 answered (image build, tools check, suite in the image all passed); outcome written · cost: 23m · sonnet-5-5 209k in + 6M cached / 25k out
