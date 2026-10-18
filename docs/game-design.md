# Game-Design-Dokument: Kipppunkt (Arbeitstitel)

Stand: 2026-10-17 · Version 0.3 (Entwurf: Antworten aus `offene-fragen.md` eingearbeitet)

> Vereinfachungen gegenüber dem echten Recht sind mit **[Vereinfachung]** markiert.
> Werte wie Schwellen, Kosten und Wahrscheinlichkeiten sind Platzhalter für das Balancing.

---

## 1. Vision & Lernziel

**Kernsatz:** Der Spieler führt eine junge Partei vom Ortsverband bis an die Schalthebel des
Staates und erlebt dabei, dass eine Demokratie selten mit einem Schlag fällt, sondern
schrittweise ausgehöhlt wird: durch legale Mittel, gebrochene Konventionen und das Schweigen
derer, die profitieren.

**Lernziele**
1. Demokratie stützt sich nicht nur auf geschriebene Regeln, sondern auf ungeschriebene
   Normen und auf Menschen, die sie einhalten.
2. Die Mechanik des Machtausbaus ist weitgehend unabhängig von der Ideologie.
3. Die wehrhafte Demokratie hat wirksame Werkzeuge, aber sie wirken nur, wenn sie rechtzeitig
   und entschlossen genutzt werden.
4. Medien, Geld und lokale Verankerung sind keine Nebenschauplätze, sondern Machtbasis.

**Designprinzipien**
- **Lernen durch Widerstand:** Der Erkenntnisgewinn entsteht dort, wo der Spieler an
  Gegenkräften scheitert oder sie umgehen muss. Gegenkräfte sind daher ein Kernsystem, kein
  Hindernis-Beiwerk.
- **Abstraktion auf Systemebene:** Aktionen sind strategische Entscheidungen mit Kosten,
  Risiken und Folgen ("Medienkampagne gegen Gericht starten"), keine operativen Anleitungen.
- **Fiktive Akteure:** Alle Parteien, Personen, Medienhäuser und Unternehmen sind erfunden.
  Reale Bezüge erscheinen nur in der Nachbesprechung (Abschnitt 11) als historische Parallelen.
- **Konsequenzen sichtbar machen:** Jede Aktion verändert messbar die demokratische
  Resilienz des Landes. Der Spieler soll sehen, was er beschädigt.
- **Der Kipppunkt bleibt unsichtbar:** Ab wann die Demokratie verloren ist, zeigt das Spiel
  nicht an. Erst die Nachbesprechung (Abschnitt 11) benennt den Moment. Daher der Titel.
- **Simulation als Rückgrat:** Der Spielzustand entsteht aus vernetzten Kennzahlen.
  Ereignisse werden überwiegend vom Zustand ausgelöst; handgeschriebene Ereignisketten gibt
  es nur für Schlüsselmomente (Abschnitt 4.2).

---

## 2. Referenzen

| Spiel | Was wir übernehmen |
|---|---|
| Tropico | Setting-Gefühl, satirischer Unterton, Fraktionen mit eigenen Erwartungen |
| Suzerain | Personen mit Loyalität und Agenda, Entscheidungen mit verzögerten Folgen |
| Democracy 4 | Vernetzte Kennzahlen, Wählergruppen mit Präferenzen |
| Through the Darkest of Times | Edukativer Anspruch, historischer Kontext, ernster Ton |
| Secret Hitler | Spannung zwischen öffentlichem Auftreten und verdeckter Absicht |

---

## 3. Spielwelt & zentrale Ansicht

### 3.1 Die Karte
Zentrale Ansicht ist eine stilisierte Deutschlandkarte mit den 16 Ländern. Auf ihr liegen
Institutionen als anklickbare Orte. Ein Wechsel zwischen **Bundesebene** und
**Regionsebene** (Zoom auf eine Region, siehe 3.4) ist möglich.

Farbliche Überlagerungen (umschaltbar):
- Umfragewerte der eigenen Partei je Land
- Regierungskonstellationen der Länder
- Medienreichweite (eigene / gegnerische)
- Beobachtungsdruck und Protestaktivität

### 3.2 Institutionen auf der Karte

**Bundesebene**
| Ort | Institution | Funktion im Spiel |
|---|---|---|
| Berlin | Bundestag | Gesetzgebung, Kanzlerwahl, Richterwahl (Hälfte BVerfG), Ausschüsse |
| Berlin | Bundesrat | Länderkammer, Zustimmungsgesetze, Richterwahl (Hälfte BVerfG) |
| Berlin | Kanzleramt / Bundesregierung | Ministerien, Personalpolitik, Haushalt |
| Berlin | Bundespräsident | Ausfertigung von Gesetzen, Ernennungen, Bundestagsauflösung |
| Karlsruhe | Bundesverfassungsgericht | Normenkontrolle, Organstreit, Parteiverbot |
| Köln | Verfassungsschutz (Bund) | Beobachtung, Einstufung von Parteien |
| verteilt | Bundesbehörden | Später: übernehmbare Verwaltung (Phase V/VI) |

**Landesebene (je Land)**
| Institution | Funktion im Spiel |
|---|---|
| Landtag | Landesgesetze, Wahl der Landesregierung |
| Landesregierung | Bestimmt die Bundesratsstimmen des Landes, Landespolizei, Landesmedienanstalt |
| Landesverfassungsgericht | Landesspezifische Kontrolle |
| Landesamt für Verfassungsschutz | Eigene Beobachtung, kann vom Bund abweichen |
| Kommunen (aggregiert je Region) | Ortsverbände, Mandate in Stadt- und Gemeinderäten |

**Nichtstaatliche Orte**
- Medienhäuser (fiktive Verlags- und Senderfamilien) in Hamburg, München, Köln, Berlin
- Unternehmen (fiktive Familienunternehmen und Konzerne), verteilt nach Wirtschaftsregionen
- Plattformen (Soziale Medien) als ortlose Ebene, erreichbar über ein eigenes Panel

### 3.3 Interaktionsmodell
Klick auf eine Institution öffnet ein **Panel** mit:
1. **Zustand:** Mehrheitsverhältnisse, Unabhängigkeit, öffentliches Vertrauen
2. **Akteure:** Personen mit ihren Attributen (siehe 3.6)
3. **Aktionen:** Was der Spieler hier tun kann, mit Kosten, Erfolgschance und Risiko
4. **Verlauf:** Was zuletzt hier geschehen ist (Nachvollziehbarkeit für den Spieler)

### 3.4 Regionen
16 Länder als je eigener Spielschauplatz würden zu Wiederholung führen. Daher gilt:

- **Länder bleiben mechanische Einheiten**, wo sie zählen: Landtagswahlen (gestaffelt),
  Landesregierungen, Bundesratsstimmen, Landesverfassungsschutz.
- **Die laufende Arbeit findet in Regionen statt:** Ortsverbände, Mobilisierung, lokale
  Medien, regionale Spender und Interessengruppen werden je Region bearbeitet.
- **Regionen unterscheiden sich in den Regeln, nicht nur in den Startwerten.**
- **Landespolitik läuft im Hintergrund automatisch**, solange die Partei dort nicht
  mitregiert. Der Spieler greift bei Wahlen und Ereignissen ein.
