# Issue #182 — issue

Requested by the engineer: "Create a new release to the point where all issues that are in progress as of now & pin the codeo plugin. Also, check the @README.md is up to date, if not then update."

## Where this stands

Questions open; no draft yet. The latest release is v1.0.9 (tagged 2026-11-24, GitHub Release 2026-11-25); `.codeo/config.json` pins `plugin.ref` to `v1.0.9` (#175). Since v1.0.9, `origin/main` has merged #175 (pin), #178 (#171, README restructure) and #180 (#170, host `codeo` command docs); `CHANGELOG.md` `## Unreleased` collects #171 so far. In progress on board 3 today: #173, #176, #177, #179. Also open, not in progress: #181. Previous release issues: #61, #75, #100, #146, #168, each gated on a fixed list and pinned in a second PR. `docs/release-checklist.md` step 6 already moves the README's installer examples to the new version. This clone's local `main` is behind `origin/main` (at 4c32c0b).

Restated problem: once the four issues in progress today (#173, #176, #177, #179) have closed, cut the next release from `main`, check that `README.md` matches what that release does and fix what does not, and move this project's pin to the new tag. The gating list is fixed at filing: an issue filed or started later, #181 included, ships in a later release.

## Questions

1. **Version number.** Every release so far has been a patch bump, even ones adding a host command (#146) or a role (#168). This one carries the README restructure (#171) and, through #176, macOS support for the sbx sandbox. v1.0.10 (patch, as before) or v1.1.0?
   *Recommendation:* v1.0.10, keeping the convention.

2. **Gating list.** "In progress as of now" read as #173, #176, #177 and #179. #181 (open, not In progress) and anything filed later, including leftovers these four produce, wait for the next release. A gating issue closed without merging (stashed or abandoned) counts as closed. Right? Note #176 is the largest of the four (macOS work, may need a Mac to verify), so it sets the pace.
   *Recommendation:* yes, the four, fixed.

3. **What "check README is up to date" means.** Options:
   a. Only the version strings, which checklist step 6 already moves.
   b. A full read of `README.md` against the code at the release commit (commands, paths, output examples, config keys, links to `docs/updating.md` and `docs/home-checkout.md`), with every mismatch fixed in the release PR.
   c. As b, but mismatches filed as their own issues and the release ships without waiting.
   *Recommendation:* b. The README was just restructured (#171) and three of the four gating issues change README text, so the check is worth doing after they land; fixing in the release PR keeps the released README accurate.

4. **Pin.** Move this project's `plugin.ref` to the new tag in a second pull request, as #75, #100, #146 and #168 did?
   *Recommendation:* yes.

5. **Priority** (`issue.priority` is on). Rubric: nothing is blocked on it and there is no defect without a workaround, so `medium` (the default) or `low`.
   *Recommendation:* `medium`.

## Outcome

Filed as #182 (2026-11-25).

## Log

- 2026-11-25 — questions 1-5 raised
- 2026-11-25 — answers received: 1 v1.0.10; 2 yes; 3 yes (read as option b); "4. Medium" read as the priority; pin taken as yes (asked for in the request). Draft written for the review gate

## Answers (engineer, 2026-11-25)

1. v1.0.10. 2. Yes. 3. Yes (option b). 4. Medium (priority). Pin: yes.

## Draft

**Title:** Release v1.0.10 once #173, #176, #177 and #179 are closed, check the README, and pin codeo to it
**Labels:** `enhancement`, `priority: medium` (rubric: nothing blocked, no defect). No type (`issue-types` prints nothing).
Body: `body.md` in this directory.
- 2026-11-25 — approved and filed as #182
