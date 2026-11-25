# Issue (new) — session title shows when the session started

| | |
|---|---|
| Working title | Session title: show when the session started, as a timestamp |
| Updated | 2026-11-25 |

## Where this stands

Draft at the review gate; Q1-Q7 answered.

## Questions

**Problem as understood.** `.devcontainer/scripts/session-title.sh` titles a Claude Code session `codeo [home] · <id8>` / `codeo [#<N>] · <id8>`, where `<id8>` is the first eight characters of the session id (not random). Looking at the list of sessions, the title does not say when each one started, so the newest cannot be picked out by name. The engineer asks for a `<year><month><day><hour><min>` timestamp in the title.

### Q1. Replace the session-id suffix, or keep it next to the timestamp?
The id suffix is what ties a title to `claude --resume <id>` and the transcript file; dropping it loses that.

### Q2. Which moment does the timestamp record?
When the session was created, fixed for its life (a lock change or a resume keeps it), or when the hook last titled it?

### Q3. Which timezone?
UTC (containers usually run in UTC), or the container's local time zone?

### Q4. Exact format?
`YYYYMMDDHHMM` as asked (`202611251842`), or a readable form such as `2026-11-25 18:42`?

**Answers (2026-11-25):** Q1: keep the session id, prefixed with a 2-digit hex number. Q2-Q4 (moment, UTC, `YYYYMMDDHHMM`) were answered, then superseded by Q5.

### Q5. What does the hex number count?
**Answer:** it replaces the timestamp, so the title is `codeo [home] · 1A-2cb71525`.

### Q6. What scope does the counter cover?
**Answer:** per container.

### Q7. Which sessions get a new number, and what happens after FF?
**Answer:** every new session id gets a new number (fresh start, /clear, fork); a resume keeps its number; after FF it wraps to 00.

## Draft

Title: Session title: prefix the session id with a per-container hex sequence number (`codeo [home] · 1A-2cb71525`)
Type: none (user-owned repository has no Issue Types). Labels: `enhancement`, `priority: low` (rubric "low": polish nobody is waiting on).
Body: see `body.md`.
