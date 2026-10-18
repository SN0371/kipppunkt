# Technischer Prototyp-Plan (MVP)

Stand: 2026-10-18 · Version 0.2 (Stand nach M4) · Bezug: `game-design.md` 0.4, `rechenmodell.md` 0.5

> Dieser Plan beschreibt, **wie** der MVP gebaut wird: Architektur, Datenformat,
> Projektstruktur, Tests, automatisierte Bot-Partien, CI und Meilensteine. **Was** gebaut
> wird, legen das Design-Dokument (Abschnitt 14) und das Rechenmodell fest.

---

## 1. Rahmen

| Punkt | Festlegung |
|---|---|
| Engine | Godot 4.7.2 (lokal installiert), Version in CI fest gepinnt |
| Sprache | GDScript mit statischer Typisierung |
| Plattform | Desktop (macOS zuerst, Linux in CI) |
| Tests | GUT 9.7.1 (MIT, Zweig `godot_4_7`), unter 4.7.2 geprüft |
| CI | GitHub Actions |
| Lizenz | Code GPL-3.0 (vorhanden); Lizenz für Inhalte noch offen |

**Code-Konventionen**
- Bezeichner, Kommentare, Commit-Nachrichten und Log-Ausgaben auf **Englisch**. Deutsche
  Fachbegriffe bleiben, wo eine Übersetzung irreführt (`land`, `bundesrat`).
- Alle öffentlichen Funktionen erhalten Doc-Kommentare (`##`).
- Statische Typen überall (`var x: float`, typisierte Arrays).

---

## 2. Architekturprinzipien

1. **Simulation und Darstellung strikt getrennt.** Die Simulation (`src/sim/`) kennt keine
   Nodes, Szenen oder UI. Sie läuft vollständig ohne Grafik. Die UI liest den Zustand und
   schickt Befehle, rechnet aber nichts selbst.
2. **Ein Eingang für Spieler und Bots.** Spieler (über die UI) und Bots geben pro Runde
   dieselben **Aktionsaufträge** ab. Bots testen damit genau den Weg, den auch Spieler gehen.
3. **Deterministisch.** Jeder Zufall kommt aus einem einzigen `RandomNumberGenerator` im
   Spielzustand, initialisiert über den Seed. Keine globalen `randf()`-Aufrufe. Gleicher
   Seed und gleiche Aufträge ergeben denselben Zustand.
4. **Datengetrieben.** Inhalte (Länder, Regionen, Themen, Parteien, Medienhäuser, Aktionen,
   Ereignisse, Krisen, Parameter, Szenarien) liegen als Daten vor, nicht im Code.
5. **Akteursbasiertes Aktionssystem** (`game-design.md` 13): Aktionen gehören zu Akteuren.
   Im MVP handelt nur die Partei des Spielers; die Struktur lässt weitere Akteure zu.
6. **Ein Modifikator-System** für alle Regel-Besonderheiten (Regionen, Krisen, Personen,
   Ereignisse).
7. **Serialisierbarer Zustand.** Der gesamte Spielzustand lässt sich als Datei speichern und
   laden. Ein Szenario ist ein gespeicherter Startzustand.
8. **Nachvollziehbar.** Jeder Rechenschritt schreibt strukturierte Protokolleinträge. Daraus
   speisen sich der "Verlauf" in der UI, die Nachbesprechung und die Auswertung der Bots.

---

## 3. Datenformat: JSON

**Entscheidung:** Inhalte, Szenarien und Spielstände werden als **JSON** gespeichert, nicht
als Godot-Resources (`.tres`).

| Kriterium | JSON | Godot-Resources |
|---|---|---|
| Sicherheit beim Laden fremder Dateien | Reine Daten | Können Skripte einbetten und beim Laden Code ausführen |
| Lesbarkeit, Diffs, Merges | Gut | Mittel (UIDs, Pfade) |
| Bearbeitung durch externe Werkzeuge und Skripte | Einfach | Umständlich |
| Typprüfung | Eigener Lader mit Validierung | Eingebaut |
| Editor-Integration | Keine | Inspector |

