# Rechenmodell der Kernschleife (MVP)

Stand: 2026-10-17 · Version 0.2 (Umsetzungsentscheidungen aus M2 ergänzt) · Bezug: `game-design.md` Version 0.3

> Dieses Dokument übersetzt die Systeme des Design-Dokuments in Zahlen und Formeln für den
> MVP (Phasen I–III, Regionen Süden und Norden spielbar). Alle Konstanten heißen `P_…`,
> stehen gesammelt in Abschnitt 13 und sind Startwerte für das Balancing, keine
> Festlegungen. Sie werden später als Daten geladen, nicht im Code fest verdrahtet.

---

## 0. Konventionen

- **Takt:** Alle Formeln gelten pro Runde (Quartal). `t` ist die aktuelle Runde.
- **Wertebereich:** Kennzahlen liegen, wenn nicht anders angegeben, in **0–100** und werden
  nach jeder Berechnung auf diesen Bereich begrenzt (`clamp`).
- **Annäherung statt Sprung:** Viele Werte bewegen sich schrittweise auf einen Zielwert zu:
  `X(t+1) = X(t) + α · (Ziel − X(t))`. Das erzeugt Trägheit und verzögerte Wirkung.
- **Zufall:** Jeder Zufallswert kommt aus dem zentralen, per Seed initialisierten Generator.
  `N(μ, σ)` ist eine Normalverteilung, `zufall()` eine Gleichverteilung in [0, 1).
- **Modifikatoren:** Regionen, Krisen, Personen und Ereignisse wirken über Modifikatoren
  (`game-design.md` Abschnitt 13). In den Formeln stehen sie als `+ Σ mod`.

---

## 1. Zustand

### 1.1 Global
| Größe | Bereich | Bedeutung |
|---|---|---|
| `t` | Runde | Aktuelles Quartal |
| `R` | 0–100 | Demokratische Resilienz |
| `Krisen` | Liste | Aktive Krisen mit Restdauer |

### 1.2 Partei des Spielers
| Größe | Bereich | Bedeutung |
|---|---|---|
| `G` | Tsd. € | Geld |
| `M` | Anzahl | Mitglieder |
| `A` | Anzahl | Verfügbare Aktivisten in dieser Runde |
| `AP` | Anzahl | Aktionspunkte in dieser Runde |
| `C` | 0–100 | Glaubwürdigkeit |
| `Rad` | 0–100 | Radikalität der Methoden |
| `B` | 0–100 | Beobachtungsdruck |
| `VS` | 0–3 | Verfassungsschutz-Stufe (0 keine, 1 Prüffall, 2 Verdachtsfall, 3 gesichert extremistisch) |
| `E` | 0–100 | Parteieinheit |
| `RP` | 0–100 | Reichweite Plattformen (soziale Medien) |
| `RK_l` | 0–100 | Reichweite klassische Medien je Land, berechnet aus den Medienhäusern (5.6) |
| `RK_Bonus` | 0–100 | Kurzfristige Aufmerksamkeit durch Aktionen und Ereignisse |
| `W` | 0–100 | Widerspruchsrisiko |
| `p_k` | −2…+2 oder leer | Bundesweite Position zu Thema `k` (leer = keine Position) |
| `p_k,r` | −2…+2 oder leer | Abweichende regionale Botschaft in Region `r` (optional) |
| `h_k` | Runden | Haltedauer der aktuellen Position zu Thema `k` |

### 1.3 Region `r`
| Größe | Bereich | Bedeutung |
|---|---|---|
| `V_r` | 0–100 | Verankerung (Ortsverbände, Kommunalmandate, Präsenz in Vereinen) |

### 1.4 Land `l` (Attribute aus Daten, Umfrage dynamisch)
| Größe | Bereich | Bedeutung |
|---|---|---|
| `U_l` | 0–100 % | Umfragewert der Partei |
| `PB_l` | 0–100 | Parteibindung der Wähler (hoch = träge) |
| `Alt_l` | 0–100 | Altersindex (hoch = ältere Bevölkerung, mehr klassische Medien) |
| `Pop_l` | Anteil | Anteil an den Wahlberechtigten im Bund |
| `w_l,k` | 0–3 | Gewichtung von Thema `k` |
| `q_l,k` | −2…+2 | Präferenz zu Thema `k` |
| `LT_l` | ja/nein | Partei im Landtag |

### 1.5 Thema `k`
| Größe | Bereich | Bedeutung |
|---|---|---|
| `s_k` | 0,5–3 | Salienz (1 = normal, Krisen erhöhen) |
| `e_k` | Vektor | Wirkung einer Position auf die Ideologie-Achsen (Abschnitt 5) |

### 1.6 Konkurrenzparteien `j`
| Größe | Bereich | Bedeutung |
|---|---|---|
| `I_j` | Vektor | Feste Ideologie-Position (Abschnitt 5.5) |
| `S_j,l` | 0–100 % | Stärke im Land (aus Daten, im MVP konstant) |
| `Haltung_j` | 0–100 | Bereitschaft zur Zusammenarbeit (im MVP nur angezeigt) |

### 1.7 Personen (Personal des Spielers)
`Loy`, `Ü` (Überzeugungskraft), `Vern`, `Komp` in 0–100, dazu `Agenda` (verborgen).

### 1.8 Geldgeber `u`
Bevorzugte Ideologie-Position, Themenpräferenzen, Zufriedenheit `Z_u` (0–100), maximale
Zahlung pro Runde `Zmax_u`, Typ (Familienunternehmen / AG / Mittelstand).

