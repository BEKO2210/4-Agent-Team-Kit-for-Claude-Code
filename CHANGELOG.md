# Changelog

All notable changes to this project are recorded here. Format loosely follows
[Keep a Changelog](https://keepachangelog.com); the project does not yet publish to a
package registry, so versions are git tags for now.

## [Unreleased]

Nothing yet. This section will collect changes that land on `main` after the next tag.

## [0.1.0] — 2026-05-26 — Initial public preview

The first feature-complete public preview. All numbered milestones from `ROADMAP.md`
(phases 0–6) are shipped; only the deliberately optional academic appendix is left out.

### Added — coordination scripts
- `scripts/lib/lock.sh` — atomic `mkdir` lock directory, PID-liveness stale detection,
  atomic rename-based break, ownership-checked release.
- `scripts/team-commit.sh` — serialised commits with `--dry-run` / `TEAM_DRY_RUN=1`.
- `scripts/team-exclusive.sh` — serialise heavy operations (build / e2e / migrations).
- `scripts/team-check.sh` — green gate (`bash -n` + optional `shellcheck -S warning` +
  test suite); the contract for "never commit red."
- `scripts/team-health.sh` — per-agent liveness, stale-task detection, deadlock signal.
- `scripts/team-sync.sh` — board↔log drift report (logs are the authority).
- `scripts/team-resume.sh` — rebuild state from logs + Git after a crash/restart.
- `scripts/team-metrics.sh` — throughput per role + board progress.
- `scripts/team-backup.sh` — snapshot / restore `.team/`.
- `scripts/team-lead-claim.sh` — fallback-lead record (`.team/state/lead`).
- `scripts/team-lint-log.sh` — validate structured `@role` handoff lines.
- `scripts/team-worktrees.sh` — per-role Git worktrees on `team/<role>` branches.
- `scripts/team-role.sh` — add / list / remove team roles at runtime (with start prompt).
- `scripts/team-handoff.sh` — paste-able briefing for a fresh Claude Code session.
- `scripts/team-sections.sh` — per-section view (sub-team `## name` board headings).
- `scripts/team-federate.sh` — aggregate boards across multiple repos.
- `scripts/team-snapshot.{mjs,sh}` — capture the full team state as one JSON document.
- `scripts/team-diff.{mjs,sh}` — diff two snapshots (counts, tasks, role states).

### Added — protocol files
- `.team/PROTOCOL.md` — the five rules, the handoff schema, resilience policy,
  sub-teams and cross-repo conventions, concurrency variants.
- `.team/roles/{lead,backend,frontend,quality}.md` — explicit lanes and definition-of-done.
- `.team/roles/_template.md` — template for runtime-added roles.
- `.team/memory.md` — durable, run-spanning decisions (lead-curated).
- `.team/board.md` — single work board (lead-owned).

### Added — GUI
- `gui/server.js` — local web console that runs the four sessions as real PTYs, plus the
  `/state` endpoint that derives board progress + per-agent health from `.team/`.
- `gui/public/index.html` — distinctive "TEAM // CONSOLE" UI: live vitals strip
  (segmented progress + colour-coded agent chips), per-agent accent decks, motion.

### Added — MCP
- `mcp/server.js` — read-only Model Context Protocol server (stdio) exposing
  `team://state | board | memory | protocol | health | metrics | log/<role>` resources
  and `team_state` / `refresh_metrics` tools.
- `mcp/test.js` — self-contained smoke test (12 checks).

### Added — schema, examples, docs, CI
- `schema/team-state.schema.json` — JSON Schema (draft 2020-12) describing the contract
  shared by `/state`, `team://state` and `team-snapshot`.
- `examples/todo-cli/` — a worked example: kickoff, board fixture, representative logs.
- `tests/run.sh` — sandboxed Bash test suite (77 checks at this tag).
- `tests/validate-schema.mjs` — structural sanity check for the JSON Schema.
- `.github/workflows/gate.yml` — GitHub Actions runs the gate on every push / PR.
- Premium English README + the German `README.de.md`.
- This `CHANGELOG.md`.

### Notes
- Core has **zero runtime dependencies**. GUI and MCP each ship their own `package.json`
  and are strictly opt-in.
- Continuous integration: see the live `gate` badge in the README.
- License remains **Private Use** — see `LICENSE`.
