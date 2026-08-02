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
| IR21 | **Hochdruck** | ×0,01 bar (Überdruck) | über eine Warmwasserladung deckt sich die Propan-Sättigungstemperatur mit dem Vorlauf auf unter 1,5 K, über sieben Punkte monoton mitlaufend |
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
| **DI07** | **Drei-Minuten-Wiederanlaufsperre** | — | ruht auf `on` und fällt nach jedem Betriebsende ab, dreizehnmal exakt 3:00 min gemessen |
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

## Unbelegt, aber eingegrenzt

| Punkt | Stand |
|---|---|
| IR11 + IR19 | Zu 99,7 % byte-identisch, ein Register wird also gespiegelt. Folgen der Außenluft mit thermischem Nachlauf. **Nicht** die Heißgastemperatur, siehe Fallstrick unten |
| IR14 | Eine Wassertemperatur, aber weder Vorlauf noch Rücklauf — siehe unten. Nicht der Heizstab (151 bei Bedienteil 174–181) |
| IR18 | Liegt über neun Stunden Stillstand konstant 10–15 K über der Außenluft und sinkt mit ihr. Eine Verdichterfrequenz wäre dort 0. Passt zu Verdichtergehäuse (Kurbelwannenheizung) oder Leistungsmodul-Kühlkörper |
| IR09 | Konstant 19 über 24 h — ein Kennwert, kein Messwert |
| IR13 | Konstant 12000; das Bedienteil zeigt denselben Rohwert unter „Kältemittel" |
| IR27 | Antwortet, steht im Stillstand auf 0 |
| **IR10 = DI32** | Derselbe Zustand auf zwei Registertypen, siehe unten. Bisher nur mit den Werten 0 und 14 aufgetreten |
| IR20 | **Folgt der Verdichterleistung** — Frequenz oder Kapazitätsanforderung, Einheit offen. Konstant sind 45–54 W Wirkleistung je Einheit über einen wechselnden Druckhub (15↔675 W, 20↔965, 30↔1354, 34↔1734, 42↔2074). Am 01.08.2026 kam **60↔2882 W** dazu: die Skala reicht weiter als 42. Kein Expansionsventil: der Wert stand 26 Minuten konstant, während die Sauggasüberhitzung von 0,6 auf 6,3 K wanderte, und über einen ganzen Takt ist die Überhitzung unkorreliert |
| HR25, HR27, HR28 | Antworten, konstant 0 über 24 h |
| DI06 | Bedeutung offen. **Im Kühlbetrieb kommt es nicht vor:** über 3268 Minuten vom 30.07. bis 01.08.2026 keine einzige Flanke, durchgehend `off`. Die frühere Notiz „wechselt" stammt aus dem Heizbetrieb |
| DI08 | **Volllastanforderung des Verdichters** — siehe unten. Nicht das Anlaufen, und nicht belegbar die *höchste* Stufe. Deshalb hier und nicht in der Tabelle oben, und deshalb heißt der Datenpunkt seit dem 31.07.2026 „Verdichter hohe Stufe" statt „Verdichter Volllast" |
| CO5 | Antwortet. Bedeutung offen, siehe Warnung unten |
| DI32 | Antwortet, erst durch Einzelabfrage gefunden. Bedeutung offen — und identisch mit IR10, siehe die Zeile dort |
| CO29, CO30 | Antworten, liegen weit außerhalb des gescannten Bereichs. Über 3268 Minuten konstant `off`, Bedeutung offen. **Nur lesend eingebunden**, aus demselben Grund wie CO5 |
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

### DI08 ist die Volllastanforderung, nicht das Anlaufen

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

Was in allen sechs Fällen gilt: **DI08 zieht in der Minute an, in der IR20 seinen
Höchstwert des Takts erreicht, und fällt, wenn IR20 zurückgeht.** In diesem
Fenster gibt es keinen Takt mit IR20 ≥ 42 und DI08 aus, bis auf eine Minute
Abtastversatz am 31.07. 22:39.

Die Wirkleistung trennt schlechter als die Anforderung: DI08 an hat ein Minimum
von 1779 W, DI08 aus erreicht im selben Fenster 2535 W. Die Stufe hängt an dem,
was angefordert wird, nicht an dem, was ankommt.

Dass es die *höchste* Stufe ist, bleibt unbelegt — und der neue IR20-Höchstwert
schwächt es weiter ab: DI08 war bei IR20 = 60 an, fiel aber schon beim Rückgang
auf 52 wieder ab.

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
