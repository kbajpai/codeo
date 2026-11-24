# Issue #163 — init

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/163 |
| Branch | `fix/close-152-leftovers-cleanup-overlay` |
| Updated | 2026-11-24 |

## Where this stands

Initialized. Branch `fix/close-152-leftovers-cleanup-overlay` off `main` at `a389a6577b15ff9529023666f63e42a7cd2967ed`. Next step: `/codeo:plan`, in the issue's container.

## Questions

None.

## Outcome

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/163 — Close the #152 leftovers: the cleanup overlay's `{N}` and by-hand fallback, a temporary-file leak in `codeo-track.sh`, and README and skills-page wording |
| State | open · labels `bug`, `documentation` |
| Branch | `fix/close-152-leftovers-cleanup-overlay` off `main` at `a389a6577b15ff9529023666f63e42a7cd2967ed` |
| Board | Ready → In progress |

**Problem.** `/codeo:qc` passed #152 with non-blocking findings that have no issue. The cleanup overlay prints `codeo rm {N}` literally under the pinned v1.0.8 `cleanup.sh`; the by-hand removal fallback marks an image `removed` that still exists, does not say where `mark` runs, and names `docker rm` for a sandbox; `codeo-track.sh` leaks a temp file on every `add` and `mark`; several README sentences say more or less than the code does; and `docs/skills.md` omits the overlay's fourth field and `fallback:`.

**Acceptance criteria** — verbatim from the issue, unchecked:
- [ ] Run against the pinned plugin version and against the new `cleanup.sh`, `/codeo:cleanup` prints a removal command with `{N}` replaced by the issue number, or the CHANGELOG names the release from which it does.
- [ ] The by-hand fallback in `.codeo/overlays/cleanup.md` and `.codeo/overlays/close.md` does not mark the `codeo-dev:<name>` image `removed` unless it removes it, says where `bash .devcontainer/codeo-track.sh mark …` is run so that it changes a row, and names a command that ends a sandbox.
- [ ] After `codeo-track.sh add` and `mark`, no `codeo-track.*` file remains in `$TMPDIR` (a test counts them before and after).
- [ ] `README.md` says a local container of that name is refused (F16), names every use of `jq` and what happens without it (F17), describes the host guard without "no longer" and gives an example comment that does not use #152's number (F18), and says how to keep Claude Code, `gh` and the plugin current (F19).
- [ ] `docs/skills.md`'s `/codeo:cleanup` section names the overlay's fourth field and the `fallback:` line.

**Out of scope.** #152 F20 (macOS `hostname` following the network, an image row left untracked after a failed `docker run`, a finished sandbox read as `stray`, two simultaneous first creations leaving two tracking comments); making `mark` match rows from another host.

**Open at intake.** Nothing: the issue's dossier recorded no open question.

## Log

- 2026-11-24 — initialized: branch fix/close-152-leftovers-cleanup-overlay off main at a389a6577b15ff9529023666f63e42a7cd2967ed · cost: 1m · sonnet-5-5 15k in + 523k cached / 2k out