Ausschlaggebend ist die **Sicherheit**: Szenarien sollen später von Lehrkräften geteilt
werden können. Eine geteilte `.tres`-Datei könnte beliebigen Code ausführen, eine JSON-Datei
nicht.

**Ausgleich für die fehlende Typprüfung:** Ein Lader übersetzt JSON in typisierte
GDScript-Klassen (Definitionen) und bricht bei Fehlern mit klarer Meldung ab (fehlende
Felder, falsche Typen, unbekannte Verweise, Werte außerhalb des Bereichs). Ein
Validierungsskript prüft alle Daten in CI.

**Bezeichner:** Sprechende String-IDs mit Präfix, z. B. `land.by`, `region.south`,
`topic.wind_power`, `party.conservatives`, `action.found_local_branch`.

---

## 4. Projektstruktur

```
kipppunkt/
├── project.godot
├── addons/gut/                     Testframework (eingebunden, MIT)
├── data/
│   ├── params.json                 Parameter P_… aus rechenmodell.md Abschnitt 13
│   ├── lands.json                  16 Länder mit Attributen und Themengewichten
│   ├── regions.json                6 Regionen, Zuordnung und Modifikatoren
│   ├── topics.json                 Themen als gerichtete Aussagen mit Ideologie-Vektoren
│   ├── contradictions.json         Widersprüchliche Positionspaare (rechenmodell.md 5.7)
│   ├── parties.json                Konkurrenzparteien
│   ├── media.json                  Medienhäuser inkl. öffentlich-rechtlichem Rundfunk
│   ├── donors.json                 Geldgeber
│   ├── crises.json                 Krisen
│   ├── actions.json                Aktionen (Kosten, Delegation, Effekte als Operationen)
│   ├── events.json                 Ereignisse, die eine Stellungnahme verlangen (5.8)
│   ├── names/suggestions.json      Namensvorschläge für den Gründungsassistenten
│   ├── map/lands.json              Vereinfachte Länderpolygone (generiert, siehe 8)
│   └── scenarios/new_party.json    Szenario "Neugründung"
├── i18n/
│   ├── de.po                       Deutsch (Hauptsprache)
│   └── en.po                       Englisch (darf anfangs unvollständig sein)
├── src/
│   ├── sim/                        Simulation, ohne Nodes
│   │   ├── defs/                   Typisierte Definitionen + JSON-Lader
│   │   ├── state/                  Spielzustand + Serialisierung
│   │   ├── systems/                Ein Skript je System aus dem Rechenmodell
│   │   ├── actions/                Auftrag, Auflösung, Loyalitätscheck
│   │   ├── modifiers/              Modifikator-System
│   │   ├── sim_log.gd              Strukturiertes Protokoll (Einträge im Spielzustand)
│   │   ├── sim_math.gd             Hilfsfunktionen
│   │   ├── voter_preferences.gd    Gemittelte Wählerpräferenzen je Gebiet
│   │   └── turn_runner.gd          Rundenablauf (rechenmodell.md Abschnitt 2)
│   ├── bots/                       Strategie-Bots, Kennzahlen, Korridore
│   ├── ui/                         UI-Skripte (Oberfläche wird im Code aufgebaut)
│   │   ├── map/                    Kartendaten und Kartenansicht
│   │   └── panels/                 Seitenleiste mit Tabs
│   └── tools/run_bots.gd           Headless-Bot-Lauf mit Korridorprüfung
├── tests/
│   ├── helpers/                    Testfixture mit festen Parametern, Zustandsvergleich
│   ├── unit/                       Formeln einzeln (sim/, bots/, ui/)
│   └── integration/                Ganze Runden, Partien, Bots, Hauptbildschirm
├── tools/map/                      Einmalige Kartenaufbereitung (siehe 8)
├── docs/
└── .github/workflows/ci.yml
```

**Zuordnung der Systeme zum Rechenmodell**

