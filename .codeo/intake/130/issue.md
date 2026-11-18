# Issue #130 — issue

## Outcome

Filed from `/codeo:triage` (`qc:100`) as #130, label `bug`, after the engineer approved the draft in the conversation. The engineer had already answered *file it* in triage, so no further questions were open.

## Draft as filed

### Description

`tests/live.test.sh` checks whether the live-signal stamp file exists with `[[ -e $(git -C "$clone" rev-parse --git-path codeo-live-beat) ]]`. `git rev-parse --git-path` prints a path relative to the directory git ran in (here `.git/codeo-live-beat` for a normal clone), but `[[ -e ]]` resolves it against the shell's current directory, not `$clone`. When the suite runs from a checkout that has its own `.git/codeo-live-beat`, the "stamp absent" assertions find that checkout's stamp and fail. Every checkout with a running workflow has one.

Where it shows on `origin/main`:
- `tests/live.test.sh:229` (`no lock: stamp`) and `:236` (`base: stamp`) use the form above and can fail for that reason.
- `:370-375` read the same `--git-path` into `$stamp` and test `[[ -e $clone/$stamp || -e $stamp ]]`. The `-e $stamp` half has the same flaw, so "stamp gone" (`:375`) can fail for the same reason.

### Motivation / Context

Raised by `/codeo:qc` for #100 as later work not filed from that checkout (`.codeo/done/100/qc.md`, line 19, citing lines 227, 234 and 373, since moved). The suite must give the same result in the checkout that runs it, whether or not a workflow is running there.

### Key Requirements

- Every stamp assertion in `tests/live.test.sh` resolves the stamp path against the clone it names, never against the current directory.
- The suite passes in a checkout that has its own `.git/codeo-live-beat`.

### Acceptance Criteria
- [ ] With a `.git/codeo-live-beat` file present in the checkout running the suite, `bash tests/live.test.sh` passes.
- [ ] With none present, it passes as before.
- [ ] No stamp assertion in `tests/live.test.sh` tests a relative `--git-path` result against the current directory.
- [ ] The "no lock", "base" and "clear deletes the ref and the stamp" cases still fail when the clone's stamp exists (or is not deleted).

### Out of Scope

- Other changes to `live.sh` or `live-signal.sh` (#118 covers its own leftovers in the same files).

### Reference

- `.codeo/done/100/qc.md`, line 19 (surfaced by `/codeo:qc` on #100; filed through `/codeo:triage`, `qc:100`).
- `tests/live.test.sh:229`, `:236`, `:370-375`.
- Related: #118 (touches `tests/live.test.sh`, different defects).

## Log

2026-11-18 — filed #130 · cost: unavailable
