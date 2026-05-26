# ROADMAP — 4-Agent Team Kit for Claude Code

> Diese Roadmap übersetzt die externen KI-Reviews (Gesamtnote **8.5/10**) in einen
> konkreten, umsetzbaren Plan. Jeder Punkt nennt **Problem → Lösung → betroffene Dateien
> → Akzeptanzkriterien → Aufwand**, damit das Team (oder ein einzelner Agent) ihn direkt
> in `board.md`-Zeilen überführen kann.
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

---

## Phasen-Überblick

| Phase | Thema | Ziel | Geschätzter Aufwand |
|-------|-------|------|---------------------|
| **0** | Fundament & Quick Wins | Skripte robuster, sicheres Testen | S (1–2 Tage) |
| **1** | Robustheit & Selbstheilung | Health-Check, Auto-Resume, Deadlock-Erkennung | M |
| **2** | Isolation & Resilienz | Worktrees als Option/Default, Fallback-Lead | M–L |
| **3** | Transparenz & Metriken | Board-Metriken, Live-Status in der GUI | M |
| **4** | Skalierbarkeit | Dynamische Rollen, Sub-Teams | L |
| **5** | Integration & Automatisierung | GitHub Actions / Webhooks, Cross-Repo | L |
| **6** | Persistenz & Lernen | Run-übergreifender Speicher, Handoff | M–L |
| **7** | Lizenz & Community | Adoption ermöglichen | S |

Aufwand: **S** = klein (Stunden–1 Tag) · **M** = mittel (Tage) · **L** = groß (Woche+).

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
- **Problem:** Neue Runtime-Dateien (`events.log`, Metriken, Health-Status) dürfen nicht ins Git.
- **Lösung:** Muster ergänzen: `.team/log/events.log`, `.team/state/*`.
- **Dateien:** `.gitignore`
- **Akzeptanz:** `git status` zeigt nach einem Run keine Runtime-Artefakte als untracked.
- **Aufwand:** S

---

## Phase 1 — Robustheit & Selbstheilung (Review: „Kurzfristig")

