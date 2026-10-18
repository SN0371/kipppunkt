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

- **M3 Bots und Balancing** erledigt (169 Tests grün, alle Korridore erfüllt):
  - 5 Strategie-Bots in `src/bots/` (eigener Zufallsgenerator, ändern den Spielzufall nicht)
  - Runner `src/tools/run_bots.gd` (CSV nach `reports/bots/`, `--param=name=wert` für
    Experimente), messbare Korridore in `src/bots/corridors.gd`
  - CI prüft die Korridore hart (100 Partien je Bot, feste Seeds, deterministisch)
  - Formeltests mit festem Parametersatz (`SimFixture.TEST_PARAMS`); Balancing ändert nur
    `data/params.json`, jede Änderung ins Protokoll `rechenmodell.md` Abschnitt 17
  - Modelländerungen (mit Nutzer entschieden): Geldgeber zahlen nur für passende
    Positionen (5.4); Mitglieder: Startschub, danach Zielwert nach Umfrage (6); relative
    Obergrenze der Parteienfinanzierung (6); Repräsentationslücke mit Wahlbeteiligung und
    Mobilisierung (3.8) – Radikalisierbarkeit aus unversorgten Anliegen, nicht aus
    Regionsmerkmalen
  - Stand (100 Partien je Bot): Geduldig 100 % Bundestag bis Runde 40; Radikal 75 % bis
    Runde 24, 90 % vorher Verdachtsfall; Doppelzüngig 64 % aufgedeckt nach 6–10 Runden;
    Passiv 100 % Bedeutungslosigkeit; Zufall 5 % Siege

**Bot-Lauf:** `godot --headless --path . -s src/tools/run_bots.gd -- --runs=200`

- **M4 Karte und UI-Grundgerüst** erledigt (189 Tests grün):
  - Karte aus Natural Earth v5.1.2 (gemeinfrei): `tools/map/build_map.py` (nur Standardbibliothek,
    Download-URL und SHA-256 im Skript), Orte der Institutionen in `tools/map/places.json`,
    Ergebnis `data/map/lands.json` (40 KB)
  - `src/ui/`: `GameSession` (Logik ohne Nodes, testbar), `MapView` (Überlagerungen Regionen,
    Umfrage, Wahlbeteiligung, Repräsentationslücke, Medienklima; Zoom; Klick auf Länder und
    Institutionen), Reiter Auswahl/Partei/Personal/Medien/Planung/Bericht, Speichern/Laden
    (`user://saves/`), Spielende-Dialog. Oberfläche wird im Code aufgebaut (`main.tscn` ist leer).
  - Übersetzungen `i18n/de.po` und `i18n/en.po` (270 Schlüssel, vollständig in beiden Sprachen);
    Test prüft, dass jeder benutzte Schlüssel existiert
  - `ActionResolver.check()` nimmt optional ein Restbudget, damit die Planung mehrere Aufträge
    gemeinsam prüft

- **Lesbarkeit (Nutzerrückmeldung):** Fenster startet mit 85 % der Bildschirmfläche in echten
  Pixeln, Oberfläche streckt mit (`canvas_items`), auf Retina also ~1,5-fach größer;
  zusätzlich Einstellung „Textgröße“ (80–200 %) in der Kopfzeile, gespeichert in
  `user://settings.cfg` (`UiSettings`).

- **Spieltest-Rückmeldung 1 (Datei `feedback`, 2026-10-18) umgesetzt:**
  - Modell: Themen als gerichtete Aussagen, 8 Themen (neu: Naturschutz, Schuldenbremse),
    widersprüchliche Positionen kosten dauerhaft Glaubwürdigkeit (`data/contradictions.json`,
    Rechenmodell 5.7), Reglermitte = keine Position, `P_Mob` 9
  - Oberfläche: Kopfzeile nur Datum, Geld, Aktionspunkte, Aktivisten; Overlay beim Rundenende
    (erst geplante Aufträge mit Abbrechen/Runde beenden, dann Ergebnisse mit Schließen);
    Overlays für regionale Botschaft (mit Erklärung), Partei-Aktionen und Geldgeber
    (`ContentDialog`); Schieberegler für Positionen (rot/grün); Werte als „x / 100“;
    Tooltips für Medienklima, Reichweite, Wahlbeteiligung; Runden bis zur nächsten Wahl;
    Länderbeschreibungen statt Themen-Tabelle; Repräsentationslücke nicht mehr sichtbar