- **Parametrisiert:** Regionen und Länder sind Datensätze mit Attributen (z. B.
  Altersdurchschnitt, Arbeitslosigkeit, Parteibindung, Mediendichte, Kommunalebene ja/nein)
  und Modifikatoren (13). Die Zuordnung ist anpassbar, neue Regionen lassen sich ohne Code
  anlegen.

| Region | Länder | Regel-Besonderheit |
|---|---|---|
| Süden | BY, BW | Viele Familienunternehmen (Geld), Vereine und Kirchen als Zugang, eine dominante etablierte Partei, die unterwandert oder beerbt werden muss |
| Metropolen | B, HH, HB | Kommune und Land sind identisch (keine eigene Kommunalebene), hohe Mediendichte, starke Zivilgesellschaft, Proteste entstehen schnell |
| Westen | NRW, SL | Strukturwandel und Abstiegsangst, Gewerkschaften als eigener Akteur (Bündnis oder Gegner) |
| Osten | MV, BB, SN, ST, TH | Schwache Parteibindung: schnelle, aber flüchtige Gewinne; dünnere Zivilgesellschaft in der Fläche; lokale Zeitungen mit Monopolstellung |
| Norden | NI, SH | Küste, Häfen, Landwirtschaft und Windkraft; Land als Anteilseigner eines großen Autoherstellers (NI) |
| Mitte | HE, RP | Finanzplatz und Chemieindustrie; Pendlerregionen, politisch ausgeglichen (Wechselwählerland) |

**[Vereinfachung]** Die Regionen sind Typisierungen. Im Lexikon wird erklärt, dass sie
Tendenzen abbilden, keine Wahrheiten über die Menschen dort. Die Besonderheiten des Ostens
werden historisch begründet (geringere Parteibindung nach 1990, Abwanderung,
Strukturbrüche), nicht als "Anfälligkeit".

Die Metropolen sind keine zusammenhängende Fläche, sondern ein Typ. Auf der Karte werden sie
gemeinsam hervorgehoben.

### 3.5 Regionale Interessen und Themen
Interessen verlaufen **quer zu den Regionen**. Deshalb hängen sie am einzelnen Land, nicht
an der Region.

**Zwei Arten von Themen**
| Typ | Beispiele | Wirkung |
|---|---|---|
| Standort-Themen | Windkraft, Verbrenner-Aus, Wolf, Häfen | Regional sehr verschieden, quer zur Ideologie |
| Grundsatz-Themen | Steuern, Sozialstaat, Renten | Bundesweit ähnlich, verschieben vor allem das Ideologie-Profil (Abschnitt 8) |

Grundsatz-Themen sind damit der Motor des Ideologie-Pfads, Standort-Themen die Quelle
regionaler Zielkonflikte.

**Modell**
- Jedes **Thema** hat je Land eine **Gewichtung** (wie wichtig, 0–3) und eine **Präferenz**
  (dafür / dagegen / gespalten).
- Die Partei bezieht auf Bundesebene eine **Position** je Thema (Programm, Reden,
  Abstimmungen). Dieselbe Position bringt in einem Land Stimmen und kostet sie im anderen.
- **Standortinteressen sind ideologieunabhängig.** Ein Thema wie das Verbrenner-Aus
  verschiebt zwar das Ideologie-Profil (Abschnitt 8), wird aber regional ganz anders bewertet.
  Daraus entsteht der eigentliche Zielkonflikt.
- Die **Salienz** (wie präsent ein Thema gerade ist) schwankt durch Ereignisse:
  Werkschließung, Hochwasser, Strompreisschock, Ernteausfall.
- **Interessengruppen** sind Akteure, die an Themen hängen: Branchenverbände,
  Gewerkschaften, Bauernverband, Umweltverbände, Mietervereine, Kommunalverbände. Sie
  liefern Geld, Aktivisten oder öffentliche Unterstützung und verlangen dafür Positionen.

**Doppelzüngigkeit als Mechanik**
Der Spieler kann regional unterschiedliche Botschaften senden: im Norden für Windkraft, im
Süden gegen Windräder vor der Haustür. Das bringt kurzfristig Stimmen in beiden Regionen.
Jede widersprüchliche Botschaft erhöht aber ein **Widerspruchsrisiko**. Recherchen oder
virale Clips (7.1) können es aufdecken, dann fällt die Glaubwürdigkeit bundesweit.
**Lernpunkt:** Populistische Strategien versprechen allen alles und spielen Regionen
gegeneinander aus.

**Bundesrat-Deals**
Länder mit starken Standortinteressen geben ihre Bundesratsstimmen gegen Zugeständnisse
(Investitionen, Ausnahmen, Fördergelder). Das verknüpft die Themen mit Bündnissen und
Versprechen (7.8).

**Themenkatalog (Entwurf)**

| Thema | Dafür / profitiert | Dagegen / betroffen | Konfliktlinie |
|---|---|---|---|
| Windkraftausbau | SH, NI, MV, BB (Erzeugung, Arbeitsplätze, Einnahmen) | BY, BW (Widerstand gegen Anlagen vor Ort), ländliche Anwohner allgemein | Wer erzeugt, wer verbraucht, wer trägt die Belastung |
| Stromtrassen Nord–Süd | BY, BW (brauchen den Strom) | Durchleitungsländer TH, HE, NI | Nutzen im Süden, Lasten in der Mitte |
| Verbrenner-Aus | Metropolen, Teile der Grünen-nahen Milieus | BW, NI, BY, SL (Hersteller und Zulieferer) | Klimaziele gegen Industriearbeitsplätze |
| Kohleausstieg | Metropolen, Umweltverbände | Lausitz (BB, SN), Rheinisches Revier (NRW) | Strukturwandel, gebrochene Versprechen an Reviere |
| Stahl und Chemie (Energiepreise) | Subventionen gewünscht in NRW, SL, NI, RP, ST | Haushaltspolitiker, Geberländer | Industriepolitik gegen Schuldenbremse |
| Landwirtschaft (Agrardiesel, Tierhaltung, Düngeregeln) | Umwelt- und Tierschutzmilieus in Städten | NI, BY, MV, SH, SN (Bauern) | Stadt gegen Land, Traktorproteste |
| Wolf | Naturschutzverbände | Weidetierhalter in BB, SN, NI, MV | Symbolthema mit hoher lokaler Emotion |
| Wohnkosten: Mieten | Mieter in Metropolen, Universitätsstädten, Großstädten im Süden | Vermieter, Wohnungswirtschaft | Mietregulierung gegen Eigentum |
| Wohnkosten: Eigentum und Bauzinsen | Junge Familien, Speckgürtel, besonders Süden (sehr teuer) | Haushalt (Förderprogramme) | Eigentumsquote gegen Kosten |
| Wohnkosten: Heiz- und Nebenkosten | Bundesweit, besonders ländliche Räume und Eigentümer im Osten | Klimaziele (Heizungsvorschriften) | Sehr emotional; Salienz steigt automatisch mit einer Energiekrise (4.3) |
| Wohnkosten: Leerstand | Ländlicher Osten | – | Problem ist Wertverlust, nicht Knappheit |
| Steuern | Je nach Position: Entlastung der Mitte, der Unternehmen oder Umverteilung | Je nach Position | Grundsatz-Thema; besonders die **Erbschaftsteuer** betrifft Familienunternehmen und damit Geldgeber (7.6), vor allem im Süden; Gewerbesteuer betrifft Kommunalfinanzen |
| Sozialstaat: Ausbau ↔ Kürzung | Regionen mit höherer Arbeitslosigkeit (Ruhrgebiet, HB, B, Teile des Ostens) bei Ausbau | Beitrags- und Steuerzahler, Haushalt | Grundsatz-Thema; neutrale Benennung bewusst gewählt |
| Renten | Ältere Wähler, Länder mit hohem Altersdurchschnitt (besonders Osten) | Jüngere, Haushalt | Generationenkonflikt; Rentner wählen zuverlässig, Zusagen sind teuer |
| Finanzausgleich | Nehmerländer (Osten, B, HB, SL) | Geberländer (BY, BW, HE) | Solidarität gegen "Wir zahlen für die anderen" |
| Migration (Sachthema) | Fachkräftebedarf in wachsenden Regionen | Grenzländer BY, SN, BB; Kommunen mit hohen Unterbringungskosten | Bewusst nüchtern und gleichgewichtet mit anderen Themen; die Mobilisierung über Feindbilder ist eine eigene, ideologieunabhängige Mechanik (8) |
| Abwanderung, Ärzte, Bahn, Funklöcher | Ländliche Räume, besonders Osten | Kostenträger im Bund | Gleichwertige Lebensverhältnisse |
| Häfen und Seehandel | HH, HB, NI, SH | Umweltverbände (Fahrrinnenvertiefung) | Wirtschaft gegen Ökologie an der Küste |
| Rüstungsindustrie | Standorte in BY, BW, NI | Friedensbewegung, Teile des Ostens | Aufrüstung als Konjunkturprogramm oder Gefahr |
| Russlandpolitik und Sanktionen | Sicherheitsorientierte Milieus | Teile des Ostens, energieintensive Industrie, Raffineriestandorte | Sicherheit gegen Energiepreise und Handel |
| Finanzplatz und Bankenregulierung | HE (Frankfurt) | Regulierungsbefürworter | Standortwettbewerb gegen Stabilität |
| Rundfunkbeitrag | Öffentlich-rechtliche Sender, Medienvielfalt | Beitragskritische Milieus | Staatsverträge brauchen die Zustimmung aller 16 Landtage: Ein einziges Land kann blockieren (Hebel für 7.2) |
| Endlagersuche Atommüll | Alle wollen eine Lösung | Jede Region, die als Standort im Gespräch ist | Sankt-Florians-Prinzip |
| Tourismus und Küstenschutz | MV, SH, BY (Alpen) | Konkurrierende Flächennutzung (Windparks, Industrie) | Landschaft als Wirtschaftsgut |

