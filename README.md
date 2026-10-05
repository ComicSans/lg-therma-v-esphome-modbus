# LG Therma V über Modbus RTU in Home Assistant

Eine vollständige ESPHome-Konfiguration für die **LG Therma V R290 Monobloc**,
angebunden über Modbus RTU mit einem ESP32 — ohne LG-Gateway, ohne Cloud.

Enthalten ist nicht nur die ESP32-Firmware, sondern auch das, was beim Nachbau
die meiste Zeit kostet: eine empirisch geprüfte
[Registerkarte](docs/registerkarte.md), die dokumentierten Sackgassen und die
Werkzeuge, mit denen sich die offenen Register weiter eingrenzen lassen.

Die Firmware ist als Wärmepumpe für [HEMS](https://github.com/ComicSans/hahems)
ausgelegt, den PV- und Energiemanager für Home Assistant aus demselben Haus, läuft
aber auch ohne ihn (siehe [Als Wärmepumpen-Rolle in HEMS](#als-wärmepumpen-rolle-in-hems)).

## Gemessen an genau diesem Gerät

| | |
|---|---|
| **Hydro Unit** | HN1639HC.NK0 |
| **Kältemittel** | R290 (Propan) |
| **Geräte-Firmware** | **3.07.2a** (am Bedienteil unter Information ablesbar) |
| **Anschluss** | Terminal Block 2, Klemme 21 (A) / 22 (B) |
| **Bus** | Modbus RTU, Slave 1, 9600 Baud, 8N1 |

> **Dieses Gerät spricht eine eigene Registerbelegung.** Keine der
> veröffentlichten Karten passt — auch nicht mit Versatz. Ob die Belegung an
> einem anderen Modell oder Firmwarestand gleich aussieht, ist **offen**. Die
> Registerkarte nennt zu jedem Punkt den Beleg — wer nachbaut, kann damit
> gegenprüfen statt zu vertrauen. Der erste Schritt ist ein Adress-Scan; er
> schreibt nichts.

## Was du bekommst

**Auslesen** — 38 antwortende Datenpunkte: Vorlauf, Rücklauf, Warmwasser, Raum,
Außentemperatur, Sauggas, Hoch- und Niederdruck, Scheinleistung, Betriebsmodus.
Die Außentemperatur ist ein Gerätefühler im besonnten Gehäuse und liegt im
Stillstand bis 13 K zu hoch — für abgeleitete Rechnungen gehört ein
unabhängiger Sensor daneben.

**Stellen** — Betriebsmodus (aus / kühlen / heizen / auto), Flüstermodus,
Warmwasser-Freigabe, Warmwasser- und Heizkreis-Solltemperatur. Dazu eine
Climate-Entität in der Firmware, direkt für einen Energiemanager verdrahtbar.

**Berechnet** — Verdampfungs- und Kondensationstemperatur aus der
Propan-Dampfdruckkurve, Sauggasüberhitzung, Temperaturhub,
Verdichtungsverhältnis, Carnot-Obergrenze, Wärmeübergang an beiden
Wärmetauschern, Spreizung.

**Statistik** — Verdichterstarts pro Tag, mittlere und kürzeste Taktlänge,
Betriebsstunden, Warmwasserladungen, Verbrauch je Kelvin Speicherhub. Alle
gedeuteten Werte tragen eine Zustandsklasse und laufen damit in die
Langzeitstatistik; die Tageszähler als `total_increasing`, weil ihr Reset um
Mitternacht dort korrekt als neuer Zyklus gilt.

**Bus-Gesundheit** — Zeit seit letzter Antwort, Zyklusdauer, Punkte ohne
Antwort, verpasste Zyklen, plus eine Schutzschaltung gegen zu lange
Abfragelücken. Zusammengefasst zu einem Urteil: `gut` / `auffällig` / `gestört`.

**Diagnose** — zehn Melder: Frostgefahr, Stillstand, Taktung, Druck (`ok` /
`zu hoch` / `zu niedrig`), Kältekreis, Wärmeübergang, Busgesundheit,
Verschleiß, Spreizung und der Messfehler-Verdacht „Temperaturen identisch".
Dazu ein Sammel-Textsensor, der alles Anstehende in einer Zeile zeigt. Jeder
Melder hat zwei Schwellen, damit er am Grenzwert nicht flattert; die
Kreis-Melder zusätzlich fünf Minuten Anlaufkarenz.

**Verschleiß und Effizienz** — Spreizung im Tagesmittel unter Last,
Laufzeitanteil, Starts je Betriebsstunde, und ein `Effizienzhinweis` in
Klartext: Umwälzpumpe drosseln, Volumenstrom prüfen, längere Takte,
Temperaturhub senken. Qualitativ formuliert, nicht in Prozent — die
Pumpenkennlinie ist hier nicht bekannt, eine Zahl wäre Scheingenauigkeit. Die
Schwellen stammen aus der Wärmepumpen-Analyse des HEMS-Projekts, die dort
entfallen ist.

Diagnose und Bewertung laufen **in der Firmware, nicht als Template in Home
Assistant**: Sie müssen auch dastehen, wenn Home Assistant neu startet oder
jemand die Templates verschiebt, und der ESP hat alle Eingangsgrößen ohnehin im
Speicher.

**Kartierungswerkzeuge** — Registerbeobachtung, Referenzzustand-Vergleich und
zwei Adress-Scanner, um offene Register zu identifizieren, **ohne zu schreiben**.
Die langsame Einzelabfrage findet dabei Register, die ein gruppenweiser Scan
übersieht.

## Was nicht geht

Über diesen Anschluss sind **nicht** erreichbar, je einzeln geprüft: Heizkreis 2
in jeder Form, Kreis-2-Pumpe, Mischkreis, Wasserdruck, **Wasserdurchfluss**. Ein
Heizstab ist an dieser Anlage nicht verbaut.

**Ohne Durchfluss kein COP.** Ohne Volumenstrom gibt es keine thermische
Leistung — weder einen COP noch einen Datenblattvergleich gegen die Kennlinie.
Als Ersatz dient der Verbrauch je Kelvin Speicherhub, bei konstantem
Speichervolumen über die Zeit vergleichbar. Wer den COP will, braucht einen
eigenen Volumenstromsensor im Heizkreis.

**Der Fehlercode der Anlage steht in keinem Register.** Am 01.08.2026 stand am
Bedienteil CH03 — Kommunikationsfehler zwischen Bedienteil und Hauptplatine —
und die Anlage blieb 76 Minuten stehen, während der Modbus lückenlos weiter
antwortete. Die Diagnosemelder hängen deshalb an der **Wirkung** einer Störung,
nicht am Code. So wirken sie gegen jeden Fehler, der die Anlage anhält, nicht
nur gegen den einen mit dem bekannten Kürzel.

Wer **Heizkreis 2** braucht, kommt an dieser Stelle nicht weiter: Der Weg führt
über das LG-Gateway PMBUSB00A oder über SG-Ready mit zwei Kontakten.

## Hardware

- **Waveshare ESP32-S3-RS485-CAN**, Strom per USB-Netzteil
- Adernpaar auf **Klemme 21 (A) und 22 (B)**, Terminal Block 2
- **DIP SW1-1 ON, SW1-2 OFF** (der Schalter wird nur beim Booten gelesen)

Drei Details entscheiden darüber, ob überhaupt ein Byte fließt — fehlender
`flow_control_pin`, Adern auf Klemme 28/29 statt 21/22, und Slave-Adresse 33 aus
dem Bedienteilmenü statt 1. Alle drei stehen mit Begründung in
[docs/hardware.md](docs/hardware.md). **Vor dem Anschließen lesen.**

## Installation

Voraussetzung ist **ESPHome 2026.9.0 oder neuer**; ältere Versionen lehnen die
Konfiguration ab (`min_version`).

```bash
git clone https://github.com/ComicSans/lg-therma-v-esphome-modbus
cd lg-therma-v-esphome-modbus
cp secrets.yaml.example secrets.yaml
# secrets.yaml ausfüllen (API-Schlüssel: openssl rand -base64 32), dann:
esphome run therma-v.yaml
```

Ein voller Abfragezyklus dauert rund 20 Sekunden. Wer weitere Register aufnimmt,
muss das `update_interval` mit anheben.

`scripts/test.sh` prüft die Konfiguration und kompiliert die Firmware, ohne zu
flashen; veraltete ESPHome-Optionen und -API gelten dabei als Fehler.
`TEST_OHNE_COMPILE=1` überspringt das Kompilieren.

### An die eigene Installation anpassen

Zwei Stellen in `therma-v.yaml` sind installationsspezifisch.

**1. Der Stromzähler.** Die Firmware liest drei Phasen eines Shelly 3EM aus Home
Assistant (`sensor.l1_power`, `sensor.l1_voltage`, `sensor.l1_current`, analog
für L2 und L3). Ohne dreiphasigen Zähler die `homeassistant`-Sensoren entfernen
— dann fallen Wirkleistung, Leistungsfaktor, Phasenschieflast, Heizstab-Verdacht
und die Betriebsstatistik aus. Kältekreis und Registerkarte funktionieren
weiter.

**2. Der Gerätename in Home Assistant** bestimmt das Präfix aller Entity-IDs.
Das mitgelieferte Dashboard nutzt `heizungskeller_warmepumpe_modbus_` — wer das
Gerät anders benannt hat, muss das Präfix durchgängig ersetzen.

### Dashboard

[home-assistant/dashboard-waermepumpe.yaml](home-assistant/dashboard-waermepumpe.yaml)
enthält eine vollständige Lovelace-Ansicht: Betrieb, Kältekreis, Strom,
Verschleiß, Bus-Gesundheit, Kartierung und Steuerung. Einbauen über den
Rohkonfigurationseditor des Dashboards.

## Als Wärmepumpen-Rolle in HEMS

Die Entitäten dieser Firmware passen direkt auf die Rollen von
[HEMS](https://github.com/ComicSans/hahems), einem PV- und
Energiemanager für Home Assistant:

| HEMS-Rolle | Feld | Entität aus dieser Firmware |
|---|---|---|
| Heizkreis | Steuer-Entität | Betriebsmodus-Select (HR26) |
| Heizkreis | Vorlauf-Sollwert-Number | Heizkreis-Solltemperatur (HR24) |
| Heizkreis | Schalter Flüsterbetrieb | Flüstermodus (Coil 2) |
| Warmwasser | Steuer-Entität | Warmwasser-Freigabe (Coil 6) |
| Warmwasser | Sollwert-Number | Warmwasser-Solltemperatur (HR29) |

Die Modus-Optionen des Selects müssen in HEMS **exakt** so eingetragen werden,
wie sie hier heißen — Groß- und Kleinschreibung zählt. Alternativ lässt sich die
Climate-Entität dieser Firmware als Steuer-Entität nutzen; dann entfällt die
Vorlauf-Number.

Für die HEMS-Rolle **Wärmepumpen-Analyse** liefert diese Firmware vier der fünf
Pflichtwerte: Vorlauf (IR16), Rücklauf (IR15), elektrische Leistung (aus dem
Shelly, nicht aus IR23 — das ist Scheinleistung) und Außentemperatur. Der
Durchfluss fehlt (siehe [Was nicht geht](#was-nicht-geht)).

> **Was HR24 bedeutet, hängt von der Regelungsart am Bedienteil ab** — Vorlauf,
> Rücklauf oder Raum, je Betriebsmodus getrennt einstellbar und über Modbus
> nicht auslesbar. An dieser Anlage: **Vorlauf im Heizen, Rücklauf im Kühlen.**
> Im Kühlbetrieb bedeuten 21 °C auf HR24 also einen Rücklauf-Soll; der Vorlauf
> läuft dabei bis auf etwa 15 °C herunter. Wer nach Vorlauf-Logik ansetzt, fährt
> die Anlage deutlich kälter, als die Zahl vermuten lässt.
>
> **Im Auto-Modus (HR26 = 3) ist HR24 gar keine Temperatur**, sondern die
> Verschiebung der Heizkurve: 19 = 0, 20 = +1, 18 = −1, Bereich 16..22. Dafür
> gibt es die Entität **Heizkurven-Verschiebung** (−3..+3), die außerhalb des
> Auto-Modus auf unbekannt steht. Die Vorlauf-Number zeigt dort weiter ihre
> 19 °C — wer sie als Sollwert stellt, verschiebt in Wahrheit die Kurve.
>
> Ein Energiemanager, der HR24 schreibt, muss deshalb den Modus mitlesen und
> die Regelungsart kennen — erfragen kann er sie nicht.

## Vorsicht bei Coil 5

Coil 5 antwortet, aber seine Bedeutung ist offen. Ein Schreibversuch blieb ohne
erkennbare Wirkung — allerdings ohne festzuhalten, **was der Bus dabei
antwortete**, und das ist der ganze Unterschied. Rücklesen 0 beweist nichts:
genau so verhält sich ein flankengetriggertes Bit, das seine Aktion ausführt und
sich selbst zurücksetzt.

Auf benachbarten Positionen liegen in der offiziellen LG-Karte Notaus,
Notbetrieb und der Desinfektionszyklus, der den Speicher stundenlang auf rund
70 °C heizt. Diese Karte gilt für dieses Gerät nicht, das ist also kein Beleg —
aber Grund genug, erst passiv zu identifizieren. Dafür sind Registerbeobachtung
und Referenzzustand-Vergleich da.

## Dokumentation

- [docs/registerkarte.md](docs/registerkarte.md) — alle 38 Punkte mit Beleg,
  offene Punkte, Messfenster und Fallstricke bei der Auswertung
- [docs/hardware.md](docs/hardware.md) — Anschluss, DIP-Schalter, Buslast,
  Sackgassen

## Verwandte Projekte

- [**HEMS**](https://github.com/ComicSans/hahems) — PV- und Energiemanager für
  Home Assistant. Steuert diese Wärmepumpe über Betriebsmodus, Sollwerte,
  Flüstermodus und Warmwasser-Freigabe; die Rollenzuordnung steht
  [oben](#als-wärmepumpen-rolle-in-hems).

## Mitmachen

Beiträge sind willkommen — besonders Messungen an **anderen
Therma-V-Baureihen** und **anderen Firmwareständen**. Die spannendste offene
Frage ist, ob die hier gefundene Registerbelegung an Modell, an Firmware oder
an beidem hängt.

Was eine Meldung brauchbar macht: Modellnummer der Hydro Unit, Firmwarestand
vom Bedienteil, die Ausgabe des Buttons **Breiter Registerscan**, und zu jedem
gedeuteten Register der Beleg — ein abgelesener Wert am Bedienteil zur selben
Minute, oder eine Flanke, die mit einem beobachtbaren Ereignis zusammenfällt.
Eine Zuordnung ohne Beleg ist eine Vermutung, und davon gibt es im Netz
bereits genug.

## Haftungsausschluss

Die Nutzung dieses Projekts erfolgt **auf eigene Gefahr**. Ich übernehme
keinerlei Haftung für Schäden an der Wärmepumpe, an der Heizungsanlage, am
Gebäude oder sonstige Folgen, die aus Nachbau, Konfiguration oder Betrieb
entstehen — soweit das gesetzlich zulässig ist. Schreibzugriffe können das
Verhalten der Anlage ändern, und ein Eingriff kann Garantie- oder
Gewährleistungsansprüche gegenüber LG oder dem Installateur gefährden. Arbeiten
an der Elektrik gehören in die Hände einer Fachkraft.

*English:* Use at your own risk. To the extent permitted by law, I accept no
liability for any damage or consequences resulting from the use of this
project.

## Lizenz

[MIT](LICENSE). Der Haftungsausschluss ergänzt die Lizenz, er ersetzt sie nicht.
