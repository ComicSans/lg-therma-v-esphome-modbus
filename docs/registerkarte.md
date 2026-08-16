# Registerkarte

Gemessen an einer **LG Therma V R290 Monobloc, Hydro Unit HN1639HC.NK0,
Geräte-Firmware 3.07.2a**, Modbus RTU über Klemme 21/22, Slave 1, 9600 Baud.

Der Firmwarestand gehört zur Karte und nicht zur Fußnote: Bei einem Gerät, für
das keine veröffentlichte Belegung passt, ist er neben der Modellnummer die
zweite Größe, an der sich die Belegung ändern kann. Ob sie es tut, ist offen —
hier liegt nur ein Stand vor.

> **„Generation" heißt weiter unten etwas anderes.** Dort ist eine Fassung der
> ESPHome-Registerliste gemeint, nicht der Firmwarestand des Geräts. Die
> Blockbildung von ESPHome ändert sich mit jeder solchen Fassung, und genau
> daran ist eine Zuordnung schon einmal gescheitert.

## Die veröffentlichten Karten passen hier nicht

Weder das allgemeine Therma-V-Handbuch (S. 262–264) noch das Modellhandbuch
(S. 181–182) noch die LG-Folie „Open MODBUS" noch das basti242-Wiki treffen auf
dieses Gerät zu — **auch nicht mit Versatz**. Ein Scan über alle 65536 Adressen
je Registertyp fand **32 antwortende Punkte**; DI32 und CO4 kamen später durch
**Einzelabfrage** hinzu. Heute fragt die Firmware **38 antwortende Punkte** ab —
die Differenz sind CO2, CO3, CO29 und CO30, die in dieser Tabelle lange fehlten.
Alles andere liefert Exception 2 (illegal data address):

| Typ | Adressen | Anzahl |
|---|---|---|
| Input Register (FC 4) | 9–27 | 19 |
| Holding Register (FC 3) | 24–29 | 6 |
| Discrete Input (FC 2) | 6, 7, 8, 9, 31, **32** | 6 |
| Coil (FC 1) | 2, 3, **4**, 5, 6, **29, 30** | 7 |

> **Bei den Coils hat der Tiefenscan mehr übersehen als gefunden** — und der
> Grund ist derselbe Blockmechanismus wie bei `force_new_range`, nur in der
> Suchrichtung. Der Scan fragte in Vierergruppen ab; enthält eine Gruppe ein
> nicht existierendes Register, lehnt das Gerät die **ganze Gruppe** mit
> Exception 2 ab, und die vorhandenen Nachbarn verschwinden mit. Einzelabfragen
> finden, was Gruppenabfragen verstecken.
>
> Die Zahlen dazu: Der Scan meldete **zwei** Coils zurück, CO5 und CO6. Fünf
> weitere antworten — CO2 und CO3 tragen sogar belegte Bedeutungen, CO29 und
> CO30 liegen weit außerhalb des Bereichs, den der Scan als Coil-Adressen
> ausgewiesen hat. Jede Zahl in dieser Tabelle ist die Zahl der *gefundenen*
> Punkte, nicht die der vorhandenen.
>
> Wer nachbaut, sollte deshalb den Button **„Breiter Registerscan"** laufen
> lassen: er prüft von der eingestellten Startadresse aus 64 Adressen in allen
> vier Registertypen einzeln.

Die offizielle Karte passt auch hier nur teilweise: Coil 0 (Ein/Aus), Holding 0
(Betriebsmodus) und Holding 9 (Energiezustand/SG-Ready) sind auf diesem Gerät
**nicht erreichbar** — der Betriebsmodus liegt stattdessen schreibbar auf HR26
(dazu unten mehr). Coil 2 dagegen trägt hier wie in der offiziellen Karte den
**Flüstermodus** und ist schaltbar (CO2 in der Tabelle unten).

### Unterhalb von Adresse 1024 liegt nichts mehr

Am 01.08.2026 sind die Startadressen **64 bis 960** in Schritten von 64
durchgelaufen, fünfzehn Scans zu je 256 Einzelanfragen. Zusammen mit dem Lauf ab
0 vom 30.07., der CO29 und CO30 fand, sind damit die **Adressen 0–1023 in allen
vier Registertypen einzeln geprüft** — 4096 Abfragen.

**Die fünfzehn Läufe ab 64 ergaben keinen einzigen Treffer.** Die Frage, ob der
Gruppenscan unterhalb von 1024 noch etwas verschluckt hat, ist damit beantwortet:
Die 38 bekannten Punkte sind dort vollständig, und alle liegen unter Adresse 32.

Was offen bleibt, ist der Raum **ab 1024**. Dort liegt nur der alte Gruppenscan
vor — derselbe, der bei den Coils fünf von sieben übersehen hat. Ihn einzeln
nachzuprüfen scheitert an der Zeit: Bei 8 Anfragen je 15 Sekunden bräuchte der
restliche Adressraum rund 136 Stunden Dauerlast auf einem Bus, an dem die
Regelung hängt.

> **Was ein Scan den Bus kostet**, für alle, die das nachfahren: Die Zyklusdauer
> stieg von 19,5 auf 30–35 s, die Lücke zwischen zwei Antworten entsprechend.
> Das ist normal und kein Grund einzugreifen — die Firmware pausiert den Scan
> von allein ab 70 % der eingestellten Grenze und nimmt ihn wieder auf. Über
> alle fünfzehn Läufe: **kein Punkt ohne Antwort, kein verpasster Zyklus, keine
> Buswarnung.** Ein erster Versuch, den Bus mit einer eigenen 30-s-Schwelle
> zusätzlich zu schützen, hat dagegen einen gesunden Lauf nach 112 von 256
> Anfragen abgewürgt: Wer hier schärfer sichert als die Firmware, bricht nur
> seine eigenen Scans ab.

## Belegte Zuordnungen

