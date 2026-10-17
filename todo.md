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
- **M1 Daten und Zustand** erledigt (32 Tests grün):
  - `data/`: Parameter (mit Symbol aus dem Rechenmodell), 16 Länder, 6 Regionen,
    6 Themen, 3 Konkurrenzparteien, 5 Medienhäuser, 5 Geldgeber, 2 Krisen,
    Szenario `scenario.new_party`. Länderwerte sind plausible Spielwerte **[Vereinfachung]**.
  - `src/sim/defs/`: `JsonReader` (typgeprüftes Lesen, sammelt Fehler),
    je Datentyp eine `*Def`-Klasse, `GameDefs.load_from_dir("res://data")` mit
    Querverweis-Prüfung (Regionen, Themen vollständig je Land, Bevölkerungsanteile = 1 …)
  - `src/sim/state/`: `GameState` und Teilzustände mit `to_dict()`/`from_dict()`,
    `StateFactory.create(defs, scenario_id, seed)`, `SaveGame` (JSON, Format-Version 1)
  - Seed und Zufallsgenerator-Zustand werden als Text gespeichert (64 Bit passen nicht
    exakt in JSON-Zahlen); Kommazahlen mit voller Genauigkeit
  - `src/sim/systems/media_system.gd`: bisher nur `target_credibility()`
- **Code-Konventionen im Projekt:** Runde heißt im Code `turn` (nicht `round`, Konflikt mit
  der eingebauten Funktion); System-Skripte heißen `*_system.gd`; IDs mit Präfix
  (`land.by`, `topic.taxes`).

**Lokal testen:**
```
godot --headless --import
mkdir -p reports && godot --headless -s addons/gut/gut_cmdln.gd -gjunit_xml_file=res://reports/junit.xml
```

## Nächster Schritt
- [ ] **M2 Kernschleife** (`prototyp-plan.md` Abschnitt 5, Formeln aus `rechenmodell.md`).
      Jedes System mit Formeltests (feste Eingaben, erwartetes Ergebnis):
  - [ ] `SimLog` (strukturiertes Protokoll) und `TurnRunner` mit Rundenablauf (Rechenmodell 2)
  - [ ] Ressourcenfluss (6)
  - [ ] Ideologie, Kurswechsel, Widerspruchsrisiko (5.1–5.3), Konkurrenzparteien (5.5)
  - [ ] Medienhäuser (5.6)
  - [ ] Umfragemodell (3)
  - [ ] Geldgeber (5.4)
  - [ ] Wahlen (7), Phasen und Spielende (12)
  - [ ] Beobachtungsdruck und Verfassungsschutz (8), Presse (9)
  - [ ] Personen: Erzeugung, Agenden, Loyalitätscheck (10)
  - [ ] Krisen (11)
  - [ ] Aktionen: Auftrag, Kosten, Erfolgschance, Effekte als Daten; Modifikator-System;
        MVP-Aktionen aus Rechenmodell 4.2 als JSON
  - [ ] Integrationstests: 100 Runden ohne Absturz, Determinismus (gleicher Seed = gleiche
        Partie), Speichern mitten in der Partie und Weiterspielen ergibt dieselbe Partie

## Meilensteine (aus `prototyp-plan.md` Abschnitt 11)
- [x] M0 Projektgerüst
- [x] M1 Daten und Zustand
- [ ] M2 Kernschleife
- [ ] M3 Bots und Balancing
- [ ] M4 Karte und UI-Grundgerüst
- [ ] M5 Inhalte und Lokalisierung
- [ ] M6 Spieltest

## Offene Entscheidungen (nicht blockierend)
- Lizenz für Inhalte (Vorschlag: CC BY-SA 4.0 zusätzlich zur GPL-3.0 für Code)
- Arbeitsnamen der Parteien und Medienhäuser durch fiktive Namen ersetzen (spätestens M5)
- Siehe außerdem `docs/offene-fragen.md`
