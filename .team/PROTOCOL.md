# Team Protocol — read once, follow always

Four Claude Code agents share **one repo / one working tree / one branch** and
coordinate **only** through files in `.team/`. There is no other channel.

You are exactly one role: **lead · backend · frontend · quality**.

## The 5 rules
1. **Stay in your lane.** Edit only the paths your role owns (`roles/<you>.md`).
   Need something outside it? Hand it off — never reach into another lane.
2. **One writer per file.** Write only files you own: your log `log/<you>.md` is
   yours; the **board** is the lead's. Read everyone's, write only yours.
3. **Serialize commits.** Never `git commit` by hand. Always:
   `scripts/team-commit.sh <you> "message" <your-paths…>`
   It takes the commit lock, runs the gate, stages **only the paths you pass**,
   commits as `[<you>]`, and releases. **Never `git add -A`.**
4. **Green before commit.** `scripts/team-check.sh` must pass. Never commit red.
5. **Only the lead pushes.** Others commit locally; the lead integrates + pushes.

## Exclusive operations (build · e2e · dev server · migrations)
Heavy commands that touch a shared resource (build output, a port, the DB) corrupt
each other if run at the same time. Wrap them so only one runs repo-wide:
`scripts/team-exclusive.sh <you> build -- <command…>`

## How work flows
- The **lead** turns the human's goal into rows on `board.md`
  (`# · task · owner · status · notes`), sets owners, posts a kickoff line.
- You **claim** an item: log `CLAIM #id` (lead reflects owner + `doing` on the board).
- You **do** it in your paths → `team-commit.sh` → log `DONE #id — <proof>`.
- **Handoff** cross-domain work — use the structured form (see § Handoffs) so it can be tracked.
- **Blocked?** Log `BLOCKED #id — @role/<reason>` and take another item.

## Board vs logs — who is the source of truth
The **board is the canonical human-facing view**; the **logs are the authority for
automation**. Your `log/<you>.md` is an append-only event stream (`CLAIM`/`DONE`/`BLOCKED`
+ `#id`). The board is a projection the lead keeps in sync with those events. When the two
disagree, the logs win and the lead reconciles the board — `scripts/team-sync.sh` reports
exactly where they drift. So always emit the event in your log first; the board follows.

## Handoffs — structured, one line, in your log
Cross-domain asks must be parseable, not free prose. Use:
`HH:MM · <you> · 🤝 HANDOFF → @<role> · #<id> · needs:<artifact> · <what & why>`
- `→ @<role>` (required) — who picks it up · `#<id>` (required) — the board row it serves.
- `needs:<…>` / `blocks:<id>` (optional) — required inputs / what it unblocks.
`scripts/team-lint-log.sh` validates handoff lines; a malformed one fails the check.

## Health, stale tasks, deadlock
- `scripts/team-health.sh` reports each agent's liveness (heartbeat = your last log append),
  flags **stale tasks** (a `doing` row whose owner has been silent past the timeout), and
  signals **deadlock** (work remains but everything is `blocked`).
- A **stale task** is reset by the **lead** to `todo`/`blocked` (timeout-and-requeue, never
  delete); the owner must re-`CLAIM` before resuming. **Never** auto-reset a `done` item.
- On a **deadlock** signal the lead breaks the jam (re-scope, unblock, or re-assign).

## Log format — `log/<you>.md`, append only, newest at bottom
`HH:MM · <you> · <emoji> <message>` — one line per meaningful step
(claim / start / done / blocker / handoff / finding). Report as you go.
**Never edit or delete another agent's lines.** Append with `>>`, not an editor,
to avoid write races.

## "status" / any nudge = continue autonomously
Re-read the board + the other logs, then **do the next unblocked thing** — don't
just report. Unblock others first. Keep the gate green.

## DONE-CHECK — when to stop
If all your board items are `done`, no open `@you` handoff, and the gate is green:
log `✅ <you> done — standing by` and idle until a new directive. **Quality** owns
the final full-gate sign-off before the lead calls it shipped.

## Resilience
- **Memory:** `.team/memory.md` holds decisions that must survive across runs. The lead
  curates it; everyone reads it at kickoff.
- **Fallback lead:** if `team-health.sh` shows the lead `stale`, **quality** claims the
  role via `team-lead-claim.sh` so integration/push never stalls. Exactly one acting lead.
- **Backup:** `team-backup.sh` snapshots `.team/` so git is not the only copy of the
  coordination state. Never force-push the shared branch without team agreement.

## Concurrency variants (pick one; shared-tree is the default)
- **Shared tree (default):** all 4 in the same checkout; serialize via the commit
  lock. Simplest for "4 terminals, one repo".
- **Worktrees:** `git worktree add ../<role>` per agent; share `.team/` by committing
  + pulling often. More isolation, more merge overhead.
- **Clones:** one clone per agent, lead integrates via PRs. Most isolation, slowest loop.