---

## 2. Rundenablauf (Reihenfolge der Berechnung)

1. **Einnahmen:** Geld, Aktivisten, Aktionspunkte (Abschnitt 6)
2. **Lage:** Krisen ziehen und fortschreiben (11), Zustandsereignisse auslösen
3. **Planung:** Spieler wählt Aktionen (Abschnitt 4)
4. **Auflösung:** Aktionen auswerten, Loyalitätschecks (10)
5. **Gegenkräfte:** Beobachtungsdruck, Verfassungsschutz, Presse (8, 9)
6. **Meinung:** Umfragewerte aktualisieren (3)
7. **Unterstützer:** Zufriedenheit der Geldgeber, Abgänge (5)
8. **Wahlen:** Falls eine Wahl in dieser Runde stattfindet (7)
9. **Abklingen:** Reichweite, Widerspruchsrisiko, Resilienz-Erholung, Haltedauer `h_k + 1`
10. **Phase und Spielende prüfen** (12)

---

## 3. Umfragemodell

Kern der Simulation. Für jedes Land `l` wird ein **Zielwert** berechnet, auf den sich die
Umfrage mit Trägheit zubewegt.

### 3.1 Themenpassung
Wie gut passen die Positionen der Partei zu den Präferenzen im Land?

```
Übereinstimmung a_l,k = 1 − |p*_k − q_l,k| / 2          (Bereich −1 … +1)
p*_k = p_k,r falls regionale Botschaft in der Region von l, sonst p_k

T_l = Σ_k (s_k · w_l,k · a_l,k)  /  Σ_k (s_k · w_l,k)    (nur Themen mit Position im Zähler,
                                                          alle Themen im Nenner)
```

- Ohne Position zu einem Thema gibt es dort weder Gewinn noch Verlust, aber auch kein Profil.
- Der Nenner über **alle** Themen sorgt dafür, dass eine Partei mit wenigen Positionen nur
  einen kleinen Teil des möglichen Zuspruchs erreicht.

### 3.2 Reichweite im Land
Botschaften wirken nur, soweit sie ankommen. Ältere Länder nutzen mehr klassische Medien.

```
Reach_l = (1 − Alt_l/100) · RP  +  (Alt_l/100) · RK_l        (0–100)
f_Reach = 0,3 + 0,7 · Reach_l / 100                           (0,3 … 1,0)
```

### 3.3 Konkurrenzdruck
Etablierte Parteien besetzen keine Themen. Sie erschweren es aber, Wähler zu gewinnen,
deren Profil ihrem eigenen ähnelt: Diese Wähler haben bereits ein bekanntes Original.

```
Nähe_j    = max(0, 1 − |I − I_j| / P_Nähe)              (0 … 1)
Konk_l    = min(0,8,  P_Konk · Σ_j (S_j,l / 100) · Nähe_j)
```

Eine profillose Partei in der Mitte (Startzustand) verliert so rund ein Drittel ihres
Zuspruchs: Die Mitte ist besetzt. Weiter außen sinkt der Druck auf 0, in jeder Richtung
gleich stark (Lage der Parteien siehe 5.5).

### 3.4 Zielwert
```
Zuspruch_l = P_T     · T_l · f_Reach · f_C              Themen
           + P_V     · V_r / 100                        Verankerung (Region von l)
           + P_Pers  · (Ü_Führung − 50) / 50 · f_Reach  Überzeugungskraft des Spitzenpersonals
           + Krisenbonus_l                              (Abschnitt 11)

Ziel_l = P_Basis
       + Zuspruch_l · (1 − Konk_l) · (1 + P_MK · MK_l)  Konkurrenzdruck (3.3), Medienklima (5.6)
       − P_Stigma · VS · (R / 100)                      Stigma durch Einstufung
       + Σ mod

f_C = 0,5 + C / 200                                     (Glaubwürdigkeit, 0,5 … 1,0)
Ü_Führung = Mittelwert aus Parteichef und Landesvorsitz der Region
```

- **Stigma** wirkt stärker, solange die Resilienz hoch ist: In einer wachen Demokratie
  schadet die Einstufung mehr.
- Für **Ideologen** im Spitzenpersonal gilt die Polarisierung (Abschnitt 10.2).

### 3.5 Bewegung
```
α_l = P_α · (1 − 0,7 · PB_l / 100)
U_l(t+1) = U_l(t) + α_l · (Ziel_l − U_l(t)) + N(0, P_σ · (1 − PB_l / 100))
U_l ∈ [0, P_Umax]
```

Geringe Parteibindung (Osten, im MVP über Daten) heißt: schnellere Bewegung und mehr
Rauschen, also schnelle, aber flüchtige Gewinne.

### 3.6 Bundesweiter Umfragewert
```
U_Bund = Σ_l Pop_l · U_l
```

### 3.7 Länder außerhalb von Süden und Norden
Im MVP nicht direkt bespielbar: `V_r` bleibt dort 0, alle anderen Terme (Themen,
Reichweite, Personal, Stigma) wirken normal. Damit folgen sie dem bundesweiten Profil der
Partei.

---

## 4. Aktionen

### 4.1 Allgemeine Form
Jede Aktion ist ein Datensatz mit:

