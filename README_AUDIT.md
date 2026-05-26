# README Audit

A record of how the current `README.md` was produced, so its claims stay verifiable.

## What was improved

- Rewrote `README.md` as a premium-but-honest landing page: centered hero, value
  proposition, feature matrix, preview, copy-paste quickstart, usage, a Mermaid
  architecture diagram, project tree, quality/security section, state roadmap, and
  contributing/license/acknowledgements.
- Added a self-contained hero asset at `assets/readme/hero.svg` (no scripts, no external
  references — GitHub-safe and readable without animation).
- Used GitHub-native techniques: alerts (`[!NOTE]`/`[!TIP]`/`[!IMPORTANT]`/`[!WARNING]`),
  a `<details>` section, a feature table, a Mermaid diagram, and an anchor table of contents.

## Assumptions made

- The project version is intentionally **not** badged. `gui/package.json` declares
  `1.0.0`, but that is the GUI sub-package only, not a release of the whole kit.
- The build badge is a **live** Shields badge wired to `.github/workflows/gate.yml`. It
  reflects the latest gate run on the default branch (`main`); during this PR it may show
  "no state" on `main` until the workflow has run there post-merge.
- The check count in prose ("87 checks at last count") is accurate at write time. The
  badge does not encode the number, so adding new tests does not require a README edit.
- Privacy is described as local/file-based because the kit only reads and writes files in
  the repo; there is no network/telemetry component in the core scripts.

## What was verified

- **Local links & images** — every relative link and `src` in `README.md` resolves to a
  real path (`.team/PROTOCOL.md`, `.team/roles`, `LICENSE`, `PROMPTS.md`, `ROADMAP.md`,
  `gui/README.md`, `scripts/lib/lock.sh`, `scripts/team-check.sh`, `docs/console.png`,
  `assets/readme/hero.svg`).
- **Badges** — all five are static `img.shields.io/badge/...` URLs (render regardless of
  repo visibility); no dynamic or CI badges are used.
- **Commands** — every command is derived from real files: setup (`.team/`, `scripts/`),
  the gate (`scripts/team-check.sh`), the suite (`bash tests/run.sh`, currently 87 checks), the
  helper scripts (each exists in `scripts/`), and the GUI (`node gui/server.js`, port 4173
  per `gui/README.md`).
- **Hero SVG** — rendered headless to confirm it displays correctly.

## Honest gaps (stated as "Planned" or omitted in the README)

- No published package (npm / PyPI / etc.) and no live demo → no such badges or links.

## Open TODOs (optional follow-ups)

- GitHub-UI items (repository topics & description, Discussions, custom social preview)
  — these can't be set from a commit and remain on the maintainer's checklist.
- Tag `v0.1.0` on `main` after this PR merges, then publish a GitHub Release.

## Resolved since the first audit

- License moved from "Private Use" to **MIT** in v0.1.0; commercial-use note added to
  the README. Roadmap item 7.1 closed.
- `SECURITY.md`, `CONTRIBUTING.md` and `CODE_OF_CONDUCT.md` now present and linked from
  the README.
- The previous "tests — N checks" rot was removed: the README badge is now the live
  `gate` workflow status, and the prose count is the current truth at write time.
- The `buildState()` / `teamStatus()` / `fold()` duplication identified in the audit is
  gone — all three call sites now import `buildState` from `lib/state.mjs`, which is
  governed by `schema/team-state.schema.json`.
- The CI now runs `npm audit` (high) on `gui/` and `mcp/` lockfiles in addition to the
  Bash gate.