**[Vereinfachung]** Zuordnungen sind Tendenzen für das Spiel, keine Analyse. Unternehmen und
Verbände bleiben fiktiv, auch wenn sie an reale Branchenstrukturen angelehnt sind.

### 3.6 Personen

**Personal des Spielers** (Generalsekretär, Landesvorsitzende, Kandidaten, Berater)
- Wird aus einem Kandidatenpool ausgewählt.
- **Sichtbare Attribute (4):**
  - *Loyalität:* Treue zur Parteiführung
  - *Überzeugungskraft:* wie stark die Person die öffentliche Meinung bewegt und wie
    wahrscheinlich die Öffentlichkeit ihren Ansichten folgt (nicht zu verwechseln mit
    Beliebtheit: auch unbeliebte, polarisierende Figuren können sehr überzeugend wirken)
  - *Vernetzung:* Einfluss hinter den Kulissen, Zugang zu Institutionen, Medien, Geldgebern
  - *Kompetenz:* Qualität der Arbeit in Amt, Apparat und Wahlkampf
- **Geheime Agenda (1):** Nur ein verborgenes Attribut, z. B.
  - *Karrierist:* springt ab, wenn die Partei schwächelt
  - *Ideologe:* radikaler als die Partei, treibt die Radikalität eigenmächtig hoch und
    **polarisiert**: Seine Überzeugungskraft wirkt verstärkt auf Anhänger und schreckt
    Gemäßigte ab. Die Polarisierung wird nicht als Wert angezeigt, sondern zeigt sich in
    Umfragen und Ereignissen. Aufmerksame Spieler können die Agenda so erahnen, ohne für
    eine Überprüfung zu bezahlen.
  - *Journalist mit Tarnidentität:* sammelt Material für eine Enthüllung
  - *V-Mann:* berichtet an den Verfassungsschutz
  - *keine:* die meisten Personen
- **Agenda bringt Vorteile:** Beim Auswürfeln erhalten Personen mit geheimer Agenda Boni auf
  passende Attribute, damit der Spieler einen Anreiz hat, sie trotz Risiko aufzunehmen:

  | Agenda | Bonus | Begründung |
  |---|---|---|
  | Karrierist | Vernetzung, Kompetenz | Hat sich gezielt hochgearbeitet und kennt die richtigen Leute |
  | Ideologe | Überzeugungskraft | Brennt für die Sache, mobilisiert (und polarisiert) |
  | Journalist mit Tarnidentität | Kompetenz, Vernetzung zu Medien | Professioneller Kommunikator |
  | V-Mann | Kompetenz, Vernetzung | Wirkt besonders engagiert, strebt nach Posten mit Einblick |

  - Loyalität erhält **keinen** Bonus, sonst würde der Loyalitätscheck gerade bei diesen
    Personen nicht greifen.
  - Es gibt seltene **Talente ohne Agenda** mit ähnlich hohen Werten. Hohe Werte sind so ein
    Verdachtsmoment, aber kein Beweis.
- **Loyalitätscheck:** Verlangt eine Aktion etwas, das der geheimen Agenda widerspricht,
  wird gegen die Loyalität geprüft. Scheitert der Check, handelt die Person gegen den
  Spieler: Sabotage, Indiskretion, Überlaufen.
- **Überprüfen kostet:** Personen durchleuchten oder "säubern" erhöht die Loyalität im
  Apparat, senkt aber die Kompetenz (fähige, aber unbequeme Leute gehen) und kostet
  Parteieinheit. **Lernpunkt:**
  Loyalität gegen Kompetenz ist das klassische Dilemma autoritärer Bewegungen.
- **Lernpunkt V-Leute:** Das erste NPD-Verbotsverfahren scheiterte 2003 an V-Leuten in der
  Parteiführung. Ein enttarnter V-Mann ist für den Spieler ein Skandal, kann aber zugleich
  ein laufendes Verbotsverfahren gefährden.

**Übrige Personen** (Kanzler, Minister, Verfassungsrichter, Medienchefs, Unternehmer, Führung
anderer Parteien)
- Werden zu Spielbeginn **ausgewürfelt**, innerhalb von Verteilungen, die je Rolle einem
  demokratieüblichen Rahmen entsprechen (z. B. Verfassungsrichter mit überwiegend hoher
  Integrität).
- **Personalwechsel** halten die Welt in Bewegung: Richter scheiden nach 12 Jahren oder mit
  68 aus, Kanzler treten ab, Erben übernehmen Medienhäuser, Parteien wählen neue Führungen.
- **Namen** entstehen aus Vor- und Nachnamen-Pools. Eine Ausschlussliste verhindert, dass
  zufällig reale Amtsträger in passender Rolle entstehen.

---

## 4. Spielschleife

