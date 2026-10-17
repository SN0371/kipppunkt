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
    exakt in JSON-Zahlen)
- **M2 Kernschleife** erledigt (145 Tests grün, Suite läuft in < 1 s):
  - Alle Systeme aus dem Rechenmodell in `src/sim/systems/*_system.gd`, dazu
    `SimMath`, `SimLog` (Protokoll im Zustand), Modifikatoren (`src/sim/modifiers/`)
  - Aktionen als Daten (`data/actions.json`, Effekte als Operationen), Auflösung in
    `src/sim/actions/action_resolver.gd` mit Kosten, Delegation, Loyalitätscheck
  - `TurnRunner`: `start_turn()` → Aufträge → `finish_turn()`; Speichern dazwischen erlaubt
  - Integrationstests (`tests/integration/`): ganze Partien, Invarianten, Determinismus,
    Weiterspielen nach Laden
  - Lücken im Rechenmodell entschieden und dokumentiert: `rechenmodell.md` Abschnitt 16
  - **Godot-Einschränkung:** JSON-Kommazahlen kommen nicht immer bitgenau zurück (letzte
    Binärstelle). Wiederholung über Seed + Aufträge ist exakt; geladene Spielstände sind
    praktisch identisch. Tests vergleichen Spielstände mit `StateCompare` (Toleranz).
- **Code-Konventionen im Projekt:** Runde heißt im Code `turn` (nicht `round`, Konflikt mit
  der eingebauten Funktion); System-Skripte heißen `*_system.gd`; IDs mit Präfix
  (`land.by`, `topic.taxes`). Test-Helfer in `tests/helpers/` (`SimFixture`, `StateCompare`).
- **Debug-Skripte:** headless mit `godot --headless --path . --quit-after 10 -s <skript>`;
  `--quit-after` beendet Godot auch nach einem Skriptfehler (macOS hat kein `timeout`).

**Lokal testen:**
```
godot --headless --import
mkdir -p reports && godot --headless -s addons/gut/gut_cmdln.gd -gjunit_xml_file=res://reports/junit.xml
```

## Nächster Schritt
- [ ] **M3 Bots und Balancing** (`prototyp-plan.md` Abschnitt 7, Korridore in
      `rechenmodell.md` Abschnitt 14):
  - [ ] 5 Strategie-Bots in `src/bots/`: geduldig, radikal, doppelzüngig, passiv, zufällig
  - [ ] Headless-Lauf `src/tools/run_bots.gd` → CSV je Partie
  - [ ] Korridorprüfung mit Bericht; kurzer Bot-Lauf in CI (zunächst nur Warnungen)
  - [ ] Balancing-Durchgang, Parameteränderungen begründen
- **Erste Befunde aus einem Probelauf (40 Partien je Strategie, Ende M2):**
  - **Geld ist kein Engpass:** Geldgeber zahlen inzwischen nur für passende Positionen
    (`rechenmodell.md` 5.4, mit Nutzer entschieden). Hauptquelle ist jetzt die staatliche
    Teilfinanzierung: Schon ~0,6 % bei der Bundestagswahl bringen ~54 T€/Quartal bei
    Fixkosten von ~9 T€. Der Betrag ist realistisch, Kosten und Aktionen sind zu billig.
    Passive Partei hat nach 15 Runden ~550–770 T€. **Im Balancing lösen** (z. B. Fixkosten,
    Aktionskosten, Personal kostet Geld).
  - Passiv: 19/40 Bedeutungslosigkeit, 21/40 Zeitablauf (Umfrage pendelt um 1 %) –
    Korridor verlangt Bedeutungslosigkeit in der Mehrheit.
  - Einfache Teststrategie: 24/40 Bundestag (Median Runde 56), sonst Zeitablauf –
    langsamer als der Korridor des geduldigen Bots (20–32 Runden).
  - Verankerung erreicht schnell 100 in beiden Regionen.

## Meilensteine (aus `prototyp-plan.md` Abschnitt 11)
- [x] M0 Projektgerüst
- [x] M1 Daten und Zustand
- [x] M2 Kernschleife
- [ ] M3 Bots und Balancing
- [ ] M4 Karte und UI-Grundgerüst
- [ ] M5 Inhalte und Lokalisierung
- [ ] M6 Spieltest

## Offene Entscheidungen (nicht blockierend)
- Lizenz für Inhalte (Vorschlag: CC BY-SA 4.0 zusätzlich zur GPL-3.0 für Code)
- Arbeitsnamen der Parteien und Medienhäuser durch fiktive Namen ersetzen (spätestens M5)
- Siehe außerdem `docs/offene-fragen.md`
