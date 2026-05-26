<div align="center">

<img src="assets/readme/hero.svg" alt="TEAM // CONSOLE — the 4-Agent Team Kit for Claude Code" width="100%" />

### Four Claude Code sessions. One repository. Coordinated through plain files.

A **task-agnostic** scaffold that lets four Claude Code agents build one repo together —
no database, no message broker, no framework. Coordination lives entirely in a `.team/`
folder of Markdown and a handful of POSIX shell scripts.

<p>
  <a href="https://github.com/BEKO2210/4-Agent-Team-Kit-for-Claude-Code/actions/workflows/gate.yml"><img alt="Gate workflow state" src="https://img.shields.io/github/actions/workflow/status/BEKO2210/4-Agent-Team-Kit-for-Claude-Code/gate.yml?label=gate"></a>
  <a href="LICENSE"><img alt="License: Private Use" src="https://img.shields.io/badge/license-Private%20Use-e8a33d"></a>
  <img alt="Built for Claude Code" src="https://img.shields.io/badge/built%20for-Claude%20Code-5b8cff">
  <img alt="Core dependencies: zero" src="https://img.shields.io/badge/core%20deps-0-2ea043">
  <img alt="GUI: Node.js" src="https://img.shields.io/badge/GUI-Node.js-3c873a">
</p>

<a href="#quickstart"><b>Quickstart</b></a> ·
<a href="#usage"><b>Usage</b></a> ·
<a href="#architecture"><b>Architecture</b></a> ·
<a href=".team/PROTOCOL.md"><b>Protocol</b></a> ·
<a href="ROADMAP.md"><b>Roadmap</b></a>

</div>

---

## Contents

