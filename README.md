# LG Therma V über Modbus RTU in Home Assistant

Eine vollständige ESPHome-Konfiguration für die **LG Therma V R290 Monobloc**
(Hydro Unit HN1639HC.NK0), angebunden über Modbus RTU mit einem ESP32 —
ohne LG-Gateway, ohne Cloud.

Enthalten ist nicht nur die Firmware, sondern auch das, was beim Nachbau die
meiste Zeit kostet: eine **empirisch geprüfte Registerkarte**, die
dokumentierten Sackgassen, und die Werkzeuge, mit denen die offenen Register
weiter eingegrenzt werden können.

> **Wichtig zu wissen:** Dieses Gerät spricht eine **eigene** Registerbelegung.
> Keine der veröffentlichten Karten passt — auch nicht mit Versatz. Was hier
> steht, gilt gemessen für diese Baureihe an diesem Anschluss.

## Was funktioniert

**Auslesen** — 32 antwortende Datenpunkte: Vorlauf, Rücklauf, Warmwasser, Raum,
Außentemperatur, Sauggas, Hoch- und Niederdruck, Scheinleistung, Betriebsmodus.

**Stellen** — Warmwasser-Freigabe (ein/aus), Warmwasser-Solltemperatur,
Heizkreis-Solltemperatur, Regelungsart.

**Berechnet** — Verdampfungs- und Kondensationstemperatur aus der
Propan-Dampfdruckkurve, Sauggasüberhitzung, Temperaturhub,
Verdichtungsverhältnis, Carnot-Obergrenze, Wärmeübergang an beiden
Wärmetauschern, Spreizung.

**Statistik** — Verdichterstarts pro Tag, mittlere und kürzeste Taktlänge,
Betriebsstunden, Warmwasserladungen, Verbrauch je Kelvin Speicherhub.

**Bus-Gesundheit** — Zeit seit letzter Antwort, Zyklusdauer, Punkte ohne
Antwort, verpasste Zyklen, plus eine Schutzschaltung gegen zu lange
Abfragelücken.

**Kartierungswerkzeuge** — Registerbeobachtung und Referenzzustand-Vergleich,
um offene Register am Bedienteil zu identifizieren, **ohne zu schreiben**.

## Was nicht funktioniert

Über diesen Anschluss sind **nicht** erreichbar, je einzeln geprüft:
Betriebsmodus als Stellgröße, Heizkreis 2 in jeder Form, Flüstermodus,
Kreis-2-Pumpe, Mischkreis, Wasserdruck, **Wasserdurchfluss**, Heizstabbetrieb.

Dass der Durchfluss fehlt, hat eine Folge: **ein COP lässt sich nicht
berechnen.** Ohne Volumenstrom keine thermische Leistung. Als Ersatz dient hier
der Verbrauch je Kelvin Speicherhub — bei konstantem Speichervolumen über die
Zeit vergleichbar.

Der belegte Weg zu Betriebsmodus und Heizkreis 2 führt über das
**LG-Gateway PMBUSB00A** oder über **SG-Ready** mit zwei Kontakten.

## Schnellstart

```bash
git clone https://github.com/ComicSans/lg-therma-v-esphome-modbus
cd lg-therma-v-esphome-modbus
cp secrets.yaml.example secrets.yaml
# secrets.yaml ausfüllen, dann:
esphome run therma-v.yaml
```

Vorher unbedingt [docs/hardware.md](docs/hardware.md) lesen — drei Details
entscheiden darüber, ob überhaupt ein Byte fließt.

## Hardware

- **Waveshare ESP32-S3-RS485-CAN**, Strom per USB-Netzteil
- Adernpaar auf **Klemme 21 (A) und 22 (B)**, Terminal Block 2
- **DIP SW1-1 ON, SW1-2 OFF**

Die drei häufigsten Fehler: fehlender `flow_control_pin`, Adern auf Klemme
28/29 (führt zur Außeneinheit), und Slave-Adresse 33 aus dem Bedienteilmenü
statt 1. Details und die Begründung, warum SW1-2 auf **OFF** gehört, obwohl
Foren das Gegenteil empfehlen: [docs/hardware.md](docs/hardware.md).

## Anpassen an die eigene Installation

