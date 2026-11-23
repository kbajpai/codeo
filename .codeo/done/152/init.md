# Issue #152 — init

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/152 |
| Branch | `feat/run-home-role-host-strict` |
| Updated | 2026-11-22 |

## Where this stands

Initialized: branch `feat/run-home-role-host-strict` cut off `origin/main` at `ee0c02069817ffffde4a884c420ded16b76ee4f2` and pushed. Next step: `/codeo:plan` in the issue's container.

## Questions

None.

## Outcome

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/152 — Run the home role on the host with a strict role guard, and track each issue's branch, containers and clean-up in a comment |
| State | open · labels `enhancement` |
| Branch | `feat/run-home-role-host-strict` off `main` at `ee0c020` |
| Board | Ready → In progress |

**Problem.** The home role (`/codeo:issue`, `/codeo:init`, `/codeo:triage`, `/codeo:cleanup`) is to move to the host, keeping `codeo-home` supported. On the host `role.sh` reports `unguarded`, which may run every skill, so the guard must recognise a host home and hold strictly in both directions. Issues must also record, in one edited tracking comment, their branch, containers, images, volumes and sandboxes with host and UTC times, and show clean-up, and creating a second container for an issue must warn.

**Acceptance criteria** — verbatim from the issue, unchecked:
- [ ] `role.sh --check` allows `issue`, `init`, `triage` and `cleanup` only in a home checkout (a host clone or `codeo-home`), and refuses each in an issue checkout, with one refusal line; a test covers every skill in every role.
- [ ] `role.sh --check` refuses `plan`, `implement`, `qc` and `close` in home, host or container, and a host checkout that is neither home nor issue is refused.
- [ ] `role.sh` reports `home` for a host clone named `<codename>-home` with no lock on the base branch, with no Docker involved.
- [ ] `/codeo:init <N>` posts exactly one tracking comment with the marker and the table above, and a second run of it, or a resume, edits that comment instead of adding one.
- [ ] A container, sandbox, image and volume created for the issue each appear as a row with the host's hostname and a UTC creation time.
- [ ] After the removal that `/codeo:cleanup` printed is run, the comment shows each of those rows `removed` with a UTC time, and a branch deleted at `/codeo:close` shown `deleted`; an unremoved item stays `active`.
- [ ] Creating a container or sandbox for an issue that already has an `active` row or a local `codeo-<N>` prints the duplicate warning and needs confirmation; opening an existing container does not warn.
- [ ] `gh` being unavailable when a script records a row does not fail the creation; the script prints the row instead.
- [ ] The README documents the host home (install and upkeep: Claude Code, `gh`, the codeo plugin, git identity), the guard, the tracking comment, and Linux, macOS and Windows/WSL; `codeo-home` stays documented as supported.
- [ ] Existing tests still pass.

**Out of scope.** Moving issue work out of containers or sandboxes; removing the `codeo-home` container or its devcontainer files; running a container command from `/codeo:cleanup`; checking live state across hosts.

**Open at intake.** None recorded in the issue. For `/codeo:plan`: how a host home is told apart from an unrelated host checkout (folder name `<codename>-home` is the issue's rule); the plugin's own `init`/`cleanup` skill text lives outside this repository's tree, so where the tracking comment is written from is plan's to settle. Note: #146 (Release v1.0.8, live on `codeo-146`) lists `README.md`, `CHANGELOG.md` and `tests/install.test.sh` in its footprint; `/codeo:plan` runs `overlap.sh` before settling its own.

## Log
- 2026-11-22 — initialized: branch feat/run-home-role-host-strict off main at ee0c020 · cost: unavailable
