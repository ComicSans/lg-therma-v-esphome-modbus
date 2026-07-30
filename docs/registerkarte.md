# Registerkarte

Gemessen an einer **LG Therma V R290 Monobloc, Hydro Unit HN1639HC.NK0**,
Modbus RTU über Klemme 21/22, Slave 1, 9600 Baud.

## Die veröffentlichten Karten passen hier nicht

Weder das allgemeine Therma-V-Handbuch (S. 262–264) noch das Modellhandbuch
(S. 181–182) noch die LG-Folie „Open MODBUS" noch das basti242-Wiki treffen auf
dieses Gerät zu — **auch nicht mit Versatz**. Ein vollständiger Scan über alle
65536 Adressen je Registertyp fand genau **32 antwortende Punkte**, alles andere
liefert Exception 2 (illegal data address):

| Typ | Adressen | Anzahl |
|---|---|---|
| Input Register (FC 4) | 9–27 | 19 |
| Holding Register (FC 3) | 24–29 | 6 |
| Discrete Input (FC 2) | 6, 7, 8, 9, 31 | 5 |
| Coil (FC 1) | 5, 6 | 2 |

Die offizielle Karte mit Coil 0 (Ein/Aus), Coil 2 (Flüstermodus), Holding 0
(Betriebsmodus) und Holding 9 (Energiezustand/SG-Ready) ist auf diesem Gerät
**nicht erreichbar** — dazu unten mehr.

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
| IR26 | Betriebsmodus: 0 = Standby, 1 = Auto, 2 = Heizen/Warmwasser | — | nur vier Wechsel in 24 h; Wert für fest eingestelltes Kühlen noch ungemessen |
| HR24 | Soll Heizkreis 1, **schreibbar** | ×0,1 | 21 °C Kühlen → 55 °C Heizen |
| HR26 | Regelungsart: 0 = Vorlauf, 1 = Rücklauf, 2 = Raum | — | folgt selbst dem Betriebsmodus |
| HR29 | Soll Warmwasser, **schreibbar** | ×0,1 | 480 bei „Warmwasser 48° eco", Änderung live gefolgt |
| CO6 | Warmwasser-Freigabe, **schaltbar** | — | schaltet die Warmwasserbereitung nachweislich |

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

## Gar nicht abgebildet

Je einzeln am Bedienteil geprüft und im Registerraum nicht gefunden:
Betriebsmodus Heizen/Kühlen/Auto als **Stellgröße**, Heizkreis 2 in jeder Form,
Flüstermodus, Kreis-2-Pumpe, 3-Wege-Ventil als Zustand, Mischkreis,
Wasserdruck, **Wasserdurchfluss**, Heizstabbetrieb.

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
Bedienteil. **Deshalb steht `force_new_range: true` an jedem Register** — 32
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
