# ROADMAP — 4-Agent Team Kit for Claude Code

> Diese Roadmap übersetzt die externen KI-Reviews in einen konkreten, umsetzbaren Plan.
> Zwei Quellen flossen ein:
> 1. ein informelles Praxis-Review (Gesamtnote **8.5/10**),
> 2. ein akademisches Technical Review als PDF (Gesamt **7.6/10**; Architektur 8, Implementierung 9,
>    Innovation 8, Doku 7, Produktionsreife 6) mit expliziter Prioritätentabelle.
>
> Jeder Punkt nennt **Problem → Lösung → betroffene Dateien → Akzeptanzkriterien → Aufwand**,
> damit das Team (oder ein einzelner Agent) ihn direkt in `board.md`-Zeilen überführen kann.
>
> **Leitprinzip bleibt:** dateibasierte Koordination, keine externe Infrastruktur,
> Git als Konsens-Mechanismus. Jede Erweiterung muss optional und abschaltbar sein –
> das Kit darf für ein simples „4 Terminals, ein Repo" nicht komplizierter werden.

---

## 0. Status quo (Basis dieser Roadmap)

**Was heute existiert**
- `.team/PROTOCOL.md` — die 5 Regeln, read-only
- `.team/board.md` — das einzige Work-Board (Lead-owned)
- `.team/roles/{lead,backend,frontend,quality}.md` — Lanes + Definition of Done
- `.team/log/*.md` — append-only Logs pro Agent (keine Write-Races)
- `scripts/team-commit.sh` — Lock → Gate → nur eigene Pfade stagen → commit → unlock
- `scripts/team-check.sh` — das Green-Gate (lint + unit)
- `scripts/team-exclusive.sh` — schwere Operationen (build/e2e) serialisiert
- `gui/` — optionale Web-Konsole (4 PTYs in einem Fenster)
- `PROMPTS.md` / `gui/agents.json` — die 4 Start-Prompts

**Was die Reviews als Schwächen markieren** (→ adressiert in den Phasen unten)
1. Keine echte Parallelität (gemeinsamer Working Tree) → **Phase 2**
2. Single Point of Failure: nur der Lead pusht → **Phase 2**
3. Keine Kontext-Persistenz / kein Recovery → **Phase 1 + Phase 6**
4. Begrenzte Skalierbarkeit (genau 4 statische Rollen) → **Phase 4**
5. Lizenz bremst Adoption → **Phase 7**
6. Skripte: kein Dry-Run, kein Logging außerhalb `.team/log/` → **Phase 0**

