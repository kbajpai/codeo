# Issue #213 — plan

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/213 |
| Branch | `feat/213-release-v1-0-11-main` |
| Updated | 2026-11-27 |

## Where this stands

Q1 and Q2 are answered (the recommendations). The plan is being drafted to `.codeo/213/plan-draft.md` for review; nothing is open.

What exploration found:
- **The gate is "what is on `main` now".** `origin/main` is at `3857710`, 8 commits past `v1.0.10`: #191 (the pin), #202 (#190), #203 (#192), #208 (#195), #211 (CI), #210 (#204), #212 (#206), #209 (#188). `inflight.sh --except 213` printed `no other workflow in flight`; `overlap.sh` runs once the footprint is written.
- **The release PR has the v1.0.10 shape:** five files (`.claude-plugin/plugin.json`, `CHANGELOG.md`, `README.md`, `docs/updating.md`, `tests/install.test.sh`), cut from `origin/main` in a worktree on `release/v1.0.11`, because `qc-verdict` fails a head that carries a live dossier. This branch carries the pin (`.codeo/config.json`), the plan and the dossier, and `/codeo:close` opens its PR after the tag exists.
- **The version moves dry-run clean.** In a scratch worktree on `origin/main`: `1.0.10`→`1.0.11` then `1.0.9`→`1.0.10` on `README.md` and `docs/updating.md`, the same on `tests/install.test.sh` with `t_latest_installed_without_version` and `t_bad_version_usage` skipped, and the one ordering stub in `t_latest_is_highest_release` taken from `v1.0.11` to `v1.0.12` ("that stub takes the next higher version"). `bash tests/install.test.sh` and `bash tests/readme.test.sh` both ended `all cases passed`. `docs/dev-environment-sbx-evaluation.md:522` (`installed codeo v1.0.9`) is a historical transcript, not a latest-release example, and stays.
- **`## Unreleased` has six bullets (#206, #190, #192, #204, #195, #188), none for #211.** Two bullets are worded for the unreleased state and are wrong once released: #192's "The guard comes with the next release" and #204's "It reaches a project with its next plugin release and pin".
- **README audit.** Three read-only agents compared all 721 lines with the code; I re-read the code for the mismatches below. The six steps of *Your first workflow* and the Configuration table match except for M5. The rest is omissions (Q1).

**The mismatches (a statement the code contradicts):**

| | README | What the code does |
|---|---|---|
| M1 | l.38: `/codeo:doctor` checks bash, `jq`, `git` and `gh` | the `deps` check reports `jq, git, bash` (`scripts/doctor.sh`, `report ok deps`); `gh` is the `gh-auth` check |
| M2 | l.173: `ruleset` "is skipped" while a value is `TODO-set-me` | doctor prints `fail ruleset: skipped: …` and exits 1 (`scripts/doctor.sh`, the `ruleset` block); re-read in Task 4 |
| M3 | l.173: setup "refuses to overwrite a `config.json` that exists" | true except `--containers` (alone or with `--codename`), which runs on an existing config (`scripts/setup.sh` header, line 19) |
| M4 | l.206: `codename` and `plugin` are "written by hand; setup leaves them out" | `setup --codename <n>` writes `codename`; `--containers` writes `codename` and the `plugin.repo`/`plugin.ref` pin (`scripts/setup.sh`, `write_pin`); README l.288 already says so |
| M5 | l.340 (`/codeo:init`): a failed assignment is reported "and nothing else is recorded" | `skills/init/SKILL.md` steps 6.5 and 9: an `assignee-add failed` line under `## Notes`, its own commit, pushed; README l.338 says so itself |
| M6 | l.495: a project set up with `/codeo:setup` "has none and is never refused" | `/codeo:setup --containers` installs `role.sh` and overlays that call it (`scripts/containers.sh`, `templates/containers/.codeo/overlays/*.md`), and the plugin's own `hooks/home-guard.sh` denies edits in a `home`, `stale:?` or `stray` checkout |
| M7 | l.497: the refusal line "starts `/codeo:<skill> can't run here:` or says where the skill runs" | the `mismatch:<N>:<folder>` role (`.devcontainer/scripts/role.sh`, line 68) prints a third form |
| M8 | l.686: each pipeline skill owns "one dossier file under `.codeo/<issue>/`" | `issue` writes `.codeo/intake/<N>/issue.md` on the intake branch (`docs/skills.md`, the `/codeo:issue` section) |

**The omissions** (true statements the README leaves out), most of them about what the unreleased work added: the home-checkout edit guard and `CODEO_HOME_EDITS=allow` (#192); a bot token or an unresolved login refused at `/codeo:init` and `lock.sh take`, the ownership refusals at lock take, `lock.sh verify --override` and the lock's `user:` line (#195); `/codeo:cleanup`'s unexpanded-placeholder stop and its removal records, and `/codeo:cleanup` in the close step's next steps (#206); `setup --containers` and `--codename` in setup step 1, the extra requirements of a home clone, and the `codeo-init.sh` skip and fail outcomes (#190); a stash or an abandon removing you from the assignees; close refusing without a clear qc verdict; `environment.hooks.*` environment variables; updating moving a user-scope install along with a project-scope one; `release-checklist.md`, `skills-inventory.md` and `dev-environment-sbx-evaluation.md` missing from *More documentation*.

## Questions

### Q1 — The README audit found eight mismatches and a long list of omissions. What does the release PR fix?

**Why it matters:** acceptance criterion 1 says "every mismatch", and a mismatch is a statement the code contradicts. An omission is a true README that says less than the code does. Fixing omissions grows a five-file release PR into prose edits no test guards, and each one is a claim the next audit must re-check. Against that, #192, #195, #190, #204 and #206 are all in this release, and a README that ignores the edit guard, the owner checks and the container setup will send an adopter into refusals it never explains.

**Options:**
- **Mismatches only (M1-M8).** The omissions go into one issue for the next release.
- **Mismatches plus the omissions the unreleased work introduced** (#190, #192, #195, #204, #206: the edit guard, the identity and ownership refusals, `setup --containers`, `/codeo:cleanup`'s records). The older omissions go into one issue for the next release.
- **Mismatches plus every omission**, as #182 did for v1.0.10.

*Recommendation:* the second. The v1.0.11 changes are the ones no README reader has met yet, so they are the ones worth explaining at the release that ships them; the older omissions are no worse than they were at v1.0.10. I cannot file the follow-up issue from this checkout, so the plan records it as a `## Notes` line for `/codeo:triage`.

**Answer:**
Go with the recommendation: mismatches M1-M8 plus the omissions the unreleased work introduced (#190, #192, #195, #204, #206); the older omissions go into one issue for the next release (engineer, in the conversation, 2026-11-27; recorded here by the skill).

### Q2 — Which entries does the `## v1.0.11` changelog section get, and how are the two "next release" bullets reworded?

**Why it matters:** criterion 2 requires an entry for each of #188, #190, #192, #195, #204 and #206, and all six exist. #211 (CI runs the test files in parallel and cancels superseded pull request runs) merged after v1.0.10 and has none; the Release notes are this section only. #192's and #204's bullets still say they arrive "with the next release", which is false in the section that ships them.

**Options for #211:** a bullet (it changes what a contributor sees when `tests/run.sh` runs: `CODEO_TEST_JOBS`, parallel files) · no bullet (CI only, nothing the plugin does changes) · no bullet and criterion 2 stays as written.
**Options for the two bullets:** reword to the released state ("comes with this release" / "reaches a project with its pin on this release") · leave them as written.

*Recommendation:* a one-line #211 bullet ending `Nothing the plugin does changes (#211).`, and reword the two bullets, since the release PR is the only place that can; the header lines (`Config schema`, `Shared state`, `Safe to bump mid-workflow`) are re-read against the diff since `v1.0.10` of `scripts/`, `lib/` and `hooks/` in Task 7 and change only if it requires it.

**Answer:**
Go with the recommendation: a one-line #211 bullet ending `Nothing the plugin does changes (#211).`, and #192's and #204's bullets reworded to the released state (engineer, in the conversation, 2026-11-27; recorded here by the skill).

## Notes

`superpowers:brainstorming` ran before these questions. The role check (`role.sh --check plan`) exited 0. The overlays `plan-shape`, `proof-of-done` and `wiki-rules` are not set (exit 3), so the generic shape and the default proof apply. No invariants document, no shared environment, no `wiki` module and no exclusive resources are configured, so no task carries `Needs lease:` and nothing is leased. The lock's host is `container`, so the engineer-host tasks (merges, tag push, rebuild) need no shell question: each command is a single neutral command. Steps 6 and 7 (`engineering:system-design`, `engineering:architecture`) do not apply: no new component and no technology choice.

Calls I made without a question:
- **Two pull requests**, as for v1.0.10 and as the issue says: the release PR from `release/v1.0.11` in a worktree cut from `origin/main`, then the pin from this branch once the tag exists. The tag is lightweight and the engineer's own action; the agent publishes the Release only after being told it is pushed.
- **The version moves** are the dry-run's, not the checklist's prose: every `1.0.10` to `1.0.11` and then every `1.0.9` to `1.0.10`, in that order, with the three skipped stubs and the one ordering stub taken to `v1.0.12`.
- **The release date** is the UTC date the release PR opens (`gh pr view --json createdAt`), corrected before merge if it merges on a later day.
- `tests/replay.test.sh` is not run: no golden directory.
- `main` may move before Task 1: the task re-reads `## Unreleased` and re-runs the README comparison for any file the new commits touched.

Loose ends found while planning, for `/codeo:triage` (no issue number: `/codeo:issue` refused in this checkout):
- Later work: `/codeo:doctor`'s `gh-scopes` and `board` remedies do not work where `gh` authenticates from `GH_TOKEN` (the sandbox proxy token). `gh auth refresh -s project` fails with "The value of the GH_TOKEN environment variable is being used for authentication", and `board` then says "not readable: 3" with no hint that the missing scope is the cause. Wanted: name the remedy that works there (add the scope on the host, then `sbx secret set github --sandbox <name> -t "$(gh auth token)"`) and name the scope as the likely cause. File it with `/codeo:issue` in a home checkout.
- Later work: `/codeo:doctor`'s `board` check reads `board.projects[]` only, so a config with just `board.gateProject` reports "every configured project is readable" while probing nothing (`scripts/doctor.sh`, the `board` block). File it with `/codeo:issue` in a home checkout.
- Later work: the README omissions Q1 leaves out, if the answer is the first or second option. File them as one issue with `/codeo:issue` in a home checkout.

## Outcome

_Pending — written at the hand-off._

## Log

- 2026-11-27 — Q1-Q2 raised · cost: 4m · fable-5-2 138k in + 1.2M cached / 9k out · sonnet-5-5 509k in + 7M cached / 53k out