Zwei Stellen in `therma-v.yaml` sind installationsspezifisch:

**1. Der Stromzähler.** Die Firmware liest drei Phasen eines Shelly 3EM aus
Home Assistant (`sensor.l1_power`, `sensor.l1_voltage`, `sensor.l1_current` und
so weiter für L2 und L3). Wer keinen dreiphasigen Zähler hat, kann die
`homeassistant`-Sensoren entfernen — dann fallen Wirkleistung,
Leistungsfaktor, Phasenschieflast, Heizstab-Verdacht und die Betriebsstatistik
aus. Der Kältekreis und die Registerkarte funktionieren weiter.

**2. Der Gerätename in Home Assistant** bestimmt das Präfix aller Entity-IDs.
Das Dashboard in [home-assistant/](home-assistant/) nutzt
`heizungskeller_warmepumpe_modbus_` — wer das Gerät anders benannt hat, muss
das Präfix durchgängig ersetzen.

## Dashboard

[home-assistant/dashboard-waermepumpe.yaml](home-assistant/dashboard-waermepumpe.yaml)
enthält eine vollständige Lovelace-Ansicht: Betrieb, Kältekreis, Strom,
Verschleiß, Bus-Gesundheit, Kartierung und Steuerung. Einbauen über den
Rohkonfigurationseditor des Dashboards.

## Zwei Fallstricke, die echte Fehldeutungen erzeugt haben

### `force_new_range: true` gehört an jedes Register

ESPHome fasst benachbarte Register zu einer Blockanfrage zusammen — und die
Gruppierung ändert sich mit **jeder** Änderung der Registerliste. Ein Register
lieferte in drei aufeinanderfolgenden Firmware-Generationen zu 100 %
physikalisch unmögliche Werte (bis 451 °C), in der vierten wieder plausible.
Die Sprünge lagen exakt auf den Generationsgrenzen, nicht auf
Betriebszuständen.

In genau einer dieser verfälschten Generationen entstand durch einen
Ablesevergleich am Bedienteil die Fehlzuordnung „dieses Register ist die
Heißgastemperatur" — sie hielt sich, bis die Generationen getrennt ausgewertet
wurden.

32 Einzelanfragen kosten Buslast (gemessen rund 20 s je Zyklus), aber sie können
nicht mehr verrutschen.

### Eine Zeitreihe über mehrere Firmware-Generationen ist kein Datensatz

Wer die Registerliste ändert, ändert die Blockbildung. Auswertungen müssen auf
eine Generation begrenzt werden — sonst mischen sie Regime mit verschiedenen
Artefakten, und die Korrelationen sehen überzeugend aus, während sie nichts
bedeuten.

## Vorsicht bei Coil 5

Coil 5 antwortet, aber seine Bedeutung ist offen. Ein Schreibversuch blieb ohne
erkennbare Wirkung — nur wurde nicht festgehalten, **was der Bus dabei
antwortete**, und das ist der ganze Unterschied. Rücklesen 0 beweist nichts:
genau so verhält sich ein flankengetriggertes Bit, das seine Aktion ausführt und
sich selbst zurücksetzt.

Auf benachbarten Positionen liegen in der offiziellen LG-Karte Notaus,
Notbetrieb und der Desinfektionszyklus, der den Speicher stundenlang auf rund
70 °C heizt. Diese Karte gilt für dieses Gerät nicht, das ist also kein Beleg —
aber Grund genug, erst passiv zu identifizieren. Dafür sind die
Registerbeobachtung und der Referenzzustand-Vergleich da.

## Dokumentation

- [docs/registerkarte.md](docs/registerkarte.md) — alle 32 Punkte, was belegt
  ist und woran, was offen bleibt
- [docs/hardware.md](docs/hardware.md) — Anschluss, DIP-Schalter, Buslast,
  Sackgassen

## Stand

Gemessen und in Betrieb seit Juli 2026. Die Firmware läuft ohne Timeouts; alle
32 Registerpunkte antworten.

Beiträge sind willkommen — besonders Messungen an **anderen Therma-V-Baureihen**.
Die spannendste offene Frage ist, ob die hier gefundene Registerbelegung
modellspezifisch ist oder für die ganze R290-Reihe gilt.