**Zusätzlich aus dem akademischen PDF-Review** (Abschnitte 6.2/8.2)
- **W1 — Keine Fehlertoleranz bei Agentenausfällen:** ein `doing`-Task eines abgestürzten Agenten wird nie zurückgesetzt → **Phase 1 (Stale-Task)**
- **W2 — Manuelle Board-Synchronisation (PDF: „Kritisch"):** kein Konsistenzmechanismus Board↔Logs → **Phase 1 (Board-Sync-Watchdog)**
- **W3 — Keine dynamische Rekonfiguration:** Rollen statisch → **Phase 4**
- **W4 — Keine semantische Kommunikation:** Handoffs sind formloser Text → **Phase 4 (Handoff-Schema)**
- **W5 — Git als Single Point of Failure:** keine Backup-/Redundanz-Strategie → **Phase 2 (Backup)**
- **MCP-Integration** (PDF: „Mittel"): Interoperabilität mit externen Tools → **Phase 5**
- **Fehlende akademische Konstrukte** (BDI, Contract Net, Partial Global Planning, Org Self-Design) → **Anhang A (optionaler Backlog, bewusst YAGNI)**

---

## Phasen-Überblick

| Phase | Thema | Ziel | Geschätzter Aufwand |
|-------|-------|------|---------------------|
| **0** | Fundament & Quick Wins | Skripte robuster, sicheres Testen | S (1–2 Tage) |
| **1** | Robustheit & Selbstheilung | Board-Sync-Watchdog, Stale-Task, Health-Check, Auto-Resume, Deadlock | M |
| **2** | Isolation & Resilienz | Worktrees, Fallback-Lead, Backup des Koordinationszustands | M–L |
| **3** | Transparenz & Metriken | Board-Metriken, Live-State in der GUI | M |
| **4** | Skalierbarkeit & Kommunikation | Dynamische Rollen, Sub-Teams, strukturiertes Handoff-Schema | L |
| **5** | Integration & Automatisierung | GitHub Actions / Webhooks, MCP, Cross-Repo | L |
| **6** | Persistenz & Lernen | Run-übergreifender Speicher, Handoff | M–L |
| **7** | Lizenz & Community | Adoption ermöglichen | S |
| **A** | Anhang: akademischer Backlog | BDI, Contract Net, PGP, Org Self-Design (optional, YAGNI) | — |

Aufwand: **S** = klein (Stunden–1 Tag) · **M** = mittel (Tage) · **L** = groß (Woche+).

---

## Umsetzungsstand (dieser Branch)

✅ **Bereits implementiert** (mit Tests, `bash tests/run.sh` — 58 grün + 12 MCP-Smoke-Tests, CI grün):
- **5.3** `mcp/` — read-only MCP-Server (stdio) exponiert `.team/` als MCP-Ressourcen
  (`team://state|board|memory|protocol|health|metrics|log/<role>`) + Tools (`team_state`,
  `refresh_metrics`). Eigenes `package.json` (opt-in), Kern bleibt zero-deps. 12 Smoke-Tests.
- **5.1** `.github/workflows/gate.yml` — GitHub Actions führt bei jedem Push das volle Gate aus
  (`bash -n` + `shellcheck -S warning` + Test-Suite). Live-Badge im README.
- **4.1** `team-role.sh add|list|remove` + `.team/roles/_template.md` — Rollen zur Laufzeit
  hinzufügen/entfernen, mit generiertem Start-Prompt für die neue Rolle.
- **6.2** `team-handoff.sh` — kombiniert `memory.md` + `team-resume.sh` + `team-metrics.sh` zu
  einem paste-baren Briefing für eine frische Claude-Code-Session.
- **2.1** `team-worktrees.sh` — `setup|list|sync|teardown`: pro Rolle ein eigener Worktree auf
  `team/<role>`-Branch; Lead integriert via `git merge`. Stärkere Isolation als Shared-Tree.
- **0.3** `scripts/lib/lock.sh` — gehärtetes Locking: atomares `mkdir`-Lock-Verzeichnis,
  PID-Liveness (`kill -0`) statt mtime-Race, atomarer Stale-Break via `rename`,
  Release nur bei eigener Ownership. `team-commit.sh`/`team-exclusive.sh` nutzen die Lib.
- **0.1** `team-commit.sh --dry-run` (bzw. `TEAM_DRY_RUN=1`) — Gate + Vorschau ohne Commit.
- **0.2** zentrales `.team/log/events.log` (Lock-/Commit-/Health-Events).
- **0.4** `.gitignore` deckt Laufzeit-Artefakte ab (`locks/*`, `events.log`, `state/`, `backups/`, `metrics.md`).
- **1.0** `team-sync.sh` — Board↔Log-Drift-Report (Logs = Autorität, Board = Projektion; meldet, schreibt nicht).
- **1.1** Stale-Task-Erkennung in `team-health.sh` (`doing` + Owner zu lange still).
- **1.2** `team-health.sh` — Liveness pro Rolle (Heartbeat = letzter Log-Append).
- **1.3** `team-resume.sh` — Resume-Briefing aus Logs + Git-History nach Crash/Neustart.
- **1.4** Deadlock-Erkennung (alles `blocked`, nichts `doing`/`todo`).
- **2.2** `team-lead-claim.sh` + Fallback-Lead-Konvention (genau ein aktiver Lead via `.team/state/lead`).
- **2.3** `team-backup.sh` — Snapshot/Restore des `.team/`-Zustands (Schutz vor „Git = einzige Kopie").
- **3.1** `team-metrics.sh` — Durchsatz pro Rolle + Board-Fortschritt → `.team/metrics.md`.
- **3.2** GUI Live-State: `/state`-Endpoint + neue „TEAM // CONSOLE"-Oberfläche
  (Vitals-Leiste mit Board-Fortschritt + Agent-Health, farbcodierte Decks, Motion) via `frontend-design`-Skill.
- **4.3** Handoff-Schema in `PROTOCOL.md` + `team-lint-log.sh`.
- **6.1** `.team/memory.md` (run-übergreifender Speicher) + Start-Prompts lesen ihn.
- **Gate/Tests:** `team-check.sh` prüft `bash -n` + optional shellcheck + Test-Suite; `tests/run.sh` (39 Tests).

⏭️ **Als Nächstes** (laut Priorisierung): 4.2 Sub-Teams (leichtgewichtige Hierarchien) ·
5.2 Cross-Repo-Federation.

> Design-Grundlage: kurze Recherche zu (a) sicherer Bash-Concurrency [mkdir/flock, TOCTOU,
> `kill -0`], (b) Blackboard/Event-Sourcing [Logs als Event-Stream, Board als Projektion;
> Lease/TTL + timeout-and-requeue für Stale-Tasks], (c) offiziellen Claude-Code-Patterns
> [Agent Teams, Worktrees, `SessionStart`-Hooks — der File-Layer ergänzt sie].

---

## Phase 0 — Fundament & Quick Wins

Kleine Härtungen an bestehenden Skripten. Niedriges Risiko, sofortiger Nutzen.

### 0.1 Dry-Run-Modus für `team-commit.sh`
- **Problem:** Agenten können einen Commit nicht „proben"; ein Fehler zeigt sich erst beim echten Commit.
- **Lösung:** Flag `--dry-run` / Env `TEAM_DRY_RUN=1`: Lock holen, Gate laufen lassen, `git add` + `git diff --cached --stat` zeigen, aber **nicht** committen.
- **Dateien:** `scripts/team-commit.sh`
- **Akzeptanz:** `TEAM_DRY_RUN=1 scripts/team-commit.sh backend "test" src/x` gibt geplante Änderungen aus, erzeugt keinen Commit, gibt den Lock frei.
- **Aufwand:** S

### 0.2 Zentrales Event-Log neben den Agenten-Logs
- **Problem:** Lock-Events (acquire/break/timeout) landen nur auf stdout des jeweiligen Terminals → bei Problemen nicht nachvollziehbar.
- **Lösung:** Skripte schreiben strukturierte Zeilen (append-only) nach `.team/log/events.log` (`ts · role · script · event`). Eine Datei, ausschließlich von Skripten beschrieben → keine Agenten-Write-Race.
- **Dateien:** `scripts/team-commit.sh`, `scripts/team-exclusive.sh`, neu: `.team/log/events.log` (+ `.gitignore`-Eintrag, da Runtime-Artefakt)
- **Akzeptanz:** Nach einem Commit + einem exclusive-Run enthält `events.log` je eine `lock_acquire`/`lock_release`-Zeile.
- **Aufwand:** S

### 0.3 Gemeinsame Lock-Logik entdoppeln
- **Problem:** `team-commit.sh` und `team-exclusive.sh` haben fast identischen Lock-Code (Stale-Detection, FIFO-Wait) → Drift-Gefahr.
- **Lösung:** `scripts/lib/lock.sh` mit `acquire_lock`/`release_lock`; beide Skripte sourcen sie.
- **Dateien:** neu `scripts/lib/lock.sh`; `scripts/team-commit.sh`, `scripts/team-exclusive.sh`
- **Akzeptanz:** Beide Skripte verhalten sich unverändert; Lock-Logik existiert nur noch an einer Stelle.
- **Aufwand:** S

### 0.4 `.gitignore` für Laufzeit-Artefakte erweitern
- **Problem:** Neue Runtime-Dateien (`events.log`, Metriken, Health-State) dürfen nicht ins Git.
- **Lösung:** Muster ergänzen: `.team/log/events.log`, `.team/state/*`.
- **Dateien:** `.gitignore`
- **Akzeptanz:** `git state` zeigt nach einem Run keine Runtime-Artefakte als untracked.
- **Aufwand:** S

---

## Phase 1 — Robustheit & Selbstheilung (Review: „Kurzfristig" + PDF W1/W2)

### 1.0 Board-Synchronisations-Watchdog ⭐ (PDF-Priorität: **Kritisch**)
- **Problem (W2):** Der Lead pflegt `board.md` manuell aus den Logs. Vergisst er ein Update, driften Board und Logs auseinander → Inkonsistenz, die größte Praxis-Schwäche laut PDF.
- **Lösung:** `scripts/team-sync.sh` parst `.team/log/*.md` (CLAIM/DONE/BLOCKED + #id) und vergleicht mit `board.md`. **Stufe 1 (sicher, empfohlen):** nur *Drift-Report* — meldet Zeilen, deren State nicht zum jüngsten Log passt, nach `.team/log/events.log`. **Stufe 2 (opt-in):** der Lead lässt sich daraus einen Board-Patch vorschlagen; Schreibrecht bleibt beim Lead (One-writer-Regel bleibt intakt).
- **Dateien:** neu `scripts/team-sync.sh`; `.team/roles/lead.md` (bei `state` zuerst `team-sync.sh` laufen lassen); `.team/PROTOCOL.md`
- **Akzeptanz:** Ein `DONE #3` im Log, während Board #3 noch `doing` zeigt, erzeugt eine Drift-Meldung; nach Lead-Update ist die Meldung weg.
- **Aufwand:** M
- **Hinweis:** Bewusst **kein** Auto-Writer aufs Board als Default — das würde die „One writer per file"-Regel (Lead besitzt das Board) verletzen. Erkennung + Vorschlag, nicht stilles Überschreiben.

### 1.1 Stale-Task-Erkennung (PDF-Priorität: **Hoch**)
- **Problem (W1):** Stürzt ein Agent mit einem Item in `doing` ab, bleibt es ewig `doing`; kein Timeout setzt es zurück.
- **Lösung:** `scripts/team-health.sh` (siehe 1.2) markiert Items, deren Owner seit > N Minuten (Default 30) keinen Log-Eintrag hat, als **stale** und meldet sie dem Lead zur Rücksetzung auf `blocked`/`todo`. Rücksetzen bleibt Lead-Aktion (Board-Ownership).
- **Dateien:** `scripts/team-health.sh`; `.team/PROTOCOL.md` (Stale-Konvention)
- **Akzeptanz:** Ein `doing`-Item ohne frischen Owner-Log nach 30 min erscheint im Health-Report als `stale`.
- **Aufwand:** S (baut auf 1.2)

### 1.2 Health-Check für Agenten (PDF-Priorität: **Mittel**)
- **Problem:** Es ist nicht erkennbar, ob alle 4 Agenten noch aktiv sind („Single Point of Failure: Lead").
- **Lösung:** `scripts/team-health.sh` wertet die `mtime`/letzte Zeile jedes `.team/log/*.md` aus und meldet pro Rolle `active` / `idle` / `stale` (z. B. >15 min ohne Eintrag). Optionaler Heartbeat: Agenten schreiben bei jedem `state`-Tick eine `tick`-Zeile.
- **Dateien:** neu `scripts/team-health.sh`; Ergänzung in `.team/PROTOCOL.md` (Heartbeat-Konvention)
- **Akzeptanz:** `scripts/team-health.sh` listet 4 Rollen mit State; ein künstlich „altes" Log wird als `stale` markiert.
- **Aufwand:** S–M

### 1.3 Auto-Resume aus Git-History / Logs
- **Problem:** Bei Session-Ende/Crash geht der Kontext verloren; Board-Zustand muss manuell rekonstruiert werden.
- **Lösung:** `scripts/team-resume.sh` parst `.team/log/*.md` (CLAIM/DONE/BLOCKED) + `git log`, erstellt einen **Resume-Report** (offene Items, letzte Proofs, wer woran war) für den Lead. Der Lead gleicht damit `board.md` ab.
- **Dateien:** neu `scripts/team-resume.sh`; Ergänzung in `.team/roles/lead.md` (Erste Aktion: bei vorhandenen Logs erst `team-resume.sh`)
- **Akzeptanz:** Nach simuliertem Abbruch reproduziert der Report die letzten offenen/erledigten Items korrekt.
- **Aufwand:** M

### 1.4 Deadlock-Erkennung (alle `blocked`)
- **Problem:** Wenn alle Agenten `blocked` sind, steht das Team still, ohne dass es jemandem auffällt.
- **Lösung:** `scripts/team-health.sh` erkennt „alle aktiven Items `blocked`" bzw. „kein DONE in N Minuten" und schreibt eine `⚠ deadlock`-Zeile nach `.team/log/events.log` + Hinweis an den Lead. (Reine Erkennung + Eskalation; keine automatische Auflösung.)
- **Dateien:** `scripts/team-health.sh`; `.team/PROTOCOL.md` (Was tut der Lead bei Deadlock-Signal)
- **Akzeptanz:** Board mit ausschließlich `blocked`-Zeilen erzeugt ein Deadlock-Signal.
- **Aufwand:** S (aufbauend auf 1.2)

---

## Phase 2 — Isolation & Resilienz (Review: „Mittelfristig" + Top-Schwächen)

### 2.1 Worktrees als unterstützter Pfad (optional Default)
- **Problem:** „Keine echte Parallelität" — alle Agenten teilen einen Working Tree; Konfliktrisiko außerhalb `.team/`.
- **Lösung:** `scripts/team-worktrees.sh setup|sync|teardown` richtet pro Rolle `git worktree add ../<repo>-<role>` ein, hält `.team/` via commit+pull synchron. PROTOCOL nennt Worktrees bereits als Variante — hier wird sie **werkzeuggestützt und dokumentiert**.
- **Dateien:** neu `scripts/team-worktrees.sh`; `.team/PROTOCOL.md` (Variante ausbauen); `README.md` (Setup-Abschnitt)
- **Akzeptanz:** `setup` erzeugt 3 Worktrees (backend/frontend/quality) + Lead im Haupt-Tree; `.team/` ist in allen sichtbar; `teardown` räumt sauber auf.
- **Aufwand:** M–L
- **Hinweis:** Default bleibt zunächst Shared-Tree (einfachster Einstieg); Worktrees per Flag/Doku empfohlen für >1 paralleler Schreiber pro Bereich.

### 2.2 Fallback-Lead
- **Problem:** Nur der Lead pusht/integriert. Hängt der Lead, ist kein Release möglich.
- **Lösung:** Konvention + Skript-Unterstützung: Wenn `team-health.sh` den Lead als `stale` meldet, darf **Quality** als designierter Stellvertreter die Lead-Rolle übernehmen (Board-Sync + Push). Promotion wird explizit in `.team/log/events.log` und `log/quality.md` protokolliert, um Doppel-Pushes zu vermeiden.
- **Dateien:** `.team/roles/quality.md` (Fallback-Mandat), `.team/roles/lead.md` (Übergabe-Regel), `.team/PROTOCOL.md` (genau ein aktiver Lead via Lock)
- **Akzeptanz:** Bei „Lead stale" dokumentiert ein zweiter Agent die Übernahme; ein `lead.lock` verhindert zwei gleichzeitige Leads.
- **Aufwand:** M

### 2.3 Backup/Redundanz des Koordinationszustands (PDF W5)
- **Problem (W5):** Das gesamte Koordinationssystem hängt an Git. Eine Repo-Korruption oder ein Fremd-Force-Push auf den Branch ist fatal — kein Backup des `.team/`-Zustands.
- **Lösung:** `scripts/team-backup.sh` schnappschießt `.team/` (board, logs, roles) als Tarball nach `.team/backups/<ts>.tgz` (gitignored) und/oder pusht periodisch auf einen zweiten Remote/Branch (`team-state-backup`). Der Lead ruft es vor riskanten Integrationen auf. Plus PROTOCOL-Hinweis: niemals `--force` auf den geteilten Branch ohne Absprache.
- **Dateien:** neu `scripts/team-backup.sh`; `.gitignore` (`.team/backups/`); `.team/PROTOCOL.md` (Force-Push-Warnung + Restore-Schritt)
- **Akzeptanz:** `team-backup.sh` erzeugt einen wiederherstellbaren Snapshot; ein Restore stellt board+logs exakt wieder her.
- **Aufwand:** S–M

---

## Phase 3 — Transparenz & Metriken (Review: „Mittelfristig")

### 3.1 Agenten-Metriken im Board
- **Problem:** Keine Sicht auf Durchsatz, Blocker-Rate, Dauer pro Task.
- **Lösung:** `scripts/team-metrics.sh` leitet aus den Log-Timestamps (CLAIM→DONE) ab: Zeit pro Task, #Blocker, Done-Quote pro Rolle. Ausgabe als Markdown-Tabelle in `.team/metrics.md` (von Skript erzeugt, read-only für Agenten).
- **Dateien:** neu `scripts/team-metrics.sh`, generiert `.team/metrics.md`
- **Akzeptanz:** Nach einem Run zeigt `metrics.md` je Rolle mind. „Tasks done", „Ø Dauer", „Blocker".
- **Aufwand:** M

### 3.2 Live-State & Metriken in der GUI
- **Problem:** Die GUI zeigt nur die 4 Terminals, keinen aggregierten Team-State.
- **Lösung:** Statusleiste in `gui/public/index.html`: Health (aus 1.2), Board-Fortschritt (done/total) und Kurz-Metriken (aus 3.1). `gui/server.js` liefert `/state` (parst `.team/`-Dateien) und pollt periodisch.
- **Dateien:** `gui/server.js` (neuer `/state`-Endpoint), `gui/public/index.html` (Statusleiste)
- **Akzeptanz:** GUI zeigt „3/7 done", Health-Punkte pro Rolle, aktualisiert sich automatisch.
- **Aufwand:** M

---

## Phase 4 — Skalierbarkeit & Kommunikation (Review: „Langfristig" + PDF W3/W4)

### 4.1 Dynamische / zusätzliche Rollen
- **Problem:** Genau 4 statische Rollen; für DevOps/Security/Docs müssen Rollen manuell erweitert werden.
- **Lösung:** `scripts/team-role.sh add <name> <globs...>` erzeugt `roles/<name>.md` (aus Template), `log/<name>.md` und einen passenden Start-Prompt. Rollen-Template extrahieren, damit neue Rollen konsistent sind.
- **Dateien:** neu `scripts/team-role.sh`, neu `.team/roles/_template.md`; README-Abschnitt „Customize" erweitern
- **Akzeptanz:** `team-role.sh add security "src/**/*.security.*"` legt Rolle, Log und Prompt an; Agent kann ohne weitere Handarbeit starten.
- **Aufwand:** M

### 4.2 Sub-Teams / Hierarchien (Konzept + leichte Umsetzung)
- **Problem:** Keine Gruppierung für größere Projekte (>10 Domains).
- **Lösung:** Board um eine optionale Spalte `Team`/`Group` erweitern; ein Lead kann Sub-Leads benennen, die jeweils eigene Board-Sektionen verantworten. Bewusst leichtgewichtig (Konventionen, keine neue Infra).
- **Dateien:** `.team/board.md` (Spalte + Konvention), `.team/roles/lead.md` (Sub-Lead-Delegation), `.team/PROTOCOL.md`
- **Akzeptanz:** Ein Board mit 2 Gruppen + Sub-Leads ist eindeutig les- und delegierbar.
- **Aufwand:** L (zuerst als dokumentiertes Muster, dann Tooling)

### 4.3 Strukturiertes Handoff-Schema (PDF-Priorität: **Hoch**, W4)
- **Problem (W4):** Cross-Domain-Handoffs (`@role <ask>`) sind formloser Text. Keine Typisierung, keine Validierung, komplexe Abhängigkeiten nur per Konvention — fehleranfällig.
- **Lösung:** Leichtes, weiterhin menschenlesbares Markdown-Schema für Handoffs im Log, z. B.:
  `HH:MM · backend · 🤝 HANDOFF → @frontend · #id · needs:<artefakt> · blocks:<id> · <beschreibung>`.
  Optional `scripts/team-lint-log.sh`, das Handoff-Zeilen auf Pflichtfelder prüft (Ziel-Rolle, #id, `needs`/`blocks`). Bleibt Konvention + optionaler Linter — kein neues Nachrichtensystem (Philosophie!).
- **Dateien:** `.team/PROTOCOL.md` (Handoff-Format spezifizieren), optional `scripts/team-lint-log.sh`, ggf. Aufruf im Green-Gate
- **Akzeptanz:** Eine unvollständige Handoff-Zeile (ohne Ziel-Rolle oder #id) wird vom Linter beanstandet; ein valider Handoff passiert.
- **Aufwand:** S–M

---

## Phase 5 — Integration & Automatisierung (Review: „Langfristig" + PDF MCP)

### 5.1 GitHub Actions bei Board-Änderungen
- **Problem:** Keine Außenwirkung/CI-Trigger bei Fortschritt.
- **Lösung:** Workflow `.github/workflows/team.yml`: bei Push, der `.team/board.md` ändert, Gate laufen lassen + Board-Fortschritt als Job-Summary/State posten. Optional: Issue/PR-Kommentar mit aktuellem Stand.
- **Dateien:** neu `.github/workflows/team.yml`; ggf. kleines `scripts/board-summary.sh`
- **Akzeptanz:** Ein Push mit Board-Änderung erzeugt eine CI-Summary „X/Y done".
- **Aufwand:** M

### 5.2 Cross-Repo-Koordination (Microservices)
- **Problem:** Nur ein Repo koordinierbar.
- **Lösung:** Konzept + PoC: `.team/` als Git-Submodule/Shared-Folder über mehrere Repos; ein „Meta-Lead" aggregiert Boards. Zuerst als dokumentiertes Muster, dann optionales Sync-Skript.
- **Dateien:** `docs/cross-repo.md` (neu), optional `scripts/team-federate.sh`
- **Akzeptanz:** Zwei Repos teilen ein konsistentes Board-Abbild; State ist zentral lesbar.
- **Aufwand:** L

### 5.3 MCP-Integration (PDF-Priorität: **Mittel**)
- **Problem:** Keine standardisierte Schnittstelle zu externen Tools/Daten; das Kit ist eine geschlossene Insel.
- **Lösung:** Optionaler, **read-first** MCP-Server, der den `.team/`-Zustand (Board, Logs, Health, Metriken) als MCP-Ressourcen/Tools exponiert — so können externe Agenten oder Dashboards den Teamstatus lesen (später ggf. Items anlegen). Strikt optional und additiv; das Kern-Kit bleibt zero-dependency.
- **Dateien:** neu `mcp/` (eigenständiger Server, eigene `package.json`), `README.md` (Abschnitt „MCP, optional")
- **Akzeptanz:** Ein MCP-Client kann Board + Health über den Server abfragen, ohne dass das Basis-Kit Abhängigkeiten erhält.
- **Aufwand:** M–L
- **Hinweis:** Bewusst getrennt vom Kern (eigenes Verzeichnis/Deps), damit die Zero-Dependency-Philosophie des Scaffolds erhalten bleibt.

---

## Phase 6 — Persistenz & Lernen (Review-Schwäche „keine Kontext-Persistenz")

### 6.1 Run-übergreifender Speicher
- **Problem:** Kein Langzeit-Gedächtnis über mehrere Runs (Entscheidungen, Konventionen, Stolperfallen).
- **Lösung:** `.team/memory.md` (append-only, Lead-kuratiert): dauerhafte Entscheidungen, „gelernte" Projekt-Regeln, wiederkehrende Blocker. Agenten lesen sie beim Start (Ergänzung in den Start-Prompts).
- **Dateien:** neu `.team/memory.md`; `PROMPTS.md` + `gui/agents.json` (Start-Prompts lesen `memory.md`)
- **Akzeptanz:** Eine im Run 1 notierte Entscheidung ist in Run 2 für alle Agenten sichtbar/berücksichtigt.
- **Aufwand:** M

### 6.2 Sauberer Handoff zwischen Sessions/Instanzen
- **Problem:** Kein definierter Übergabe-Mechanismus zwischen verschiedenen Claude-Instanzen.
- **Lösung:** `scripts/team-handoff.sh` erzeugt ein Snapshot-Briefing (offene Items + `memory.md` + Resume-Report aus 1.3), das eine neue Instanz als Kontext bekommt.
- **Dateien:** neu `scripts/team-handoff.sh` (nutzt 1.3 + 6.1)
- **Akzeptanz:** Eine frische Instanz kann ausschließlich aus dem Briefing nahtlos weiterarbeiten.
- **Aufwand:** M

---

## Phase 7 — Lizenz & Community (Review-Schwäche „Lizenz bremst Adoption")

### 7.1 Lizenz-Strategie entscheiden
- **Problem:** „Private use only" verhindert Verbreitung/kommerzielle Nutzung.
- **Lösung:** Bewusste Entscheidung des Eigentümers (Belkis Aslani): Status quo behalten **oder** auf permissive Lizenz (z. B. MIT/Apache-2.0) bzw. duale Lizenz wechseln. Roadmap **empfiehlt** keinen Wechsel automatisch — sie macht die Option sichtbar.
- **Dateien:** `LICENSE`, `README.md`
- **Akzeptanz:** Dokumentierte, bewusste Entscheidung; falls Wechsel: konsistent in `LICENSE` + README.
- **Aufwand:** S
- **⚠️ Achtung:** Lizenzwechsel ist eine **Eigentümer-Entscheidung**, kein Agenten-Task. Nicht ohne ausdrückliche Freigabe ändern.

---

## Priorisierung (empfohlene Reihenfolge)

1. **Phase 0** komplett — billig, entlastet sofort und ist Fundament für alles Weitere.
2. **1.0 Board-Sync-Watchdog** + **1.1 Stale-Task** — die im PDF als *kritisch/hoch* bewerteten Lücken (Board↔Log-Drift, hängende `doing`-Tasks).
3. **1.2 Health-Check** + **1.4 Deadlock-Erkennung** — direkter Schmerz aus beiden Reviews.
4. **1.3 Auto-Resume** + **6.1 Memory** — adressiert die größte konzeptionelle Lücke (Persistenz).
5. **4.3 Handoff-Schema** — PDF *hoch*; macht Cross-Domain-Übergaben zuverlässig.
6. **2.2 Fallback-Lead** + **2.3 Backup** — entschärfen die Single-Points-of-Failure (Lead, Git).
7. **3.1/3.2 Metriken & GUI-State** — macht Fortschritt sichtbar, motiviert.
8. **2.1 Worktrees** — echte Parallelität, sobald Bedarf besteht.
9. **4.1/4.2 Skalierbarkeit**, **5.x Integration (inkl. MCP)** — wenn das Kit über kleine Projekte hinauswächst.
10. **7.1 Lizenz** — jederzeit, aber nur durch den Eigentümer.
11. **Anhang A** — nur falls akademische Vollständigkeit gewünscht ist (sonst bewusst weglassen).

### Aufwand/Wirkung-Matrix
| | Geringer Aufwand | Hoher Aufwand |
|---|---|---|
| **Hohe Wirkung** | 0.1–0.4, 1.1, 1.2, 1.4, 4.3, 6.1 | 1.0, 1.3, 2.1, 2.2, 3.x |
| **Geringere Wirkung** | 2.3, 7.1 | 4.1, 4.2, 5.2, 5.3 |

### Mapping zur PDF-Prioritätentabelle (Abschnitt 8.2 / Tabelle 7)
| PDF-Priorität | PDF-Empfehlung | Roadmap-Punkt |
|---|---|---|
| **Kritisch** | Automatische Board-Synchronisation | **1.0** Board-Sync-Watchdog |
| **Hoch** | Stale-Task-Erkennung | **1.1** Stale-Task |
| **Hoch** | Strukturierte Handoff-Formate | **4.3** Handoff-Schema |
| **Mittel** | MCP-Integration | **5.3** MCP-Server |
| **Mittel** | Health-Check-Script | **1.2** Health-Check |
| **Niedrig** | Dynamische Rollenverwaltung | **4.1** Dynamische Rollen |
| (W5, 6.2) | Backup/Redundanz des Zustands | **2.3** Backup |
| (6.3) | BDI / Contract Net / PGP / Org Self-Design | **Anhang A** (optional) |

---

## Umsetzung mit dem Kit selbst (Dogfooding)

Diese Roadmap eignet sich, um das Kit **an sich selbst** zu erproben:

- **Lead:** überführt eine Phase in `board.md`-Zeilen, integriert + pusht.
- **Backend:** Shell-Skripte (`scripts/team-*.sh`, `scripts/lib/`).
- **Frontend:** GUI-Erweiterungen (`gui/server.js`, `gui/public/index.html`).
- **Quality:** erweitert `scripts/team-check.sh` um Tests für die neuen Skripte (z. B. mit `bats`), validiert jede DONE-Zeile.

Vorgeschlagener erster Meilenstein für `board.md` (deckt die PDF-Top-Prioritäten zuerst ab):

```
| #  | Task                                      | Owner    | State | Notes                  |
| 1  | 0.3 lib/lock.sh extrahieren               | backend  | todo   | Basis für 0.1/0.2      |
| 2  | 0.1 --dry-run in team-commit.sh           | backend  | todo   | nach #1                |
| 3  | 0.2 events.log + 0.4 .gitignore           | backend  | todo   | nach #1                |
| 4  | 1.2 team-health.sh                         | quality  | todo   | liest .team/log/*      |
| 5  | 1.1 Stale-Task-Erkennung in health         | quality  | todo   | nach #4 · PDF „hoch"   |
| 6  | 1.4 Deadlock-Signal in health              | quality  | todo   | nach #4                |
| 7  | 1.0 team-sync.sh (Board↔Log-Drift-Report)  | backend  | todo   | PDF „kritisch"         |
| 8  | 4.3 Handoff-Schema in PROTOCOL + Linter    | quality  | todo   | PDF „hoch"             |
| 9  | bats-Tests für neue Skripte               | quality  | todo   | erweitert team-check   |
| 10 | Doku: README + PROTOCOL aktualisieren     | lead     | todo   | nach #1–#9             |
```

---

## Anhang A — Akademischer Backlog (optional, bewusst YAGNI)

Das PDF (Abschnitt 6.3) listet etablierte Multi-Agenten-Konstrukte, die das Kit **bewusst nicht**
hat. Das PDF selbst wertet diese Abwesenheit als YAGNI-konforme Designentscheidung. Sie stehen
hier nur als optionaler Forschungs-Backlog — eine Umsetzung würde die Einfachheit (Kern-Stärke
laut beiden Reviews) gefährden und sollte nur mit klarem Bedarf erfolgen.

- **BDI-Modell (Belief–Desire–Intention):** explizite Ziel-/Absichtsrepräsentation pro Agent (heute implizit im letzten Log-Eintrag). Denkbar: ein `intent:`-Feld in der Log-Konvention.
- **Contract Net Protocol:** dezentrale Task-Auktion statt zentraler Lead-Zuweisung. Widerspricht dem Lead-zentrierten Modell — nur bei sehr großen Teams sinnvoll.
- **Partial Global Planning:** Abgleich lokaler Pläne mit globaler Koordination. Teilweise schon durch board+logs angenähert.
- **Organizational Self-Design:** Team passt seine Struktur dynamisch an die Aufgabe an. Überschneidet sich mit 4.1/4.2 (dynamische Rollen/Sub-Teams).

**Empfehlung:** nicht umsetzen, bis ein konkreter Anwendungsfall es erzwingt. In der Roadmap als
Niedrigst-Priorität geführt.

---

## Hinweis zur Quelle dieser Roadmap

Diese Roadmap konsolidiert **zwei** externe KI-Reviews:
1. ein informelles Praxis-Review (Gesamt **8.5/10**) mit Kurz-/Mittel-/Langfrist-Vorschlägen;
2. das akademische **PDF-Technical-Review** „4-Agent Team Kit for Claude Code" (Gesamt **7.6/10**),
   inkl. Critical Assessment (W1–W5), fehlender Konstrukte (6.3) und der priorisierten
   Empfehlungstabelle (8.2 / Tabelle 7).

Beide Quellen sind vollständig eingearbeitet; die PDF-Prioritäten sind oben explizit gemappt
(siehe „Mapping zur PDF-Prioritätentabelle"). Die durchgehende Leitlinie bleibt die von beiden
Reviews gelobte Kern-Stärke: **radikale Einfachheit und Zero-Dependency** — jede Erweiterung ist
additiv, optional und darf das „4 Terminals, ein Repo"-Erlebnis nicht verkomplizieren.