### 4.1 Runden und Zeit

**Rundenlänge:** 1 Quartal. Ein volles Spiel umfasst grob 20–25 Spieljahre (80–100 Runden).
Das **Startjahr ist fiktiv**; der Wahlkalender kommt aus dem Szenario.
Es gibt **kein festes Zeitlimit**; Limits setzen nur Szenarien (4.5). Historische Vorbilder
zeigen, dass der Weg unter den Bedingungen des Grundgesetzes eher länger als 16 Jahre dauert.

**Wahlkampfquartal:** Das Quartal vor einer Wahl hat eigene Wahlkampfaktionen und mehr
Aktionspunkte, weil Wahlkämpfe sich in Wochen entscheiden, nicht in Quartalen.

**Ablauf einer Runde**
1. **Lage:** Nachrichtenüberblick, neue Ereignisse, Umfrageveränderungen
2. **Planung:** Spieler verteilt Aktionspunkte (AP) und Ressourcen auf Aktionen
3. **Auflösung:** Aktionen werden ausgewertet, Gegenkräfte reagieren
4. **Folgen:** Kennzahlen aktualisieren, verzögerte Effekte früherer Runden treten ein

**Aktionspunkte:** Begrenzte Aufmerksamkeit der Parteiführung. AP steigen mit Parteigröße
und Personal (Generalsekretär, Landesvorsitzende), sodass Delegation wichtig wird.
Delegierte Aktionen sind billiger, aber abhängig von Loyalität und Kompetenz der Person.

**Wahlkalender** (gestaffelt, pro Land eigener Rhythmus)
| Wahl | Turnus | Wirkung |
|---|---|---|
| Kommunalwahlen | 5 Jahre | Mandate, Ortsverbände, Personalreservoir |
| Landtagswahlen | 5 Jahre **[Vereinfachung]** | Landesregierungen, Bundesratsstimmen |
| Bundestagswahl | 4 Jahre (vorgezogen möglich) | Bundestag, Kanzlerwahl |
| Bundesversammlung | 5 Jahre | Wahl des Bundespräsidenten |

### 4.2 Simulation und Ereignisse
- **Simulation als Rückgrat:** Kennzahlen, Themen-Salienz und Personen bilden den Zustand.
- **Zustandsereignisse (Mehrheit):** Werden ausgelöst, wenn Bedingungen erfüllt sind, z. B.
  Einstufung als Verdachtsfall → "Spender zieht sich zurück"; hohes Widerspruchsrisiko →
  "Enthüllungsrecherche". Viele bieten Entscheidungen mit Zielkonflikten.
- **Ereignisketten (wenige, handgeschrieben):** Nur für Schlüsselmomente, z. B.
  Kanzlerwahl, Parteiverbotsverfahren, Einbindungsversuch durch Bündnispartner (7.8),
  Enttarnung eines V-Manns, Kipppunkt.

### 4.3 Krisen
Krisen sind seltene, große Ereignisse mit Dauer und Verlauf.

- **Beispiele:** Finanzkrise, Energiekrise, Krieg mit zusammenbrechenden Lieferketten,
  Pandemie, Naturkatastrophe.
- **Wirkung:** Krisen ändern die Salienz von Themen (Energiekrise → Wohnkosten, Industrie,
  Russlandpolitik) und begünstigen je nach Themenposition bestimmte Parteien.
- **Jede Krise ist eine Chance, aber für wen:** Krisen kosten die **Regierung**
  Glaubwürdigkeit. In der Opposition ist das die Chance des Spielers; sobald er mitregiert,
  ist es sein Risiko.
- **Sammlungseffekt:** Zu Beginn einer Krise steigt das Vertrauen in die Regierung kurz an,
  erst danach erodiert es.
- **Krise als Vorwand:** Ab Phase V rechtfertigen Krisen Ausnahmemaßnahmen (siehe 9).
- **Zufall mit Kontrolle:** Krisen werden aus einem gewichteten Stapel gezogen, mit
  Abklingzeiten zwischen Krisen. **Vorzeichen** kündigen manche Krisen an; wer sich früh
  darauf einstellt, wettet.

### 4.4 Ausländische Mächte
- **Fiktive Staaten** mit erkennbaren Mustern (keine realen Staaten), passend zum Prinzip
  fiktiver Akteure.
- **Angebote:** Geld, Bot-Netzwerke in sozialen Medien, Medienkampagnen. Der Spieler kann
  annehmen oder ablehnen.
- **Annehmen:** Ressourcen gegen **Abhängigkeit**. Die Macht stellt später Forderungen,
  die im Versprechens-Register (7.8) landen. Aufdeckung (Verfassungsschutz, Presse) führt zu
  schwerem Glaubwürdigkeitsverlust. **[Vereinfachung]** Spenden aus Staaten außerhalb der
  EU sind für Parteien verboten; das Spiel bildet das als hohes Risiko ab.
- **Ablehnen schützt nicht vollständig:** Eine Macht kann trotzdem helfen, und die Partei
  wird dafür verantwortlich gemacht.
- **Gegenwind:** Mächte, deren Interessen die Positionen der Partei widersprechen, machen
  Stimmung gegen sie oder unterstützen Konkurrenten.

### 4.5 Szenarien und Zufall
- **Szenario = Startzustand als Datei:** Phase, Kennzahlen, Personen, laufende Krisen,
  optional Zeitlimit und Siegbedingung. Beispiele:
  - *Neugründung:* das volle Spiel
  - *Im Landtag:* Start in Phase II
  - *Königsmacher:* Fraktion im Bundestag, ohne Partner geht nichts
  - *Krisenjahr:* Start mitten in einer Energiekrise
- Szenarien verkürzen Partien und ermöglichen später den Bildungseinsatz.
- **Zufallsstartwert (Seed):** Jede Partie hat einen Startwert. Gleicher Seed ergibt gleiche
  Zufallsereignisse: wichtig für Fehlersuche und dafür, dass eine Klasse dieselbe Partie
  spielt und Entscheidungen vergleicht.

---

## 5. Ressourcen & Kernwerte

**Ressourcen (verbrauchbar)**
| Ressource | Quelle | Verwendung |
|---|---|---|
| Geld | Spenden, Mitgliedsbeiträge, staatliche Parteienfinanzierung | Kampagnen, Personal, Medien |
| Aktivisten | Mitglieder, Mobilisierung | Wahlkampf vor Ort, Demonstrationen |
| Aktionspunkte | Parteiführung, Personal | Jede Aktion |
| Druckmittel | Recherche, Überläufer, Ereignisse | Einfluss auf einzelne Akteure (abstrahiert) |

**Kennzahlen (Zustand)**
| Kennzahl | Bedeutung |
|---|---|
| Umfragewerte je Land | Grundlage für Wahlergebnisse; ergeben sich aus Regionsarbeit und Themenpositionen (3.5) |
| Themenpositionen | Position der Partei je Thema, plus Widerspruchsrisiko bei regional abweichenden Botschaften |
| Reichweite: Plattformen / klassische Medien | Wie stark Botschaften ankommen |
| Glaubwürdigkeit | Vertrauen von Wählern und Partnern; sinkt bei Widersprüchen und gebrochenen Versprechen |
| Ideologie-Profil | Position auf zwei Achsen (siehe Abschnitt 8) |
| Radikalität der Methoden | Wie offen die Partei Regeln bricht; treibt Beobachtungsdruck |
| Beobachtungsdruck | Aufmerksamkeit von Verfassungsschutz, Presse, Justiz |
| Parteieinheit | Zusammenhalt der Flügel; niedrig = Abspaltungen |