| Feld | Bedeutung |
|---|---|
| Kosten | `AP`, `G`, `A` |
| Ziel | Region, Land, Thema, Person oder keines |
| Ausführende Person | optional (Delegation) |
| Grundchance `p0` | Erfolgswahrscheinlichkeit ohne Modifikatoren |
| Effekte | bei Erfolg / bei Misserfolg |
| Nebenwirkungen | Änderungen an `Rad`, `B`, `R`, `W`, `E`, `C` |
| Agenda-Konflikt | welche geheimen Agenden diese Aktion ablehnen würden |

```
Erfolgschance = clamp(p0 + (Komp − 50) / 200 + Σ mod,  0,05,  0,95)
```

Ohne ausführende Person zählt die Kompetenz des Parteichefs. **Delegation** kostet 1 AP
weniger (Minimum 1), setzt aber einen Loyalitätscheck voraus, wenn ein Agenda-Konflikt
besteht (Abschnitt 10).

### 4.2 Beispielaktionen MVP
| Aktion | System | Kosten | Wirkung (Erfolg) | Nebenwirkung |
|---|---|---|---|---|
| Ortsverband gründen | Kommunen | 2 AP, 5 G, 20 A | `V_r` +4 | – |
| Präsenz in Vereinen | Kommunen | 1 AP, 30 A | `V_r` +2, Mitglieder +2 % | – |
| Lokales Thema besetzen | Kommunen/Themen | 1 AP | `p_k,r` setzen | `W` steigt (Abschnitt 5.3) |
| Social-Media-Kampagne | Soziale Medien | 1 AP, 10 G | `RP` +6 | – |
| Empörungswelle reiten | Soziale Medien | 1 AP | `RP` +10, `s_k` +0,3 für ein Thema | `Rad` +3, `C` −2 |
| Influencer gewinnen | Soziale Medien | 2 AP, 20 G | `RP` +8 dauerhaft (langsamer Zerfall) | Aufdeckung: `C` −5 |
| Gegner diskreditieren | Soziale Medien | 1 AP | Konkurrenz −0,5 % (vereinfacht: `U_l` +0,3) | `Rad` +4, `R` −0,5 |
| Pressekonferenz | Klassische Medien | 1 AP | `RK` +3 | – |
| Spender umwerben | Finanzierung | 1 AP | `Z_u` +10 für ein Unternehmen | – |
| Großspende annehmen | Finanzierung | 0 AP | `G` + Spende | Aufdeckungsrisiko bei Intransparenz |
| Unterstützung über Dritte | Finanzierung | 2 AP | `G` +, keine Veröffentlichung | `B` +3, Recherche-Risiko |
| Position beziehen/ändern | Themen | 1 AP | `p_k` setzen | Kurswechselkosten (5.2) |
| Parteitag | Partei | 3 AP, 30 G | `E` +10 | Gelegenheit für Flügelkonflikte |
| Personal überprüfen | Personen | 2 AP, 10 G | Agenda einer Person aufdecken (Chance 70 %) | `E` −3 |
| Säuberung | Personen | 3 AP | Alle Personen mit `Loy` < 40 entfernen | `Komp` im Apparat −, `E` −10 |
| Wahlkampf (nur Wahlkampfquartal) | Wahlen | 2 AP, 40 G, 50 A | Wahlergebnis +1,5 % im Land | – |

Die vollständige Liste von rund 20 Aktionen entsteht als Daten im Prototyp.

---

## 5. Ideologie, Kurswechsel und Unterstützer

### 5.1 Ideologie-Profil
Jedes Thema hat einen Vektor `e_k = (e_x, e_y)` auf den Achsen Wirtschaft (−100 Staat …
+100 Markt) und Gesellschaft (−100 progressiv … +100 traditionell). Das Profil wird aus den
Positionen **berechnet**, nicht gesetzt:

```
I = 50 · Σ_k (p_k · e_k)  /  Σ_k |e_k|        (nur Themen mit Position; Ergebnis je Achse −100 … +100)
```

MVP-Themen und Vektoren (Position +2 bedeutet "stark dafür"):

| Thema | Typ | `e_k` | Bedeutung von +2 |
|---|---|---|---|
| Windkraftausbau | Standort | (0, −1) | Ausbau stark vorantreiben |
| Verbrenner-Aus | Standort | (−0,5, −1) | Aus festschreiben |
| Landwirtschaft | Standort | (0, +1) | Bauern schützen, Auflagen lockern |
| Wohnkosten | Standort/Grundsatz | (−1, 0) | Stärker regulieren und fördern |
| Steuern | Grundsatz | (+1, 0) | Entlasten, Erbschaftsteuer senken |
| Sozialstaat | Grundsatz | (−1, 0) | Ausbauen |

### 5.2 Kurswechsel (Lock-in)
Eine Position zu ändern kostet Glaubwürdigkeit, umso mehr, je länger sie gehalten wurde und
je mehr Unterstützer an ihr hängen:

```
ΔC = − P_Wechsel · |Δp_k| · (1 + h_k / 8) · (1 + n_k / 2)
n_k = Anzahl Geldgeber mit starker Präferenz zu Thema k
h_k wird auf 0 gesetzt
```

### 5.3 Widerspruchsrisiko
Jede regionale Botschaft, die von der Bundesposition abweicht, erhöht pro Runde das Risiko:

```
W(t+1) = W(t) + P_W · Σ_(k,r) |p_k,r − p_k| · s_k   −  P_Wzerfall
```

Aufdeckung siehe Presse (Abschnitt 9).

