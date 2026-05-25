# 4-Agent Team Kit for Claude Code

A **task-agnostic** scaffold that lets four Claude Code sessions work one repo together,
coordinating only through plain files. Copy it into any repo, open 4 terminals, paste the
prompts, and hand the lead your goal. No task is baked in — you supply it at kickoff.

> Distilled from a real multi-agent run, with the friction designed out (see *Why* below).

## What's in here
```
.team/
  PROTOCOL.md          the rules (read-only, never changes)
  board.md             the single work board (the lead owns it)
  roles/{lead,backend,frontend,quality}.md   each agent's lane + definition-of-done
  log/{lead,backend,frontend,quality}.md     per-agent append-only logs (no write races)
  locks/               runtime locks (git.lock, build.lock, …)
scripts/
  team-commit.sh       lock → gate → stage only your paths → commit "[role] …" → unlock
  team-check.sh        the green gate (EDIT for your stack)
  team-exclusive.sh    run build/e2e/etc. under a lock so heavy ops never collide
PROMPTS.md             the 4 copy-paste terminal prompts
```

## Setup (once per repo)
```bash
# from your repo root:
cp -r /path/to/workflow/.team .team
cp -r /path/to/workflow/scripts/* scripts/    # or wherever you keep scripts
chmod +x scripts/team-*.sh
$EDITOR scripts/team-check.sh                  # set your real lint+test command
$EDITOR .team/roles/*.md                       # point each lane's globs at YOUR repo
printf '\n.team/locks/*.lock\n' >> .gitignore  # don't commit runtime locks
```

## Run it
1. Open **4 terminals** in the repo, run `claude` in each.
2. Paste the matching block from `PROMPTS.md` (Lead / Backend / Frontend / Quality).
3. In the **Lead** terminal, replace `<<< paste … >>>` with your goal.
4. The lead fills the board and pings the others; they start working their lanes.
5. Nudge any terminal with **`status`** to push it forward; it continues autonomously.
6. Done when every board row is `done`, quality signs the full gate, and the lead pushes.

## The rules in one breath
Stay in your lane · write only your own files · commit only via `team-commit.sh`
(never `git add -A`) · green before commit · only the lead pushes · heavy ops under a lock ·
log every step · `status` = do the next thing, don't just report.

## Why it's built this way (lessons baked in)
- **Per-agent logs** instead of one shared log → no "file changed since read" write races.
- **`team-commit.sh`** automates the commit lock (atomic acquire, stale-lock break, auto
  release) so nobody forgets to unlock and two agents never commit at once.
- **One board, lead-curated** replaces overlapping roadmap/sync/phase files.
- **`team-exclusive.sh`** stops a `build`/`e2e` from crashing another agent's dev server.
- **Shared tree + serial commits + lead-only push** avoids PR/CI cancel storms; switch to
  worktrees or clones (see PROTOCOL.md) only if you need stronger isolation.
- **Explicit path ownership** per role keeps edits from clobbering each other.

## Customize
- **Roles/domains:** rename and re-scope `roles/*.md` for your repo (e.g. mobile/infra/docs).
  Fewer than 4 areas? Merge roles. More? The model extends — just add a role file + a prompt.
- **Gate:** `scripts/team-check.sh` is the contract for "green". Keep it fast.
- **Push policy:** default is lead-only direct push to one branch; switch to PRs in `roles/lead.md`.
