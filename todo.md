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
- Design-Dokument, Rechenmodell: abgestimmt und committet.
- Prototyp-Plan: Entwurf geschrieben, **wartet auf Freigabe** durch den Nutzer, noch nicht
  committet.
- Noch kein Code.

## Nächster Schritt
- [ ] Freigabe des Prototyp-Plans einholen, dann committen und pushen
- [ ] **M0 Projektgerüst** beginnen:
  - [ ] Prüfen, ob GUT mit Godot 4.7.2 läuft (Branch `godot_4_7`?); sonst gdUnit4
  - [ ] `project.godot` und Ordnerstruktur laut `prototyp-plan.md` Abschnitt 4
  - [ ] Ein Beispieltest, der headless läuft
  - [ ] GitHub-Actions-Workflow (Godot 4.7.2 Linux, Import, Tests)

## Meilensteine (aus `prototyp-plan.md` Abschnitt 11)
- [ ] M0 Projektgerüst
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
