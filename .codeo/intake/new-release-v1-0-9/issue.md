# Issue new-release-v1-0-9 — issue

Requested by the engineer: "Create an issue to create a release after all current issues are closed. Any issues after the release get another issue."

## Where this stands

Questions open; no draft yet. The latest release is v1.0.8 (2026-11-22); `.codeo/config.json` pins `plugin.ref` to `v1.0.8` (#159). Since v1.0.8, `main` has merged #159 (pin), #160 (#154), #162 (#152), #164 (#157) and #167 (#161); `CHANGELOG.md` `## Unreleased` collects #154, #152 and #157. Open issues now: #163 and #166, both In progress on the board. Previous release issues: #61, #75, #100, #146 (each gated on a fixed list, #100 and #146 pinned in a second PR).

Restated problem: once every issue open today (#163, #166) has closed, cut the next release from `main` and move this project's pin to it. The gating list is fixed at filing: any issue filed or started after this one ships in a later release, tracked by its own release issue.

## Questions

1. **Version number.** Every release so far has been a patch bump, #146 explicitly "even though #133 adds a host command". Since v1.0.8, #152 adds a role (`stray`), refuses the lock skills in `home`, and adds the tracking comment and `codeo-track.sh`. v1.0.9 (patch, as before) or v1.1.0?
   *Recommendation:* v1.0.9, keeping the convention.

2. **Pin.** Move this project's own `plugin.ref` to the new tag in a second pull request, as #75, #100 and #146 did?
   *Recommendation:* yes.

3. **Gating list.** "All current issues" read as #163 and #166 — the only open issues today, and this release issue itself excluded. An issue filed later (including leftovers #163 or #166 produce) waits for the next release. Right?
   *Recommendation:* yes.

## Outcome

## Log

- 2026-11-25 — questions 1-3 raised

## Answers (engineer, 2026-11-25)

1. v1.0.9. 2. yes, a second pin PR. 3. yes, gate on #163 and #166.

## Draft

**Title:** Release v1.0.9 once #163 and #166 are closed, and pin codeo to it
**Labels:** `enhancement` (as #146). No type (`issue-types` prints nothing). No priority.
Body: `body.md` in this directory.

## Log

- 2026-11-25 — answers 1-3 received; draft written for the review gate