| Punkt | Bedeutung | Skalierung | Grundlage |
|---|---|---|---|
| IR12 | Außentemperatur **des Geräts**, kein Wetterwert | ×0,1 | 305 bei 30 °C am Bedienteil. Der Fühler sitzt im besonnten Gehäuse: gegen drei unabhängige Außensensoren nachts bei Stillstand ±0 K, tagsüber bei Stillstand +7,9 K im Mittel und bis +12,9 K, bei laufendem Ventilator noch +3,9 K. Beim Ventilatorstart fiel der Wert um 8 K, während alle drei unabhängigen Sensoren stiegen |
| IR15 | Wasser-Rücklauf | ×0,1 | Vorlauf > Rücklauf im Heizbetrieb, umgekehrt im Kühlbetrieb |
| IR16 | Wasser-Vorlauf | ×0,1 | dito |
| IR17 | **Sauggastemperatur** | ×0,1 | gegen die Sättigungstemperatur aus IR22 gerechnet: im **Stillstand** 5–8 K, bei **laufendem Verdichter** nur 1,2 K im Median (533 Werte, 30.07.–02.08.2026). Die ältere Angabe „durchgehend 5–8 K" stammte aus einer Stichprobe, die überwiegend Stillstand war. Der Momentanwert pendelt im Lauf zwischen −6,7 und +8,8 K, weil der Druck sofort folgt und der Fühler träge ist — auswertbar ist nur der gleitende Median. Wird negativ, was für Sauggas normal ist |
| IR21 | **Hochdruck** | ×0,01 bar (Überdruck) | über eine Warmwasserladung deckt sich die Propan-Sättigungstemperatur mit dem Vorlauf auf unter 1,5 K, über sieben Punkte monoton mitlaufend. Die Deckung ist um rund 1 K einseitig verschoben — siehe unten |
| IR22 | **Niederdruck** | ×0,01 bar | im Stillstand praktisch gleich IR21 (Druckausgleich), im Betrieb weit darunter |
| IR23 | **Scheinleistung** | VA | siehe unten |
| IR24 | Raumtemperatur | ×0,1 | 205 bei „innen 20,5" |
| IR25 | Warmwassertemperatur | ×0,1 | 506 bei 50,6 °C am Bedienteil |
| IR26 | **Wärmeanforderung:** 0 = keine, 1 = bereit, 2 = angefordert | — | fiel beim Abschalten der Warmwasser-Freigabe von 2 auf 0, während HR26 stehenblieb — siehe unten |
| HR24 | Soll Heizkreis 1 in der am Bedienteil gewählten Regelgröße, **schreibbar** | ×0,1 | 21 °C Kühlen → 55 °C Heizen; folgt der Anlage bei jedem Moduswechsel — siehe unten |
| **HR26** | **Betriebsmodus, schreibbar:** 0 = Aus / nur Warmwasser, 1 = Kühlen, 2 = Heizen, 3 = Auto | — | am Bedienteil geschaltet, alle vier Werte sekundengenau belegt — siehe unten |
| HR29 | Soll Warmwasser, **schreibbar** | ×0,1 | 480 bei „Warmwasser 48° eco", Änderung live gefolgt |
| **CO2** | **Flüstermodus, schaltbar** | — | vier Wechsel sekundengenau zur Bedienung am Bedienteil, kein anderer Punkt ging mit |
| CO4 | Heizkreis 1 aktiv | — | ging an/aus zeitgleich mit Heizkreis 1, zwei Wechsel; nur lesend eingebunden |
| CO6 | Warmwasser-Freigabe, **schaltbar** | — | schaltet die Warmwasserbereitung nachweislich |
| DI31 | Heizkreis 1, invertiert zu CO4 | — | on wenn HK1 aus, off wenn HK1 läuft |
| **CO3** | **Außeneinheit in Betrieb** | — | rund 20 Flanken decken sich mit dem Verdichtermelder, überwiegend mit 5 s Abfrageversatz. Der Melder hängt an der Wirkleistung eines Shelly, der Beleg ist also nicht zirkulär |
| **DI07** | **Drei-Minuten-Wiederanlaufsperre** | — | ruht auf `on` und fällt nach jedem Betriebsende ab. 68 Abfallphasen vom 02.–08.08.2026: **61-mal exakt 180 s**, sechsmal 210 s (180 s plus ein Zyklus, Abtastartefakt), einmal 360 s |
| **IR11 = IR19** | **Außenwärmetauscher** — Kondensator im Kühlen, Verdampfer im Heizen | ×0,1 | Vorzeichen dreht mit der Betriebsrichtung, und der Wert landet beide Male auf der passenden Sättigungstemperatur — siehe unten |
| **IR18** | **Verdichtergehäuse, Hochdruckseite** | ×0,1, faktisch 1 K | folgt dem Hochdruck (r = +0,959), nicht der Wirkleistung (r = +0,689); hält im Stillstand ein Plateau — siehe unten |
| **IR20** | **Verdichterdrehzahl** (Einheit offen, Hz naheliegend) | — | IR20 = 20 zieht bei Warmwasser 1690 W, IR20 = 30 im Kühlen nur 1351 W: eine Leistungsskala kann das nicht — siehe unten |
| **DI08** | **Höchste Verdichterstufe** — deckungsgleich mit IR20 = 60 | — | 56 Takte vom 07.–16.08.2026: alle 22 Takte mit DI08 erreichen 60, alle 34 ohne bleiben bei ≤ 55. Auf Impulsebene 27 IR20-60-Phasen gegen 27 DI08-Impulse, keiner ohne Gegenstück, Versatz ausschließlich ±½ Zyklus — siehe unten |
| **DI09** | **Warmwasserbereitung** | — | deckt zwei Ladungen deckungsgleich ab und blieb in den Kühltakten des 31.07. aus, obwohl die Speichertemperatur genug schwankte, um eine rein temperaturbasierte Erkennung auszulösen |

### HR26 ist der Betriebsmodus, nicht die Regelungsart

Ursprünglich als „Regelungsart" (Vorlauf/Rücklauf/Raum) gedeutet. Am Bedienteil
zeigte sich: es ist der **Betriebsmodus**, und er ist schreibbar. Mit
Zeitstempeln gegengeprüft:

| Wert | Modus | Beleg |
|---|---|---|
| 0 | Aus / nur Warmwasser | beim Abschalten von Heizkreis 1 |
| 1 | Kühlen | Heizkreis-Soll blieb 21 °C |
| 2 | Heizen | Heizkreis-Soll sprang gleichzeitig auf 55 °C |
| 3 | Auto | im Automatikbetrieb |

Die Abschaltung von Heizkreis 1 lief gestaffelt und reproduzierbar: **CO4
zuerst, drei Sekunden später HR26 auf 0, zehn Sekunden später DI31.** Bei 20 s
Abfragetakt ist diese Reihenfolge echt und kein Abtastartefakt.

### HR24 ist in jedem Modus lesbar — auch Auto

Der Zielwert HR24 ist ein eigenes Register, unabhängig vom Modus. In der
ThinQ-App war das ein Problem: dort ging entweder Auto **oder** die Sicht auf
den Zielwert, im Auto-Modus wurde er blind. Über Modbus ist HR24 in jedem Modus
sichtbar und folgt der Anlage aktiv (21 °C im Kühlen, 55 °C im Heizen).

**Welche Größe HR24 meint, bestimmt die Regelungsart am Bedienteil** — Vorlauf,
Rücklauf oder Raum, je Betriebsmodus getrennt einstellbar. An dieser Anlage
steht sie auf **Vorlauf im Heizen und Rücklauf im Kühlen**; die 55 °C oben sind
also ein Vorlauf-Soll, die 21 °C ein Rücklauf-Soll.