**Globaler Wert: Demokratische Resilienz (0–100)**
Zusammengesetzt aus Unabhängigkeit der Justiz, Medienvielfalt, Vertrauen in Institutionen,
Zivilgesellschaft und Einhaltung der Normen. Wird permanent angezeigt. Hohe Resilienz macht
Gegenkräfte stärker; sinkt sie unter Schwellen, werden neue Aktionen möglich. Der Spieler
sieht also direkt, dass sein Fortschritt aus dem Abbau dieser Resilienz besteht.

---

## 6. Phasen

Phasen sind keine harten Level, sondern Schwellen: Neue Institutionen und Aktionen werden
freigeschaltet, sobald die Partei die nötige Stärke erreicht.

| Phase | Ziel | Schlüsselsysteme | Übergang |
|---|---|---|---|
| I Graswurzel | Ortsverbände, erste Kommunalmandate | Kommunale Mobilisierung, Soziale Medien, Finanzierung | Mandate in mehreren Ländern |
| II Landtage | Einzug in Landtage, erste Regierungsbeteiligung | Mediendynastien, Bündnisse, Parteien/Fraktionen | Regierungsbeteiligung in einem Land = Bundesratsstimmen |
| III Bundestag | 5-%-Hürde überwinden, Fraktion bilden | Alle bisherigen + Ungeschriebene Gesetze | Fraktionsstatus im Bundestag |
| IV Regierung | Koalition oder Mehrheit, Kanzleramt | Bündnisse & Versprechen, Parteien/Fraktionen | Kanzlerwahl (Art. 63 GG) |
| V Institutionen | Gerichte, Behörden, Medienaufsicht, Bundespräsident | BVerfG, Ungeschriebene Gesetze, Mediendynastien | Kontrolle über definierte Schlüsselinstitutionen |
| VI Machtsicherung | Gegenkräfte dauerhaft neutralisieren | Alle | Sieg- oder Niederlagebedingung (Abschnitt 10) |

---

## 7. Systeme je Komponente

Jedes System ist eigenständig, beeinflusst aber gemeinsame Kennzahlen. Aktionen sind als
Beispiele zu verstehen, nicht als abschließende Liste.

### 7.1 Soziale Medien
- **Zweck:** Billige, schnelle Reichweite, besonders bei jüngeren und politisch entfremdeten
  Wählern.
- **Aktionen:** Themen setzen; Empörungswellen nutzen; Influencer gewinnen; Gegner diskreditieren;
  Netzwerk von Unterstützerkonten aufbauen (abstrahiert).
- **Risiken:** Faktenchecks und Recherchen senken Glaubwürdigkeit; Plattformsperren;
  Eskalation radikalisiert die eigene Basis schneller als gewollt.
- **Wechselwirkungen:** Hohe Plattform-Reichweite erhöht Umfragewerte kurzfristig,
  aber Volatilität steigt. Klassische Medien greifen virale Themen auf (Verstärker).

### 7.2 Dynastien von Medienunternehmen
- **Zweck:** Glaubwürdige, breite Reichweite; Deutungshoheit.
- **Modell:** Jede Mediendynastie ist eine Familie mit Oberhaupt, Erben und Chefredaktionen.
  Familienmitglieder haben unterschiedliche Haltungen; Erbfolge-Ereignisse können die
  Linie eines Hauses ändern.
- **Zwei Kräfte in jedem Haus:** Der Eigentümer will seine Positionen vertreten sehen, die
  Redaktion will unabhängigen Journalismus. Daraus folgen zwei konkurrierende Attribute:
  **Reichweite** (Zuspitzung bringt Publikum, macht bekannt) und **Glaubwürdigkeit**
  (entsteht durch Unabhängigkeit, überzeugt). Ein Eigentümer, der die Redaktion auf Linie
  bringt, gewinnt Reichweite und verliert Glaubwürdigkeit. Details: `rechenmodell.md` 5.6.
- **Öffentlich-rechtlicher Rundfunk:** Ohne Eigentümer; dessen Rolle übernehmen die
  Aufsichtsgremien (höchstens ein Drittel staatsnah, Rest gesellschaftliche Gruppen).
  Programmautonomie schützt die Redaktion. Hebel sind Gremienbesetzung über
  Landesregierungen, Intendantenwahl, Rundfunkbeitrag und Delegitimierung als "Staatsfunk":
  langsam und indirekt, aber nachhaltig.
- **Aktionen:** Exklusivinterviews anbieten; Werbeetats von Unterstützern lenken; Erben
  umwerben; Übernahme durch befreundete Investoren (spät); Einfluss auf Landesmedienanstalten
  und Rundfunkräte über Landesregierungen.
- **Risiken:** Redaktionen sind nicht deckungsgleich mit Eigentümern (Widerstand von innen,
  Kündigungswellen, Gegenrecherche).
- **Wechselwirkungen:** Ein freundliches Haus dämpft Skandale; ein feindliches verstärkt sie.

### 7.3 Mobilisierung in den Kommunen
- **Zweck:** Verankerung, Personalreservoir, Normalisierung der Partei im Alltag.
- **Ebene:** Je Region (3.4), nicht je Land. In den Metropolen entfällt die Kommunalebene.
- **Aktionen:** Ortsverbände gründen; Präsenz in Vereinen und Bürgerinitiativen; regionale
  Themen besetzen (3.5); Kandidaten für Bürgermeister- und Landratswahlen aufstellen.
- **Risiken:** Unerfahrenes Personal erzeugt Skandale; lokale Gegenbündnisse.
- **Wechselwirkungen:** Kommunalmandate senken die Kosten für Landtagswahlkämpfe und liefern
  Personal für höhere Ebenen. Aktivisten sind die Währung dieses Systems.

### 7.4 Umgehen ungeschriebener Gesetze in den Verfassungsorganen
- **Zweck:** Zeigen, wie viel der Demokratie an Konventionen hängt, die niemand erzwingen kann.
- **Modell:** Jede Institution hat eine Liste von **Normen**. Eine Norm zu brechen ist legal
  oder halblegal, kostet aber Glaubwürdigkeit und senkt die Resilienz dauerhaft. Gebrochene
  Normen bleiben gebrochen und können später auch von anderen Akteuren gebrochen werden.
- **Beispiel-Normen:**
  - Jede Fraktion stellt einen Vizepräsidenten des Parlaments
  - Ausschussvorsitze werden nach Stärke verteilt
  - Verfassungsrichter werden parteiübergreifend im Konsens gewählt
  - Die konstituierende Sitzung wird neutral geleitet
  - Urteile des Verfassungsgerichts werden ohne öffentliche Delegitimierung umgesetzt
  - Verwaltungsspitzen werden nach Eignung, nicht nach Loyalität besetzt
  - Die Regierung nutzt den Haushalt nicht gegen einzelne Länder oder Kommunen
- **Spiegel-Mechanik:** Auch die anderen Parteien können Normen brechen, um die Partei des
  Spielers auszugrenzen. Das schützt kurzfristig, kann aber ebenfalls Resilienz kosten und
  der Partei des Spielers ein Opfer-Narrativ liefern.

