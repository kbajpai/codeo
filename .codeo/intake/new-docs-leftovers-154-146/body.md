### Description

`/codeo:qc` passed #154 and #146 with non-blocking documentation findings that were recorded for triage and have no issue. This issue closes them: a removal flowchart and README paragraphs that say slightly more than the code does, a v1.0.8 changelog line that omits two shipped changes, and a release checklist step that omits two files a release moves.

### Motivation / Context

- **#154 F1:** `.devcontainer/README.md`, flowchart edge `G -- "docker rm -f failed (with --force, only while the container is still listed), …"`: with `--force`, `cmd_rm` also dies when the follow-up `docker ps -a` listing itself fails (`.devcontainer/codeo:658`, `listing=$(docker ps -a …) || die "could not remove container $name"`).
- **#154 F2:** the `H` edge carries the same `--force` parenthesis, but `H` is reached only from "anything else, no --force"; the parenthesis describes a case that cannot happen.
- **#154 F3:** the sandbox paragraph says "running it again fails the same way, because the script stops before it reads `--force`". `cmd_end` reads `--force` first (`.sbx/codeo-sandbox.sh:372-376`); the missing-clone `die` happens with or without it. The conclusion (`sbx rm --force codeo-<N>` is the way out) stands.
- **#154 F4:** the inspect paragraph says "A container `codeo` had to start for that read is stopped again". When `docker ps -a` itself fails, `started` stays 0, so a stopped container is started and left running (very rare). "A container `codeo` knows it started" is accurate.
- **#154 F5:** flowchart node `Q` ("refuse: nothing removed; a container codeo started is stopped again") is also reached by the "no such container, no --force" edge, where nothing was started.
- **#146 F1:** the `Shared state:` line (`CHANGELOG.md:6`) of v1.0.8 omits that `scripts/dossier-check.sh`, `scripts/inflight.sh` and `scripts/qc-verdict.sh` now match `## Outcome` exactly (so `## Outcomes` and `## Outcome notes` no longer count), and that `scripts/lock.sh` gains a reader of the `### Round <n> — stashed|abandoned` headings (`is_parked`, used by the web hook under `CODEO_LOCK_SKIP_PARKED=1`). `docs/release-checklist.md` step 6 says the line must name every dossier convention a script reads back. The tag `v1.0.8` is pushed, so the Release notes can be repaired with `gh release edit v1.0.8 --notes-file <the section>`, and `main`'s changelog line then differs from the tag's copy.
- **#146 F2:** `docs/release-checklist.md` step 6 says to set the version "in `.claude-plugin/plugin.json` only", but a release also moves the README's installer examples and `tests/install.test.sh`'s stubs to the latest release.

### Key Requirements

- The README's removal flowchart and the two paragraphs say what `.devcontainer/codeo` and `.sbx/codeo-sandbox.sh` do in the cases F1-F5 name.
- The v1.0.8 `Shared state:` line names the two omitted changes, on `main` and, if the engineer decides it is worth it, in the Release notes.
- The release checklist names every file a release moves the version in.

### Acceptance Criteria
- [ ] The flowchart edge from `G` names the failed follow-up `docker ps -a` listing under `--force`, and the `H` edge no longer carries a `--force` parenthesis.
- [ ] The sandbox paragraph no longer says the script stops "before it reads `--force`" and still names `sbx rm --force codeo-<N>` as the way out.
- [ ] The inspect paragraph no longer says a container `codeo` "had to start" is always stopped again.
- [ ] Node `Q`'s label is true for every edge that reaches it.
- [ ] `CHANGELOG.md`'s v1.0.8 `Shared state:` line names the exact `## Outcome` match in `dossier-check.sh`, `inflight.sh` and `qc-verdict.sh` and the `### Round <n> — stashed|abandoned` reader in `lock.sh`.
- [ ] `docs/release-checklist.md` step 6 names the README installer examples and `tests/install.test.sh` stubs as files a release also moves.

### Out of Scope

- #154 F6 (soft-wrap in the sandbox paragraph, a vague last sentence in the CHANGELOG `## Unreleased` bullet, early-wrapped `inflight.sh` comments).
- #146 F3 (`plan.md`'s "two files" note in an archived dossier).
- Moving or re-tagging `v1.0.8`.

### Reference

- `.codeo/done/154/qc.md` round 1 (F1-F6), `.codeo/done/146/qc.md` round 1 (F1-F3) and its `## Notes`.
- `.devcontainer/README.md`, `.devcontainer/codeo`, `.sbx/codeo-sandbox.sh`, `CHANGELOG.md`, `docs/release-checklist.md`.
- Surfaced in `/codeo:triage` run 20 (`qc:154:F1-F5`, `qc:146:F1-F2`).
