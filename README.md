# LG Therma V über Modbus RTU in Home Assistant

Eine vollständige ESPHome-Konfiguration für die **LG Therma V R290 Monobloc**
(Hydro Unit HN1639HC.NK0), angebunden über Modbus RTU mit einem ESP32 — ohne
LG-Gateway, ohne Cloud.

Enthalten ist nicht nur die Firmware, sondern auch das, was beim Nachbau die
meiste Zeit kostet: eine empirisch geprüfte
[Registerkarte](docs/registerkarte.md), die dokumentierten Sackgassen und die
Werkzeuge, mit denen sich die offenen Register weiter eingrenzen lassen.

> **Dieses Gerät spricht eine eigene Registerbelegung.** Keine der
> veröffentlichten Karten passt — auch nicht mit Versatz. Was hier steht, gilt
> gemessen für diese Baureihe an diesem Anschluss.

## Was du bekommst

**Auslesen** — 34 antwortende Datenpunkte: Vorlauf, Rücklauf, Warmwasser, Raum,
Außentemperatur, Sauggas, Hoch- und Niederdruck, Scheinleistung, Betriebsmodus.

**Stellen** — Betriebsmodus (aus / kühlen / heizen / auto), Flüstermodus,
Warmwasser-Freigabe, Warmwasser- und Heizkreis-Solltemperatur. Als
Climate-Entität in der Firmware, direkt für einen Energiemanager verdrahtbar.

**Berechnet** — Verdampfungs- und Kondensationstemperatur aus der
Propan-Dampfdruckkurve, Sauggasüberhitzung, Temperaturhub,
Verdichtungsverhältnis, Carnot-Obergrenze, Wärmeübergang an beiden
Wärmetauschern, Spreizung.

**Statistik** — Verdichterstarts pro Tag, mittlere und kürzeste Taktlänge,
Betriebsstunden, Warmwasserladungen, Verbrauch je Kelvin Speicherhub.

**Bus-Gesundheit** — Zeit seit letzter Antwort, Zyklusdauer, Punkte ohne
Antwort, verpasste Zyklen, plus eine Schutzschaltung gegen zu lange
Abfragelücken.

**Kartierungswerkzeuge** — Registerbeobachtung, Referenzzustand-Vergleich und
zwei Adress-Scanner, um offene Register zu identifizieren, **ohne zu schreiben**.
Die langsame Einzelabfrage findet dabei Register, die ein gruppenweiser Scan
übersieht.

## Was nicht geht

Über diesen Anschluss sind **nicht** erreichbar, je einzeln geprüft: Heizkreis 2
in jeder Form, Kreis-2-Pumpe, Mischkreis, Wasserdruck, **Wasserdurchfluss**. Ein
Heizstab ist an dieser Anlage nicht verbaut.

Der fehlende Durchfluss hat eine Folge: **ein COP lässt sich nicht berechnen.**
Ohne Volumenstrom keine thermische Leistung. Als Ersatz dient der Verbrauch je
Kelvin Speicherhub — bei konstantem Speichervolumen über die Zeit vergleichbar.

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

## Schnellstart

```bash
git clone https://github.com/ComicSans/lg-therma-v-esphome-modbus
cd lg-therma-v-esphome-modbus
cp secrets.yaml.example secrets.yaml
# secrets.yaml ausfüllen, dann:
esphome run therma-v.yaml
```

Ein voller Abfragezyklus dauert rund 20 Sekunden. Wer weitere Register aufnimmt,
muss das `update_interval` mit anheben.

## An die eigene Installation anpassen

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

## Dashboard

[home-assistant/dashboard-waermepumpe.yaml](home-assistant/dashboard-waermepumpe.yaml)
enthält eine vollständige Lovelace-Ansicht: Betrieb, Kältekreis, Strom,
Verschleiß, Bus-Gesundheit, Kartierung und Steuerung. Einbauen über den
Rohkonfigurationseditor des Dashboards.

## Als Wärmepumpen-Rolle in HEMS

Die Firmware-Entitäten passen direkt auf die Rollen von
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
Climate-Entität der Firmware als Steuer-Entität nutzen; dann entfällt die
Vorlauf-Number.

> **Was HR24 bedeutet, hängt von der Regelungsart am Bedienteil ab** — Vorlauf,
> Rücklauf oder Raum, je Betriebsmodus getrennt einstellbar, über Modbus nicht
> auslesbar. An dieser Anlage: Vorlauf im Heizen, **Rücklauf im Kühlen**. Für
> den Heizbetrieb passt die Verdrahtung über die Vorlauf-Number damit genau.
>
> Fürs Kühlen nicht: HEMS schreibt sein Kühl-Vorlauf-Soll dann auf ein
> Rücklauf-Soll, und der Rücklauf ist beim Kühlen die wärmere Seite — die Anlage
> fährt kälter als beabsichtigt, mit entsprechendem Kondensatrisiko. Zwei Wege:
> die Regelungsart auch für den Kühlmodus auf Vorlauf stellen, oder die
> Modus-Option „Kühlen“ in HEMS leer lassen, damit HEMS im Kühlbetrieb keinen
> Sollwert schreibt.

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

- [docs/registerkarte.md](docs/registerkarte.md) — alle 34 Punkte, was belegt ist
  und woran, was offen bleibt, und die zwei Fallstricke, die echte
  Fehldeutungen erzeugt haben
- [docs/hardware.md](docs/hardware.md) — Anschluss, DIP-Schalter, Buslast,
  Sackgassen

## Mitmachen

Beiträge sind willkommen — besonders Messungen an **anderen
Therma-V-Baureihen**. Die spannendste offene Frage ist, ob die hier gefundene
Registerbelegung modellspezifisch ist oder für die ganze R290-Reihe gilt.