### 5.4 Geldgeber
```
Abstand_u = min(1, |I − I_u| / 200)                   (0 … 1, euklidisch über beide Achsen)
Ziel_Z_u  = 100 · (1 − Abstand_u) − 15 · (Themen-Konflikte mit u) − Abzug_VS(u, VS) + Σ mod
Z_u(t+1)  = Z_u(t) + 0,3 · (Ziel_Z_u − Z_u(t))
Zahlung_u = Zmax_u · max(0, (Z_u − 40) / 60) · f_C
```

- **Abgang:** Liegt `Z_u` zwei Runden in Folge unter 30, zieht sich der Geldgeber zurück
  (Ereignis). Rückkehr frühestens nach 8 Runden, mit halbiertem `Zmax_u`.
- **Abzug durch Einstufung:** AGs reagieren ab `VS` = 1 (−20 je Stufe),
  Familienunternehmen erst ab `VS` = 2 (−15 je Stufe), Mittelstand dazwischen.

### 5.5 Konkurrenzparteien
Drei gemäßigte Parteien mit grober Zielsetzung, gleichmäßig im Abstand von 120° und mit
Radius 35 um die Mitte verteilt. Keine Richtung ist dadurch offener als eine andere.

| Partei (Arbeitsname) | Zielsetzung | `I_j` (Wirtschaft, Gesellschaft) |
|---|---|---|
| Konservative | Werte, Tradition, Ordnung | (+9, +34) |
| Wirtschaftsliberale | Markt, Eigentum, niedrige Steuern | (+25, −25) |
| Arbeiterpartei | Arbeit, soziale Sicherheit, ohne radikalen Umbau | (−34, −9) |

- Positionen sind im MVP **fest**; spätere Versionen können sie langsam wandern lassen,
  z. B. wenn eine Partei Forderungen des Spielers übernimmt.
- **Stärke je Land** `S_j,l` kommt aus den Daten (z. B. Konservative im Süden stärker).
- **Haltung zur Partei des Spielers** (Grundlage für Bündnisse ab Phase IV, im MVP nur
  angezeigt):
  ```
  Haltung_j = 100 · Nähe_j − 0,5 · Rad − 20 · VS
  ```
  Nähe macht Bündnisse möglich, Radikalität und Einstufung verschließen sie.

### 5.6 Medienhäuser
In jedem Medienhaus ringen zwei Kräfte: der **Eigentümer**, der seine Positionen vertreten
sehen will, und die **Redaktion**, die unabhängigen Journalismus will. Daraus ergeben sich
zwei konkurrierende Attribute:

- **Reichweite** (`Reach_m`): wie viele Menschen das Haus erreicht. Zuspitzung im Sinne des
  Eigentümers bringt Publikum. **Reichweite macht bekannt.**
- **Glaubwürdigkeit** (`Glaub_m`): wie sehr das Publikum dem Haus vertraut. Sie entsteht
  durch unabhängige Redaktionen. **Glaubwürdigkeit überzeugt.**

Ein Eigentümer, der die Redaktion auf Linie bringt, gewinnt kurzfristig Reichweite und
verliert auf Dauer Überzeugungskraft. **Lernpunkt:** Vereinnahmte Medien mobilisieren die
eigenen Leute, überzeugen aber immer weniger andere.

**Zustand je Haus `m`**
| Größe | Bereich | Bedeutung |
|---|---|---|
| `Reach_m` | 0–100 | Anteil des erreichten Publikums (national oder in einer Region) |
| `Glaub_m` | 0–100 | Vertrauen des Publikums |
| `Unab_m` | 0–100 | Unabhängigkeit der Redaktion (100 = Eigentümer greift nie ein) |
| `I_m` | Vektor | Ideologie-Position des Eigentümers, zu Spielbeginn ausgewürfelt (Radius ≤ 50) |
| `Gebiet_m` | bundesweit / Region | Wo das Haus wirkt |

**Berichterstattung über die Partei des Spielers**
```
Eigentümer_m = clamp(1 − |I − I_m| / 50,  −1, 1)                       Sympathie des Eigentümers
Redaktion_m  = clamp(0,3 + (C − 50) / 100 − Rad / 80 − 0,25 · VS,  −1, 1) journalistisches Urteil
Ton_m        = (1 − Unab_m / 100) · Eigentümer_m + (Unab_m / 100) · Redaktion_m

Aufm         = min(1, U_Bund / 10)                                      Relevanz der Partei
RK_l         = min(100, Σ_m in l (Reach_m · Aufm) + RK_Bonus)

MK_l         = Σ_m in l (Reach_m · Glaub_m · Ton_m)  /  Σ_m in l (Reach_m · Glaub_m)   (−1 … +1)
MK_Bund      = MK_l gewichtet mit Pop_l
```

- **Reichweite** (`RK_l`) entscheidet, ob die Botschaften der Partei ankommen (3.2).
- **Medienklima** (`MK_l`) entscheidet, ob sie wohlwollend ankommen (3.4) und wohin sich die
  Glaubwürdigkeit der Partei bewegt (6). Glaubwürdige Häuser zählen dabei mehr.

**Dynamik je Haus**
```
Ziel_Glaub_m = 20 + 0,7 · Unab_m
Ziel_Reach_m = Grundreichweite_m + P_Zuspitz · (1 − Unab_m / 100)
Annäherung jeweils 0,1 pro Runde
```

