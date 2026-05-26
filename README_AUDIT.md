# README Audit

A record of how the current `README.md` was produced, so its claims stay verifiable.

## What was improved

- Rewrote `README.md` as a premium-but-honest landing page: centered hero, value
  proposition, feature matrix, preview, copy-paste quickstart, usage, a Mermaid
  architecture diagram, project tree, quality/security section, status roadmap, and
  contributing/license/acknowledgements.
- Added a self-contained hero asset at `assets/readme/hero.svg` (no scripts, no external
  references — GitHub-safe and readable without animation).
- Used GitHub-native techniques: alerts (`[!NOTE]`/`[!TIP]`/`[!IMPORTANT]`/`[!WARNING]`),
  a `<details>` section, a feature table, a Mermaid diagram, and an anchor table of contents.

## Assumptions made

- The project version is intentionally **not** badged. `gui/package.json` declares
  `1.0.0`, but that is the GUI sub-package only, not a release of the whole kit.
- The "tests — 45 checks" badge is a **static** badge reflecting the suite at the time of
  writing (`bash tests/run.sh`). It is not a live CI badge; CI is on the roadmap (5.1).
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
  the gate (`scripts/team-check.sh`), the suite (`bash tests/run.sh`, 45 checks), the
  helper scripts (each exists in `scripts/`), and the GUI (`node gui/server.js`, port 4173
  per `gui/README.md`).
- **Hero SVG** — rendered headless to confirm it displays correctly.

## Honest gaps (stated as "Planned" or omitted in the README)

- No GitHub Actions workflow exists → **no CI badge**; CI is listed under Roadmap 5.1.
- No `SECURITY.md`, `CONTRIBUTING.md`, or `CODE_OF_CONDUCT.md` → not linked; the README
  states the security-reporting path and the private-use contribution policy in prose.
- No published package (npm/PyPI/etc.) and no live demo → no such badges or links.

## Open TODOs (optional follow-ups)

- Add a GitHub Actions workflow that runs `bash tests/run.sh`, then swap the static tests
  badge for a live build badge (Roadmap 5.1).
- Consider a `SECURITY.md` and a `CONTRIBUTING.md` if the license is ever relaxed.
