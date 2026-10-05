# LG Therma V over Modbus RTU in Home Assistant

A complete ESPHome configuration for the **LG Therma V R290 Monobloc**,
connected over Modbus RTU with an ESP32 — no LG gateway, no cloud.

It contains not just the ESP32 firmware but also what costs the most time when
reproducing it: an empirically verified
[register map](docs/register-map.md), the documented dead ends, and the
tools for narrowing down the open registers further.

The firmware is designed as the heat pump for [HEMS](https://github.com/ComicSans/hahems),
the PV and energy manager for Home Assistant from the same author, but also runs
without it (see [As the heat pump role in HEMS](#as-the-heat-pump-role-in-hems)).

## Measured on exactly this unit

| | |
|---|---|
| **Hydro unit** | HN1639HC.NK0 |
| **Refrigerant** | R290 (propane) |
| **Unit firmware** | **3.07.2a** (shown on the control panel under Information) |
| **Connection** | Terminal Block 2, terminal 21 (A) / 22 (B) |
| **Bus** | Modbus RTU, slave 1, 9600 baud, 8N1 |

> **This unit speaks its own register layout.** None of the
> published maps fits — not even with an offset. Whether the layout looks the
> same on another model or firmware version is **open**. The
> register map gives the evidence for every point — anyone reproducing this can
> cross-check instead of trusting. The first step is an address scan; it
> writes nothing.

## What you get

**Reading** — 38 responding data points: flow, return, hot water, room,
outdoor temperature, suction gas, high and low pressure, apparent power, operating mode.
The outdoor temperature comes from the unit's own sensor in the sunlit housing and reads
up to 13 K too high at standstill — derived calculations need an
independent sensor alongside it.

**Control** — operating mode (off / cool / heat / auto), silent mode,
hot water enable, hot water and heating circuit setpoints. Plus a
climate entity in the firmware, ready to wire directly to an energy manager.

**Calculated** — evaporating and condensing temperature from the
propane vapour pressure curve, suction superheat, temperature lift,
compression ratio, Carnot limit, heat transfer at both
heat exchangers, flow/return delta.

**Statistics** — compressor starts per day, mean and shortest cycle length,
operating hours, hot water charges, energy per kelvin of tank lift. All
interpreted values carry a state class and therefore go into
long-term statistics; the daily counters as `total_increasing`, because their reset at
midnight is correctly treated there as a new cycle.

**Bus health** — time since last response, cycle duration, registers without
response, missed cycles, plus a safeguard against overly long
polling gaps. Summarised into one verdict: `good` / `degraded` / `faulty`.

**Diagnostics** — ten indicators: frost risk, standstill, short cycling, pressure (`ok` /
`too high` / `too low`), refrigerant circuit, heat transfer, bus health,
wear, flow/return delta, and the measurement-error suspicion "Temperatures Identical".
Plus a summary text sensor that shows everything pending in one line. Every
indicator has two thresholds so it does not flap at the limit; the
circuit indicators additionally have a five-minute start-up grace period.

**Wear and efficiency** — daily mean flow/return delta under load,
runtime share, starts per operating hour, and an `Efficiency Hint` in
plain language: throttle the circulation pump, check the flow rate, longer cycles,
lower the temperature lift. Phrased qualitatively, not in percent — the
pump curve is not known here, a number would be false precision. The
thresholds come from the heat pump analysis of the HEMS project, which has been
dropped there.

Diagnostics and assessment run **in the firmware, not as templates in Home
Assistant**: they have to be there even when Home Assistant restarts or
someone moves the templates, and the ESP has all input values in
memory anyway.

**Mapping tools** — register observation, reference-state comparison and
two address scanners for identifying open registers **without writing**.
The slow one-by-one polling finds registers that a block-wise scan
misses.

## What does not work

The following are **not** reachable over this connection, each checked individually: heating circuit 2
in any form, circuit 2 pump, mixing circuit, water pressure, **water flow rate**. No
backup heater is installed in this system.

**No flow rate, no COP.** Without the volume flow there is no thermal
output — neither a COP nor a datasheet comparison against the performance curve.
As a substitute, energy per kelvin of tank lift serves; with a constant
tank volume it is comparable over time. Anyone who wants the COP needs their
own flow sensor in the heating circuit.

**The system's error code is not in any register.** On 01.08.2026 the
control panel showed CH03 — communication error between control panel and main board —
and the system stood still for 76 minutes while Modbus kept answering
without a gap. The diagnostic indicators therefore depend on the **effect** of a fault,
not on the code. That way they work against any fault that stops the system, not
only against the one with the known code.

Anyone who needs **heating circuit 2** cannot go further here: the way is
via the LG gateway PMBUSB00A or via SG-Ready with two contacts.

## Hardware

- **Waveshare ESP32-S3-RS485-CAN**, powered by a USB power supply
- Wire pair on **terminal 21 (A) and 22 (B)**, Terminal Block 2
- **DIP SW1-1 ON, SW1-2 OFF** (the switch is only read at boot)

Three details decide whether a single byte flows at all — a missing
`flow_control_pin`, wires on terminal 28/29 instead of 21/22, and slave address 33 from
the control panel menu instead of 1. All three are described with reasons in
[docs/hardware.md](docs/hardware.md). **Read before connecting.**

## Installation

Requires **ESPHome 2026.9.0 or newer**; older versions reject the
configuration (`min_version`).

```bash
git clone https://github.com/ComicSans/lg-therma-v-esphome-modbus
cd lg-therma-v-esphome-modbus
cp secrets.yaml.example secrets.yaml
# fill in secrets.yaml (see below), then:
esphome run therma-v.yaml
```

`secrets.yaml` needs five entries (template: `secrets.yaml.example`):

| Entry | Content |
|---|---|
| `wifi_ssid`, `wifi_password` | Wi-Fi |
| `ap_password` | Fallback AP, a separate password |
| `api_key` | API encryption, `openssl rand -base64 32`; Home Assistant asks for it when adding the device |
| `ota_password` | Firmware updates over Wi-Fi |

Anyone coming from a version before `v2026.10` adds `api_key` and
`ota_password`. After the first flash Home Assistant drops the connection and
asks for the key; this flash still goes through without an OTA password.
Anyone coming from a version before the English release (`v2026.11`) must
additionally rename all five keys in their `secrets.yaml` and follow
[docs/migration/README.md](docs/migration/README.md) for the Home Assistant
entity IDs.

A full polling cycle takes about 22 seconds (38 individual requests of
about 590 ms each). Anyone adding more registers
must raise the `update_interval` accordingly.

`scripts/test.sh` validates the configuration and compiles the firmware without
flashing; deprecated ESPHome options and API count as errors.
`TEST_SKIP_COMPILE=1` skips the compile step.

### Adapting to your own installation

Two places in `therma-v.yaml` are installation-specific.

**1. The power meter.** The firmware reads three phases of a Shelly 3EM from Home
Assistant (`sensor.l1_power`, `sensor.l1_voltage`, `sensor.l1_current`, likewise
for L2 and L3), in W, V and A. Enter your own entity IDs there. Without a
three-phase meter, **leave the entries in place** — if you remove them, the
firmware no longer builds. They then stay without a value: active power, power factor
and phase imbalance are missing, and the compressor and statistics logic fall back to the
apparent power from IR23. A meter in kW instead of W skews the
compressor detection (thresholds 350/500 W). The same applies to the independent
outdoor temperature (`sensor.aussentemperatur`); without it the firmware uses
the unit's own sensor.

**2. The device name in Home Assistant** determines the prefix of all entity IDs.
A fresh installation produces `lg_therma_v_heatpump_` (from
`friendly_name`); the dashboard uses `heizungskeller_warmepumpe_modbus_`, the
name of the original installation. Replace it with:

```bash
sed -i 's/heizungskeller_warmepumpe_modbus_/lg_therma_v_heatpump_/g' home-assistant/dashboard-waermepumpe.yaml
```

### Dashboard

[home-assistant/dashboard-waermepumpe.yaml](home-assistant/dashboard-waermepumpe.yaml)
is the Lovelace view of the original installation: operation, refrigerant circuit, power,
wear, bus health, mapping and control. Add it via the dashboard's
raw configuration editor. Some cards use entities that do
not come from this firmware (HEMS metrics `sensor.wp_*`, an
efficiency device `*generisch_luft_wasser_*`); elsewhere they show "unavailable"
and can be deleted.

## As the heat pump role in HEMS

The entities of this firmware map directly onto the roles of
[HEMS](https://github.com/ComicSans/hahems), a PV and
energy manager for Home Assistant:

| HEMS role | Field | Entity from this firmware |
|---|---|---|
| Heating circuit | Control entity | Operating Mode select (HR26) |
| Heating circuit | Flow setpoint number | Heating Circuit 1 Setpoint (HR24) |
| Heating circuit | Silent operation switch | Silent Mode (coil 2) |
| Hot water | Control entity | Hot Water Enable (coil 6) |
| Hot water | Setpoint number | Hot Water Setpoint (HR29) |

The select's mode options must be entered in HEMS **exactly**
as they are named here — upper and lower case matter. The climate entity
is **not** suitable as a control entity: it shows the system's mode and sets
the setpoint, but only switches off, never on.

For the HEMS role **heat pump analysis** this firmware supplies four of the five
required values: flow (IR16), return (IR15), electrical power (from the
Shelly, not from IR23 — that is apparent power) and outdoor temperature. The
flow rate is missing (see [What does not work](#what-does-not-work)).

> **What HR24 means depends on the control type set on the control panel** — flow,
> return or room, settable separately per operating mode and not readable
> over Modbus. On this system: **flow when heating, return when cooling.**
> In cooling mode, 21 °C on HR24 therefore means a return setpoint; the flow
> drops to about 15 °C. Anyone applying flow logic runs
> the system considerably colder than the number suggests.
>
> **In auto mode (HR26 = 3) HR24 is not a temperature at all**, but the
> heating curve shift: 19 = 0, 20 = +1, 18 = −1, range 16..22. For this
> there is the entity **Heating Curve Shift** (−3..+3), which is unknown outside
> auto mode. The flow number keeps showing its
> 19 °C there — anyone setting it as a setpoint is actually shifting the curve.
>
> An energy manager that writes HR24 must therefore also read the mode and
> know the control type — it cannot query it.

## Caution with coil 5

Coil 5 responds, but its meaning is open. A write attempt had no
visible effect — but without recording **what the bus answered**,
and that is the whole difference. Reading back 0 proves nothing:
that is exactly how an edge-triggered bit behaves that executes its action and
resets itself.

In the official LG map, neighbouring positions hold emergency stop,
emergency operation and the disinfection cycle, which heats the tank to about
70 °C for hours. That map does not apply to this unit, so this is no evidence —
but reason enough to identify passively first. That is what register observation
and reference-state comparison are for.

## Documentation

- [docs/register-map.md](docs/register-map.md) — all 38 points with evidence,
  open points, measurement windows and analysis pitfalls
- [docs/hardware.md](docs/hardware.md) — connection, DIP switches, bus load,
  dead ends

## Related projects

- [**HEMS**](https://github.com/ComicSans/hahems) — PV and energy manager for
  Home Assistant. Controls this heat pump via operating mode, setpoints,
  silent mode and hot water enable; the role mapping is
  [above](#as-the-heat-pump-role-in-hems).

## Contributing

Contributions are welcome — especially measurements on **other
Therma V series** and **other firmware versions**. The most interesting open
question is whether the register layout found here depends on the model, on the firmware or
on both.

What makes a report useful: model number of the hydro unit, firmware version
from the control panel, the output of the **Wide Register Scan** button, and for every
interpreted register the evidence — a value read on the control panel in the same
minute, or an edge that coincides with an observable event.
A mapping without evidence is a guess, and there are already enough of those
on the internet.

## Disclaimer

Use of this project is **at your own risk**. I accept
no liability whatsoever for damage to the heat pump, the heating system, the
building, or any other consequences arising from reproduction, configuration or operation
— to the extent permitted by law. Write access can change the
behaviour of the system, and an intervention can jeopardise warranty or
statutory guarantee claims against LG or the installer. Work
on the electrical installation belongs in the hands of a qualified electrician.

Use at your own risk. To the extent permitted by law, I accept no
liability for any damage or consequences resulting from the use of this
project.

## License

[MIT](LICENSE). The disclaimer supplements the license; it does not replace it.
