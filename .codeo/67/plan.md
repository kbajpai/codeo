# Issue #67 — plan

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/67 |
| Branch | `feat/move-dev-container-image-ubuntu` |
| Updated | 2026-11-14 |

## Where this stands

Explored and checked the two questions intake left open; both are settled by evidence (Notes). The
change itself is small: the `FROM` line, two comments, one test case, the README and the changelog.
What is not settled is how the image gets proved. This container has no `docker`, and CI does not
build the image, so no later step can run acceptance criteria 2 and 3 here. Blocked on Q1 and Q2.

## Questions

### Q1 — Who builds the 26.04 image and runs the in-image checks, given this container has no `docker`?

**Why it matters:** acceptance criteria 2 and 3 (`docker build` succeeds; `bash`, `git`, `jq`,
`shellcheck`, `gh`, `claude --version` run and `id dev` is UID 1000) need a container engine. The
dev container leaves one out on purpose, and `.github/workflows/ci.yml` only runs
`bash tests/run.sh` on `ubuntu-latest`. The answer decides whether the plan ends with a task that
stops and waits for you, or grows a CI job.
**Options:**
- **A — you run it on the host (recommended).** The plan's last task prints one `docker build` and
  one `docker run` command, stops, and waits for you to paste the output; `/codeo:qc` reads the
  pasted output as the evidence. Same form as the stop-and-wait tasks in the v1.0.4 release plan.
  Nothing outside the issue's scope changes.
- **B — a CI job builds the image and runs the checks.** Proves it on every later pull request
  too, but it changes `.github/workflows/ci.yml`, which the issue lists as out of scope, and adds
  a few minutes to each run.
- **C — A now, and I file B as its own issue** through `/codeo:issue`.

**Answer:**

### Q2 — Should the `shell` suite also be run inside the built 26.04 image?

**Why it matters:** acceptance criterion 4 says the suite passes, without saying where. Run in
this checkout it passes on 24.04's tools, which proves the test change but not that the scripts
work in the new image. The 26.04 base differs in ways that could change script behaviour: its
default coreutils are the Rust rewrite (`rust-coreutils` 0.10, so `stat`, `readlink`, `install`
and the rest), bash is 5.3 (5.2 here), jq 1.8.1 (1.7 here), git 2.53 (2.43 here) and shellcheck
0.11 (0.9 here). The answer adds `bash tests/run.sh` inside the image to the Q1 verification, or
leaves it out. If it is added and something fails, the fix belongs to this issue ("change only
where 26.04 requires it") and comes back as another round.
**Options:** run the suite inside the image as well (recommended) · this checkout only.

**Answer:**

## Notes

**Intake's two open questions, checked against the published image and package index** (no
`docker` here, so the base layer of `ubuntu:26.04`, amd64, was read from Docker Hub directly):

- The image is Ubuntu 26.04.1 LTS (Resolute Raccoon). Its `/etc/passwd` still ends with
  `ubuntu:x:1000:1000:Ubuntu:/home/ubuntu:/bin/bash`, and `/home/ubuntu` exists. So
  `userdel -r ubuntu` stays as it is; only its comment changes.
- Every package in the apt list exists under the same name in `resolute`: `ca-certificates`,
  `curl`, `git`, `gnupg`, `jq`, `less`, `locales`, `sudo` in `main`; `shellcheck` in `universe`,
  which the image's `ubuntu.sources` enables. The apt list does not change.
- `gh`'s apt repository uses the suite `stable`, not an Ubuntu codename, so its line does not
  change.
- Not checked, because it needs a build: that installing the `sudo` package on 26.04 gives a
  working `/usr/bin/sudo` (the base image ships neither `sudo` nor `sudo-rs`), and that the Claude
  Code installer runs. The Q1 verification covers both.

**Files that name the version today** (history excluded): `.devcontainer/Dockerfile` lines 1, 6
and 30; `tests/devcontainer.test.sh` lines 9, 111, 115 and 1644. `CHANGELOG.md:18` is #36's
released entry and stays.

**Calls I am making, stated so they can be corrected:**

- The test case is renamed `dockerfile_is_ubuntu_2604_with_the_tools`. Criterion 5 reads the old
  name as naming 24.04.
- `.devcontainer/README.md`'s *Rebuilding* section gains a line: a container built before this
  change is still on 24.04 until it is rebuilt. The changelog entry says the same.
- One pull request. Output is a plan under `docs/plans/`, with no separate reference doc.
- No other workflow is in flight (`inflight.sh --except 67`), so there is no overlap to raise.
  No invariants document, shared environment, `wiki` module or exclusive resources are configured.

## Outcome

_Pending — written at the hand-off._

## Log

- 2026-11-14 — explored; intake's two open questions settled by evidence; Q1-Q2 raised · cost: 2m · fable-5-2 97k in + 589k cached / 5k out
