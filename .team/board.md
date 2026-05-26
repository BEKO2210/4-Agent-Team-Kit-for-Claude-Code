# Board — single source of truth (owned by LEAD)

The lead fills this from the human's goal and keeps it in sync with the logs.
State values: `todo` · `doing` · `blocked` · `done`.

| #  | Task                                   | Owner    | State | Notes |
|----|----------------------------------------|----------|--------|-------|
| 1  | _example: the lead splits the goal here_ | —        | todo   | —     |

## Milestones (optional grouping)
- **M1** — …
- **M2** — …

## Conventions
- Highest priority / unblocks-others first.
- One agent per row at a time. Cross-domain work = a new row + a `@role` handoff.
- A row is `done` only when its owner proved it (test/build/etc.) and logged the proof.
