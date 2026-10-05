# Hardware and connection

## Material

- **Waveshare ESP32-S3-RS485-CAN** (other RS485 boards work, see
  `flow_control_pin`)
- short wire pair, USB power supply
- ESPHome ≥ 2026.9.0

## Connection

**Terminal 21 = A, terminal 22 = B**, Terminal Block 2 („3rd Party Controller,
5 V DC").

> **Trap:** terminal 28/29 is also labelled A/B, but leads to the
> outdoor unit. Nothing answers there.

## DIP switches

**SW1-1 ON, SW1-2 OFF.** The switch is only read at boot; the
indoor unit must be powered down.

- **SW1-2 ON** („offenes Protokoll" (open protocol) according to the manual, the setting of the official
  LG map): the unit stays silent. 247 addresses × six baud rates (4800–115200),
  measured four times, not a single byte.
- Only SW1-1 (master/slave), SW1-2 (open protocol) and
  SW1-8 (glycol) have a function, manual manualslib 1118948, p. 103. **Do not touch SW1-3.**
- Untested: SW2 block (bit 8 ON for third-party thermostats).

## Without these three points the bus stays silent

**1. `flow_control_pin` is mandatory.** The board's RS485 driver does not switch
direction by itself.

```yaml
uart:
  tx_pin: GPIO17
  rx_pin: GPIO18
  flow_control_pin: GPIO21
```

**2. Slave address 1.** The control panel may show 33 (0x21) as the
central address; on this connection only 1 works.

**3. `reuse_previous_range: false` on every register** (up to ESPHome 2026.8
`force_new_range: true`). Otherwise block grouping shifts values between
neighbouring registers, see [register-map.md](register-map.md#analysis-pitfalls).

## Bus load

Measured with 34 individual requests: about **20 s per cycle**, roughly 590 ms per request
(wire time ~15 ms). With today's 38 requests it is about 22 s, so with
`update_interval: 30s` three quarters continuous load, so far without a timeout. **Anyone adding registers must raise the interval.**

## Dead ends

- **TCP bridge** (`stream_server`): sends, never receives, because the
  direction switching does not know the end of the frame. Negative tests with it
  prove nothing either.
- **Line of the LG cloud gateway:** no Modbus. Complete silence instead of
  exception 2 fits LGAP, LG's proprietary protocol.
- **Wires swapped:** one `00` per request, activity LED stays lit continuously
  instead of blinking.
- **Device identification** (FC 17, FC 43 all levels): no response, no
  exception.
- **Installateurmenü → Konnektivität → Energiezustand → ESS-Nutzungstyp
  „Modbus"** (installer menu → connectivity → energy state → ESS usage type): register space unchanged.

## Heating circuit 2

Not reachable over this connection. Options:

- **LG gateway PMBUSB00A**: CH1 as Modbus slave (9600), CH2 to the outdoor unit,
  Therma V on the compatibility list, three-digit price.
- **SG-Ready** via two contacts, without protocol work.

## Mapping by reading the panel

The control panel shows the same raw values as the bus („Kältemittel 12000" (refrigerant 12000) = IR13).
Reading them off assigns registers, provided each register is polled individually.