### 7.5 Bundesverfassungsgericht
- **Zweck:** Stärkste institutionelle Gegenkraft und schwierigstes Ziel.
- **Modell:** 16 Richter in zwei Senaten, je zur Hälfte von Bundestag und Bundesrat mit
  Zweidrittelmehrheit gewählt, 12 Jahre Amtszeit, keine Wiederwahl. Freie Stellen entstehen
  nach Kalender.
- **Seit 2024 im Grundgesetz verankert:** Struktur, Amtszeit und ein Ersatzwahlmechanismus
  (blockiert ein Wahlorgan, kann das andere wählen). Änderungen daran benötigen nun eine
  Verfassungsänderung (2/3 in Bundestag und Bundesrat). Im Spiel macht das den direkten
  Umbau des Gerichts sehr teuer.
- **Aktionen:** Richterwahlen blockieren, um Stellen offenzuhalten; Kandidaten mit hoher
  Loyalität durchsetzen (erfordert Sperrminorität oder Partner); Gericht öffentlich
  delegitimieren; Urteile ignorieren (extreme Norm, Phase V/VI).
- **Gericht als Akteur:** Entscheidet über Klagen der Opposition und über Parteiverbotsanträge
  (siehe 9). Richter haben Integrität und Haltung; Urteile sind nicht vorherbestimmt.

### 7.6 Unternehmen und Finanzierung
- **Zweck:** Geld ist die Ressource, die alle anderen Systeme speist.
- **Modell:** Unternehmen haben Typ (Familienunternehmen, Aktiengesellschaft, Mittelstand),
  Branche, Standort, Erwartungen an die Politik (Ideologie-Profil und Themenpositionen, 3.5)
  und **Transparenzgrad**. Ein Zulieferer in BW zahlt für eine Position gegen das
  Verbrenner-Aus, die in den Metropolen Stimmen kostet.
  - Familienunternehmen: weniger Kontrolle durch Aufsichtsrat und Aktionäre, Entscheidungen
    hängen an Einzelpersonen, daher leichter zu gewinnen, aber launischer.
  - Aktiengesellschaften: zahlen selten direkt, reagieren empfindlich auf Reputationsrisiken.
- **Aktionen:** Spender umwerben; Großspenden annehmen (Veröffentlichungspflicht ab
  Schwelle); Unterstützung über Dritte (Vereine, Kampagnen) organisieren (abstrahiert);
  Gegenleistungen in Aussicht stellen (verknüpft mit 7.8).
- **Risiken:** Spendenaffären, Rückforderungen, Strafen; Geldgeber springen ab, wenn das
  Ideologie-Profil sich von ihren Erwartungen entfernt (siehe 8).
- **[Vereinfachung]** Parteiengesetz und Spendenregeln werden auf Schwellen und Risiken
  reduziert.

### 7.7 Parteien und Fraktionen
- **Eigene Partei:** Mehrere Flügel (z. B. Pragmatiker, Radikale, Wirtschaftsflügel) mit
  eigenen Anführern und Erwartungen. Parteitage sind Ereignisse mit Abstimmungen über
  Programm und Personal. Niedrige Parteieinheit führt zu Austritten oder Abspaltungen.
- **Andere Parteien:** Fiktive Parteien mit Ideologie-Profil, Führung und Haltung zur
  Partei des Spielers (Ausgrenzung, Duldung, Kooperation). Ihre Haltung kann kippen,
  etwa durch Wahlniederlagen, Führungswechsel oder gezielte Angebote.
  - Drei etablierte Parteien mit nur **grober Zielsetzung**: eine konservative (Werte),
    eine wirtschaftsliberale und eine Arbeiterpartei mit sozialem, aber nicht radikalem
    Einschlag.
  - Sie stehen **gemäßigt und gleichmäßig verteilt nahe der Mitte** des Ideologie-Raums.
    Sie besetzen keine Themen, sondern konkurrieren um Wähler, deren Profil ihrem ähnelt.
  - **Ideologieoffenheit bleibt erhalten:** Jede Richtung hat gleich viel Konkurrenz in der
    Mitte und gleich viel freien Raum nach außen. Jede der drei hat eine autoritäre
    Verlängerung (reaktionär, oligarchisch, linksautoritär), die dem Spieler offensteht.
  - **Nähe ist Abwägung:** Wer nah an einer etablierten Partei steht, findet leichter
    Verbündete, verliert aber Wähler an das bekanntere Original. Wer weit weg steht, hat
    eigenen Raum, aber keine Partner.
- **Fraktionen:** In jedem Parlament eigenständig, mit Fraktionsdisziplin und möglichen
  Überläufern in beide Richtungen.

### 7.8 Bündnisse und (falsche) Versprechungen
- **Zweck:** Macht entsteht in Koalitionen; Vertrauen ist eine Ressource.
- **Versprechens-Register:** Jedes Versprechen (an Partei, Unternehmen, Medienhaus, Person)
  wird mit Inhalt, Empfänger und Frist gespeichert. Der Spieler kann Versprechen einhalten,
  verschieben oder brechen.
- **Falsche Versprechen** sind eine bewusste Option: billiger als echte Zugeständnisse,
  aber mit Aufdeckungsrisiko. Gebrochene Versprechen senken die Glaubwürdigkeit beim
  Empfänger stark und, wenn sie öffentlich werden, allgemein.
- **Bündnistypen:** Wahlabsprachen, Duldungen, Koalitionen, Unterstützung bei
  Personalwahlen, Absprachen mit Verbänden, Bundesrat-Deals mit Ländern (3.5).
- **Lernpunkt:** Bündnispartner, die glauben, die Partei "einhegen" zu können, sind ein
  wiederkehrendes historisches Muster und sollen im Spiel als Ereigniskette auftauchen.

---

## 8. Ideologie-Pfad-Mechanik

**Start:** Die Partei wird mit einem **Gründungsprogramm aus zwei Positionen** gegründet,
denn eine Gründung hat einen Grund. Zu allen anderen Themen schweigt sie zunächst.

**Ereignisse zwingen zur Stellungnahme:** Massendemos, Stromausfälle, Naturkatastrophen, ein
Wolf, der ein Kind verletzt: Zu jedem Thema kommt früher oder später ein Ereignis, bei dem
die Partei Farbe bekennen muss – oder schweigt und dafür Glaubwürdigkeit verliert. Bei einem
erneuten Ereignis kann sie "noch einmal ganz neu nachdenken": Kurswechsel ohne
Aktionspunkte, aber mit vollem Glaubwürdigkeitsverlust. Zwischen Ereignissen kostet jeder
Wechsel Aktionspunkte und Glaubwürdigkeit. So bestimmen die Ereignisse die Reihenfolge, in
der sich das Profil bildet, und der Spieler rutscht in einen Pfad, statt ihn zu wählen
(Details: `rechenmodell.md` 5.8).

**Zwei Achsen**
- Wirtschaft: Markt ↔ Staat
- Gesellschaft: progressiv ↔ traditionell

**Davon getrennt: Radikalität der Methoden.** Die Ideologie bestimmt, *wer* die Partei
unterstützt. Die Radikalität bestimmt, *wie* sie Macht gewinnt, und treibt den
Beobachtungsdruck. Damit zeigt das Spiel: Der Weg in den autoritären Staat funktioniert
aus jeder ideologischen Richtung.