### 1.1 Health-Check für Agenten
- **Problem:** Es ist nicht erkennbar, ob alle 4 Agenten noch aktiv sind („Single Point of Failure: Lead").
- **Lösung:** `scripts/team-health.sh` wertet die `mtime`/letzte Zeile jedes `.team/log/*.md` aus und meldet pro Rolle `active` / `idle` / `stale` (z. B. >15 min ohne Eintrag). Optionaler Heartbeat: Agenten schreiben bei jedem `status`-Tick eine `tick`-Zeile.
- **Dateien:** neu `scripts/team-health.sh`; Ergänzung in `.team/PROTOCOL.md` (Heartbeat-Konvention)
- **Akzeptanz:** `scripts/team-health.sh` listet 4 Rollen mit Status; ein künstlich „altes" Log wird als `stale` markiert.
- **Aufwand:** S–M

### 1.2 Auto-Resume aus Git-History / Logs
- **Problem:** Bei Session-Ende/Crash geht der Kontext verloren; Board-Zustand muss manuell rekonstruiert werden.
- **Lösung:** `scripts/team-resume.sh` parst `.team/log/*.md` (CLAIM/DONE/BLOCKED) + `git log`, erstellt einen **Resume-Report** (offene Items, letzte Proofs, wer woran war) für den Lead. Der Lead gleicht damit `board.md` ab.
- **Dateien:** neu `scripts/team-resume.sh`; Ergänzung in `.team/roles/lead.md` (Erste Aktion: bei vorhandenen Logs erst `team-resume.sh`)
- **Akzeptanz:** Nach simuliertem Abbruch reproduziert der Report die letzten offenen/erledigten Items korrekt.
- **Aufwand:** M

### 1.3 Deadlock-Erkennung (alle `blocked`)
- **Problem:** Wenn alle Agenten `blocked` sind, steht das Team still, ohne dass es jemandem auffällt.
- **Lösung:** `scripts/team-health.sh` erkennt „alle aktiven Items `blocked`" bzw. „kein DONE in N Minuten" und schreibt eine `⚠ deadlock`-Zeile nach `.team/log/events.log` + Hinweis an den Lead. (Reine Erkennung + Eskalation; keine automatische Auflösung.)
- **Dateien:** `scripts/team-health.sh`; `.team/PROTOCOL.md` (Was tut der Lead bei Deadlock-Signal)
- **Akzeptanz:** Board mit ausschließlich `blocked`-Zeilen erzeugt ein Deadlock-Signal.
- **Aufwand:** S (aufbauend auf 1.1)

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

---

## Phase 3 — Transparenz & Metriken (Review: „Mittelfristig")

### 3.1 Agenten-Metriken im Board
- **Problem:** Keine Sicht auf Durchsatz, Blocker-Rate, Dauer pro Task.
- **Lösung:** `scripts/team-metrics.sh` leitet aus den Log-Timestamps (CLAIM→DONE) ab: Zeit pro Task, #Blocker, Done-Quote pro Rolle. Ausgabe als Markdown-Tabelle in `.team/metrics.md` (von Skript erzeugt, read-only für Agenten).
- **Dateien:** neu `scripts/team-metrics.sh`, generiert `.team/metrics.md`
- **Akzeptanz:** Nach einem Run zeigt `metrics.md` je Rolle mind. „Tasks done", „Ø Dauer", „Blocker".
- **Aufwand:** M

### 3.2 Live-Status & Metriken in der GUI
- **Problem:** Die GUI zeigt nur die 4 Terminals, keinen aggregierten Team-Status.
- **Lösung:** Statusleiste in `gui/public/index.html`: Health (aus 1.1), Board-Fortschritt (done/total) und Kurz-Metriken (aus 3.1). `gui/server.js` liefert `/status` (parst `.team/`-Dateien) und pollt periodisch.
- **Dateien:** `gui/server.js` (neuer `/status`-Endpoint), `gui/public/index.html` (Statusleiste)
- **Akzeptanz:** GUI zeigt „3/7 done", Health-Punkte pro Rolle, aktualisiert sich automatisch.
- **Aufwand:** M

---

## Phase 4 — Skalierbarkeit (Review: „Langfristig")

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

---

## Phase 5 — Integration & Automatisierung (Review: „Langfristig")

### 5.1 GitHub Actions bei Board-Änderungen
- **Problem:** Keine Außenwirkung/CI-Trigger bei Fortschritt.
- **Lösung:** Workflow `.github/workflows/team.yml`: bei Push, der `.team/board.md` ändert, Gate laufen lassen + Board-Fortschritt als Job-Summary/Status posten. Optional: Issue/PR-Kommentar mit aktuellem Stand.
- **Dateien:** neu `.github/workflows/team.yml`; ggf. kleines `scripts/board-summary.sh`
- **Akzeptanz:** Ein Push mit Board-Änderung erzeugt eine CI-Summary „X/Y done".
- **Aufwand:** M

### 5.2 Cross-Repo-Koordination (Microservices)
- **Problem:** Nur ein Repo koordinierbar.
- **Lösung:** Konzept + PoC: `.team/` als Git-Submodule/Shared-Folder über mehrere Repos; ein „Meta-Lead" aggregiert Boards. Zuerst als dokumentiertes Muster, dann optionales Sync-Skript.
- **Dateien:** `docs/cross-repo.md` (neu), optional `scripts/team-federate.sh`
- **Akzeptanz:** Zwei Repos teilen ein konsistentes Board-Abbild; Status ist zentral lesbar.
- **Aufwand:** L

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
- **Lösung:** `scripts/team-handoff.sh` erzeugt ein Snapshot-Briefing (offene Items + `memory.md` + Resume-Report aus 1.2), das eine neue Instanz als Kontext bekommt.
- **Dateien:** neu `scripts/team-handoff.sh` (nutzt 1.2 + 6.1)
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
2. **1.1 Health-Check** + **1.3 Deadlock-Erkennung** — direkter Schmerz aus den Reviews.
3. **1.2 Auto-Resume** + **6.1 Memory** — adressiert die größte konzeptionelle Lücke (Persistenz).
4. **2.2 Fallback-Lead** — entschärft den Single Point of Failure.
5. **3.1/3.2 Metriken & GUI-Status** — macht Fortschritt sichtbar, motiviert.
6. **2.1 Worktrees** — echte Parallelität, sobald Bedarf besteht.
7. **4.x Skalierbarkeit**, **5.x Integration** — wenn das Kit über kleine Projekte hinauswächst.
8. **7.1 Lizenz** — jederzeit, aber nur durch den Eigentümer.

### Aufwand/Wirkung-Matrix
| | Geringer Aufwand | Hoher Aufwand |
|---|---|---|
| **Hohe Wirkung** | 0.1–0.4, 1.1, 1.3, 6.1 | 1.2, 2.1, 2.2, 3.x |
| **Geringere Wirkung** | 7.1 | 4.2, 5.2 |

---

## Umsetzung mit dem Kit selbst (Dogfooding)

Diese Roadmap eignet sich, um das Kit **an sich selbst** zu erproben:

- **Lead:** überführt eine Phase in `board.md`-Zeilen, integriert + pusht.
- **Backend:** Shell-Skripte (`scripts/team-*.sh`, `scripts/lib/`).
- **Frontend:** GUI-Erweiterungen (`gui/server.js`, `gui/public/index.html`).
- **Quality:** erweitert `scripts/team-check.sh` um Tests für die neuen Skripte (z. B. mit `bats`), validiert jede DONE-Zeile.

Vorgeschlagener erster Meilenstein für `board.md`:

```
| # | Task                                   | Owner    | Status | Notes                |
| 1 | 0.3 lib/lock.sh extrahieren            | backend  | todo   | Basis für 0.1/0.2    |
| 2 | 0.1 --dry-run in team-commit.sh        | backend  | todo   | nach #1              |
| 3 | 0.2 events.log + 0.4 .gitignore        | backend  | todo   | nach #1              |
| 4 | 1.1 team-health.sh                      | quality  | todo   | liest .team/log/*    |
| 5 | 1.3 Deadlock-Signal in health          | quality  | todo   | nach #4              |
| 6 | bats-Tests für neue Skripte            | quality  | todo   | erweitert team-check |
| 7 | Doku: README + PROTOCOL aktualisieren  | lead     | todo   | nach #1–#6           |
```

---

## Hinweis zur Quelle dieser Roadmap

Diese Roadmap basiert auf den in der Anfrage übermittelten KI-Review-Texten
(Gesamtnote 8.5/10, inkl. Stärken/Schwächen und Kurz-/Mittel-/Langfrist-Vorschlägen).
Eine **PDF war im Upload nicht enthalten** (nur das Profilbild kam an). Sobald die PDF
nachgereicht wird, kann diese Roadmap um dort genannte, hier noch nicht erfasste Punkte
ergänzt werden.