**Konflikt zwischen Eigentümer und Redaktion**
Bewerten Eigentümer und Redaktion die Partei sehr unterschiedlich
(`|Eigentümer_m − Redaktion_m| > 1`), kommt es mit Wahrscheinlichkeit 0,2 pro Runde zum
Konflikt:
- **Eigentümer setzt sich durch** (Wahrscheinlichkeit `1 − Unab_m / 100`): `Unab_m` −10;
  mit 30 % Wahrscheinlichkeit Kündigungswelle (`Glaub_m` −10); `R` −0,5.
- **Redaktion setzt sich durch:** `Unab_m` +5.

**Lernpunkt:** Eine polarisierende Partei verschärft die inneren Konflikte der Medienhäuser.
Schon ihre Existenz kann die Unabhängigkeit der Presse schwächen, ohne dass sie selbst
eingreift.

**Erbfolge:** Mit 1 % pro Runde und Haus wechselt der Eigentümer; `I_m` wird neu
ausgewürfelt (`game-design.md` 7.2).

**MVP:** Die Häuser reagieren auf die Partei, der Spieler kann sie aber noch nicht direkt
beeinflussen. Aktionen wie Exklusivinterviews oder das Umwerben von Erben folgen später.

**Häuser im MVP (Startwerte)**
| Haus (Arbeitsname) | Typ | Gebiet | `Reach_m` | `Unab_m` |
|---|---|---|---|---|
| Boulevard-Dynastie | Boulevard | bundesweit | 35 | 30 |
| Verlegerfamilie Qualitätspresse | Qualitätszeitung | bundesweit | 15 | 80 |
| Regionale Zeitungsgruppe Süd | Regionalpresse | Süden | 30 | 55 |
| Regionale Zeitungsgruppe Nord | Regionalpresse | Norden | 30 | 55 |
| Öffentlich-rechtlicher Rundfunk | Öffentlich-rechtlich | bundesweit | 35 | 85 (fest) |

`Glaub_m` startet auf dem Zielwert, `Grundreichweite_m` = `Reach_m` − Zuspitzungsanteil.

#### Öffentlich-rechtlicher Rundfunk
Es gibt keinen Eigentümer. Seine Rolle übernehmen die **Aufsichtsgremien** (Rundfunkrat,
Verwaltungsrat), die die Intendanz wählen und das Programm überwachen.

```
I_Gremien = 1/3 · I_Politik + 2/3 · I_Gesellschaft
I_Politik = Positionen der Parteien in Landesregierungen, gewichtet nach Regierungsanteilen
            (im MVP: die drei Konkurrenzparteien, gewichtet nach bundesweiter Stärke)
I_Gesellschaft = (0, 0)   gesellschaftliche Gruppen (Kirchen, Gewerkschaften, Verbände)

Eigentümer_ÖR = clamp(1 − |I − I_Gremien| / 50,  −1, 1)
```

- **[Vereinfachung]** Der staatsnahe Anteil der Gremien ist seit dem ZDF-Urteil des BVerfG
  (2014) auf höchstens ein Drittel begrenzt; das Spiel übernimmt diesen Anteil direkt.
- **Programmautonomie:** Die Gremien greifen nicht in Inhalte ein. `Unab_ÖR` bleibt fest bei
  85, es gibt **keinen** Konflikt zwischen Eigentümer und Redaktion. Ton und Medienklima
  werden mit denselben Formeln berechnet wie bei den anderen Häusern.
- **Hebel (ab Phase II, nicht im MVP):**
  - *Gremienbesetzung:* Regiert die Partei in Ländern mit, verschiebt sich `I_Politik` zu ihr.
  - *Intendantenwahl:* seltenes Ereignis; eine Gremienmehrheit kann `Unab_ÖR` senken.
  - *Rundfunkbeitrag:* Staatsverträge brauchen alle 16 Landtage. Blockiert ein Land, sinken
    Budget und `Reach_ÖR` (`game-design.md` 3.5).
  - *Delegitimierung:* Kampagnen gegen den "Staatsfunk" senken `Glaub_ÖR`, kosten aber
    Radikalität und Resilienz.
- **Später:** Aufteilung in eine bundesweite Anstalt und regionale Landesrundfunkanstalten,
  passend zu den Regionen.

---

## 6. Ressourcenfluss pro Runde

```
G(t+1) = G(t)
       + M · P_Beitrag                                   Mitgliedsbeiträge
       + Σ_u Zahlung_u                                   Spenden
       + P_Staat · Stimmen_letzte_Wahlen                 staatliche Teilfinanzierung
       − P_Fix · (1 + Σ_r V_r / 50)                      Geschäftsstellen, Personal
       − Ausgaben für Aktionen
```

- **[Vereinfachung]** Staatliche Teilfinanzierung ab 1 % bei einer Landtagswahl oder 0,5 %
  bei einer Bundestagswahl, pro Stimme.
- **Mitglieder:**
  `M(t+1) = M · (1 + P_Mwachs + 0,02 · ΔU_Bund − Austritt(E))`,
  `Austritt(E) = 0,03 · max(0, (40 − E) / 40)`.
- **Aktivisten:** `A = M · Quote`, `Quote = 0,05 + 0,10 · E/100 + 0,10 · Rad/100`. Radikale
  Parteien haben aktivere Mitglieder. Aktivisten erneuern sich jede Runde vollständig.
- **Aktionspunkte:** `AP = 4 + besetzte Funktionen + Landtagsfraktionen`, höchstens 10.
  Funktionen im MVP: Generalsekretär, Schatzmeister, Landesvorsitz Süden, Landesvorsitz
  Norden. Im Wahlkampfquartal ×1,5 (abgerundet).
