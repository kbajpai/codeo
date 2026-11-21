# Issue (new) — issue

Requested by the engineer: "Create an issue to release a new version for codeo".

## Where this stands

Questions open; no draft yet. The latest release is v1.0.7 (2026-11-18); `.claude-plugin/plugin.json` says `1.0.7` and `.codeo/config.json` pins `plugin.ref` to `v1.0.7`. `CHANGELOG.md` `## Unreleased` on `origin/main` (2e02100) holds #108, #102, #112, #133, #126, #131 (with #123, #125) and #122. In flight now: #143, #144, #145 (all at `/codeo:plan`). Backlog: #138. Previous release issues: #61, #75, #100 (#100 gated on five named issues and pinned in a second PR).

## Questions

1. **Version number.** Earlier releases have all been patch bumps, #100 explicitly "even though #70 adds a skill". This one adds the `codeo` host command (#133) and a new optional config key `issue.priority` (#102). v1.0.8 (patch, as before) or v1.1.0?
   *Recommendation:* v1.0.8, keeping the convention.

2. **What it waits for.** #143 fixes `codeo rm` paths that can remove unpushed work or print false advice — in the command #133 adds and this release would ship for the first time. #144 and #145 are wording and consistency fixes. Options: (a) release now from `main`, (b) wait for #143 only, (c) wait for #143, #144 and #145, as #100 waited for its five.
   *Recommendation:* (c) — #143 at least, so the first release of `codeo rm` is not the unsafe one; #144 and #145 are already in flight, so one version carries them all. The gating list is fixed at filing; anything started later ships after.

3. **Pin.** Move this project's own `plugin.ref` to the new tag in a second pull request, as #75 and #100 did? (This is also what makes #131's sandbox-lock change visible in a real sandbox — its changelog line says so.)
   *Recommendation:* yes.

## Outcome

## Log

- 2026-11-21 — questions 1-3 raised
