# new-release-and-pin — issue

| | |
|---|---|
| Issue | not filed yet |
| Updated | 2026-11-27 |

## Where this stands

Request: "Create a release & bump the plugin." Questions open: 1, 2, 3.

## Problem statement

The latest release is v1.0.10 (tagged 2026-11-26) and this project pins it in `.codeo/config.json`
(`plugin.ref`). Since then #188, #190, #192, #195, #204, #206 and #211 have merged to `main`, and
`CHANGELOG.md` collects them under `## Unreleased` — including a `Shared state` change (#195: the
`| Owner |` row of `init.md`, the lock's `user:` line, the `override:` line; #206: the
`cleanup/removed/<N>.md` intake file). None of it reaches this project's sessions or dev containers
until it is cut as a release (README check, version bump and changelog PR, clean-clone test, tag,
GitHub Release, per `docs/release-checklist.md` steps 6-8) and the project's pin moves to the new tag
in a second PR, as #182 did for v1.0.10.

No issue is In progress on the board right now; #207 is Ready, the rest of the open issues are in
Backlog.

## Questions

1. **Version.** Every earlier release was a patch bump. This one adds features (#190 reusable
   containers and `/codeo:setup --containers`, #192 the home-checkout edit guard, #195 strict
   identity) and changes shared state. v1.0.11 (patch, as before) or v1.1.0 (minor)?
   **Answer:**

2. **Gating.** Release what is on `main` now, or wait for named issues first — for example #205
   (the #190 and #192 QC leftovers, guard bypasses) or #207 (Ready)? If waiting, the list is fixed
   at filing, as in #182.
   **Answer:**

3. **Scope as in #182?** Same shape as last time: read `README.md` in full against the code at the
   release commit and fix every mismatch in the release PR; the pin to the new tag is its own second
   PR; done means this project's dev container and sessions run the new version. Anything to add or
   drop — e.g. does "bump the plugin" also mean any pin written by the #190 templates or
   `examples/csharp-angular/`, or only this project's `.codeo/config.json`?
   **Answer:**

## Log

- 2026-11-27 — dossier opened from `/codeo:issue "Create a realease & bump the plugin"`.
