# Hardware und Anschluss

## Material

- **Waveshare ESP32-S3-RS485-CAN** (andere RS485-Boards gehen, siehe
  `flow_control_pin`)
- kurzes Adernpaar, USB-Netzteil
- ESPHome ≥ 2026.9.0

## Anschluss

**Klemme 21 = A, Klemme 22 = B**, Terminal Block 2 („3rd Party Controller,
5 V DC").

> **Falle:** Klemme 28/29 ist ebenfalls A/B beschriftet, führt aber zur
> Außeneinheit. Dort antwortet nichts.

## DIP-Schalter

**SW1-1 ON, SW1-2 OFF.** Der Schalter wird nur beim Booten gelesen; die
Inneneinheit muss stromlos gemacht werden.

- **SW1-2 ON** (laut Handbuch „offenes Protokoll", Stellung der offiziellen
  LG-Karte): Das Gerät schweigt. 247 Adressen × sechs Baudraten (4800–115200),
  viermal gemessen, kein Byte.
- Funktion haben nur SW1-1 (Meister/Sklave), SW1-2 (offenes Protokoll) und
  SW1-8 (Glykol), Handbuch manualslib 1118948, S. 103. **SW1-3 nicht anfassen.**
- Ungetestet: SW2-Block (Bit 8 ON für Drittanbieter-Thermostate).

## Ohne diese drei Punkte schweigt der Bus

**1. `flow_control_pin` ist Pflicht.** Der RS485-Treiber des Boards schaltet die
Richtung nicht selbst um.

```yaml
uart:
  tx_pin: GPIO17
  rx_pin: GPIO18
  flow_control_pin: GPIO21
```

**2. Slave-Adresse 1.** Das Bedienteil zeigt unter Umständen 33 (0x21) als
Zentraladresse; an diesem Anschluss funktioniert nur 1.

**3. `reuse_previous_range: false` an jedem Register** (bis ESPHome 2026.8
`force_new_range: true`). Sonst verschiebt die Blockbildung Werte zwischen
Nachbarregistern, siehe [registerkarte.md](registerkarte.md#fallstricke-bei-der-auswertung).

## Buslast

Gemessen mit 34 Einzelanfragen: rund **20 s je Zyklus**, etwa 590 ms je Anfrage
(Leitungszeit ~15 ms). Mit den heutigen 38 Anfragen sind es rund 22 s, bei
`update_interval: 30s` also drei Viertel Dauerlast, bisher ohne Timeout. **Wer Register ergänzt, muss das Intervall anheben.**

## Sackgassen

- **TCP-Brücke** (`stream_server`): sendet, empfängt nie, weil die
  Richtungsumschaltung das Frame-Ende nicht kennt. Auch negative Tests damit
  beweisen nichts.
- **Leitung des LG-Cloud-Gateways:** kein Modbus. Vollständige Stille statt
  Exception 2 passt zu LGAP, dem LG-eigenen Protokoll.
- **Adern vertauscht:** ein `00` je Anfrage, Aktivitäts-LED leuchtet dauerhaft
  statt zu blinken.
- **Geräteidentifikation** (FC 17, FC 43 alle Ebenen): keine Antwort, keine
  Exception.
- **Installateurmenü → Konnektivität → Energiezustand → ESS-Nutzungstyp
  „Modbus"**: Registerraum unverändert.

## Heizkreis 2

Über diesen Anschluss nicht erreichbar. Wege:

- **LG-Gateway PMBUSB00A**: CH1 als Modbus-Slave (9600), CH2 zur Außeneinheit,
  Therma V in der Kompatibilitätsliste, dreistelliger Betrag.
- **SG-Ready** über zwei Kontakte, ohne Protokollarbeit.

## Kartieren durch Ablesen

Das Bedienteil zeigt dieselben Rohwerte wie der Bus („Kältemittel 12000" = IR13).
Ablesen ordnet zu, sofern jedes Register einzeln abgefragt wird.