- **Reichweite:**
  `RP(t+1) = RP · (1 − P_RPzerfall) + Aktionen`,
  `RK_l` ergibt sich aus den Medienhäusern (5.6); `RK_Bonus` steigt durch Aktionen und
  Ereignisse und zerfällt um 30 % pro Runde.
- **Glaubwürdigkeit:** erholt sich langsam auf einen Wert zu, den das bundesweite
  Medienklima verschiebt: `C(t+1) = C + 0,05 · (60 + P_MKC · MK_Bund − C)`.
- **Parteieinheit:** erholt sich auf 60 zu (Annäherung 0,1); Ideologen im Personal und
  Kurswechsel senken sie.

---

## 7. Wahlen

```
Ergebnis_l = U_l + Wahlkampfbonus_l + N(0, P_σWahl)
```

| Wahl | Hürde | Folge im MVP |
|---|---|---|
| Kommunalwahl (je Land) | keine | `V_r` + `P_Kommunal` · Ergebnis_l; Mitglieder +5 %; Personalpool wächst |
| Landtagswahl | 5 % | `LT_l` = ja: +1 AP, `RK` +10, Teilfinanzierung |
| Bundestagswahl | 5 % bundesweit | ≥ 5 %: Fraktion im Bundestag, MVP gewonnen |

Der Wahlkalender kommt aus dem Szenario. In "Neugründung" liegen in den ersten 6 Jahren
mindestens je eine Kommunal- und Landtagswahl in jedem der vier spielbaren Länder und zwei
Bundestagswahlen.

---

## 8. Radikalität, Beobachtungsdruck, Verfassungsschutz

### 8.1 Radikalität
Steigt durch Aktionen (Nebenwirkungen) und Ideologen im Personal (+1 pro Runde und
Person). Sinkt langsam: `Rad(t+1) = Rad − 0,5` ohne radikale Aktionen in dieser Runde.

### 8.2 Beobachtungsdruck
Größere Parteien werden genauer beobachtet:
```
Ziel_B = Rad · (0,6 + U_Bund / 20) · (R / 100) + Σ Aufdeckungen + Σ mod
B(t+1) = B + 0,25 · (Ziel_B − B)
```
V-Leute im Personal liefern Informationen: Jede V-Person senkt die Schwellen in 8.3 um 5.

### 8.3 Eskalationsstufen
| Stufe | Schwelle `B` | Bedingung |
|---|---|---|
| 1 Prüffall | 35 | 2 Runden in Folge darüber |
| 2 Verdachtsfall | 55 | 3 Runden in Folge darüber |
| 3 gesichert extremistisch | 75 | 4 Runden in Folge darüber |

- Bei erfüllter Bedingung steigt `VS` mit Wahrscheinlichkeit 0,6 pro Runde (Behörden
  arbeiten nicht mechanisch).
- **Herabstufung:** `B` 6 Runden in Folge mehr als 15 unter der Schwelle der aktuellen
  Stufe, dann `VS` − 1 (in der Realität selten, im Spiel möglich).
- **Folgen:** Stigma im Umfragemodell (3.4), Abzüge bei Geldgebern (5.4), ab Stufe 2
  Austritte von Mitgliedern im öffentlichen Dienst (`M` −3 % einmalig je Stufe).

---

## 9. Presse

```
Pressestärke PS = R / 100 · P_Presse
```

Jede Runde würfelt die Presse auf drei Recherchen:

| Recherche | Wahrscheinlichkeit pro Runde | Folge bei Treffer |
|---|---|---|
| Widerspruch | `PS · W / 100 · (0,5 + RP / 200)` | `C` − `W / 3`; alle regionalen Botschaften werden öffentlich, `W` halbiert |
| Finanzierung | `PS · Intransparenz / 100` | `C` −10, `B` +10, ggf. Rückzahlung |
| Person | Journalist mit Tarnidentität hat `Material` ≥ 100 | Enthüllung: `C` −15, `E` −10 |

`Intransparenz` steigt mit "Unterstützung über Dritte" und intransparenten Großspenden und
sinkt langsam.

---

## 10. Personen

### 10.1 Erzeugung
```
Attribut = clamp(N(50, 15), 5, 95)
```

| Agenda | Wahrscheinlichkeit | Bonus (+15) |
|---|---|---|
| Karrierist | 10 % | Vernetzung, Kompetenz |
| Ideologe | 8 % | Überzeugungskraft |
| Journalist mit Tarnidentität | 3 % | Kompetenz, Vernetzung |
| V-Mann | 2 % + 3 % · `VS` | Kompetenz, Vernetzung |
| keine | Rest | – |

Zusätzlich sind 5 % der Personen ohne Agenda **Talente** mit +15 auf zwei zufällige
Attribute außer Loyalität. Die Wahrscheinlichkeit von V-Leuten steigt mit der Einstufung,
weil der Verfassungsschutz dann aktiv anwirbt.

Pro Runde stehen `2 + Σ_r V_r / 25` neue Kandidaten im Personalpool zur Auswahl.

### 10.2 Wirkung der Agenden
| Agenda | Laufende Wirkung | Auslöser für Loyalitätscheck |
|---|---|---|
| Karrierist | – | `U_Bund` sinkt zwei Runden in Folge |
| Ideologe | `Rad` +1/Runde, `E` −1/Runde; Polarisierung: Personal-Term in 3.4 ×1,5, aber `P_Polar` Abzug in Ländern mit `R` > 60 | Aktionen, die `Rad` senken oder Positionen abschwächen |
| Journalist | `Material` + `Vern` / 10 pro Runde | Aktionen mit Aufdeckungsrisiko (er dokumentiert statt sabotiert) |
| V-Mann | Senkt VS-Schwellen (8.2) | Aktionen mit `B`-Nebenwirkung: Information fließt ab, `B` +5 |