Das ist eine Einstellung, keine Eigenschaft des Registers: Wer die Regelungsart
umstellt, ändert die Bedeutung von HR24, ohne dass sich am Register etwas
ablesen lässt. **Die Regelungsart selbst ist über Modbus nicht abgebildet** —
ein Energiemanager, der auf HR24 schreibt, kann sie nicht prüfen und muss von
der Einstellung am Gerät ausgehen.

### Im Auto-Modus ist HR24 keine Temperatur, sondern eine Kurvenverschiebung

Steht HR26 auf 3 (Auto), führt die Anlage den Vorlauf selbst nach der
Heizkurve. HR24 trägt dann nur noch, um wie viele Stufen der Nutzer die Kurve am
Bedienteil verschoben hat:

| HR24 | Bedeutung |
|---|---|
| 16 | −3 |
| 17 | −2 |
| 18 | −1 |
| **19** | **0 — automatisch geführter Wert** |
| 20 | +1 |
| 21 | +2 |
| 22 | +3 |

Der Wertebereich ist damit 16..22 statt 5..65, und keiner dieser Werte ist eine
Vorlauftemperatur. Wer 19 °C als Sollwert liest, liest falsch.

> **Herkunft, abweichend vom Rest dieser Karte:** vom Betreiber berichtet
> (2026-08-02), nicht am Bus gemessen. Alle anderen Zuordnungen hier hängen an
> einer Bedienung mit Zeitstempel. **Gegenprobe:** im Auto-Modus die Kurve am
> Bedienteil auf +3 schieben und prüfen, ob HR24 auf 220 (22,0 °C) steht.

Die Firmware bildet das über eine eigene Entität **Heizkurven-Verschiebung**
(−3..+3, Schritt 1) ab, die auf dasselbe Register schreibt und außerhalb des
Auto-Modus auf unbekannt steht. Die Number „Soll-Temperatur Heizkreis 1" behält
ihren Bereich 5..65 — `min_value`/`max_value` sind Traits, die Home Assistant
bei der Registrierung übernimmt und die sich zur Laufzeit nicht umschalten
lassen. Im Auto-Modus zeigt sie deshalb 19 °C und meint es nicht so.

### IR23 ist Scheinleistung, nicht Wirkleistung

Entschieden gegen einen Shelly 3EM, der Spannung, Strom und Leistungsfaktor je
Phase einzeln misst. Über 27 Messpunkte einer Warmwasserladung:

```
IR23 / Scheinleistung = 0,907 .. 0,984   (Median 0,946)   <- konstant
IR23 / Wirkleistung   = 1,179 .. 1,360                    <- unruhig
```

Der gemessene Leistungsfaktor lief in derselben Zeit von 0,709 auf 0,790 — er
steigt mit der Last, wie bei einem Inverterverdichter zu erwarten. Genau diese
Laststeigerung macht das Wirkleistungs-Verhältnis unruhig und das
Scheinleistungs-Verhältnis konstant.

Die rund 5 % Abweichung nach unten gegenüber der externen Messung bleibt offen.
**Im Stillstand ist der Wert keine Messung**: er parkt stundenlang exakt auf
417, während der Zähler rund 180 VA sieht. Wer den Verdichterzustand braucht,
nimmt eine externe Wirkleistungsmessung — die interne Energiemessung der
Therma V ist ohnehin als ungenau bekannt.

### Das Messfenster vom August 2026

Drei der folgenden Zuordnungen und zwei Korrekturen stammen aus einem
zusammenhängenden Fenster: **02.08.2026 18:24 bis 08.08.2026 18:11, 8622
Minuten, eine einzige Generation der Registerliste.** Der Anfang ist der Flash
selbst, erkennbar an der Lücke aller Register-Entitäten.

Zwei Dinge gehören zu diesem Fenster dazu, bevor man seine Zahlen mit den
älteren vergleicht:

**Die Zyklusdauer steht auf 30,0 s** (min 29,9 / max 30,1 über 17059 Werte),
gesetzt durch `update_interval: 30s`. Alle Sekundenaussagen weiter oben stammen
aus dem 19,5-s-Regime; Flankenversätze aus beiden Fenstern sind nicht
vergleichbar, und eine gemessene Dauer trägt hier ±30 s.

**HR26 stand sechs Tage auf 3 (Auto)**, CO4 durchgehend an, DI31 aus. Das
Fenster enthält deshalb **keinen einzigen Vorlauf-Sollwert** — HR24 = 19,0 ist
hier die Kurvenverschiebung 0, keine Temperatur. Die Gegenprobe zur
Kurvenverschiebung (oben) bleibt damit offen.

Der Bus war in diesen sechs Tagen sauber: kein verpasster Zyklus, kein Punkt
ohne Antwort, keine Buswarnung.

> **Zwei abgebrochene Verdichterstarts, je genau ein Zyklus lang** — am 03.08.
> 01:52:11 (912 W) und am 08.08. 10:27:14 (574 W). Das ist kein Melderflackern:
> die Wirkleistung des Shelly, CO3 und IR20 (Sprung auf 30, im nächsten Zyklus
> zurück auf 0) zeigen es unabhängig voneinander. Sie gehen als 0,5-min-Takte in
> `Kürzester Takt heute` ein und ziehen die Taktstatistik nach unten. Bei 30 s
> Zyklus ist ein Takt dieser Länge nicht weiter auflösbar.

### Das zweite Messfenster: 07.–16.08.2026

**07.08.2026 00:00 bis 16.08.2026 08:13, 9,34 Tage, 26591 Zyklen.** Dieselbe
Generation der Registerliste wie das erste Augustfenster: Die Änderung vom
15.08. an `therma-v.yaml` betraf ausschließlich Kommentare, kein Register kam
hinzu, keines fiel weg — die Blockbildung von ESPHome ist damit unverändert.

Der Anfang ist keine Wahl, sondern die Wand: **weiter zurück reicht der
Recorder nicht.** Die Zahlen des ersten Fensters (02.–08.08.) lassen sich
deshalb nicht nachrechnen, nur fortschreiben.

