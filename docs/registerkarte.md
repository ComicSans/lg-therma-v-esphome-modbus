# Registerkarte

Gemessen an einer **LG Therma V R290 Monobloc, Hydro Unit HN1639HC.NK0,
Geräte-Firmware 3.07.2a**, Modbus RTU über Klemme 21/22, Slave 1, 9600 Baud.
Modell und Firmwarestand sind die beiden Größen, an denen sich die Belegung
ändern kann; hier liegt nur ein Stand vor.

**Generation** meint in dieser Karte eine Fassung der ESPHome-Registerliste,
nicht den Firmwarestand des Geräts. Mit jeder Generation ändert sich die
Blockbildung (siehe [Fallstricke](#fallstricke-bei-der-auswertung)).

## Registerraum

Keine veröffentlichte Karte passt, auch nicht mit Versatz: weder das
Therma-V-Handbuch (S. 262–264) noch das Modellhandbuch (S. 181–182), die
LG-Folie „Open MODBUS" oder das basti242-Wiki. Alles außer den folgenden
**38 Punkten** liefert Exception 2 (illegal data address):

| Typ | Adressen | Anzahl |
|---|---|---|
| Input Register (FC 4) | 9–27 | 19 |
| Holding Register (FC 3) | 24–29 | 6 |
| Discrete Input (FC 2) | 6, 7, 8, 9, 31, 32 | 6 |
| Coil (FC 1) | 2, 3, 4, 5, 6, 29, 30 | 7 |

Aus der offiziellen Karte trifft CO2 (Flüstermodus) zu. Coil 0 (Ein/Aus),
Holding 0 (Betriebsmodus) und Holding 9 (Energiezustand/SG-Ready) sind nicht
erreichbar; der Betriebsmodus liegt auf HR26.

**Gruppenscans übersehen Register.** Der erste Scan über alle 65536 Adressen je
Typ fragte in Vierergruppen ab und fand 32 Punkte. Enthält eine Gruppe ein
fehlendes Register, lehnt das Gerät die ganze Gruppe ab. Von den sieben Coils
meldete er nur CO5 und CO6. DI32, CO2, CO3, CO4, CO29 und CO30 kamen erst durch
Einzelabfrage hinzu („Randbereiche prüfen", „Breiter Registerscan").

**Adressen 0–1023 sind einzeln geprüft**, in allen vier Typen (4096 Abfragen,
30.07. und 01.08.2026). Ab Adresse 64 gab es keinen Treffer; alle 38 Punkte
liegen unter 32. Ab 1024 liegt nur der Gruppenscan vor. Einzeln nachzuprüfen
hieße bei 8 Anfragen je 15 s rund 136 Stunden Dauerlast.

Ein breiter Scan hebt die Zyklusdauer von 19,5 auf 30–35 s. Die Firmware
pausiert ihn ab 70 % der eingestellten Bus-Lücken-Grenze. Über fünfzehn Läufe:
kein Punkt ohne Antwort, kein verpasster Zyklus. Eine zusätzliche eigene
30-s-Schwelle brach einen gesunden Lauf nach 112 von 256 Anfragen ab.

## Belegte Zuordnungen

| Punkt | Bedeutung | Skalierung | Beleg |
|---|---|---|---|
| IR11 = IR19 | **Außenwärmetauscher** (Kondensator im Kühlen, Verdampfer im Heizen) | ×0,1 | liegt je Betriebsrichtung auf der passenden Sättigungstemperatur, [siehe unten](#ir11-und-ir19-außenwärmetauscher) |
| IR12 | Außentemperatur **des Geräts** | ×0,1 | 305 bei 30 °C am Bedienteil. Fühler im besonnten Gehäuse: gegen drei unabhängige Sensoren nachts im Stillstand ±0 K, tagsüber im Stillstand +7,9 K (max. +12,9 K), mit Ventilator +3,9 K. Beim Ventilatorstart −8 K, während alle drei Sensoren stiegen |
| IR15 | Wasser-Rücklauf | ×0,1 | Vorlauf > Rücklauf im Heizen, umgekehrt im Kühlen |
| IR16 | Wasser-Vorlauf | ×0,1 | dito |
| IR17 | Sauggastemperatur | ×0,1 | Überhitzung gegen IR22: Stillstand 5–8 K, Verdichterlauf 1,2 K im Median (533 Werte, 30.07.–02.08.). Momentanwert pendelt −6,7 bis +8,8 K; nur der gleitende Median ist auswertbar |
| IR18 | **Verdichtergehäuse, Hochdruckseite** | ×0,1, faktisch 1 K | [siehe unten](#ir18-verdichtergehäuse) |
| IR20 | **Verdichterdrehzahl** (Einheit offen, Hz naheliegend) | — | [siehe unten](#ir20-drehzahl) |
| IR21 | Hochdruck (Überdruck) | ×0,01 bar | Sättigungstemperatur deckt sich bei Warmwasser mit dem Vorlauf auf < 1,5 K, sieben Punkte monoton; rund 1 K einseitig verschoben, [siehe unten](#ir21-kondensation-und-vorlauf) |
| IR22 | Niederdruck | ×0,01 bar | im Stillstand ≈ IR21 (Druckausgleich), im Betrieb weit darunter |
| IR23 | **Scheinleistung** | VA | [siehe unten](#ir23-scheinleistung) |
| IR24 | Raumtemperatur | ×0,1 | 205 bei „innen 20,5" |
| IR25 | Warmwassertemperatur | ×0,1 | 506 bei 50,6 °C am Bedienteil |
| IR26 | Wärmeanforderung: 0 keine, 1 bereit, 2 angefordert | — | fiel beim Abschalten der Warmwasser-Freigabe von 2 auf 0, HR26 blieb stehen |
| HR24 | Soll Heizkreis 1, **schreibbar** | ×0,1 | [siehe unten](#hr24-sollwert) |
| HR26 | **Betriebsmodus, schreibbar** | — | [siehe unten](#hr26-betriebsmodus) |
| HR29 | Soll Warmwasser, **schreibbar** | ×0,1 | 480 bei „Warmwasser 48° eco", Änderung live gefolgt |
| CO2 | **Flüstermodus, schaltbar** | — | vier Wechsel sekundengenau zur Bedienung, kein anderer Punkt ging mit |
| CO3 | Außeneinheit in Betrieb | — | rund 20 Flanken decken sich mit dem Verdichtermelder (Shelly-Wirkleistung, nicht zirkulär) |
| CO4 | Heizkreis 1 aktiv | — | zwei Wechsel zeitgleich mit HK1. **Nur lesend**: in der offiziellen LG-Karte liegt hier Notaus/Notbetrieb |
| CO6 | Warmwasser-Freigabe, **schaltbar** | — | schaltet die Warmwasserbereitung |
| DI07 | Drei-Minuten-Wiederanlaufsperre | — | [siehe unten](#di07-wiederanlaufsperre) |
| DI08 | Höchste Verdichterstufe, ≡ IR20 = 60 | — | [siehe unten](#di08-höchste-stufe) |
| DI09 | Warmwasserbereitung | — | deckt zwei Ladungen ab; blieb in den Kühltakten des 31.07. aus, obwohl die Speichertemperatur stark schwankte |
| DI31 | Heizkreis 1, invertiert zu CO4 | — | on bei HK1 aus |

### HR26: Betriebsmodus

Am Bedienteil geschaltet, alle vier Werte mit Zeitstempel belegt:

| Wert | Modus | Beleg |
|---|---|---|
| 0 | Aus / nur Warmwasser | beim Abschalten von HK1 |
| 1 | Kühlen | HR24 blieb 21 °C |
| 2 | Heizen | HR24 sprang gleichzeitig auf 55 °C |
| 3 | Auto | im Automatikbetrieb |

Das Abschalten von HK1 läuft reproduzierbar gestaffelt: **CO4, nach 3 s HR26 = 0,
nach weiteren 10 s DI31.** Bei 20 s Abfragetakt ist die Reihenfolge echt.

### HR24: Sollwert

HR24 ist in jedem Modus lesbar und folgt der Anlage (21 °C Kühlen, 55 °C
Heizen). Welche Größe es meint, bestimmt die **Regelungsart am Bedienteil**:
Vorlauf, Rücklauf oder Raum, je Modus getrennt. Hier: Vorlauf im Heizen,
Rücklauf im Kühlen. Die Regelungsart ist über Modbus nicht abgebildet.

**Im Auto-Modus (HR26 = 3) ist HR24 eine Kurvenverschiebung:** 16..22 entspricht
−3..+3, 19 = 0. Die Firmware bildet das als Entität „Heizkurven-Verschiebung"
ab (außerhalb von Auto unbekannt). Die Number „Soll-Temperatur Heizkreis 1"
behält 5..65, weil `min_value`/`max_value` zur Laufzeit nicht umschaltbar sind;
sie zeigt im Auto-Modus 19 °C.

> **Herkunft:** vom Betreiber berichtet (02.08.2026), nicht am Bus gemessen.
> **Offene Gegenprobe:** im Auto-Modus die Kurve auf +3 schieben, HR24 muss
> 220 zeigen.

### IR23: Scheinleistung

Gegen einen Shelly 3EM über 27 Punkte einer Warmwasserladung:

```
IR23 / Scheinleistung = 0,907 .. 0,984   (Median 0,946)   <- konstant
IR23 / Wirkleistung   = 1,179 .. 1,360                    <- unruhig
```

Der Leistungsfaktor stieg dabei von 0,709 auf 0,790. Offen bleibt ein Versatz
von rund −5 %. **Im Stillstand ist der Wert keine Messung**: er parkt auf 417,
während der Zähler rund 180 VA sieht.

### IR21: Kondensation und Vorlauf

Über 622 Warmwasserminuten liegt die gerechnete Kondensation im Median 0,6 K
**unter** dem Vorlauf (71,4 % der Minuten), physikalisch unmöglich. Ein
Ablesversatz ist es nicht, der Effekt ist im Ruhezustand am größten:

| Vorlauf | n | Median | Anteil negativ |
|---|---|---|---|
| steht (< 0,2 K/min) | 157 | −0,98 K | 98,1 % |
| steigt (> 0,3 K/min) | 438 | −0,15 K | 61,4 % |

Ursache zu einem Drittel: Die Propan-Tabelle in `therma-v.yaml` lag gegen
CoolProp ab 45 °C zu hoch (bis 0,17 bar bei 65 °C, entspricht −0,2 bis −0,4 K).
Lineare Interpolation (−0,01 bis −0,05 K) und der Offset 1,0 statt 1,013 bar
(−0,03 K) sind vernachlässigbar. Die restlichen 0,6 K liegen in der Toleranz
von Vorlauffühler und Druckaufnehmer.

| °C | alt | CoolProp | Fehler |
|---|---|---|---|
| 45 | 15,40 | 15,34 | −0,17 K |
| 50 | 17,20 | 17,13 | −0,18 K |
| 55 | 19,20 | 19,07 | −0,32 K |
| 60 | 21,30 | 21,17 | −0,30 K |
| 65 | 23,60 | 23,43 | −0,36 K |
| 70 | 26,00 | 25,87 | −0,26 K |

> **Korrigiert und geflasht am 16.08.2026, 10:57.** Gegenprobe: 16,18 bar →
> 50,13 °C statt 49,94 °C (+0,19 K, wie gerechnet). Kondensation und
> Temperaturhub springen damit um +0,2 bis +0,4 K, Verdampfung und Überhitzung
> um ≤ 0,1 K. Alle Kondensationszahlen dieser Karte stammen von davor (IR11
> +0,7 K, IR18 10–16 K, Kondensation 14,8 K über Rücklauf im Kühlen).

### IR11 und IR19: Außenwärmetauscher

Trenner ist das Vorzeichen gegen die Sättigungstemperaturen aus IR21/IR22
(aus den Drücken gerechnet, nicht zirkulär):

| Zustand | IR11 − Gerätefühler | IR11 − Kondensation | IR11 − Verdampfung |
|---|---|---|---|
| Kühlen, Verdichter (1672 min) | +5,2 K | **+0,7 K** (p10 −0,0 / p90 +1,9) | +22,0 K |
| Warmwasser (622 min) | −7,8 K | −39,2 K | **+5,2 K** (p10 +1,9 / p90 +11,0) |
| Stillstand (6326 min) | +1,7 K | — | — |

IR19 spiegelt IR11: 85,8 % exakt gleich, 95 % innerhalb 0,5 K im ±35-s-Fenster.
Die Abweichung ist ein Abtastschritt (IR11 ändert sich im Kühlen um 0,5 K je
Zyklus).

### IR18: Verdichtergehäuse

Über 2294 Minuten Verdichterbetrieb:

```
r(IR18, Hochdruck)               = +0,959
r(IR18, Kondensationstemperatur) = +0,958
r(IR18, Verdichtungsverhältnis)  = +0,910
r(IR18, Wirkleistung)            = +0,689
r(IR18, Verdampfungstemperatur)  = −0,122
```

| Betriebsart | Wirkleistung | IR18 | Kondensation | Differenz |
|---|---|---|---|---|
| Kühlen | 1500–2000 W | 51 °C | 37,4 °C | +12,2 K |
| Warmwasser | 1500–2000 W | 72 °C | 60,3 °C | +11,5 K |
| Kühlen | 2600–3200 W | 58 °C | 41,6 °C | +16,5 K |

- **Kein Kühlkörper:** Bei doppelter Leistung ist IR18 14 K kälter als bei
  Warmwasser.
- **Kein Heißgas:** Nach dem Stopp fällt IR18 aus dem Kühlbetrieb in 30 min nur
  2–5 K und hält ein Plateau 10–18 K über dem Gerätefühler (60 Stopps). Aus der
  Warmwasserladung fällt es 20–40 K.

Im Lauf liegt IR18 konstant 10–16 K über der Kondensation, im Stillstand hält es
die Wärme: Gehäuse der Hochdruckseite. Trotz `multiply: 0.1` nur ganze Kelvin.
Bereich 33–78 °C.

### IR20: Drehzahl

| Betriebsart | IR20 | Wirkleistung | W je Einheit | Druckverhältnis |
|---|---|---|---|---|
| Kühlen | 15 | 660 W | 44,0 | 1,75 |
| Kühlen | 30 | 1351 W | 45,0 | 1,99 |
| Kühlen | 42 | 2070 W | 49,3 | 2,28 |
| Kühlen | 60 | 3013 W | 50,2 | 2,29 |
| Warmwasser | 20 | 1690 W | 84,5 | 3,07 |
| Warmwasser | 36 | 2267 W | 63,0 | 2,92 |

**IR20 = 20 zieht bei Warmwasser 1690 W, IR20 = 30 im Kühlen 1351 W.** Eine
Leistungsskala kann das nicht. Fit über 1072 stabile Minuten:
`W / IR20 = 25,5 · Druckverhältnis + 0,6` (r = 0,932), also Leistung ∝ IR20 ×
Druckverhältnis. Das r stützt sich auf zwei Cluster (n = 590 um 1,75, n = 166
über 3,0). Bereich 15–60 mit Anschlag bei exakt 60 (859 Werte: 27-mal 60,
einmal 59, zweimal 58). Kein Expansionsventil: 26 min konstant, während die Überhitzung von 0,6
auf 6,3 K wanderte.

Der Entitätsname „Verdichterleistung Anforderung" bleibt, weil eine Umbenennung
die Historie abschneidet.

### DI08: höchste Stufe

DI08 ist IR20 = 60. Über 56 Takte (07.–16.08.2026):

| | Takte | IR20max min | IR20max max |
|---|---|---|---|
| mit DI08 | 22 | 60 | 60 |
| ohne DI08 | 34 | 0 | 55 |

Auf Impulsebene: 27 Phasen IR20 = 60 gegen 27 DI08-Impulse, keiner ohne
Gegenstück, in 21 Paaren gleiche Dauer (±1 Zyklus). Der Versatz ist
ausschließlich −14 s oder +16 s: Beide Register werden 14 s auseinander im
selben 30-s-Zyklus gelesen. Daraus entstanden die früheren Deutungen
„Anlauf" und „Schwelle ≥ 42".

DI08 trägt nichts, was nicht in IR20 steht. Es bleibt als unabhängige
Bestätigung eingebunden, unter dem alten Namen „Verdichter hohe Stufe".

### DI07: Wiederanlaufsperre

Ruht auf `on` und fällt nach jedem Betriebsende ab. 133 Abfallphasen in zwei
Fenstern (02.–16.08.2026): **125-mal exakt 180 s**; sieben mal 210 s (ein Zyklus
Abtastung), einmal 360 s.

## Unbelegt, aber eingegrenzt

Über 9,34 Tage (07.–16.08.2026) ohne jede Änderung: IR09, IR10, IR13, IR27,
HR25, HR27, HR28, DI06, DI32, CO5, CO29, CO30.

| Punkt | Stand |
|---|---|
| IR09 | konstant 19, ein Kennwert |
| IR13 | konstant 12000; das Bedienteil zeigt denselben Rohwert unter „Kältemittel" |
| IR14 | Wassertemperatur zwischen Vorlauf und Rücklauf, [siehe unten](#ir14) |
| IR10 = DI32 | derselbe Zustand, [siehe unten](#ir10--di32) |
| IR27, HR25, HR27, HR28 | konstant 0, auch unter Volllast (3013 W) und 19 Warmwasserladungen |
| DI06 | keine Flanke im Kühlen (3268 min), bei Warmwasser (682 min) und im August. Bleibt der Raumheizbetrieb |
| CO5 | Bedeutung offen, [Warnung](#warnung-zu-coil-5) |
| CO29, CO30 | konstant `off` über alle Messreihen. Nur lesend, wie CO5 |

### IR14

Beim Verdichterstopp bricht die Kondensation in Sekunden ein, das Wasser nicht.
Über 23 Stopps (31.07.–01.08.) folgte IR14 16-mal dem Wasser und nie dem
Kältemittel; sieben waren nicht trennbar. Beispiel 31.07. 20:55:31:
Kondensation −16,1 K, Vorlauf +5,1 K, IR14 ±0,0 K.

IR14 liegt zwischen Vorlauf und Rücklauf und rückt zum Rücklauf:

| Lage | IR14 − Vorlauf | IR14 − Rücklauf |
|---|---|---|
| Kühlen, Verdichter (1672 min) | +0,4 K | −2,8 K |
| Warmwasser (622 min) | −1,7 K | +3,6 K |
| Stillstand (6326 min) | +0,4 K | +0,4 K |

Die erste Messreihe (31.07.–01.08.) zeigte im Kühlen +2,4 K zum Vorlauf, sonst
dieselbe Richtung. IR14 ist unruhiger als beide Fühler (5,0 K/min gegen
1,3 und 0,4 K/min) und reicht von 8,1 bis 68,3 °C. Nicht der Heizstab: 151 bei
Bedienteil 174–181.

### IR10 = DI32

Über 3264 Minuten (30.07.–01.08.):

```
IR10 \ DI32      off      on
   0            3183       0
  14               1      81
```

Die Abweichung ist Abtastung (Flankenpaare 1–25 s auseinander). Belegt ist die
Gleichzeitigkeit, nicht Wertegleichheit; IR10 kennt bisher nur 0 und 14.

Aufgetreten zweimal (59 und 21 min), jeweils bei HR26 = 0, CO4 aus, DI31 an,
< 15 W, 1–6 s nach DI31. **Nicht „Anlage aus":** Eine 456-min-Abschaltung mit
gleicher Registerlage zog nicht an. Unterschied: dort aus Verdichterbetrieb
(1215 W) abgeschaltet, sonst aus Pumpenbetrieb (96 W). Zu wenig Fälle für eine
Deutung.

## Gar nicht abgebildet

Je am Bedienteil geprüft und im Registerraum nicht gefunden: Heizkreis 2,
Kreis-2-Pumpe, 3-Wege-Ventil als Zustand, Mischkreis, Wasserdruck,
**Wasserdurchfluss**, Heizstabbetrieb, Fehlercode. Konfiguration am Bedienteil
(auch die Regelungsart) ist unsichtbar; nur physikalische Größen und die
Haupt-Sollwerte spiegeln sich. Ohne Durchfluss kein COP.

## Messfenster

| Fenster | Dauer | Generation | Zyklus |
|---|---|---|---|
| 30.07.–02.08.2026 | 2,3 Tage | — | 19,5–20 s |
| 02.08. 18:24 – 08.08. 18:11 | 8622 min | eine | 30,0 s |
| 07.08. 00:00 – 16.08. 08:13 | 9,34 Tage, 26591 Zyklen | dieselbe wie davor | 30,0 s |

- Sekundenangaben aus dem 20-s-Regime sind mit denen aus dem 30-s-Regime nicht
  vergleichbar; eine Dauer trägt dort ±30 s.
- Im August stand HR26 durchgehend auf 3 (Auto), CO4 an, DI31 aus. Es gibt
  keinen Vorlauf-Sollwert und keinen Raumheizbetrieb in diesen Daten.
- Bus August: erstes Fenster ohne verpassten Zyklus. Zweites Fenster mit vier
  Lücken (3 × 90 s, 1 × 120 s, zusammen 0,05 %).
- Zwei abgebrochene Verdichterstarts von je einem Zyklus (03.08. 01:52, 912 W;
  08.08. 10:27, 574 W), unabhängig belegt durch Shelly, CO3 und IR20. Sie gehen
  als 0,5-min-Takte in „Kürzester Takt heute" ein.
- Der Recorder reicht nicht vor den 07.08. zurück; das erste Augustfenster ist
  nicht nachrechenbar.
- CO3 und DI08 wurden am 31.07. umbenannt; ihre Aussagen aus Juli stützen sich
  auf 28 Stunden.

## Fallstricke bei der Auswertung

**1. Blockbildung verschiebt Werte.** ESPHome fasst benachbarte Register zu
einer Anfrage zusammen, die Gruppierung ändert sich mit jeder Generation. Anteil
unmöglicher IR11-Werte (> 120 °C) über sieben Generationen eines Tages:

| Generation | 1 | 2 | 3 | 4 | 5 | 6 | 7 (einzeln) |
|---|---|---|---|---|---|---|---|
| > 120 °C | 0 % | 0 % | 100 % | 100 % | 100 % | 8,9 % | 0 % |

In einer der Generationen 3–5 entstand die Fehlzuordnung „IR11 = Heißgas"
durch Ablesevergleich am Bedienteil. Deshalb steht
`reuse_previous_range: false` (bis ESPHome 2026.8 `force_new_range: true`) an
jedem Register.

**2. Zeitreihen nur innerhalb einer Generation auswerten.** Sonst mischen sie
Artefakte und erzeugen überzeugende, bedeutungslose Korrelationen. Deshalb
tragen unbelegte Punkte **keine `state_class`** (IR09, IR10, IR27, HR25, HR27,
HR28, Betriebsmodus-Rohwert, Kältemittel-Kennwert, die zwei
Beobachtungs-Sensoren). Wer einen Punkt deutet, vergibt sie und legt damit fest,
ab wann die Historie gilt. IR11, IR18, IR19 und IR20 hatten sie schon vorher;
auswertbar sind sie ab dem Flash vom 02.08.2026 18:24.

**3. Home-Assistant-Neustarts sind keine Lücken.** Alle Entitäten gehen
gemeinsam kurz auf `unavailable`, während der ESP weiterfragt. Maßgeblich ist
die Zyklusreihe der Firmware. Beispiel: Eine DI07-Phase am 12.08. stand als
44 s + 135 s in der Historie (44 + 1 + 135 = 180).

**4. Nicht auf Minutenraster auswerten.** Die Hälfte der DI08-Impulse dauert
einen 30-s-Zyklus und verschwindet im Raster.

## Warnung zu Coil 5

Coil 5 antwortet. Ein Schreibversuch blieb ohne erkennbare Wirkung, die
Busantwort ist aber nicht festgehalten:

- Exception → nicht schreibbar
- Quittung, Rücklesen sofort 0 → Wert verworfen, **oder** ein
  flankengetriggertes Bit, das ausgeführt und zurückgesetzt hat
- Quittung, Rücklesen bleibt 1, keine Wirkung → Vorbedingung fehlt

In der offiziellen LG-Karte liegen daneben Notaus, Notbetrieb und der
Desinfektionszyklus (Speicher stundenlang auf rund 70 °C). Die Karte gilt hier
nicht, ist also kein Beleg. Erst passiv identifizieren: Registerbeobachtung und
Referenzzustand-Vergleich.