| Skript in `src/sim/systems/` | Rechenmodell |
|---|---|
| `economy_system.gd` | 6 Ressourcenfluss |
| `crisis_system.gd` | 11 Krisen |
| `polling_system.gd` | 3 Umfragemodell |
| `representation_system.gd` | 3.8 Repräsentationslücke, Wahlbeteiligung, Mobilisierung |
| `ideology_system.gd` | 5.1–5.3, 5.7 Ideologie, Kurswechsel, Widerspruchsrisiko, widersprüchliche Positionen |
| `founding_system.gd` | 5.8 Gründung mit Gründungsprogramm |
| `event_system.gd` | 5.8 Ereignisse und Stellungnahmen |
| `donor_system.gd` | 5.4 Geldgeber |
| `rival_system.gd` | 5.5 Konkurrenzparteien |
| `media_system.gd` | 5.6 Medienhäuser |
| `election_system.gd` | 7 Wahlen |
| `surveillance_system.gd` | 8 Radikalität, Beobachtungsdruck, Verfassungsschutz |
| `press_system.gd` | 9 Presse |
| `person_system.gd` | 10 Personen |
| `phase_system.gd` | 12 Phasen und Spielende |

**Namen im Code für die Symbole des Rechenmodells (Auszug)**

| Rechenmodell | Code |
|---|---|
| `G`, `M`, `A`, `AP` | `money`, `members`, `activists`, `action_points` |
| `C`, `Rad`, `B`, `VS` | `credibility`, `radicalism`, `scrutiny`, `vs_level` |
| `E`, `W`, `R` | `unity`, `contradiction_risk`, `resilience` |
| `RP`, `RK_l` | `reach_platform`, `reach_classic[land]` |
| `U_l`, `V_r` | `polling[land]`, `anchoring[region]` |
| `p_k`, `p_k,r`, `h_k` | `positions[topic]`, `regional_messages[region][topic]`, `position_age[topic]` |

---

## 5. Simulationskern

- **Zustand** (`src/sim/state/`): einfache Datenklassen mit `to_dict()` und
  `static from_dict()`. Kein Verweis auf Definitionen per Objekt, nur per ID.
- **Systeme** sind zustandslos: `static func step(state: GameState, defs: GameDefs) -> void`.
  Den Zufall holen sie aus `state.rng`, Protokolleinträge schreiben sie über `SimLog` in den
  Zustand.
- **TurnRunner** ruft die Systeme in der Reihenfolge aus `rechenmodell.md` Abschnitt 2 auf.
  Eine Runde ist zweigeteilt: `start_turn` (Einnahmen, Krisen, Ereignis, Kandidatenpool)
  vor der Planung, `finish_turn` mit den Aktionsaufträgen danach. Dazwischen beantwortet der
  Spieler ein anstehendes Ereignis.
- **Aktionen:** Ein Auftrag nennt Aktion, Ziel und optional die ausführende Person. Die
  Auflösung prüft Kosten, berechnet die Erfolgschance, führt den Loyalitätscheck aus und
  wendet Effekte und Nebenwirkungen an. Effekte sind in den Aktionsdaten als Liste
  einfacher Operationen beschrieben (z. B. `{"op": "add", "path": "anchoring.region", "value": 4}`),
  nicht als Code.
- **Modifikatoren:** Quelle, Ziel (Kennzahl, Aktion oder Formelterm), Art (`add`, `mul`),
  Wert, Dauer. Das System sammelt pro Berechnung alle passenden Modifikatoren ein.
- **Determinismus-Prüfung:** Ein Test spielt eine Partie zweimal mit gleichem Seed und
  vergleicht den serialisierten Zustand nach jeder Runde. Spielstände speichern Seed und
  RNG-Zustand als Text; nach dem Laden wird mit kleiner Toleranz verglichen, weil Godot
  Fließkommazahlen aus JSON nicht immer bitgenau einliest.

---

## 6. Tests

