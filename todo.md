# TODO – Einstiegspunkt für neue Sessions

Stand: 2026-10-17

## Kontext in 30 Sekunden
- **Projekt:** "Kipppunkt", edukatives Strategiespiel (Godot 4.7.2, GDScript). Der Spieler
  führt eine junge Partei und versucht, eine Demokratie nach bundesdeutschem Vorbild
  autoritär umzubauen; Lernziel ist die wehrhafte Demokratie.
- **Dokumente** (in dieser Reihenfolge lesen):
  1. `docs/game-design.md` – Was das Spiel ist (Version 0.3)
  2. `docs/rechenmodell.md` – Formeln und Parameter der Kernschleife (Version 0.1)
  3. `docs/prototyp-plan.md` – Wie der MVP gebaut wird (Version 0.1, Meilensteine M0–M6)
  4. `docs/offene-fragen.md` – Inhaltliche Fragen, die noch warten können
- **Sprachen:** Design- und Planungsdokumente auf Deutsch; Code, Kommentare, Commits auf
  Englisch. Keine "Co-Authored-By"-Zeilen in Commits.
- **Repo:** GitHub `SN0371/kipppunkt`, Branch `main`.

## Aktueller Stand
- Design-Dokument, Rechenmodell, Prototyp-Plan: abgestimmt und committet.
- **M0 Projektgerüst** erledigt:
  - GUT 9.7.1 (Tag auf Branch `godot_4_7`) unter `addons/gut/`, läuft mit Godot 4.7.2
  - `project.godot`, `.gitignore`, `.gitattributes`, `.gutconfig.json`
  - Rauchtest `tests/unit/test_smoke.gd` (prüft Engine-Version 4.7)
  - CI `.github/workflows/ci.yml`: Godot 4.7.2 mit gepinnter SHA-512-Prüfsumme, Import,
    Tests, JUnit-Bericht als Artefakt
  - Ordner aus `prototyp-plan.md` Abschnitt 4 entstehen mit ihren ersten Dateien
    (keine leeren Platzhalter)

**Lokal testen:**
```
godot --headless --import
mkdir -p reports && godot --headless -s addons/gut/gut_cmdln.gd -gjunit_xml_file=res://reports/junit.xml
```

## Nächster Schritt
- [ ] **M1 Daten und Zustand** (`prototyp-plan.md` Abschnitte 3–5):
  - [ ] JSON-Daten für den MVP: Parameter, Länder, Regionen, Themen, Parteien,
        Medienhäuser, Geldgeber, Krisen, Szenario "Neugründung"
  - [ ] Typisierte Definitionen und Lader mit Validierung (`src/sim/defs/`)
  - [ ] Spielzustand mit `to_dict()`/`from_dict()` (`src/sim/state/`)
  - [ ] Tests: Daten laden, Verweise prüfen, Speichern/Laden ergibt identischen Zustand

## Meilensteine (aus `prototyp-plan.md` Abschnitt 11)
- [x] M0 Projektgerüst
- [ ] M1 Daten und Zustand
- [ ] M2 Kernschleife
- [ ] M3 Bots und Balancing
- [ ] M4 Karte und UI-Grundgerüst
- [ ] M5 Inhalte und Lokalisierung
- [ ] M6 Spieltest

## Offene Entscheidungen (nicht blockierend)
- Lizenz für Inhalte (Vorschlag: CC BY-SA 4.0 zusätzlich zur GPL-3.0 für Code)
- Arbeitsnamen der Parteien und Medienhäuser durch fiktive Namen ersetzen (spätestens M5)
- Siehe außerdem `docs/offene-fragen.md`
