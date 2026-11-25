# Issue #171 — init

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/171 |
| Branch | `docs/make-readme-complete-easy-follow` |
| Updated | 2026-11-25 |

## Where this stands

Initialized: branch `docs/make-readme-complete-easy-follow` cut off `origin/main` at `6e6628336c9bd40037c1cd7c80c8694f0ecddc21`, and pushed. Next step: `/codeo:plan` in the issue's container.

## Questions

None.

## Outcome

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/171 — Make the README a complete, easy-to-follow guide to installing, setting up, using and troubleshooting codeo |
| State | open · labels `documentation` |
| Branch | `docs/make-readme-complete-easy-follow` off `main` at `6e6628336c9bd40037c1cd7c80c8694f0ecddc21` |
| Board | Ready → In progress |

**Problem.** The README has sections for installing, setting a project up, a first workflow, updating, uninstalling and troubleshooting, but does not read as a guide a first-time user can follow start to finish. Install and update text buries the common path under replace-and-restore detail, the first workflow is a summary list, the project config is never described as a whole, and troubleshooting covers only `/codeo:doctor` checks and two installer errors. The issue asks for a more informative, easier-to-follow README for a first-time user in a new project.

**Acceptance criteria** — verbatim from the issue, unchecked:
- [ ] The README opens with a short summary and a table of contents, and a "start here" path from install to a merged pull request.
- [ ] Install, update/replace/restore and uninstall are separate sections, the common install first.
- [ ] The first workflow walks through all six steps with the command, what it asks, the file it writes and what comes next.
- [ ] A section describes every key of `.codeo/config.json` that the plugin reads, which are optional, and shows an example.
- [ ] Troubleshooting has entries for a role-guard refusal, a stuck or foreign lock, an interrupted step, and a card that is not Ready, each with symptom, cause and fix, besides the existing doctor entries.
- [ ] Every command, path and link the README names exists and is spelled as in the repo.
- [ ] `bash tests/run.sh` passes, with any wording pins updated.

**Out of scope.** The #170 items (the `codeo` host command installs separately, macOS `flock` and keychain) and #163's README wording fixes; rewriting `.devcontainer/README.md`, `docs/skills.md` or other reference pages beyond links and any moved detail; changing how codeo behaves.

**Open at intake.** None. The issue records the decisions: the reader is a first-time user in a new project; the README may be restructured with the wording-pinning tests updated; containers link to `.devcontainer/README.md`; reference detail may move to `docs/`.

**Overlap to watch.** `inflight.sh` shows #168 (release v1.0.9, in implement, live on `codeo-168`) with `README.md` in its footprint, since it bumps the example version tags. #171 restructures that file, so whichever merges second will conflict on the install examples. #170 (Ready, not started) also edits the README.

## Log

- 2026-11-25 — initialized: branch docs/make-readme-complete-easy-follow off main at 6e6628336c9bd40037c1cd7c80c8694f0ecddc21 · 1m · sonnet-5-5 135k in + 491k cached / 4k out
