# Team GUI — one window, no terminal hopping

A tiny local web console that runs all four agents at once: each agent is a real
Claude Code session (a PTY) shown in its own panel; you chat, hit Enter, and fire the
common commands from buttons — without switching terminals.

## Run
```bash
cd gui
npm install            # installs node-pty + ws (prebuilt binaries, no compiler needed on common platforms)
cd ..                  # run from your repo root so agents see .team/
node gui/server.js     # → open http://localhost:4173
```
The agents launch in the directory you run from (override with `REPO_DIR=/path/to/repo`).

## Use
1. The 4 panels start their `claude` sessions automatically.
2. Type your task into the **Goal** box (top).
3. Click **▶ Kickoff all** — sends each agent its role prompt (Lead first), Goal injected.
4. Drive them: per-panel **message box** (Enter sends), or the buttons:
   **⮞ prompt** (resend role prompt) · **⏎ Enter** · **status** (the autopilot nudge) ·
   **y** · **Esc** · **^C** · **restart**. Top bar: **↻ status → all**.
5. You can also click into any panel and type directly — it's a full terminal.

## Config (`agents.json`)
- `cmd`/`args` — defaults to `claude`; change if your CLI differs or to add flags.
- `prompt` — the launch prompt per agent (mirrors `../PROMPTS.md`); `{{GOAL}}` (lead) is
  filled from the Goal box.
- `label` — panel title.

## Env
- `PORT` (default `4173`), `REPO_DIR` (default: cwd), `AUTOSTART=0` (don't auto-launch;
  use each panel's **restart**), `TEST_CMD=bash` (smoke-test the bridge without claude).

## Notes
- Binds to `127.0.0.1` only (local). It drives whatever `claude` would do in your repo —
  same permission prompts; approve them with the panel buttons or by typing.
- Multi-line text (messages / prompts) is sent via bracketed paste so it doesn't submit
  line-by-line.
- `node-pty` is a native module; if `npm install` can't find a prebuilt binary it will
  compile (needs Python + a C/C++ toolchain).
