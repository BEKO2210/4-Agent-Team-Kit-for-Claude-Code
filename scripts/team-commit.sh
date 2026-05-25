#!/usr/bin/env bash
# Serialize commits across agents sharing one working tree.
#   scripts/team-commit.sh <role> "<message>" <path> [<path>...]
# Takes the commit lock, runs the green gate, stages ONLY the given paths,
# commits as "[role] message", releases the lock (even on failure). Never `git add -A`.
set -euo pipefail

ROLE="${1:?usage: team-commit.sh <role> <message> <path...>}"; shift
MSG="${1:?commit message required}"; shift
[ "$#" -ge 1 ] || { echo "team-commit: pass at least one path (never -A)"; exit 1; }

LOCK=".team/locks/git.lock"
STALE=600   # seconds; older lock is assumed orphaned and broken

mtime() { stat -c %Y "$1" 2>/dev/null || stat -f %m "$1" 2>/dev/null || echo 0; }

for _ in $(seq 1 150); do
  if ( set -C; printf '%s %s\n' "$ROLE" "$$" > "$LOCK" ) 2>/dev/null; then
    LOCKED=1; break
  fi
  if [ -f "$LOCK" ] && [ "$(( $(date +%s) - $(mtime "$LOCK") ))" -gt "$STALE" ]; then
    echo "team-commit: breaking stale lock (was '$(cat "$LOCK" 2>/dev/null)')"; rm -f "$LOCK"; continue
  fi
  echo "team-commit: git.lock held by '$(cat "$LOCK" 2>/dev/null)' — waiting…"; sleep 2
done
[ "${LOCKED:-}" = 1 ] || { echo "team-commit: timed out waiting for git.lock"; exit 1; }
trap 'rm -f "$LOCK"' EXIT

if [ -x scripts/team-check.sh ]; then
  echo "team-commit: running green gate…"
  scripts/team-check.sh
fi

git add -- "$@"
if git diff --cached --quiet; then
  echo "team-commit: nothing staged in those paths — skipping."; exit 0
fi
git commit -m "[$ROLE] $MSG"
echo "team-commit: ✅ committed [$ROLE] $MSG"