**Vier Abfragelücken, zusammen 6,5 Minuten** (0,05 % des Fensters): dreimal
90 s, einmal 120 s, am 08.08. 23:14, 11.08. 21:59, 15.08. 19:18 und 16.08.
00:01. Das sind zwei bis drei ausgefallene Zyklen je Lücke; alles darunter
liegt im Rahmen. Der Bus war also nicht ganz so makellos wie im ersten Fenster
(„kein verpasster Zyklus"), aber ohne erkennbare Häufung.

> **Acht `unavailable`-Marken sind KEINE Lücken.** Alle 106 Entitäten gingen
> achtmal gemeinsam auf `unavailable` und im selben oder nächsten Sekundenschlag
> wieder zurück — Home-Assistant-Neustarts, nicht Geräteausfälle. Der Beleg ist
> die Zyklusreihe der Firmware: an keinem dieser acht Zeitpunkte steht dort eine
> Lücke, der ESP hat durchgehend weitergefragt. Wer sie trotzdem als Ausfall
> zählt, zerschneidet Phasen — siehe DI07 unten.

**Die offenen Punkte sind über 9,34 Tage unverändert geblieben.** Keine einzige
Flanke, kein einziger anderer Wert: IR09 = 19, IR13 = 12000, IR27 = 0,
HR25/27/28 = 0, IR10 = 0, DI32 `off`, CO5 `off`, CO29 `off`, CO30 `off`,
**DI06 `off`**. Für IR10/DI32 und DI06 ist das die erwartete Bestätigung —
HR26 stand die ganze Zeit auf 3 (Auto), CO4 durchgehend an, und geheizt wurde
im August nicht. Für IR27 und HR25/27/28 ist es die dritte Messreihe in Folge
ohne Regung.

**Die Gegenprobe zur Kurvenverschiebung bleibt offen und ist es auch weiter.**
HR26 hat das Fenster nie verlassen, die Number „Heizkurven-Verschiebung" stand
durchgehend auf 0, HR24 durchgehend auf 19,0. Diese Frage schließt keine
Wartezeit — sie braucht eine Bedienung am Bedienteil.

**56 Takte, 66 Wiederanlaufsperren, 27 Phasen auf der höchsten Stufe.** Die
Auswertung von DI08 daraus steht weiter unten.

### DI07: 180 s halten auch über 9 Tage

65 Abfallphasen der Wiederanlaufsperre, Lücken herausgerechnet: **64-mal exakt
180 s**, einmal 210 s (11.08. 08:43, unmittelbar nach einem abgebrochenen
Verdichterstart). Zusammen mit den 68 Phasen des ersten Fensters sind das 133
gemessene Sperrzeiten, davon 125 auf die Sekunde bei 180 s.

> **Eine 66. Phase war keine.** Am 12.08. 08:27:18 begann eine Sperre, die auf
> 44 s und 135 s aufgeteilt in der Historie steht — dazwischen liegt der
> Home-Assistant-Neustart um 08:28:02. 44 + 1 + 135 = 180. Wer solche Marken
> nicht zusammenführt, erfindet kurze Sperrzeiten und Takte, die es nie gab.

### Der Vorlauf liegt bei Warmwasser rund 1 K über der Kondensation

Der Beleg für IR21 = Hochdruck ist die Deckung von Kondensationstemperatur und
Vorlauf über eine Warmwasserladung. Sie hält — aber sie ist einseitig
verschoben. Über die 622 Warmwasserminuten des Augustfensters liegt die
gerechnete Kondensation im Median 0,6 K **unter** dem Vorlauf, in 71,4 % der
Minuten. Wasser kann den Kondensator nicht wärmer verlassen, als das
Kältemittel kondensiert.

**Ein Ablesversatz ist es nicht.** Der wäre dort am größten, wo der Vorlauf
schnell steigt. Es ist umgekehrt:

| Vorlauf | n | Median | Anteil negativ |
|---|---|---|---|
| steht (< 0,2 K/min) | 157 | **−0,98 K** | **98,1 %** |
| steigt (> 0,3 K/min) | 438 | −0,15 K | 61,4 % |

Gerade im ruhigen Zustand ist der Effekt am deutlichsten. Größenordnung
Fühlertoleranz — aber weil an dieser Deckung ein Beleg hängt, lohnte der Blick
auf die Umrechnung in `therma-v.yaml`: eine Propan-Dampfdrucktabelle mit
**5-K-Stützstellen, linear interpoliert**. Zwei Kandidaten standen im Raum, die
lineare Sehne unter einer gekrümmten Kurve und die Stützstellen selbst. Am
16.08.2026 gegen CoolProp (R290-Zustandsgleichung) nachgerechnet:

| Kandidat | Beitrag zur Kondensationstemperatur |
|---|---|
| Sehne unter der Kurve | **−0,01 bis −0,05 K** — vernachlässigbar |
| Stützstellen zu hoch | **−0,20 bis −0,38 K** im Ladebereich (17–26 bar abs.) |
| Absolutdruck +1,0 statt 1,013 bar | −0,03 K |

**Die Sehne ist damit ausgeschlossen** — Propan ist über 5 K so gerade, dass
die Interpolation nichts kostet. Die Stützstellen dagegen liegen ab 45 °C
systematisch zu hoch, im Maximum 0,17 bar bei 65 °C:

| °C | Tabelle | CoolProp | Fehler in K |
|---|---|---|---|
| 45 | 15,40 | 15,34 | −0,17 |
| 50 | 17,20 | 17,13 | −0,18 |
| 55 | 19,20 | 19,07 | −0,32 |
| 60 | 21,30 | 21,17 | −0,30 |
| 65 | 23,60 | 23,43 | −0,36 |
| 70 | 26,00 | 25,87 | −0,26 |

Die frühere Schätzung „0,5 bar zu hoch ergäbe rund 1 K" trifft die
Größenordnung nicht: Die Abweichung ist 0,06 bis 0,17 bar und ergibt 0,2 bis
0,4 K. **Damit ist rund ein Drittel der gemessenen −0,98 K erklärt**; die
restlichen gut 0,6 K bleiben offen und liegen im Bereich der Toleranz von
Vorlauffühler und Druckaufnehmer.

> **Geflasht am 16.08.2026 um 10:57 Uhr (08:57 UTC).** Die Gegenprobe im
> ersten Zyklus danach: Hochdruck 16,18 bar Überdruck, gemeldete Kondensation
> **50,13 °C**. Die alte Tabelle hätte für denselben Druck 49,94 °C ergeben —
> +0,19 K, in Richtung und Betrag wie gerechnet. Alle Zahlen dieser Karte, die
> eine Kondensations- oder Verdampfungstemperatur enthalten, stammen aus der
> Zeit davor.
>
> Der Flash fiel in einen laufenden Takt (Verdichter seit 10:41 an); dieser
> eine Takt trägt beide Umrechnungen.
>
> **Und der Flash ist ein Regimewechsel für vier abgeleitete Größen.** Die
> Registerliste bleibt unberührt, die Blockbildung also auch — aber
> Kondensation, Verdampfung, Überhitzung und Temperaturhub werden *gerechnet*,
> tragen eine Zustandsklasse und springen mit dem Flash: **Kondensation und
> Temperaturhub um +0,2 bis +0,4 K** im Ladebereich, Verdampfung und
> Überhitzung um höchstens 0,1 K. Wer Zeitreihen über den Flash hinweg
> auswertet, mischt zwei Umrechnungen — siehe Fallstrick 2. Betroffen sind
> insbesondere die Näherungszahlen weiter oben: IR11 +0,7 K über der
> Kondensation im Kühlen, IR18 10–16 K über der Kondensation, Kondensation
> 14,8 K über dem Rücklauf im Kühlbetrieb.

Im Kühlbetrieb tritt das nicht auf; dort liegt die Kondensation 14,8 K über dem
Rücklauf.

### IR11 und IR19 sind der Außenwärmetauscher

Die frühere Einordnung — „folgt der Außenluft mit Nachlauf" — stammt aus einem
Fenster ohne Richtungswechsel. Der Trenner ist das Vorzeichen gegen die
Sättigungstemperaturen aus IR21 und IR22. Die werden aus den Drücken gerechnet,
nicht aus IR11: der Beleg ist nicht zirkulär.

| Zustand | IR11 − Gerätefühler | IR11 − Kondensation | IR11 − Verdampfung |
|---|---|---|---|
| Kühlen, Verdichter läuft (1672 min) | +5,2 K | **+0,7 K** (p10 −0,0 / p90 +1,9) | +22,0 K |
| Warmwasserladung (622 min) | −7,8 K | −39,2 K | **+5,2 K** (p10 +1,9 / p90 +11,0) |
| Stillstand (6326 min) | +1,7 K | — | — |

Im Kühlen ist der Außenwärmetauscher der Kondensator, bei der Warmwasserladung
der Verdampfer. IR11 liegt beide Male auf der jeweils richtigen
Sättigungstemperatur, und das Vorzeichen gegen die Außenluft dreht mit der
Richtung mit. So verhält sich ein Fühler am Lamellenblock, nicht einer in der
Luft.

**Die Spiegelung hält.** Die 99,7 % byte-identisch von damals sind hier 85,8 %
exakt gleich — der Grund ist nicht Drift, sondern Tempo: IR11 ändert sich im
Kühlbetrieb um 0,5 K je Zyklus (90. Perzentil 1,5 K), und 95 % aller
IR19-Werte finden im Fenster ±35 s einen IR11-Wert innerhalb von 0,5 K. Die
Abweichung ist genau ein Abtastschritt.

### IR18 ist das Verdichtergehäuse, nicht der Kühlkörper

Von den beiden Kandidaten der alten Zeile trägt nur einer. Über 2294 Minuten
Verdichterbetrieb:

```
r(IR18, Hochdruck)              = +0,959
r(IR18, Kondensationstemperatur)= +0,958
r(IR18, Verdichtungsverhältnis) = +0,910
r(IR18, Wirkleistung)           = +0,689     <- deutlich schwächer
r(IR18, Verdampfungstemperatur) = −0,122
```

Der Trenner ist derselbe Leistungsbereich in zwei Betriebsarten:

| Betriebsart | Wirkleistung | IR18 | Kondensation | IR18 − Kondensation |
|---|---|---|---|---|
| Kühlen | 1500–2000 W | 51 °C | 37,4 °C | +12,2 K |
| Warmwasser | 1500–2000 W | **72 °C** | 60,3 °C | +11,5 K |
| Kühlen | 2600–3200 W | **58 °C** | 41,6 °C | +16,5 K |

Bei doppelter elektrischer Leistung ist IR18 **14 K kälter** als während der
Warmwasserladung. Ein Leistungsmodul-Kühlkörper kann das nicht — der folgt dem
Strom. **Damit ist der Kühlkörper ausgeschlossen.**

**Das Heißgas selbst ist es aber auch nicht.** Über 60 Verdichterstopps fällt
IR18 aus dem Kühlbetrieb in 30 Minuten nur 2–5 K und bleibt dann auf einem
Plateau 10–18 K über dem — selbst schon zu warmen — Gerätefühler stehen. Gas am
Verdichteraustritt klingt auf Umgebung ab; eine warme Masse tut das nicht. Aus
der Warmwasserladung fällt IR18 dagegen 20–40 K, weil das Gehäuse dort 30 K
über seinem Ruheniveau war.

Beide Hälften erklärt dieselbe Stelle: **das Gehäuse der Hochdruckseite.** Im
Lauf liegt es auf Druckgasbedingungen — konstant 10–16 K über der
Kondensationstemperatur über alle Betriebspunkte — und im Stillstand hält es
seine Wärme.

> **Auflösung:** IR18 liefert trotz `multiply: 0.1` nur ganze Kelvin; alle
> Rohwerte sind Vielfache von 10. Wertebereich im Fenster 33–78 °C.

### IR20 ist eine Drehzahl, keine Leistungsskala

Die alte Zeile hielt 45–54 W Wirkleistung je Einheit für konstant. Das gilt nur
im Kühlbetrieb:

| Betriebsart | IR20 | Wirkleistung | W je Einheit | Druckverhältnis |
|---|---|---|---|---|
| Kühlen | 15 | 660 W | 44,0 | 1,75 |
| Kühlen | 30 | 1351 W | 45,0 | 1,99 |
| Kühlen | 42 | 2070 W | 49,3 | 2,28 |
| Kühlen | 60 | 3013 W | 50,2 | 2,29 |
| **Warmwasser** | **20** | **1690 W** | **84,5** | 3,07 |
| Warmwasser | 36 | 2267 W | 63,0 | 2,92 |

Der tragende Vergleich braucht keine Rechnung: **IR20 = 20 zieht bei
Warmwasser 1690 W, IR20 = 30 im Kühlen nur 1351 W.** Der niedrigere Wert steht
für die höhere Leistung — eine Leistungs- oder Kapazitätsskala kann das nicht.

Konsistent damit, aber schwächer als es aussieht, der Fit über 1072 stabile
Minuten: `W / IR20 = 25,5 · Druckverhältnis + 0,6` bei r = 0,932, also
**Leistung ∝ IR20 × Druckverhältnis** — Massenstrom mal spezifische
Verdichtungsarbeit, die Signatur einer Drehzahl. Das r ruht allerdings weit
überwiegend auf zwei Druckverhältnis-Clustern (n = 590 um 1,75, n = 166 über
3,0); der Achsenabschnitt nahe null ist Beiwerk, kein Beweis.

Der Wertebereich ist 15–60. Dass 15 und 60 typische Eckfrequenzen eines
Inverterverdichters sind, macht Hertz naheliegend, belegt es aber nicht. Was
die alte Zeile schon sagte, bleibt: **kein Expansionsventil** — der Wert stand
26 Minuten konstant, während die Sauggasüberhitzung von 0,6 auf 6,3 K wanderte.

## Unbelegt, aber eingegrenzt

| Punkt | Stand |
|---|---|
| IR14 | Eine Wassertemperatur, aber weder Vorlauf noch Rücklauf — siehe unten. Nicht der Heizstab (151 bei Bedienteil 174–181) |
| IR09 | Konstant 19 über 24 h — ein Kennwert, kein Messwert |
| IR13 | Konstant 12000; das Bedienteil zeigt denselben Rohwert unter „Kältemittel" |
| IR27 | Antwortet, konstant 0. Nicht mehr nur im Stillstand: über die 8622 Minuten vom 02.–08.08.2026 einschließlich Volllast (3013 W) und 19 Warmwasserladungen keine einzige Änderung |
| **IR10 = DI32** | Derselbe Zustand auf zwei Registertypen, siehe unten. Bisher nur mit den Werten 0 und 14 aufgetreten. Im Fenster 02.–08.08.2026 **gar nicht** aufgetreten — passend zur Eingrenzung „nur bei HR26 = 0", denn HR26 stand dort durchgehend auf 3 |
| HR25, HR27, HR28 | Antworten, konstant 0 — wie IR27 auch über die 8622 Minuten unter Last |
| DI06 | Bedeutung offen, aber weiter eingegrenzt. **Im Kühlbetrieb kommt es nicht vor:** über 3268 Minuten vom 30.07. bis 01.08.2026 keine Flanke. **In der Warmwasserladung auch nicht:** 682 Minuten vom 02.–08.08.2026, kältemittelseitig Heizbetrieb, ebenfalls keine Flanke. Damit sind Kreisrichtung, Umschaltventil und Warmwasser ausgeschlossen; was bleibt, kommt nur im Raumheizbetrieb vor — die frühere Notiz „wechselt" stammt von dort |
| CO5 | Antwortet. Bedeutung offen, siehe Warnung unten |
| DI32 | Antwortet, erst durch Einzelabfrage gefunden. Bedeutung offen — und identisch mit IR10, siehe die Zeile dort |
| CO29, CO30 | Antworten, liegen weit außerhalb des gescannten Bereichs. Über 3268 Minuten der ersten Messreihe und weitere 8622 Minuten im August konstant `off`, Bedeutung offen. **Nur lesend eingebunden**, aus demselben Grund wie CO5 |
| CO4 | Antwortet, erst durch Einzelabfrage gefunden. **Nur lesend eingebunden** — in LGs offizieller Karte liegt hier Notaus/Notbetrieb |

### IR14 ist Wasser, aber weder Vorlauf noch Rücklauf

Die frühere Einordnung stützte sich auf Korrelationen aus einem Fenster, in dem
die Anlage überwiegend stand — dort folgen alle Temperaturen gemeinsam der
Außenluft, und jede korreliert mit jeder. Das trennt nichts.

**Der Verdichterstopp trennt.** Beim Taktende gleicht sich der Druck in Sekunden
aus und die Kondensationstemperatur bricht ein, während das Wasser seine Masse
behält. Über alle 23 Stopps vom 31.07. bis 01.08.2026, gemessen als Änderung in
den vier Minuten danach: **16-mal folgte IR14 dem Wasser, kein einziges Mal dem
Kältemittel**; sieben Stopps waren unbrauchbar, weil Kondensation und Vorlauf zu
nah beieinander lagen. Deutlichster Fall am 31.07. 20:55:31 — Kondensation
−16,1 K, Vorlauf +5,1 K, IR14 ±0,0 K.

Damit ist „Wassertemperatur" belegt statt korreliert. Zwei Dinge ändern sich:

**Der Bereich reicht bis 67,3 °C, nicht bis 26,0 °C.** Die alte Obergrenze stammt
aus einem Fenster ohne Warmwasserladung.

**Es ist ein dritter Punkt zwischen Vorlauf und Rücklauf.** Das Vorzeichen dreht
mit der Betriebsart, und zwar jedes Mal in Richtung des Rücklaufs:

| Lage | IR14 − Vorlauf (Median) | wärmer | kälter |
|---|---|---|---|
| Kühlen, Verdichter läuft, kein Warmwasser (277 min) | **+2,4 K** | 190 | 72 |
| Warmwasserladung (193 min) | **−1,5 K** | 5 | 172 |
| Stillstand (1259 min) | +0,7 K | 851 | 102 |

Beim Kühlen ist der Rücklauf der wärmere, bei Warmwasser der kältere — IR14 liegt
beide Male dazwischen. Auf den 274 Minuten mit über 4 K Spreizung: 1,9 K zum
Vorlauf, 4,2 K zum Rücklauf. Für „ist der Mittelwert der beiden" reicht es nicht;
der träfe mit 1,7 K nicht wesentlich besser.

**Und es ist unruhiger als beide.** Änderung je Minute im Kühlbetrieb, 90.
Perzentil: IR14 **6,2 K**, Vorlauf 1,4 K, Rücklauf 0,6 K. So verhält sich ein
Fühler an einer Stelle mit wechselnder Durchströmung, nicht einer im
durchströmten Hauptkreis.

Das Fenster vom August bestätigt beides auf der fünffachen Datenmenge, mit
einer Abschwächung im Kühlbetrieb:

| Lage | IR14 − Vorlauf | IR14 − Rücklauf |
|---|---|---|
| Kühlen, Verdichter (1672 min) | +0,4 K *(statt +2,4)* | −2,8 K |
| Warmwasserladung (622 min) | −1,7 K | +3,6 K |
| Stillstand (6326 min) | +0,4 K | +0,4 K |

Die Richtung stimmt weiter — IR14 liegt in beiden Betriebsarten zwischen den
Fühlern und rückt zum Rücklauf hin —, im Kühlen aber deutlich näher am Vorlauf
als in der ersten Messreihe. Unruhe und Bereich bestätigen sich: 5,0 K je
Minute gegen 1,3 K am Vorlauf und 0,4 K am Rücklauf, Wertebereich 8,1–68,3 °C.

### IR10 und DI32 sind derselbe Zustand

Beide standen getrennt als unbelegt in der Liste. Über 3264 gemeinsame Minuten
vom 30.07. bis 01.08.2026:

```
IR10 \ DI32      off      on
   0            3183       0
  14               1      81
```

Die eine abweichende Minute ist Sampling: In Sekundenauflösung liegen die vier
Flankenpaare 1–25 s auseinander, bei 20 s Abfragetakt. Am 01.08. 14:04:03 ging
DI32 an, fünf Sekunden später sprang IR10 auf 14; um 14:25:16 fiel IR10 zurück,
19 Sekunden später DI32.

**Das ist kein Spiegelregister wie IR11/IR19.** Die sind über einen ganzen
Wertebereich byte-identisch; IR10 ist bisher nur mit zwei Werten aufgetreten.
Belegt ist die Gleichzeitigkeit, nicht die Wertegleichheit. Der Nutzen ist
trotzdem konkret: zwei offene Punkte sind einer, und was den einen erklärt,
erklärt den anderen.

**Was der Zustand bedeutet, bleibt offen** — aber er ist eingegrenzt. Er trat in
2,3 Tagen zweimal auf, 59 und 21 Minuten lang, immer nur bei HR26 = 0, CO4 aus,
DI31 an und unter 15 W Wirkleistung, und begann jeweils 1–6 s nach DI31.

**„Anlage aus" ist er nicht.** Am 30.07. 22:25 lief eine 456 Minuten lange
Abschaltung mit genau derselben Registerlage durch, ohne dass IR10 oder DI32
anzogen. Der einzige erkennbare Unterschied: dort wurde aus dem laufenden
Verdichterbetrieb abgeschaltet (1215 W in der Minute davor), in den beiden
anderen Fällen aus dem reinen Pumpenbetrieb (96 W). Zwei Fälle gegen einen tragen
das nicht.

### DI08 ist eine hohe Stufe, nicht das Anlaufen

Naheliegend war, DI08 als Anlauf mit voller Leistung zu lesen — der Verdichter
fährt zu Taktbeginn hoch und regelt zurück. Über die 23 Takte vom 31.07. 11:50
bis 01.08. 15:50 hält das nicht:

| Taktbeginn | Taktdauer | DI08 ab Minute | IR20 beim Einschalten | IR20 beim Ausschalten |
|---|---|---|---|---|
| 31.07. 13:28 | 27 min | 2 | 42 | 30 |
| 31.07. 14:46 | 5 min | 2 | 42 | (Taktende) |
| 31.07. 17:02 | 12 min | **9** | 42 | 0 |
| 31.07. 20:41 | 15 min | **14** | 42 | (Taktende) |
| 31.07. 21:40 | 74 min | **60** | 42 | (Taktende) |
| 01.08. 15:24 | 16 min | 3 | 60 | 52 |

In drei von sechs Fällen kommt DI08 in den ersten drei Minuten — daher der
Eindruck. In den anderen dreien nach 9, 14 und 60 Minuten.

Die Wirkleistung trennt schlechter als die Anforderung: DI08 an hat ein Minimum
von 1779 W, DI08 aus erreicht im selben Fenster 2535 W. Die Stufe hängt an dem,
was angefordert wird, nicht an dem, was ankommt.

#### Es ist nicht das Takt-Maximum, sondern eine feste Schwelle

Aus demselben Fenster stammte die Regel „DI08 zieht in der Minute an, in der
IR20 seinen Höchstwert des Takts erreicht". Die 63 Takte vom 02.–08.08.2026
tragen sie nicht:

| IR20-Höchstwert des Takts | Takte | davon mit DI08 |
|---|---|---|
| ≤ 34 | 15 | **0** |
| 35–41 | 17 | **0** |
| 42–49 | 11 | 6 |
| 50–60 | 20 | 19 |

**32 Takte erreichen ihren Höchstwert, ohne dass DI08 ein einziges Mal
anzieht** — alle unter 42. Im alten Fenster fiel „Höchstwert des Takts" mit
„≥ 42" zusammen, weil es dort nur Takte mit 42 und 60 gab; erst die niedrigen
Takte trennen die beiden Regeln.

Hinreichend ist die Schwelle nicht: vier Takte mit einem Höchstwert von 42
bzw. 52 bleiben stumm. **Notwendig ist sie auf Taktebene ausnahmslos.**

Auf Zyklusebene gilt sie nicht — und das ist die eigentliche Spur. Von den 30
Anziehvorgängen kommen vier bei gleichzeitigem IR20 = 35…37, darunter die
beiden längsten Phasen (600 s und 1320 s). Am 03.08. 19:33:43 zieht DI08 bei
IR20 = 35 an, **und IR20 erreicht 42 erst danach.** DI08 läuft der Anforderung
dort voraus. Der Versuch, DI08 als nachlaufenden Melder zu lesen, scheitert
entsprechend: weder die Wirkleistung noch die aus W/Druckverhältnis geschätzte
Ist-Frequenz erkennt mehr als ein Drittel der Impulse.

#### Die zweite Bedingung gibt es nicht: DI08 ist IR20 = 60

Das zweite Augustfenster (07.–16.08.2026, siehe unten) löst beides auf. Über
seine 56 Takte trennt der Höchstwert von IR20 vollständig:

| | Takte | IR20max min | IR20max max |
|---|---|---|---|
| mit DI08 | 22 | **60** | **60** |
| ohne DI08 | 34 | 0 | **55** |

**Jeder Takt mit DI08 erreicht 60, kein Takt ohne DI08 kommt über 55** — und
darunter liegen Takte mit 55, 55, 52, 51, 49, 47, 47, 45 und 44, also genau die
Fälle, die die alte Schwelle „≥ 42" hätten auslösen müssen.

Die Gegenprobe auf Impulsebene macht es endgültig. Im Fenster liegen **27
Phasen mit IR20 ≥ 60 und 27 DI08-Impulse**:

- keine einzige IR20-60-Phase ohne DI08-Impuls,
- kein einziger DI08-Impuls ohne IR20-60-Phase,
- der Versatz beträgt **ausschließlich −14 s oder +16 s**, nie etwas dazwischen,
- in 21 der 27 Paare ist die Dauer beider Phasen gleich (±1 Zyklus).

Die beiden Versatzwerte sind die Erklärung für alles, was vorher wie ein
Vorlauf aussah: −14 und +16 ergeben zusammen die 30 s des Abfragezyklus. DI08
und IR20 werden **14 s auseinander im selben Zyklus** gelesen. Fällt die Flanke
zwischen die beiden Lesungen, meldet DI08 sie 14 s früher; fällt sie davor,
holt DI08 sie erst im nächsten Zyklus nach, 16 s später. Am 11.08. 11:29:18
zieht DI08 bei gelesenem IR20 = 41 an, und 14 s später steht IR20 auf 60 — das
ist derselbe Zyklus, nicht ein Vorlauf. Der Fall vom 03.08. 19:33:43 („DI08 bei
IR20 = 35, 42 erst danach") ist mit hoher Wahrscheinlichkeit dasselbe Artefakt;
nachrechnen lässt er sich nicht mehr, seine Rohwerte sind aus dem Recorder
gefallen.

Damit ist auch die offene Frage aus der Überschrift beantwortet — und die
Obergrenze ist gemessen, nicht angenommen. Über die 859 IR20-Werte des Fensters
steht das Maximum auf **exakt 60**, und die Verteilung stapelt sich dort:
einmal 59, zweimal 58, achtmal 55 — aber **27-mal 60**. So sieht ein Anschlag
aus, nicht ein Ausläufer. **DI08 ist die höchste Stufe.**

Praktisch folgt daraus, dass **DI08 nichts trägt, was nicht schon in IR20
steht.** Der Melder ist redundant. Er bleibt eingebunden, weil er als eigener
Registertyp die Lesart von IR20 unabhängig bestätigt — als Informationsquelle
ist er verzichtbar.

> **Der Datenpunkt heißt trotzdem weiter „Verdichter hohe Stufe".** Eine
> Umbenennung ändert die Entity-ID und schneidet die Historie ab — dieselbe
> Abwägung wie bei IR20, wo der überholte Name „Verdichterleistung
> Anforderung" aus genau diesem Grund stehen bleibt.

> **Auf 30-s-Zyklen achten, wer das nachrechnet.** Die Hälfte der 30
> Anziehvorgänge dauert genau einen Zyklus. Eine Auswertung auf Minutenraster
> verschluckt sie und zählt die betroffenen Takte fälschlich als „DI08 nie an" —
> die Tabelle oben entstand deshalb aus den Rohwerten, nicht aus dem Raster.

> **CO3 und DI08 haben ein kürzeres Fenster als der Rest.** Beide wurden am
> 31.07.2026 umbenannt, ihre Historie davor liegt in Home Assistant unter den
> alten Entity-IDs. Alle Aussagen zu Takten und zu DI08 stützen sich deshalb auf
> 28 Stunden, nicht auf die 2,3 Tage der übrigen Punkte.

## Gar nicht abgebildet

Je einzeln am Bedienteil geprüft und im Registerraum nicht gefunden:
Heizkreis 2 in jeder Form, Kreis-2-Pumpe, 3-Wege-Ventil als Zustand,
Mischkreis, Wasserdruck, **Wasserdurchfluss**, Heizstabbetrieb.

Betriebsmodus als Stellgröße und Flüstermodus galten hier lange als nicht
abgebildet — die Bedienteilmessung im Juli 2026 hat beide widerlegt: der
Betriebsmodus ist schreibbar (HR26), der Flüstermodus schaltbar (CO2), beide
in der Tabelle oben belegt.

Konfiguration am Bedienteil ist über Modbus unsichtbar; nur physikalische
Größen und die Haupt-Sollwerte spiegeln sich. Dass der Durchfluss fehlt, ist
der Grund, warum sich **kein COP** berechnen lässt — ohne Volumenstrom keine
thermische Leistung.

## Warum unbelegte Punkte keine Zustandsklasse tragen

Alle gedeuteten Sensoren haben eine `state_class` und laufen damit in die
Langzeitstatistik von Home Assistant. Die noch unbelegten haben bewusst
**keine**: IR09, IR10, IR27, HR25, HR27, HR28, der Betriebsmodus-Rohwert, der
Kältemittel-Kennwert und die beiden Beobachtungs-Sensoren.

Der Grund steht einen Abschnitt weiter unten: Eine Zeitreihe über mehrere
Fassungen der Registerliste ist kein Datensatz — die Blockbildung von ESPHome
ändert sich mit jeder Änderung, und damit auch die Artefakte. Eine
Langzeitstatistik auf einem Punkt, dessen Bedeutung offen ist, lädt genau zu
dieser Auswertung ein: Monate schöner Kurven, die verschiedene Regime mischen.

Wer einen Punkt deutet, gibt ihm dabei seine Zustandsklasse — und hat dann
bewusst entschieden, ab wann die Historie gilt.

IR11, IR19, IR18 und IR20 tragen ihre Zustandsklasse seit jeher, weil sie als
Messwerte eingebunden waren, bevor ihre Bedeutung feststand. Mit den Belegen
oben ist das nachträglich richtig geworden — ihre Historie mischt aber
Generationen, und für IR11 ist genau das dokumentiert (Fallstrick 1).
Auswertbar ist sie ab dem Flash vom 02.08.2026 18:24.

## Zwei Fallstricke, die echte Fehldeutungen erzeugt haben

### 1. Fehlendes `force_new_range` verschiebt Werte zwischen Nachbarregistern

ESPHome fasst benachbarte Register zu einer Blockanfrage zusammen, und die
Gruppierung ändert sich mit **jeder** Änderung der Registerliste. Anteil
physikalisch unmöglicher Werte bei IR11 je Firmware-Generation eines einzigen
Tages:

| Generation | Werte > 120 °C |
|---|---|
| 1 | 0 % |
| 2 | 0 % |
| 3 | **100 %** |
| 4 | **100 %** |
| 5 | **100 %** |
| 6 | 8,9 % |
| 7 (mit `force_new_range`) | 0 % |

Die Sprünge liegen exakt auf den Generationsgrenzen, nicht auf
Betriebszuständen. Genau in einer der verfälschten Generationen entstand die
Fehlzuordnung „IR11 = Heißgastemperatur" durch einen Ablesevergleich am
Bedienteil. **Deshalb steht `force_new_range: true` an jedem Register** — eine
Einzelanfrage je Punkt kostet Buslast, aber sie kann nicht mehr verrutschen.

### 2. Eine Zeitreihe über mehrere Firmware-Generationen ist kein Datensatz

Wer die Registerliste ändert, ändert die Blockbildung. Auswertungen müssen auf
eine Generation begrenzt werden, sonst mischen sie Regime mit verschiedenen
Artefakten — und die Korrelationen sehen überzeugend aus, während sie nichts
bedeuten.

## Warnung zu Coil 5

Coil 5 antwortet. Ein Schreibversuch blieb ohne erkennbare Wirkung — aber es
ist nicht festgehalten, **was der Bus dabei antwortete**. Das ist der
entscheidende Unterschied:

- Exception → nicht schreibbar, Thema durch
- Quittung, Rücklesen sofort 0 → das Gerät verwirft den Wert
- Quittung, Rücklesen bleibt 1, keine Wirkung → richtiges Bit, fehlende
  Vorbedingung

**Rücklesen 0 beweist nichts.** Genau so verhält sich ein flankengetriggertes
Bit, das seine Aktion ausführt und sich selbst zurücksetzt. Auf benachbarten
Positionen liegen in der offiziellen LG-Karte Notaus, Notbetrieb und der
Desinfektionszyklus (heizt den Speicher stundenlang auf rund 70 °C). Das ist
eine Analogie aus einer Karte, die dieses Gerät nicht spricht, also kein Beleg —
aber Grund genug, erst passiv zu identifizieren. Dafür sind die
Registerbeobachtung und der Referenzzustand-Vergleich in der Firmware.
