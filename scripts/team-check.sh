#!/usr/bin/env bash
# The green gate — EDIT this for your project. Every commit must pass it.
# Keep it FAST (lint + unit). Leave slow build/e2e to the quality agent's sign-off
# (run those via team-exclusive.sh so they don't collide).
set -euo pipefail

# --- pick / replace for your stack ---
#   npm run lint && npm test
#   pnpm lint && pnpm test
#   yarn lint && yarn test
#   ruff check . && pytest -q
#   go vet ./... && go test ./...
#   cargo clippy -- -D warnings && cargo test

npm run lint && npm test
