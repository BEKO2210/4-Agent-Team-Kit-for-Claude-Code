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
- **Handoff** cross-domain work: `@role <ask>` in your log; they pick it up next tick.
- **Blocked?** Log `BLOCKED #id — @role/<reason>` and take another item.

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

## Concurrency variants (pick one; shared-tree is the default)
- **Shared tree (default):** all 4 in the same checkout; serialize via the commit
  lock. Simplest for "4 terminals, one repo".
- **Worktrees:** `git worktree add ../<role>` per agent; share `.team/` by committing
  + pulling often. More isolation, more merge overhead.
- **Clones:** one clone per agent, lead integrates via PRs. Most isolation, slowest loop.