**Wie sich der Pfad schließt**
1. Entscheidungen (Programm, Ereignisse, Bündnisse, Spender) verschieben das Profil.
2. Jede Unterstützergruppe (Wählermilieus, Geldgeber, Medienhäuser, Bündnispartner) hat
   eine bevorzugte Position. Je größer der Abstand, desto unzufriedener.
3. Widersprüchliche Entscheidungen in kurzer Folge kosten Glaubwürdigkeit.
4. **Lock-in:** Mit der Zeit steigen die Kosten für Kurswechsel. Unterstützer, die die
   Partei tragen, verlangen Treue; wer abspringt, kommt selten zurück.
5. Ergebnis: Der Spieler wählt keinen Pfad, er rutscht in einen hinein. Im Rückblick
   (Abschnitt 11) wird gezeigt, welche Entscheidungen den Ausschlag gaben.

**Feindbild-Mechanik**
Die Partei kann eine Gruppe zum Feindbild erklären. Welche Gruppen verfügbar sind, hängt vom
Ideologie-Pfad ab, z. B. "die Eliten", "die Konzerne", "die Zuwanderer", "die Klimasünder",
"die Systemmedien". Die Wirkung ist immer gleich:
- mobilisiert stark und schnell, bindet die eigenen Anhänger
- spaltet die Gesellschaft und senkt die demokratische Resilienz
- erhöht Beobachtungsdruck und Radikalität
- kann Gewalt-Ereignisse auslösen, die der Partei zugerechnet werden

**Lernpunkt:** Die Konstruktion eines Feindbilds ist ein Werkzeug autoritärer Bewegungen
aus jeder Richtung. Deshalb ist sie vom Sachthema Migration (3.5) getrennt: Kein einzelnes
Thema soll der stärkste Hebel sein und den Spieler unabhängig von seinen Entscheidungen in
eine Richtung schieben.

---

## 9. Gegenkräfte: wehrhafte Demokratie

Gegenkräfte reagieren auf Beobachtungsdruck, Radikalität und gebrochene Normen. Ihre Stärke
hängt von der demokratischen Resilienz ab.

| Gegenkraft | Mechanik |
|---|---|
| Verfassungsschutz | Eskalationsstufen: *Prüffall* → *Verdachtsfall* → *gesichert extremistisch*. Höhere Stufen: Spender und Partner springen ab, Beamte als Mitglieder unter Druck, Grundlage für Verbotsverfahren. Länderämter können abweichend einstufen. Kann V-Leute im Personal der Partei führen (3.6). |
| Parteiverbot (Art. 21 GG) | Antrag durch Bundestag, Bundesrat oder Bundesregierung. Das BVerfG prüft Verfassungsfeindlichkeit und ob die Partei realistisch in der Lage ist, ihre Ziele zu erreichen. Mildere Variante: Ausschluss von der staatlichen Finanzierung. Ein Verbot beendet das Spiel. **Lernpunkt:** Das Verfahren ist früh schwer zu begründen und spät politisch kaum durchsetzbar. |
| Freie Presse | Recherchen decken Spenden, falsche Versprechen und Absprachen auf. Stärke sinkt mit Medienkonzentration. |
| Zivilgesellschaft | Proteste, Gegenbündnisse, Wahlbeteiligung. Massenproteste können Bündnispartner zum Rückzug zwingen. |
| Justiz | Fachgerichte und Landesverfassungsgerichte stoppen einzelne Maßnahmen. |
| Föderalismus | Länder ohne Beteiligung der Partei blockieren im Bundesrat, verweigern Umsetzung. |
| Bundespräsident | Prüft Gesetze vor der Ausfertigung, kann bei offensichtlicher Verfassungswidrigkeit verweigern. |
| Ewigkeitsklausel (Art. 79 Abs. 3 GG) | Kernprinzipien (Menschenwürde, Demokratie, Rechtsstaat, Bundesstaat) sind auch mit Zweidrittelmehrheit nicht änderbar. Der Spieler kann sie nur faktisch aushöhlen, nie formal abschaffen. |
| Widerstandsrecht (Art. 20 Abs. 4 GG) | Narratives Element in Phase VI: Massenhafte Verweigerung in Verwaltung und Gesellschaft. |
| Andere Parteien | Ausgrenzung ("Brandmauer") oder Einbindung; beides hat Vor- und Nachteile für sie. |

**Kein Notverordnungsrecht:** Anders als die Weimarer Verfassung (Art. 48) kennt das
Grundgesetz keine präsidiale Notverordnung. Notstandsregeln sind eng an das Parlament
gebunden. Das Spiel macht diesen Unterschied als Lernpunkt sichtbar.

**Krise als Vorwand:** Ab Phase V kann die Partei Krisen (4.3) nutzen, um Ausnahmemaßnahmen
zu begründen. Das ist das historisch wichtigste Muster der Machtsicherung. Gegenkräfte
reagieren darauf umso stärker, je höher die Resilienz noch ist.

---

## 10. Sieg- und Niederlagebedingungen

**Sieg: Machtsicherung**
Die Partei kontrolliert gleichzeitig eine definierte Anzahl an **Machtsäulen** und die
demokratische Resilienz liegt unter einer Schwelle. Der eigentliche **Kipppunkt** (der
Moment, ab dem die Gegenkräfte nicht mehr gewinnen konnten) liegt meist deutlich früher und
wird erst in der Nachbesprechung benannt. Mögliche Säulen:
- Kanzleramt und Bundestagsmehrheit
- Sperrminorität oder Mehrheit im Bundesrat
- Mehrheit der loyalen Richter in mindestens einem Senat des BVerfG
- Bundespräsident
- Führung des Verfassungsschutzes und der Sicherheitsbehörden
- Dominanz in der Medienlandschaft

Der Sieg wird bewusst nicht als Triumph inszeniert, sondern endet in der Nachbesprechung
(Abschnitt 11) mit den Folgen für das Land.

**Niederlagen**
| Ende | Auslöser |
|---|---|
| Verbot | Erfolgreiches Parteiverbotsverfahren |
| Bankrott | Geld dauerhaft unter null, Spender verloren |
| Bedeutungslosigkeit | Umfragewerte über längere Zeit unter Schwelle |
| Spaltung | Parteieinheit bricht zusammen, Flügel gründen eigene Parteien |
| Die Demokratie hält | Resilienz erholt sich über Schwelle, nachdem die Partei an der Macht war; Abwahl |

---

## 11. Lern-Ebene

- **Nachbesprechung am Spielende:** Zeitleiste der wichtigsten Entscheidungen, jeweils mit
  der Gegenkraft, die hätte eingreifen können, und warum sie es (nicht) tat.
- **Enthüllung des Kipppunkts:** Die Nachbesprechung benennt das Quartal, in dem die
  Demokratie kippte, und die Entscheidung, die dazu führte, z. B. "Quartal 3/2034: Die
  Richterwahl lief nicht mehr im Konsens."
- **Vergleich:** Mit gleichem Seed (4.5) können mehrere Spieler dieselbe Partie spielen und
  ihre Wege vergleichen.