| Ebene | Inhalt | Beispiel |
|---|---|---|
| Einheit | Jede Formel aus dem Rechenmodell mit festen Eingaben und erwartetem Ergebnis | Themenpassung bei bekannten Positionen; Konkurrenzdruck in der Mitte ≈ 0,31 |
| Daten | Alle JSON-Dateien laden fehlerfrei, Verweise stimmen | Jede Aktion verweist auf existierende Kennzahlen |
| Integration | Ganze Runden und Partien | 100 Runden ohne Absturz; Determinismus; Speichern und Laden ergibt identischen Zustand |
| Lokalisierung | Alle verwendeten Textschlüssel existieren in `de.po` | Fehlender Schlüssel lässt den Test scheitern |

Tests laufen ohne Grafik: `godot --headless -s addons/gut/gut_cmdln.gd` (Konfiguration in
`.gutconfig.json`; für JUnit-XML zusätzlich `-gjunit_xml_file=res://reports/junit.xml`).
Formeltests verwenden feste Testparameter (`tests/helpers/sim_fixture.gd`), damit
Balancing-Änderungen in `params.json` sie nicht brechen.

---

## 7. Strategie-Bots und Balancing

- **Bots** (`src/bots/`): geduldig, radikal, doppelzüngig, passiv, zufällig
  (`rechenmodell.md` Abschnitt 14). Jeder Bot ist ein Skript, das aus dem Zustand die
  Aufträge einer Runde ableitet.
- **Lauf:** `godot --headless --path . -s src/tools/run_bots.gd -- --bot=patient --runs=500 --seed=1`
  spielt Partien und schreibt je Partie eine Zeile in eine CSV-Datei (`reports/bots/`):
  Ausgang, Runde des Bundestagseinzugs, höchste VS-Stufe, Runde der ersten Aufdeckung,
  Endwerte. `--param=<name>=<wert>` überschreibt einen Parameter für Experimente.
- **Korridorprüfung:** Derselbe Lauf vergleicht die Ergebnisse mit den Zielkorridoren
  (`src/bots/corridors.gd`) und gibt einen kurzen Bericht aus. Parameter werden angepasst,
  bis alle Bots in ihren Korridoren liegen; jede Änderung steht in `rechenmodell.md` 17.
- Die Bots laufen **vor** dem Bau der UI. So ist sichergestellt, dass die Simulation
  trägt, bevor Zeit in die Oberfläche fließt.

---

## 8. Karte

- **Quelle:** Natural Earth, Verwaltungsgrenzen erster Ordnung (Maßstab 1:10 Mio.).
  Gemeinfrei, keine Namensnennung nötig, für eine stilisierte Karte genau genug.
  Ausweichquelle: Bundesamt für Kartographie und Geodäsie (Namensnennung nötig).
- **Aufbereitung:** Ein einmaliges Python-Skript (`tools/map/build_map.py`, Natural Earth
  v5.1.2 mit SHA-256-Prüfsumme) schneidet Deutschland aus, vereinfacht die Polygone und
  schreibt sie zusammen mit Orten aus `tools/map/places.json` nach `data/map/lands.json`. Das Ergebnis wird
  committet; zur Laufzeit wird kein Python gebraucht.
- **Darstellung:** `Polygon2D` je Land, Färbung nach gewählter Überlagerung (Umfrage,
  Reichweite usw.), Regionen als Gruppierung.

---

## 9. Benutzeroberfläche (MVP)

Platzhaltergrafik, Fokus auf Bedienbarkeit.

| Ansicht | Inhalt |
|---|---|
| Gründungsassistent | Parteiname und Kürzel, Vorsitz, Gründungsprogramm aus zwei Positionen mit regionaler Stimmung; Namensvorschläge |
| Ereignis-Overlay | Vor der Planung: Stellung beziehen oder schweigen, bei besetzten Themen beibehalten oder neu nachdenken |
| Karte | 16 Länder, Überlagerungen (Regionen, Umfrage, Wahlbeteiligung, Medienklima), Institutionen als Symbole |
| Auswahl | Zustand und Aktionen des gewählten Landes oder der gewählten Institution (`game-design.md` 3.3) |
| Rundenplanung | Aktionspunkte, Ressourcen, geplante Aufträge mit ausführender Person; "Runde beenden" zeigt die Aufträge zur Bestätigung und danach die Ergebnisse |
| Quartalsbericht | Ereignisse, Umfrageveränderungen, Presseberichte der letzten Runde |
| Partei | Kennzahlen, Themenpositionen, regionale Botschaften, Ideologie-Profil |
| Personal | Kandidatenpool, Funktionen, Attribute (Agenda verborgen) |
| Medien | Häuser mit Reichweite, Glaubwürdigkeit, Ton |
| Speichern/Laden | Spielstände als JSON (Format-Version 2) |
| Einstellungen | Textgröße 80–200 %; Fenster wird an den Bildschirm angepasst |

