# Registerkarte

Gemessen an einer **LG Therma V R290 Monobloc, Hydro Unit HN1639HC.NK0**,
Modbus RTU über Klemme 21/22, Slave 1, 9600 Baud.

## Die veröffentlichten Karten passen hier nicht

Weder das allgemeine Therma-V-Handbuch (S. 262–264) noch das Modellhandbuch
(S. 181–182) noch die LG-Folie „Open MODBUS" noch das basti242-Wiki treffen auf
dieses Gerät zu — **auch nicht mit Versatz**. Ein Scan über alle 65536 Adressen
je Registertyp fand **32 antwortende Punkte**; zwei weitere kamen später durch
**Einzelabfrage** hinzu — insgesamt **34**. Alles andere liefert Exception 2
(illegal data address):

| Typ | Adressen | Anzahl |
|---|---|---|
| Input Register (FC 4) | 9–27 | 19 |
| Holding Register (FC 3) | 24–29 | 6 |
| Discrete Input (FC 2) | 6, 7, 8, 9, 31, **32** | 6 |
| Coil (FC 1) | **4**, 5, 6 | 3 |

> **DI32 und CO4 hat der Tiefenscan übersehen** — und der Grund ist derselbe
> Blockmechanismus wie bei `force_new_range`, nur in der Suchrichtung. Der Scan
> fragte in Vierergruppen ab; enthält eine Gruppe ein nicht existierendes
> Register, lehnt das Gerät die **ganze Gruppe** mit Exception 2 ab, und die
> vorhandenen Nachbarn verschwinden mit. Einzelabfragen finden, was
> Gruppenabfragen verstecken.
>
> Wer nachbaut, sollte deshalb den Button **„Breiter Registerscan"** einmal
> laufen lassen: er prüft die Adressen 0–63 in allen vier Registertypen
> einzeln. Möglich, dass hier noch mehr liegt.

Die offizielle Karte passt auch hier nur teilweise: Coil 0 (Ein/Aus), Holding 0
(Betriebsmodus) und Holding 9 (Energiezustand/SG-Ready) sind auf diesem Gerät
**nicht erreichbar** — der Betriebsmodus liegt stattdessen schreibbar auf HR26
(dazu unten mehr). Coil 2 dagegen trägt hier wie in der offiziellen Karte den
**Flüstermodus** und ist schaltbar (CO2 in der Tabelle unten).

## Belegte Zuordnungen

| Punkt | Bedeutung | Skalierung | Grundlage |
|---|---|---|---|
| IR12 | Außentemperatur | ×0,1 | 305 bei 30 °C am Bedienteil |
| IR15 | Wasser-Rücklauf | ×0,1 | Vorlauf > Rücklauf im Heizbetrieb, umgekehrt im Kühlbetrieb |
| IR16 | Wasser-Vorlauf | ×0,1 | dito |
| IR17 | **Sauggastemperatur** | ×0,1 | ergibt gegen die Sättigungstemperatur aus IR22 durchgehend 5–8 K Überhitzung; wird negativ, was für Sauggas normal ist |
| IR21 | **Hochdruck** | ×0,01 bar (Überdruck) | über eine Warmwasserladung deckt sich die Propan-Sättigungstemperatur mit dem Vorlauf auf unter 1,5 K, über sieben Punkte monoton mitlaufend |
| IR22 | **Niederdruck** | ×0,01 bar | im Stillstand praktisch gleich IR21 (Druckausgleich), im Betrieb weit darunter |
| IR23 | **Scheinleistung** | VA | siehe unten |
| IR24 | Raumtemperatur | ×0,1 | 205 bei „innen 20,5" |
| IR25 | Warmwassertemperatur | ×0,1 | 506 bei 50,6 °C am Bedienteil |
| IR26 | **Wärmeanforderung:** 0 = keine, 1 = bereit, 2 = angefordert | — | fiel beim Abschalten der Warmwasser-Freigabe von 2 auf 0, während HR26 stehenblieb — siehe unten |
| HR24 | Soll Heizkreis 1, **schreibbar** | ×0,1 | 21 °C Kühlen → 55 °C Heizen; folgt der Anlage bei jedem Moduswechsel |
| **HR26** | **Betriebsmodus, schreibbar:** 0 = Aus / nur Warmwasser, 1 = Kühlen, 2 = Heizen, 3 = Auto | — | am Bedienteil geschaltet, alle vier Werte sekundengenau belegt — siehe unten |
| HR29 | Soll Warmwasser, **schreibbar** | ×0,1 | 480 bei „Warmwasser 48° eco", Änderung live gefolgt |
| **CO2** | **Flüstermodus, schaltbar** | — | vier Wechsel sekundengenau zur Bedienung am Bedienteil, kein anderer Punkt ging mit |
| CO4 | Heizkreis 1 aktiv | — | ging an/aus zeitgleich mit Heizkreis 1, zwei Wechsel; nur lesend eingebunden |
| CO6 | Warmwasser-Freigabe, **schaltbar** | — | schaltet die Warmwasserbereitung nachweislich |
| DI31 | Heizkreis 1, invertiert zu CO4 | — | on wenn HK1 aus, off wenn HK1 läuft |

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
sichtbar und folgt der Anlage aktiv (21 °C im Kühlen, 55 °C im Heizen). Seine
**Bedeutung** wechselt mit dem Modus: im Heizen ein Vorlauf-Soll, im Kühlen ein
Raum-Soll.

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
| IR14 | Eine Wassertemperatur: r = +0,87 zum Vorlauf, +0,82 zum Rücklauf, Bereich 9,4–26,0 °C. Nicht der Heizstab (151 bei Bedienteil 174–181) |
| IR18 | Liegt über neun Stunden Stillstand konstant 10–15 K über der Außenluft und sinkt mit ihr. Eine Verdichterfrequenz wäre dort 0. Passt zu Verdichtergehäuse (Kurbelwannenheizung) oder Leistungsmodul-Kühlkörper |
| IR09 | Konstant 19 über 24 h — ein Kennwert, kein Messwert |
| IR13 | Konstant 12000; das Bedienteil zeigt denselben Rohwert unter „Kältemittel" |
| IR10, IR20, IR27 | Antworten, stehen im Stillstand auf 0 |
| HR25, HR27, HR28 | Antworten, konstant 0 über 24 h |
| DI06, DI08, DI31 | Wechseln, Bedeutung offen |
| DI07 | **Nicht** die Hauptpumpe: stand auf AUS, während das Display „Umwälzpumpe in Betrieb" meldete |
| DI09 | Als Warmwasser-Flag unbestätigt — während einer eindeutigen Ladung lieferte der Punkt keinen Wert |
| CO5 | Antwortet. Bedeutung offen, siehe Warnung unten |
| DI32 | Antwortet, erst durch Einzelabfrage gefunden. Bedeutung offen |
| CO4 | Antwortet, erst durch Einzelabfrage gefunden. **Nur lesend eingebunden** — in LGs offizieller Karte liegt hier Notaus/Notbetrieb |

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
Bedienteil. **Deshalb steht `force_new_range: true` an jedem Register** — 34
Einzelanfragen kosten Buslast, aber sie können nicht mehr verrutschen.

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