- **Historische Parallelen:** Spielmechaniken werden realen Mustern zugeordnet, z. B.
  - Weimar 1930–33: Präsidialkabinette, Notverordnungen, Einbindungsversuche der Konservativen
  - Ungarn ab 2010: Verfassungsänderungen, Medienkonzentration, Umbau der Justiz
  - Polen 2015–23: Konflikt um Verfassungsgericht und Justizreform, spätere Umkehr
  - Deutschland: Diskussionen um Parlamentsnormen, Richterwahl und die Verankerung des
    BVerfG im Grundgesetz 2024
- **Wahlbeteiligung und Repräsentationslücke:** Die Nachbesprechung zeigt, dass die Partei
  dort am stärksten wurde, wo vorher die Wahlbeteiligung niedrig war, weil drängende
  Probleme von den etablierten Parteien nicht hinreichend adressiert wurden
  (`rechenmodell.md` 3.8). Der Grund liegt in unversorgten Anliegen, nicht in den Menschen
  einer Region.
- **Institutionen-Lexikon im Spiel:** Jede Institution und Norm hat einen kurzen,
  verständlichen Erklärtext, erreichbar aus dem Panel.
- **Kennzeichnung von Vereinfachungen:** Wo das Spiel vom echten Recht abweicht, steht dies
  im Lexikon.

---

## 12. Inhalt & Tonalität

- **Fiktiv:** Alle Parteien, Personen, Medienhäuser, Unternehmen und Plattformen erhalten
  erfundene Namen. Keine realen Personen oder Parteien im Spielgeschehen.
- **Ton:** Ernst mit satirischen Spitzen (Tropico), aber ohne die Gegenkräfte lächerlich zu
  machen.
- **Abstraktion:** Aktionen beschreiben Strategie und Wirkung, nicht Methoden im Detail.
- **Keine verfassungsfeindliche Symbolik**, keine Anlehnung an reale extremistische Ästhetik.
- **Zielgruppe:** Jugendliche ab ca. 16 Jahren und Erwachsene; Einsatz in politischer Bildung
  möglich (Unterricht, Landeszentralen).

---

## 13. Technische Leitplanken

- **Engine:** Godot 4 (aktuelle stabile Version), GDScript
- **Plattform:** Desktop (macOS, Windows, Linux) zuerst
- **Datengetriebener Inhalt:** Institutionen, Akteure, Aktionen, Ereignisse, Normen als
  Datendateien (Godot-Resources oder JSON), nicht im Code
- **Lokalisierung DE + EN von Anfang an:** Alle Texte über Übersetzungsschlüssel, keine
  fest verdrahteten Strings; Godot-Übersetzungsdateien (gettext/PO bevorzugt)
- **Tests:** Spiellogik getrennt von der Darstellung, automatisierte Tests mit GUT
- **Speichern/Laden:** Von Beginn an vorgesehen, da Spiele lang sind. Der gesamte
  Spielzustand muss serialisierbar sein; Szenarien (4.5) sind gespeicherte Startzustände.
- **Akteursbasiertes Aktionssystem:** Aktionen gehören zu Akteuren; der Spieler ist einer
  davon. Andere Parteien, Verfassungsschutz, Presse usw. nutzen dasselbe System, gesteuert
  durch KI. Das hält einen späteren Verteidigungsmodus (Spieler steuert die Gegenkräfte)
  offen, ohne ihn jetzt zu bauen.
- **Ein einheitliches Modifikator-System:** Regionen, Länder, Krisen, Personen und
  Ereignisse verändern Kosten, Erfolgschancen und Kennzahlen über denselben Mechanismus.
  Regel-Besonderheiten werden so als Daten ausgedrückt, nicht als Sonderfälle im Code.
- **Zufall:** Ein zentraler, über den Seed initialisierter Zufallsgenerator.

### Grafik
- **Brettspiel-Optik:** Stilisierte Karte, Spielsteine, Karten, Porträts.
- **Assets per generativer KI.** Vorher einen **Stilleitfaden** festlegen (Farbpalette,
  Perspektive, Linienstärke, Beispielbilder), damit die Assets zusammenpassen.
- **Karte aus offenen Geodaten** (Ländergrenzen, z. B. vom Bundesamt für Kartographie und
  Geodäsie; Namensnennung beachten), danach stilisiert. Nicht generieren lassen, da
  Grenzverläufe sonst falsch werden.
- **Porträt-Pool** mit Merkmalen (Alter, Geschlecht, Rolle), der generierten Personen
  zugeordnet wird. Prompts nie mit realen Namen, um Ähnlichkeiten mit realen Personen zu
  vermeiden.
- Lizenzbedingungen des verwendeten Generators vor einer Veröffentlichung prüfen.

Details folgen in einem eigenen Prototyp-Plan.

---

## 14. MVP-Umfang (Vorschlag)

Ziel: Den Kern der Spielschleife testen, nicht das ganze Spiel.

- **Phasen:** I–III (Graswurzel bis Bundestag)
- **Karte:** Alle 16 Länder sichtbar, 2 kontrastierende Regionen vollständig spielbar
  (festgelegt: Süden und Norden, wegen Windkraft und Autoindustrie als Konfliktthemen)
- **Systeme:** Soziale Medien, Kommunale Mobilisierung, Finanzierung, Ideologie-Pfad,
  regionale Themen (8 Themen als gerichtete Aussagen, inklusive Widerspruchsrisiko:
  Windkraft ausbauen, Verbrenner-Aus festschreiben, Ökologische Landwirtschaft fördern,
  Mieten regulieren, Naturschutz stärken, Steuern senken, Sozialstaat ausbauen,
  Schuldenbremse einhalten). Widersprüchliche Positionen kosten dauerhaft Glaubwürdigkeit
  (`rechenmodell.md` 5.7).
- **Rechenmodell:** siehe `rechenmodell.md`
- **Gegenkräfte:** Verfassungsschutz-Stufen, freie Presse
- **Kennzahlen:** Vollständig, inklusive demokratischer Resilienz
- **Personen:** Eigenes Personal mit Attributen und geheimer Agenda; übrige Personen ausgewürfelt
- **Krisen:** 2 Krisen (z. B. Energiekrise, Finanzkrise)
- **Szenario:** Nur "Neugründung", aber bereits als Datei geladen; Seed von Anfang an
- **Inhalt:** ca. 20 Aktionen, 30 Ereignisse, 3 Mediendynastien (nur passiv), 5 Unternehmen
- **Grafik:** Platzhalter
- **Sprachen:** DE und EN (Struktur), EN-Übersetzung darf zunächst unvollständig sein

---

## 15. Offene Fragen

1. **Spieldauer:** Hängt davon ab, wie abwechslungsreich das Spiel wird; nach dem MVP neu
   bewerten. Szenarien (4.5) ermöglichen kürzere Partien.
2. **Verteidigungsmodus:** Technisch offengehalten (13), Entscheidung später.
3. **Bildungseinsatz:** Szenarien sind vorgesehen; ob das Spiel reif für den Unterricht
   wird, entscheidet sich nach Tests.
4. **Feindbilder:** Welche Gruppen stehen auf welchem Ideologie-Pfad zur Verfügung?
5. **Ausländische Mächte:** Wie viele fiktive Staaten, mit welchen Interessen?
6. **Krisenkatalog:** Welche Krisen, wie häufig, mit welchen Vorzeichen?
7. **Fachliche Prüfung:** Wer liest rechtliche Angaben und regionale Zuordnungen gegen?