Die Oberfläche wird im Code aufgebaut (`main.tscn` enthält nur den Wurzelknoten); Abschnitte
lassen sich einklappen. Alle Texte über Übersetzungsschlüssel (`tr()`), keine fest
verdrahteten Strings.

---

## 10. CI (GitHub Actions)

Bei jedem Push und Pull Request:
1. Godot 4.7.2 (Linux, offizielles Release) herunterladen, mit Cache.
2. Projekt einmal importieren (`godot --headless --import`), damit Klassen registriert sind.
3. Datenvalidierung: läuft als Test (`test_shipped_data_loads_without_errors`) im Testschritt mit, kein eigenes Skript.
4. Tests mit GUT, Ergebnis als JUnit-XML.
5. Bot-Lauf mit 100 Partien je Bot und festen Seeds. Die Korridorprüfung ist ein hartes
   Kriterium: Verfehlt ein Bot seinen Korridor, hat eine Änderung das Balancing gebrochen.

---

## 11. Meilensteine

Jeder Meilenstein endet mit einem prüfbaren Ergebnis und einem Commit.

| # | Meilenstein | Ergebnis / Prüfung | Stand |
|---|---|---|---|
| M0 | Projektgerüst | `project.godot`, Ordnerstruktur, GUT läuft unter 4.7.2 (sonst gdUnit4), ein Beispieltest, CI grün | ✓ |
| M1 | Daten und Zustand | Alle MVP-Daten als JSON, Lader mit Validierung, Spielzustand mit Speichern/Laden, Szenario "Neugründung" lädt; Tests grün | ✓ |
| M2 | Kernschleife | Alle Systeme aus dem Rechenmodell, Aktionsauflösung, Modifikatoren, Protokoll; Formeltests, 100-Runden-Test, Determinismus-Test grün | ✓ |
| M3 | Bots und Balancing | 5 Bots, Bot-Lauf, Korridorbericht; erster Balancing-Durchgang, Parameter in `params.json` angepasst und begründet | ✓ |
| M4 | Karte und UI-Grundgerüst | Karte aus Geodaten, Ansichten aus Abschnitt 9 mit Platzhaltern; eine Partie ist von Hand spielbar | ✓ (inkl. Spieltest-Runden 1–4) |
| M5 | Inhalte und Lokalisierung | ca. 20 Aktionen, 30 Ereignisse, Namenspools, deutsche Texte vollständig, englische Schlüssel vorhanden | offen (18 Aktionen, 18 Ereignisse vorhanden) |
| M6 | Spieltest | Du spielst; Rückmeldungen fließen in Design-Dokument, Rechenmodell und Parameter | offen |

---

## 12. Risiken

| Risiko | Gegenmaßnahme |
|---|---|
| Balancing trägt nicht | Bots vor der UI (M3); Parameter vollständig in Daten |
| GUT noch nicht für 4.7 freigegeben | Erledigt: GUT 9.7.1 läuft unter 4.7.2 |
| Fließkomma-Unterschiede zwischen Plattformen | Determinismus nur je Plattform garantieren; CI prüft unter Linux |
| Umfang wächst | Nur, was in `game-design.md` 14 steht; Neues erst nach M6 |
| Leistung der Bot-Läufe in GDScript | Größenordnung ca. 500 Partien × 100 Runden × 16 Länder ist unkritisch; bei Bedarf Läufe parallel als mehrere Prozesse |
