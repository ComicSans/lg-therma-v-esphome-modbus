# Hardware und Anschluss

## Was gebraucht wird

- **Waveshare ESP32-S3-RS485-CAN** (ein anderes RS485-Board geht auch, siehe
  Fallstrick 1)
- kurzes Adernpaar
- USB-Netzteil
- ESPHome auf dem Rechner (`pip install esphome` oder Homebrew)

## Anschluss an der Inneneinheit

**Klemme 21 = A, Klemme 22 = B**, Terminal Block 2, beschriftet
„3rd Party Controller, 5 V DC".

> **Falle:** Klemme 28/29 ist ebenfalls mit A/B beschriftet, führt aber zur
> Außeneinheit. Dort antwortet nichts.

## DIP-Schalter

**SW1-1 ON, SW1-2 OFF.**

In dieser Stellung läuft der Bus mit der Registerkarte in
[registerkarte.md](registerkarte.md). Mit SW1-2 auf **ON** schweigt das Gerät
vollständig — viermal gemessen, entgegen der verbreiteten Empfehlung in Foren.

Das ist bemerkenswert, denn ON ist laut Handbuch das „einheitliche offene
Protokoll" und damit die Stellung, in der LGs offizielle Registerkarte gelten
sollte. Sie tut es hier nicht: 247 Adressen × sechs Baudraten von 4800 bis
115200 ergaben kein einziges Byte.

Der Schalter wird **nur beim Booten gelesen** — die Inneneinheit muss also
stromlos gemacht werden.

Nur drei Schalter haben überhaupt eine Funktion (Handbuch manualslib 1118948,
S. 103): SW1-1 Meister/Sklave, SW1-2 offenes Protokoll, SW1-8 Glykol.
**SW1-3 hat keine Funktion** — nicht anfassen.

Ungetestet blieb der SW2-Block; für Drittanbieter-Thermostate soll dort Bit 8
auf ON stehen.

## Drei Fallstricke, ohne die der Bus schweigt

### 1. `flow_control_pin` ist Pflicht

```yaml
uart:
  tx_pin: GPIO17
  rx_pin: GPIO18
  flow_control_pin: GPIO21   # ohne diese Zeile sendet das Board nie ein Byte
```

Der RS485-Treiber dieses Boards hat keine automatische
Richtungsumschaltung. Fehlt die Zeile, bleibt er im Empfangsmodus.

### 2. Slave-Adresse ist 1, nicht die aus dem Bedienteilmenü

Das Bedienteil zeigt unter Umständen 33 (hex 21) als Zentraladresse. An diesem
Anschluss funktioniert **nur 1**.

### 3. `force_new_range: true` an jedem Register

Sonst verschiebt die Blockbildung Werte zwischen Nachbarregistern — der Grund
für eine handfeste Fehldeutung, dokumentiert in
[registerkarte.md](registerkarte.md).

## Gemessene Buslast

32 Einzelanfragen je Zyklus brauchen rund **20 Sekunden** — etwa 625 ms pro
Anfrage. Die Anlage antwortet also deutlich träger als die reine Leitungszeit
von ~15 ms vermuten lässt.

Bei `update_interval: 30s` sind das rund zwei Drittel Dauerlast. Es läuft ohne
einen einzigen Timeout, aber Puffer ist kaum da: **wer weitere Register
aufnimmt, muss das Intervall mit anheben.**

## Sackgassen — nicht wiederholen

- **Transparente TCP-Brücke** (`stream_server`, oxan/esphome-stream-server):
  sendet sauber, empfängt aber nie. Die Richtungsumschaltung fällt nicht
  rechtzeitig auf Empfang zurück, weil das Frame-Ende unbekannt ist. Als
  Messmittel wertlos — auch negative Tests *mit* ihr beweisen nichts.
- **Die Leitung des LG-Cloud-Gateways ist kein Modbus.** Über Minuten keine
  einzige Antwort, nur Timeouts. Entscheidend ist das *wie*: bei falscher
  Adresse oder falschem Register käme Exception 2 von einem antwortenden Gerät.
  Vollständige Stille passt zu LGAP, dem LG-eigenen Protokoll — dort bekommt
  ein Modbus-Master nie eine Antwort, gleich welche Adresse oder Baudrate.
- **Adern vertauscht ergibt Nullbytes, nicht Antworten:** ein einzelnes `00` je
  Anfrage, und die Aktivitäts-LED leuchtet dauerhaft statt zu blinken. Bei
  richtiger Belegung blinkt sie.
- **Geräteidentifikation** über FC 17 (Report Slave ID) und FC 43 (Device
  Identification, alle drei Ebenen) wird ignoriert — keine Antwort, nicht einmal
  eine Ausnahme.
- **Installateurmenü → Konnektivität → Energiezustand → ESS-Nutzungstyp auf
  „Modbus"** umgestellt und neu gestartet: der Registerraum bleibt exakt gleich.

## Der belegte Weg zu Betriebsmodus und Heizkreis 2

Über diesen Anschluss gibt es sie nicht. Wer sie über Modbus braucht, braucht
das **LG-Gateway PMBUSB00A** — CH1 als Modbus-Slave mit 9600, CH2 zur
Außeneinheit, Therma V in der Kompatibilitätsliste, dreistelliger Betrag.

Die Alternative ohne Protokollarbeit ist **SG-Ready über zwei Kontakte**.

## Kniff für weitere Kartierung

Das Bedienteil zeigt dieselben **Rohwerte** wie der Modbus. „Kältemittel 12000"
am Display ist wörtlich der Rohwert aus IR13. Damit lässt sich durch bloßes
Ablesen zuordnen — vorausgesetzt, `force_new_range` ist gesetzt, sonst ordnet
man verschobene Werte zu.
