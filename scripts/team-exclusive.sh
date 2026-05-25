#!/usr/bin/env bash
# Run a heavy/exclusive command so two agents never run conflicting ones at once
# (production build, e2e, dev server, DB migration — anything sharing a resource).
#   scripts/team-exclusive.sh <role> <lock-name> -- <command...>
# e.g.  scripts/team-exclusive.sh quality e2e -- npm run test:e2e
set -euo pipefail

ROLE="${1:?usage: team-exclusive.sh <role> <lock-name> -- <command...>}"
NAME="${2:?lock name required}"; shift 2
[ "${1:-}" = "--" ] && shift
[ "$#" -ge 1 ] || { echo "team-exclusive: pass a command after --"; exit 1; }

LOCK=".team/locks/${NAME}.lock"
STALE=1800
mtime() { stat -c %Y "$1" 2>/dev/null || stat -f %m "$1" 2>/dev/null || echo 0; }

for _ in $(seq 1 600); do
  if ( set -C; printf '%s %s\n' "$ROLE" "$$" > "$LOCK" ) 2>/dev/null; then
    LOCKED=1; break
  fi
  if [ -f "$LOCK" ] && [ "$(( $(date +%s) - $(mtime "$LOCK") ))" -gt "$STALE" ]; then
    echo "team-exclusive: breaking stale '$NAME' lock"; rm -f "$LOCK"; continue
  fi
  echo "team-exclusive: '$NAME' held by '$(cat "$LOCK" 2>/dev/null)' — waiting…"; sleep 2
done
[ "${LOCKED:-}" = 1 ] || { echo "team-exclusive: timed out on '$NAME'"; exit 1; }
trap 'rm -f "$LOCK"' EXIT

echo "team-exclusive: running under '$NAME' lock: $*"
"$@"