- **Spieltest-Rückmeldung 2 (2026-10-18) umgesetzt:** Ernennen zeigt nach dem Planen einen
  Haken statt der zurückspringenden Auswahl; Personenwerte als Tabelle; Agenda-Hinweis
  entfernt (Aha-Moment); Partei-Reiter mit Klappbereichen (`FoldableContainer`);
  Delegation automatisch nach zuständiger Funktion (`delegate` in `data/actions.json`),
  kein AP-Rabatt, Parteichef übernimmt für +1 AP (Planungs-Reiter)

- **Spieltest-Rückmeldung 3 (2026-10-18) umgesetzt:** Aktionsknöpfe zeigen „✓ n× geplant“
  (grün getönt; Mehrfachplanung bleibt erlaubt), sind mit Grund im Tooltip deaktiviert, wenn
  die Aktion gerade nicht möglich ist (auch Positionsregler); Rückmeldezeile oben im Reiter;
  abgelehnter Positionswechsel setzt den Regler zurück (das war die Ursache für „nur eine
  Position pro Runde“: Ablehnung wegen Aktionspunkten war nur in der Statuszeile sichtbar)
- **Datei `feedback`:** private Spieltest-Notizen des Nutzers, in `.git/info/exclude`,
  nie committen (war einmal versehentlich in 61484c6, Historie bleibt so)

- **Spieltest-Rückmeldung 4 (2026-10-18) umgesetzt:** Gründungsassistent (Name, Abkürzung,
  Parteichef, Gründungsprogramm aus genau 2 Positionen; Namensvorschläge aus
  `data/names/suggestions.json`); Themen sind gesperrt, bis ein Ereignis zur Stellungnahme
  zwingt (`data/events.json`, 18 Ereignisse, `EventSystem`, Overlay vor der Planung);
  Schweigen kostet Glaubwürdigkeit; erneutes Ereignis erlaubt „neu nachdenken“ ohne AP;
  Positionswechsel per Regler 1 AP je Stufe; 0 = bewusst neutral; Speicherformat Version 2;
  Bots gründen und antworten nach Strategie; Balancing `P_RMin` 0,15, Mobilisierung · f_Reach

**Spiel starten:** `godot --path .` (oder im Editor F5).
**Bildschirmfotos ohne Hand:** Debug-Skript mit Fenster, `root.get_texture().get_image().save_png()`.

## Nächster Schritt
- [ ] **Nutzer spielt eine Partie von Hand** und gibt Rückmeldung zur Bedienung
- [ ] **M5 Inhalte und Lokalisierung** (`prototyp-plan.md` Abschnitt 11):
  - [ ] ca. 20 Aktionen (derzeit 18), weitere Ereignisse (derzeit 18 Themen-Ereignisse; noch
        keine Ereignisse ohne Themenbezug, z. B. Skandale, Überläufer)
  - [ ] Namenspools für Personen (derzeit namenlos, nur Funktion/Kandidat)
  - [ ] Fiktive Namen für Konkurrenzparteien, Medienhäuser und Geldgeber statt Arbeitsnamen
  - [ ] Lexikon-Texte (Institutionen, Normen, Vereinfachungen)

## Beobachtungen für später (M6 Spieltest)
- **Das MVP ist eher zu leicht:** Geduldig und Radikal gewinnen fast immer, selbst der
  Zufallsbot 5 %. Die Korridore haben keine Obergrenze für Erfolg. Im Spieltest prüfen,
  ob der Weg zum Bundestag spannend genug ist; ggf. Korridore um Obergrenzen ergänzen.
- Geld am Ende noch reichlich (Median 4.000–8.000 T€), aber erstmals in sinnvoller Größe.

## Meilensteine (aus `prototyp-plan.md` Abschnitt 11)
- [x] M0 Projektgerüst
- [x] M1 Daten und Zustand
- [x] M2 Kernschleife
- [x] M3 Bots und Balancing
- [x] M4 Karte und UI-Grundgerüst
- [ ] M5 Inhalte und Lokalisierung
- [ ] M6 Spieltest

## Offene Entscheidungen (nicht blockierend)
- Lizenz für Inhalte (Vorschlag: CC BY-SA 4.0 zusätzlich zur GPL-3.0 für Code)
- Arbeitsnamen der Parteien und Medienhäuser durch fiktive Namen ersetzen (spätestens M5)
- Siehe außerdem `docs/offene-fragen.md`