### 10.3 Loyalitätscheck
```
bestanden, wenn zufall() < Loy / 100 · (0,5 + E / 200)
```
- **Nicht bestanden:** Karrierist tritt aus (bei hohem `Vern` mit Wechsel zur Konkurrenz,
  `U_l` −0,5 in seiner Region); Ideologe handelt eigenmächtig (Aktion wird radikaler
  ausgeführt, `Rad` +5); V-Mann und Journalist: siehe Tabelle 10.2.
- **Überprüfung** (Aktion) deckt die Agenda mit 70 % Wahrscheinlichkeit auf.

---

## 11. Krisen (MVP: zwei)

```
Wahrscheinlichkeit pro Runde = P_Krise, wenn letzte Krise ≥ 8 Runden her, sonst 0
Vorzeichen: 1–2 Runden vorher, Zuverlässigkeit 70 % (auch Fehlalarme möglich)
```

| Krise | Dauer | Salienz | Weitere Wirkung |
|---|---|---|---|
| Energiekrise | 4–8 Runden | Wohnkosten ×2, Windkraft ×1,5, Verbrenner-Aus ×1,5 | Unternehmen zahlen 20 % weniger |
| Finanzkrise | 4–6 Runden | Steuern ×2, Sozialstaat ×2 | Unternehmen zahlen 30 % weniger, `M`-Wachstum halbiert |

**Krisenbonus im Umfragemodell (Opposition):**
```
Krisenbonus_l = P_Krisenbonus · Krisenpassung_l     ab der 2. Krisenrunde
Krisenbonus_l = − 1                                  in der 1. Krisenrunde (Sammlungseffekt)
Krisenpassung_l = Themenpassung T_l, berechnet nur über die Krisenthemen
```
Im MVP regiert die Partei nicht, Krisen sind also immer eine Chance.

---

## 12. Phasen und Spielende (MVP)

| Übergang | Bedingung |
|---|---|
| I → II | Kommunalmandate in mindestens 2 Ländern |
| II → III | Landtagseinzug in mindestens 2 Ländern |
| MVP gewonnen | ≥ 5 % bei einer Bundestagswahl |

| Niederlage | Bedingung |
|---|---|
| Bankrott | `G` < 0 zwei Runden in Folge |
| Bedeutungslosigkeit | `U_Bund` < 1 % für 8 Runden in Folge, frühestens ab Runde 8 |
| Spaltung | `E` < 15 |

Regierungsbeteiligung, Bundesrat und Parteiverbot sind nicht Teil des MVP.

---

## 13. Parameter (Startwerte)

| Parameter | Wert | Wirkung |
|---|---|---|
| `P_Basis` | 1,0 | Grundpotenzial in % |
| `P_T` | 14 | Max. Prozentpunkte durch Themenpassung |
| `P_V` | 6 | Max. Prozentpunkte durch Verankerung |
| `P_Pers` | 2 | Max. Prozentpunkte durch Spitzenpersonal |
| `P_Stigma` | 1,5 | Punkte Abzug je VS-Stufe bei `R` = 100 |
| `P_Polar` | 1 | Abzug durch Ideologen in resilienten Ländern |
| `P_α` | 0,25 | Annäherungsgeschwindigkeit Umfragen |
| `P_σ` | 0,6 | Umfragerauschen |
| `P_Umax` | 45 | Obergrenze Umfrage |
| `P_σWahl` | 0,8 | Rauschen am Wahltag |
| `P_Wechsel` | 3 | Glaubwürdigkeitskosten Kurswechsel |
| `P_W` | 2 | Anstieg Widerspruchsrisiko |
| `P_Wzerfall` | 1 | Abklingen Widerspruchsrisiko |
| `P_Beitrag` | 0,03 | Tsd. € pro Mitglied und Quartal |
| `P_Staat` | 0,0002 | Tsd. € pro Stimme und Quartal |
| `P_Fix` | 8 | Fixkosten in Tsd. € pro Quartal |
| `P_Mwachs` | 0,02 | Grundwachstum Mitglieder |
| `P_RPzerfall` | 0,08 | Zerfall Plattformreichweite |
| `P_Kommunal` | 2 | Verankerungsgewinn je Prozentpunkt Kommunalwahlergebnis |
| `P_Presse` | 0,8 | Grundstärke Presse |
| `P_Krise` | 0,03 | Krisenwahrscheinlichkeit pro Runde |
| `P_Krisenbonus` | 4 | Max. Prozentpunkte durch Krisenpassung |
| `P_Nähe` | 60 | Ideologie-Abstand, ab dem eine Konkurrenzpartei keinen Druck mehr ausübt |
| `P_Konk` | 1 | Stärke des Konkurrenzdrucks |
| `P_MK` | 0,2 | Wirkung des Medienklimas auf den Zuspruch (±20 %) |
| `P_MKC` | 20 | Verschiebung des Glaubwürdigkeits-Ruhewerts durch das Medienklima |
| `P_Zuspitz` | 15 | Zusätzliche Reichweite eines vollständig vereinnahmten Hauses |

