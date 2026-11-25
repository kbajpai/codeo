# Issue (new) — session title shows when the session started

| | |
|---|---|
| Working title | Session title: show when the session started, as a timestamp |
| Updated | 2026-11-25 |

## Where this stands

Q&A pass, Q1-Q4 open.

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
