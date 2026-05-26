#!/usr/bin/env node
// Capture the full team state as one self-contained JSON document.
// Useful for inspection, diffing two points in time, attaching to a bug report,
// or feeding a dashboard. Read-only: never writes into .team/ itself.
//
//   node scripts/team-snapshot.mjs                           print snapshot to stdout
//   node scripts/team-snapshot.mjs --save                    also write to .team/snapshots/<ts>.json
//   REPO_DIR=/path node scripts/team-snapshot.mjs            snapshot a different repo
import fs from "node:fs";
import path from "node:path";
import { execSync } from "node:child_process";

const REPO_DIR = process.env.REPO_DIR || process.cwd();
const TEAM_DIR = path.join(REPO_DIR, ".team");
const SAVE = process.argv.includes("--save");

const readFileSafe = (p, fallback = null) => { try { return fs.readFileSync(p, "utf8"); } catch { return fallback; } };
const mtimeMs = (p) => { try { return fs.statSync(p).mtimeMs; } catch { return 0; } };

function gitHead() {
  try { return execSync("git rev-parse HEAD", { cwd: REPO_DIR, stdio: ["ignore", "pipe", "ignore"] }).toString().trim(); }
  catch { return null; }
}

function listRoles() {
  let files = [];
  try { files = fs.readdirSync(path.join(TEAM_DIR, "roles")); } catch { return []; }
  return files.filter((f) => f.endsWith(".md") && !f.startsWith("_")).map((f) => f.replace(/\.md$/, "")).sort();
}

function parseBoard() {
  const counts = { todo: 0, doing: 0, blocked: 0, done: 0, total: 0 };
  const tasks = [];
  for (const line of (readFileSafe(path.join(TEAM_DIR, "board.md")) || "").split("\n")) {
    if (!/^\s*\|/.test(line) || /----/.test(line)) continue;
    const c = line.split("|").map((s) => s.trim());
    const id = c[1];
    if (!/^\d+$/.test(id)) continue;
    const state = (c[4] || "").toLowerCase();
    counts.total++;
    if (counts[state] !== undefined) counts[state]++;
    tasks.push({ id, task: c[2] || "", owner: (c[3] || "").replace(/[@\s]/g, "").toLowerCase(), state });
  }
  return { counts, tasks };
}

function fold() {
  const now = Date.now();
  const ACTIVE = Number(process.env.TEAM_ACTIVE_SECS || 900);
  const STALE = Number(process.env.TEAM_STALE_SECS || 1800);
  const { counts, tasks } = parseBoard();
  const roles = listRoles().map((id) => {
    const mt = mtimeMs(path.join(TEAM_DIR, "log", id + ".md"));
    const ageSec = mt ? Math.round((now - mt) / 1000) : -1;
    let state = "no-log";
    if (ageSec >= 0) state = ageSec < ACTIVE ? "active" : ageSec < STALE ? "idle" : "stale";
    return { id, ageSec, state };
  });
  return {
    generatedAt: new Date().toISOString(),
    repoDir: REPO_DIR,
    gitHead: gitHead(),
    counts,
    tasks,
    roles,
  };
}

const snap = fold();
const out = JSON.stringify(snap, null, 2);
process.stdout.write(out + "\n");

if (SAVE) {
  const dir = path.join(TEAM_DIR, "snapshots");
  try { fs.mkdirSync(dir, { recursive: true }); } catch {}
  const ts = snap.generatedAt.replace(/[:.]/g, "-").replace("Z", "");
  const file = path.join(dir, ts + ".json");
  fs.writeFileSync(file, out);
  process.stderr.write(`team-snapshot: ✅ saved ${file}\n`);
}