**Startwerte Szenario "Neugründung":** `G` 50, `M` 300, `U_l` 0,5 %, `C` 50, `R` 75,
`Rad` 10, `B` 0, `VS` 0, `E` 70, `RP` 5, `RK_Bonus` 0, `V_r` 2 (Süden, Norden), 0 sonst,
keine Themenpositionen, Funktionen unbesetzt.

---

## 14. Balancing: Zielkorridore und automatisierte Partien

Die Startwerte werden nicht von Hand, sondern über **automatisierte Partien** abgestimmt:
Strategie-Bots spielen ohne Grafik (Godot headless) hunderte Partien mit verschiedenen
Seeds. Die Ergebnisse müssen in diesen Korridoren liegen:

| Strategie-Bot | Erwartung |
|---|---|
| Geduldig, gemäßigt, konsistent | Bundestag nach 20–32 Runden in der Mehrheit der Partien |
| Radikal und schnell | Bundestag eher nach 12–20 Runden, aber in mindestens einem Drittel der Partien Verdachtsfall vorher |
| Doppelzüngig (regionale Botschaften) | Aufdeckung meist nach 6–10 Runden |
| Passiv (fast keine Aktionen) | Bedeutungslosigkeit in der Mehrheit der Partien |
| Zufällig | Kaum Siege |

Liegt ein Bot außerhalb seines Korridors, werden die Parameter angepasst. So bleibt das
Balancing nachvollziehbar und wiederholbar.

---

## 15. Offene Punkte

Derzeit keine.

Entschieden: Das Startjahr ist **fiktiv**; der Wahlkalender kommt aus dem Szenario. Der
öffentlich-rechtliche Rundfunk ist als eigenes Haus enthalten (5.6).

---

## 16. Umsetzungsentscheidungen (M2)

Wo das Modell Details offenließ, wurde bei der Umsetzung so entschieden. Alle Werte sind
Startwerte für das Balancing (M3).

| Thema | Entscheidung |
|---|---|
| Wahlkampfquartal | Das Quartal, in dem die Wahl stattfindet; gewählt wird am Ende der Runde |
| Kommunalmandate (Phase I → II) | Ab 1 % Kommunalwahlergebnis in einem Land |
| Kurswechsel | Kostet zusätzlich 2 Parteieinheit je Positionsstufe |
| Regionale Botschaft ohne Bundesposition | Bezugswert 0; widersprüchliche Botschaften in zwei Regionen zählen also immer |
| Presse: Widerspruch aufgedeckt | Regionale Botschaften werden gelöscht (sie sind öffentlich), `W` halbiert |
| Presse: Finanzierung aufgedeckt | Intransparenz auf 0, keine Rückzahlung |
| Intransparenz | Sinkt um 1 pro Runde |
| Resilienz-Erholung | 2 % der Differenz zum Startwert des Szenarios pro Runde |
| Krisen | Jede echte Krise hat ein Vorzeichen; Fehlalarme so häufig, dass 70 % der Vorzeichen eintreffen; höchstens eine Krise gleichzeitig |
| Geldgeber: Einstufung | AG −20 je Stufe ab VS 1; Mittelstand −15 je Stufe ab VS 1; Familienunternehmen −15 je Stufe ab VS 2 (VS 2: −15, VS 3: −30) |
| Geldgeber: Themenkonflikt | Partei und Geldgeber stehen auf entgegengesetzten Seiten (Vorzeichen) |
| Geldgeber: Rückkehr | Nach der Wartezeit, sobald die Zufriedenheit wieder mindestens 50 erreicht |
| Bedeutungslosigkeit | Wird erst ab Runde 8 gezählt, frühestes Ende also in Runde 15 |
| Karrierist läuft über | Bei Vernetzung > 70: −0,5 Umfrage in der geführten Region, bei Bundesfunktion in allen Ländern |
| Loyalitätsbruch bei Delegation | Ideologe: `Rad` +5; Journalist: `Material` +20; V-Mann: `B` +5; Karrierist verlässt die Partei, die Aktion entfällt |
| Agenda-Konflikte | Ideologe: Abschwächen einer Position; V-Mann: Aktionen, die `B` erhöhen; Journalist: Aktionen, die Intransparenz erhöhen; zusätzlich je Aktion in den Daten |
| Sichere Aktionen | Aktionen mit Grundchance 1 gelingen immer (keine Kappung auf 95 %) |
| Influencer gewinnen | `RP` +8 sofort, danach +2 pro Runde für 8 Runden; Nebenwirkung Intransparenz +5 (Aufdeckung über die Finanzrecherche) |
| Großspende | Doppelte Maximalzahlung, Zufriedenheit −15, setzt Zufriedenheit ≥ 60 voraus |
| Unterstützung über Dritte | Dreifache Maximalzahlung, Zufriedenheit −10, Intransparenz +15, `B` +3, setzt Zufriedenheit ≥ 50 voraus |
| Säuberung | Entfernt Personal mit Loyalität < 40; übriges Personal −5 Kompetenz |
| Medienhäuser | Werden im Schritt "Meinung" nach der Umfrageberechnung fortgeschrieben |
| Staatliche Teilfinanzierung | 45 Mio. abgegebene Stimmen bundesweit, je Land anteilig nach Bevölkerung **[Vereinfachung]** |
| Landesvorsitz | Im MVP fest je eine Funktion für Süden und Norden |
| Spielstände | Kommazahlen werden auf etwa 16 Stellen genau geladen (Einschränkung von Godots Zahlenumwandlung); Seed, Zufallsgenerator und Ganzzahlen exakt. Wiederholung über Seed und Aufträge ist exakt |
