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
  log/events.log       script-written event trail (lock/commit/health — gitignored)
  locks/               runtime locks (git.lock, build.lock, …)
scripts/
  lib/lock.sh          shared atomic-mkdir lock + event-log helpers (sourced, not run)
  team-commit.sh       lock → gate → stage only your paths → commit "[role] …" → unlock
  team-check.sh        the green gate (EDIT for your stack)
  team-exclusive.sh    run build/e2e/etc. under a lock so heavy ops never collide
  team-health.sh       agent liveness + stale-task + deadlock report
  team-sync.sh         board↔log drift report (logs are authority; lead reconciles)
  team-lint-log.sh     validate structured @role handoff lines
tests/run.sh           self-contained test suite for the scripts (no framework needed)
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

## Coordination helpers
```bash
scripts/team-health.sh                  # who's active/idle/stale · stale tasks · deadlock
scripts/team-sync.sh                    # where board.md drifts from the logs (lead fixes it)
scripts/team-sync.sh --strict           # exit 1 on drift (use in a gate)
scripts/team-resume.sh                  # rebuild state from logs + git after a crash/restart
scripts/team-metrics.sh                 # throughput per role + board progress → .team/metrics.md
scripts/team-backup.sh [restore [file]] # snapshot/restore .team/ (git isn't the only copy)
scripts/team-lead-claim.sh <role>       # fallback-lead: record the acting lead
scripts/team-lint-log.sh                # check @role handoff lines are well-formed
scripts/team-commit.sh --dry-run <role> "msg" <paths>   # run gate + preview, don't commit
bash tests/run.sh                       # run the script test suite (39 checks)
```
Heartbeats and stale-task timeouts are tunable: `TEAM_ACTIVE_SECS` (default 900) and
`TEAM_STALE_SECS` (default 1800). Lock/commit/health events are appended to
`.team/log/events.log` (gitignored). `.team/memory.md` carries decisions across runs.
Tip: wire `team-health.sh` into a Claude Code `SessionStart` hook to auto-report team
state when an agent (re)starts.

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

## GUI — one window instead of 4 terminals (optional)
Don't want to hop between terminals? `gui/` is a tiny local web console ("TEAM // CONSOLE"):
it runs all four `claude` sessions in colour-coded panels and lets you chat + fire the common
commands (Kickoff, `status`, Enter, `y`, Esc, ^C, restart) from buttons. A live **vitals
strip** reads `.team/` every few seconds and shows board progress (done/doing/blocked/todo)
and each agent's health (active/idle/stale) — so you see the whole team at a glance.
```bash
cd gui && npm install && cd ..
node gui/server.js            # → http://localhost:4173
```
See `gui/README.md` for details.

## License
**Private use only** — see [`LICENSE`](LICENSE). Personal, non-commercial use is allowed;
distribution or commercial use requires written permission.