- [Why this exists](#why-this-exists)
- [Features](#features)
- [Preview](#preview)
- [Quickstart](#quickstart)
- [Usage](#usage)
- [Architecture](#architecture)
- [Project structure](#project-structure)
- [Quality and security](#quality-and-security)
- [Roadmap](#roadmap)
- [Contributing](#contributing)
- [License](#license)
- [Acknowledgements](#acknowledgements)

---

## Why this exists

Running several AI coding agents on one repository usually ends in chaos: they overwrite
each other's files, race on commits, and lose track of who is doing what. The common fix
is a heavyweight orchestration framework with its own runtime and learning curve.

This kit takes the opposite path. Coordination is reduced to its primitives — a **board**,
per-agent **logs**, file **locks**, and a **green gate** — and each primitive is implemented
with nothing more than the file system and Git. The result is a coordination *protocol*,
not a framework: copy it into any repo, open four terminals, and the agents stay in their
lanes, serialize their commits, and never ship red.

**Who it's for**

- Developers who want to drive a small team of Claude Code agents on a real codebase.
- Anyone curious how multi-agent coordination works without framework lock-in.
- Teams that need coordination with **zero external infrastructure**.

> [!NOTE]
> This is a coordination scaffold, not an autopilot. You supply the goal; the agents do the
> work within the rules in [`.team/PROTOCOL.md`](.team/PROTOCOL.md).

## Features

| | Feature | What it does |
|---|---|---|
| 🗂️ | **File-based coordination** | All state lives in `.team/` (board, logs, roles, locks) — readable, auditable, Git-versioned. No services to run. |
| 🔒 | **Atomic commit serialization** | `team-commit.sh` takes an atomic `mkdir` lock, runs the gate, stages only your paths, commits as `[role] …`. Never `git add -A`. |
| ✅ | **Green gate** | `team-check.sh` must pass before any commit — "never commit red." Edit one file to match your stack. |
| 🫀 | **Health, stale-task & deadlock detection** | `team-health.sh` reports each agent's liveness, flags tasks stuck `doing`, and signals when everything is blocked. |
| 🔁 | **Board ↔ log reconciliation** | `team-sync.sh` treats the append-only logs as the source of truth and reports where the board has drifted. |
| ♻️ | **Crash recovery & memory** | `team-resume.sh` rebuilds state from logs + Git; `.team/memory.md` carries decisions across runs. |
| 🛟 | **Resilience** | Fallback-lead (`team-lead-claim.sh`) and `.team/` snapshots (`team-backup.sh`) so a stalled lead or a bad push isn't fatal. |
| 🌿 | **Stronger isolation (optional)** | `team-worktrees.sh` gives each agent its own Git worktree + branch; the lead integrates by merge. |
| 🖥️ | **Optional live console** | A tiny local web UI (`gui/`) runs all four sessions in one window with a live vitals strip. |
| 🔌 | **Optional MCP server** | `mcp/` exposes the team state (board, logs, memory, health, metrics) as read-only Model Context Protocol resources for any MCP client. |
| 🧪 | **Tested in CI** | A self-contained Bash test suite (`tests/run.sh`, currently 58 checks) runs on every push via [`.github/workflows/gate.yml`](.github/workflows/gate.yml) — no test framework required. |

## Preview

The optional GUI — **TEAM // CONSOLE** — runs all four agents in one window and shows a live
vitals strip (board progress and each agent's health) derived from `.team/`.

![TEAM // CONSOLE: four colour-coded agent terminals with a live vitals strip showing board progress and per-agent health](docs/console.png)

Launch it locally with [`node gui/server.js`](#optional-the-gui) — see [Usage](#usage).

## Quickstart

> [!IMPORTANT]
> Prerequisites: **Bash**, **Git**, and the **[Claude Code](https://claude.com/claude-code) CLI**.
> The optional GUI additionally needs **Node.js** (18+).

**1. Drop the kit into your repo**

```bash
# from your repo root
cp -r /path/to/this-kit/.team .team
cp -r /path/to/this-kit/scripts/* scripts/
chmod +x scripts/team-*.sh scripts/lib/*.sh
printf '\n.team/locks/*\n.team/log/events.log\n.team/state/\n.team/backups/\n.team/metrics.md\n' >> .gitignore
```

**2. Point the gate and lanes at your project**

```bash
$EDITOR scripts/team-check.sh     # set your real lint + test command
$EDITOR .team/roles/*.md          # point each lane's globs at YOUR repo
```

**3. Verify the scripts work**

```bash
bash tests/run.sh                 # the script test suite (58 checks at last count); all should pass
scripts/team-health.sh            # prints a team-health report
```

## Usage

**Run the team (four terminals)**

1. Open **4 terminals** in the repo and run `claude` in each.
2. Paste the matching block from [`PROMPTS.md`](PROMPTS.md) — Lead, Backend, Frontend, Quality.
3. In the **Lead** terminal, replace `<<< paste … >>>` with your goal.
4. The lead fills the board and pings the others; they start working their lanes.
5. Nudge any terminal with `state` to push it forward; it continues autonomously.
6. Done when every board row is `done`, quality signs the gate, and the lead pushes.

> [!TIP]
> `state` means *do the next thing*, not *report*. A nudged agent re-reads the board and
> the other logs, unblocks others first, and keeps the gate green.

**The rules in one breath**

Stay in your lane · write only your own files · commit only via `team-commit.sh` (never
`git add -A`) · green before commit · only the lead pushes · heavy ops under a lock · log
every step.

**Coordination helpers**

```bash
scripts/team-health.sh                  # who's active/idle/stale · stale tasks · deadlock
scripts/team-sync.sh [--strict]         # where board.md drifts from the logs (lead reconciles)
scripts/team-resume.sh                  # rebuild state from logs + git after a crash/restart
scripts/team-metrics.sh                 # throughput per role + board progress → .team/metrics.md
scripts/team-backup.sh [restore [file]] # snapshot / restore .team/ (git isn't the only copy)
scripts/team-lead-claim.sh <role>       # fallback-lead: record the acting lead
scripts/team-lint-log.sh                # validate structured @role handoff lines
scripts/team-worktrees.sh setup         # per-role git worktrees for stronger isolation
scripts/team-role.sh add <name> <globs> # add a runtime role + emit its start prompt
scripts/team-handoff.sh                 # produce a briefing for a fresh session
scripts/team-commit.sh --dry-run <role> "msg" <paths>   # run the gate + preview, don't commit
```

<details>
<summary><b>Tunables &amp; behaviour</b></summary>

- `TEAM_ACTIVE_SECS` (default `900`) and `TEAM_STALE_SECS` (default `1800`) set the
  liveness/stale-task thresholds for `team-health.sh`.
- Lock, commit, and health events are appended to `.team/log/events.log` (gitignored).
- `.team/memory.md` is read at kickoff and carries durable decisions across runs.
- Logs are the authority for automated reconciliation; the board is the human-facing view.

</details>

<a id="optional-the-gui"></a>

**Optional — the GUI**

```bash
cd gui && npm install && cd ..
node gui/server.js            # → http://localhost:4173
```

The console runs each agent as a real terminal, adds buttons for the common commands
(Kickoff, `state`, Enter, `y`, Esc, ^C, restart), and polls `.team/` for the live vitals
strip. Details in [`gui/README.md`](gui/README.md).

## Architecture

```mermaid
flowchart TB
  human([You: the goal]) --> lead

  subgraph agents [Four Claude Code sessions]
    lead[Lead — plan · integrate · push]
    backend[Backend — server · data]
    frontend[Frontend — UI · UX]
    quality[Quality — tests · gate]
  end

  subgraph team [".team/ — the shared blackboard"]
    board[board.md — single work board]
    logs[log/*.md — append-only events]
    memory[memory.md — durable decisions]
    locks[locks/*.lock — runtime locks]
  end

  scripts[["scripts/team-*.sh — commit · check · health · sync · resume …"]]

  lead --> board
  agents --> logs
  agents -. read .-> board
  agents --> scripts --> team
  gui[["gui/ — optional console"]] -. reads state .-> team
```

- **Agents** are four `claude` sessions, each with an explicit lane and definition-of-done
  in [`.team/roles/`](.team/roles).
- **`.team/`** is the blackboard: the lead owns `board.md`; every agent appends only to its
  own `log/*.md`; `memory.md` survives across runs.
- **`scripts/`** are the only sanctioned way to commit and run heavy/exclusive operations;
  [`lib/lock.sh`](scripts/lib/lock.sh) provides the atomic lock used everywhere.

## Project structure

```text
.
├─ .team/
│  ├─ PROTOCOL.md         # the rules (read-only, never changes)
│  ├─ board.md            # the single work board (lead-owned)
│  ├─ memory.md           # durable, run-spanning decisions
│  ├─ roles/              # per-agent lane + definition-of-done
│  └─ log/                # per-agent append-only logs
├─ scripts/
│  ├─ lib/lock.sh         # atomic mkdir lock + event-log helpers
│  ├─ team-commit.sh      # lock → gate → stage your paths → commit "[role] …"
│  ├─ team-check.sh       # the green gate (edit for your stack)
│  ├─ team-exclusive.sh   # serialize heavy ops (build/e2e/migrations)
│  ├─ team-health.sh      # liveness · stale tasks · deadlock
│  ├─ team-sync.sh        # board ↔ log drift report
│  ├─ team-resume.sh      # rebuild state after a crash/restart
│  ├─ team-metrics.sh     # throughput + board progress
│  ├─ team-backup.sh      # snapshot / restore .team/
│  ├─ team-lead-claim.sh  # fallback-lead
│  ├─ team-lint-log.sh    # validate @role handoff lines
│  ├─ team-worktrees.sh   # per-role git worktrees
│  ├─ team-role.sh        # add / list / remove team roles at runtime
│  └─ team-handoff.sh     # produce a briefing for a fresh Claude Code session
├─ gui/                   # optional one-window web console (Node.js)
├─ mcp/                   # optional read-only MCP server (exposes .team/ as resources)
├─ .github/workflows/     # GitHub Actions (gate workflow runs the suite on every push)
├─ tests/run.sh           # Bash test suite (58 checks at last count)
├─ docs/console.png       # GUI screenshot
├─ PROMPTS.md             # the 4 copy-paste terminal prompts
├─ ROADMAP.md             # phased plan + implementation state
└─ LICENSE                # Private Use
```

## Quality and security

- **Continuous integration** — every push runs [`.github/workflows/gate.yml`](.github/workflows/gate.yml),
  which executes the full green gate (`bash -n` + `shellcheck` + the test suite) on Ubuntu.
- **Tests** — `bash tests/run.sh` runs 58 sandboxed checks against the real scripts; no
  external test framework is required.
- **Green gate** — [`scripts/team-check.sh`](scripts/team-check.sh) syntax-checks every
  script (`bash -n`), runs `shellcheck -S warning` when available, and runs the test suite.
- **Concurrency safety** — locks use an atomic `mkdir` directory with PID-liveness stale
  detection and an atomic, rename-based break, so two agents can't both acquire one lock.
- **Privacy** — everything is local and file-based: the coordination state lives in your
  own repo, and runtime artifacts (`events.log`, `locks/`, `state/`, `backups/`, `metrics.md`)
  are gitignored.

> [!NOTE]
> There is no `SECURITY.md` yet — please report concerns privately to the maintainer
> (see [LICENSE](LICENSE) for contact context).

## Roadmap

Shipped in this repo:

- [x] Atomic locking library + serialized commits (`lib/lock.sh`, `team-commit.sh`)
- [x] Green gate, dry-run commits, central event log
- [x] Health, stale-task & deadlock detection (`team-health.sh`)
- [x] Board ↔ log drift reconciliation (`team-sync.sh`)
- [x] Crash recovery (`team-resume.sh`) + run-spanning memory (`memory.md`)
- [x] Fallback-lead (`team-lead-claim.sh`) + state backup (`team-backup.sh`)
- [x] Throughput metrics (`team-metrics.sh`)
- [x] Structured handoff schema + linter (`team-lint-log.sh`)
- [x] Git worktrees for stronger isolation (`team-worktrees.sh`)
- [x] Live web console with vitals (`gui/`, `/state`)
- [x] Dynamic / additional roles at runtime (`team-role.sh`)
- [x] Cross-session handoff briefing (`team-handoff.sh`)
- [x] GitHub Actions CI + live badge (`.github/workflows/gate.yml`)
- [x] Optional read-only MCP server exposing coordination state (`mcp/`)

Planned:

- [ ] Sub-teams / hierarchies (4.2)
- [ ] Cross-repo federation for multi-service teams (5.2)

See [`ROADMAP.md`](ROADMAP.md) for the full phased plan, priorities, and rationale.

## Contributing

This is a personal project under a private-use license (see [License](#license)), so it is
not open for general redistribution. There is no `CONTRIBUTING.md` yet. If you have a fix or
an idea, please open an issue first to discuss it. Before proposing any change, make sure the
gate is green:

```bash
bash scripts/team-check.sh
```

## License

**Private Use** — personal, non-commercial use is permitted; distribution or commercial use
requires prior written permission. Copyright © 2026 Belkis Aslani (BEKO2210). Full terms in
[`LICENSE`](LICENSE).

## Acknowledgements

- Built for [Claude Code](https://claude.com/claude-code) by Anthropic.
- The optional GUI uses [xterm.js](https://xtermjs.org/), [node-pty](https://github.com/microsoft/node-pty), and [ws](https://github.com/websockets/ws).
- Distilled from a real multi-agent run, with the friction designed out.
