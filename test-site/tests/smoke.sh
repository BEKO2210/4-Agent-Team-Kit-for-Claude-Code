#!/usr/bin/env bash
# Smoke test for the test-site demo (board row #4, owner: quality).
# Boots the backend server, asserts /, /about, /contact, /api/hello return 200,
# and verifies /api/hello returns JSON with a "message" field.
# Skips cleanly (rc=0) until #2 (public/index.html) and #3 (server/server.js) land,
# so the gate stays green while frontend/backend are still in flight.
set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/.." && pwd)"
SERVER="$ROOT/server/server.js"
INDEX="$ROOT/public/index.html"
PORT="${TEST_SITE_PORT:-8080}"

if [ ! -f "$SERVER" ] || [ ! -f "$INDEX" ]; then
  echo "  test-site smoke: skipped — waiting on #2 (public/index.html) and/or #3 (server/server.js)"
  exit 0
fi

if ! command -v node >/dev/null 2>&1; then
  echo "  test-site smoke: skipped — node not on PATH"
  exit 0
fi
if ! command -v curl >/dev/null 2>&1; then
  echo "  test-site smoke: skipped — curl not on PATH"
  exit 0
fi

PID=""
cleanup() {
  if [ -n "$PID" ] && kill -0 "$PID" 2>/dev/null; then
    kill "$PID" 2>/dev/null || true
    wait "$PID" 2>/dev/null || true
  fi
}
trap cleanup EXIT

PORT="$PORT" node "$SERVER" >/dev/null 2>&1 &
PID=$!

ready=0
for _ in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20; do
  if curl -fsS -o /dev/null "http://127.0.0.1:$PORT/" 2>/dev/null; then ready=1; break; fi
  sleep 0.2
done
if [ "$ready" -ne 1 ]; then
  echo "  test-site smoke: FAIL — server did not become ready on :$PORT within ~4s"
  exit 1
fi

fail=0
check_200() {
  local path="$1" code
  code="$(curl -s -o /dev/null -w '%{http_code}' "http://127.0.0.1:$PORT$path" 2>/dev/null || echo 000)"
  if [ "$code" = "200" ]; then
    echo "  test-site smoke: ok   GET $path -> 200"
  else
    echo "  test-site smoke: FAIL GET $path -> $code (expected 200)"
    fail=$((fail + 1))
  fi
}

check_200 /
check_200 /about
check_200 /contact
check_200 /api/hello

body="$(curl -s "http://127.0.0.1:$PORT/api/hello" 2>/dev/null || true)"
if printf '%s' "$body" | grep -q '"message"'; then
  echo "  test-site smoke: ok   /api/hello body contains \"message\""
else
  echo "  test-site smoke: FAIL /api/hello body missing \"message\" (got: $body)"
  fail=$((fail + 1))
fi

if [ "$fail" -ne 0 ]; then
  echo "test-site smoke: $fail check(s) failed"
  exit 1
fi
echo "test-site smoke: green"
