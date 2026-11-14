# Issue #67 — implement

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/67 |
| Branch | `feat/move-dev-container-image-ubuntu` |
| Updated | 2026-11-14 |

## Where this stands

Tasks 1 and 2 of `docs/plans/2026-11-14-ubuntu-2604-dev-container.md` are done, reviewed (task reviews and the whole-branch review all clean) and pushed: `ceb38d3` (test re-pinned, Dockerfile on `ubuntu:26.04`) and `a58fc7e` (README *Rebuilding* paragraph, changelog `## Unreleased`). The configured build (`true`) exits 0. Task 3 is the engineer's — this container has no `docker` — and is waiting on Q1. Nothing is deployed: no shared environment is configured.

## Questions

### Q1 — What did Task 3's build and in-image checks print on your Docker host?

**Why it matters:** acceptance criteria 2 and 3 (`docker build` succeeds; the tools run and `id dev` is UID 1000) and the in-image `shell` suite (plan Q2) can only be proved on a host with Docker. Without the output `/codeo:qc` marks them not yet checkable; with it, a failure becomes a new task here (a script fix "only where 26.04 requires it") rather than a surprise at QC.
**How:** from a checkout of this branch on that host, run the three commands in Task 3 of the plan (`docker build`, the tools check, the suite inside the image) and paste each one's output under **Answer:**. Each is expected to exit 0; the tools check should print `os: 26.04`, a version line per tool, `uid=1000(dev)`, `ubuntu: gone`, `sudo: ok`, `LANG=en_US.UTF-8` and `en_US.utf8`; the suite should print `all cases passed`.

**Answer:**

## Notes

- Task 1 review: spec compliant, no findings. Its one ⚠️ (that `userdel -r ubuntu` and the apt list work on a real 26.04 image) is what Task 3 checks; the plan's Notes record that the published base layer still has `ubuntu` at UID 1000.
- Whole-branch review: criteria 1, 4, 5, 6 met in this checkout; 2, 3 and the in-image suite left to Task 3, as planned. No findings. Concrete residual risks it named, all covered by Task 3: `sudo` installing a working binary on 26.04 (whose default is `sudo-rs`), Rust coreutils and bash 5.3 changing script behaviour.
- No rulings were made. No deviation from the plan. No out-of-scope work filed.

## Outcome

_Pending — written at the hand-off._

## Log

- 2026-11-14 — Tasks 1-2 implemented and reviewed; Task 3 waiting on Q1 · cost: 9m · sonnet-5-5 201k in + 4.6M cached / 18k out
