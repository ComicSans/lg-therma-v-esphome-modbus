# Register map

Measured on an **LG Therma V R290 Monobloc, hydro unit HN1639HC.NK0,
unit firmware 3.07.2a**, Modbus RTU via terminals 21/22, slave 1, 9600 baud.
Model and firmware version are the two variables that can change the
assignment; only one version is covered here.

In this map, **generation** means a version of the ESPHome register list,
not the unit's firmware version. The request grouping changes with every
generation (see [pitfalls](#analysis-pitfalls)).

## Register space

No published map fits, not even with an offset: neither the Therma V manual
(pp. 262–264) nor the model manual (pp. 181–182), the LG slide "Open MODBUS" or
the basti242 wiki. Everything except the following **38 points** returns
exception 2 (illegal data address):

| Type | Addresses | Count |
|---|---|---|
| Input register (FC 4) | 9–27 | 19 |
| Holding register (FC 3) | 24–29 | 6 |
| Discrete input (FC 2) | 6, 7, 8, 9, 31, 32 | 6 |
| Coil (FC 1) | 2, 3, 4, 5, 6, 29, 30 | 7 |

From the official map, CO2 (silent mode) holds. Coil 0 (on/off), holding 0
(operating mode) and holding 9 (energy state/SG Ready) are not reachable; the
operating mode is on HR26.

**Group scans miss registers.** The first scan over all 65536 addresses per
type read in groups of four and found 32 points. If a group contains a missing
register, the unit rejects the whole group. Of the seven coils, it reported only
CO5 and CO6. DI32, CO2, CO3, CO4, CO29 and CO30 were added only by individual
reads ("Check Edge Registers", "Wide Register Scan").

**Addresses 0–1023 are checked individually**, in all four types (4096 reads,
30.07. and 01.08.2026). From address 64 upward there was no hit; all 38 points
lie below 32. From 1024 upward only the group scan exists. Checking those
individually would mean around 136 hours of continuous load at 8 requests per
15 s.

A wide scan raises the poll-cycle duration from 19.5 to 30–35 s. The firmware
pauses it at 70 % of the configured bus-gap limit. Over fifteen runs: no
register without response, no missed poll cycle. An additional, separate 30 s
threshold aborted a healthy run after 112 of 256 requests.

## Evidenced assignments

| Point | Meaning | Scaling | Evidence |
|---|---|---|---|
| IR11 = IR19 | **Outdoor heat exchanger** (condenser in cooling, evaporator in heating) | ×0.1 | sits on the matching saturation temperature for each operating direction, [see below](#ir11-and-ir19-outdoor-heat-exchanger) |
| IR12 | Outdoor temperature **of the unit** | ×0.1 | 305 at 30 °C on the control panel. Sensor in the sun-exposed housing: against three independent sensors ±0 K at night at standstill, +7.9 K by day at standstill (max. +12.9 K), +3.9 K with the fan running. At fan start −8 K, while all three sensors rose |
| IR15 | Water return | ×0.1 | flow > return in heating, the reverse in cooling |
| IR16 | Water flow | ×0.1 | ditto |
| IR17 | Suction gas temperature | ×0.1 | superheat against IR22: 5–8 K at standstill, 1.2 K median with the compressor running (533 values, 30.07.–02.08.). The instantaneous value swings from −6.7 to +8.8 K; only the moving median is usable |
| IR18 | **Compressor shell, high-pressure side** | ×0.1, effectively 1 K | [see below](#ir18-compressor-shell) |
| IR20 | **Compressor speed** (unit open, Hz likely) | — | [see below](#ir20-speed) |
| IR21 | High pressure (gauge) | ×0.01 bar | during hot water, the saturation temperature matches the flow to < 1.5 K, seven points monotonic; shifted about 1 K in one direction, [see below](#ir21-condensing-temperature-and-flow) |
| IR22 | Low pressure | ×0.01 bar | ≈ IR21 at standstill (pressure equalization), far below it during operation |
| IR23 | **Apparent power** | VA | [see below](#ir23-apparent-power) |
| IR24 | Room temperature | ×0.1 | 205 at "innen 20,5" (indoor 20.5) |
| IR25 | Hot water temperature | ×0.1 | 506 at 50.6 °C on the control panel |
| IR26 | Heat demand: 0 none, 1 ready, 2 requested | — | dropped from 2 to 0 when the hot water enable was switched off, HR26 stayed unchanged |
| HR24 | Heating circuit 1 setpoint, **writable** | ×0.1 | [see below](#hr24-setpoint) |
| HR26 | **Operating mode, writable** | — | [see below](#hr26-operating-mode) |
| HR29 | Hot water setpoint, **writable**, 30–60 °C as on the control panel | ×0.1 | 480 at "Warmwasser 48° eco" (hot water 48° eco), followed changes live |
| CO2 | **Silent mode, switchable** | — | four changes matching the panel operation to the second, no other point moved with them |
| CO3 | Outdoor unit running | — | around 20 edges match the compressor-running signal (Shelly active power, not circular) |
| CO4 | Heating circuit 1 active | — | two changes simultaneous with HC1. **Read only**: in the official LG map this address is emergency stop/emergency operation |
| CO6 | Hot water enable, **switchable** | — | switches hot-water production |
| DI07 | Three-minute restart lock | — | [see below](#di07-restart-lock) |
| DI08 | Top compressor stage, ≡ IR20 = 60 | — | [see below](#di08-top-stage) |
| DI09 | Hot-water production | — | covers two hot-water charges; stayed off during the cooling cycles of 31.07., even though the tank temperature fluctuated strongly |
| DI31 | Heating circuit 1, inverted to CO4 | — | on when HC1 is off |

### HR26: operating mode

Switched on the control panel, all four values evidenced with timestamps:

| Value | Mode | Evidence |
|---|---|---|
| 0 | Off / Hot Water Only | when HC1 was switched off |
| 1 | Cool | HR24 stayed at 21 °C |
| 2 | Heat | HR24 jumped to 55 °C at the same time |
| 3 | Auto | in automatic operation |

HR26 is written through the select (HEMS, climate entity). So far the control
mode has stayed unchanged across mode changes; in jourdant/esphome-lgap issue 24
(LGAP interface), a mode change switched it to the room sensor. Check it on the
control panel now and then after changes.

Switching off HC1 is reproducibly staggered: **CO4, after 3 s HR26 = 0, after
another 10 s DI31.** At a 20 s poll interval the order is real.

### HR24: setpoint

HR24 is readable in every mode and follows the system (21 °C cooling, 55 °C
heating). Which quantity it refers to is set by the **control mode on the
control panel**: flow, return or room, separately per mode. Here: flow in
heating, return in cooling. The control mode is not exposed over Modbus.

**In Auto mode (HR26 = 3), HR24 is a curve shift:** 16..22 corresponds to
−3..+3, 19 = 0. The firmware exposes this as the entity "Heating Curve Shift"
(unknown outside Auto). The number "Heating Circuit 1 Setpoint" keeps 5..65,
because `min_value`/`max_value` cannot be switched at runtime; in Auto mode it
shows 19 °C.

> **Source:** reported by the operator (02.08.2026), not measured on the bus.
> **Open cross-check:** in Auto mode, shift the curve to +3; HR24 must show
> 220.

### IR23: apparent power

Against a Shelly 3EM over 27 points of one hot-water charge:

```
IR23 / apparent power = 0.907 .. 0.984   (median 0.946)   <- constant
IR23 / active power   = 1.179 .. 1.360                    <- noisy
```

Over the same period, the power factor rose from 0.709 to 0.790. An offset of
around −5 % remains open. **At standstill the value is not a measurement**: it
parks at 417, while the meter sees around 180 VA.

### IR21: condensing temperature and flow

Over 622 hot-water minutes, the calculated condensing temperature lies a median
0.6 K **below** the flow (71.4 % of minutes), which is physically impossible. It
is not a read-timing offset; the effect is largest at rest:

| Flow | n | Median | Share negative |
|---|---|---|---|
| steady (< 0.2 K/min) | 157 | −0.98 K | 98.1 % |
| rising (> 0.3 K/min) | 438 | −0.15 K | 61.4 % |

One third of the cause: the propane table in `therma-v.yaml` was too high
against CoolProp from 45 °C upward (up to 0.17 bar at 65 °C, corresponding to
−0.2 to −0.4 K). Linear interpolation (−0.01 to −0.05 K) and the offset of 1.0
instead of 1.013 bar (−0.03 K) are negligible. The remaining 0.6 K lie within
the tolerance of the flow sensor and the pressure transducer.

| °C | old | CoolProp | Error |
|---|---|---|---|
| 45 | 15.40 | 15.34 | −0.17 K |
| 50 | 17.20 | 17.13 | −0.18 K |
| 55 | 19.20 | 19.07 | −0.32 K |
| 60 | 21.30 | 21.17 | −0.30 K |
| 65 | 23.60 | 23.43 | −0.36 K |
| 70 | 26.00 | 25.87 | −0.26 K |

> **Corrected and flashed on 16.08.2026, 10:57.** Cross-check: 16.18 bar →
> 50.13 °C instead of 49.94 °C (+0.19 K, as calculated). Condensing temperature
> and temperature lift therefore jump by +0.2 to +0.4 K, evaporating temperature
> and superheat by ≤ 0.1 K. All condensing figures in this map date from before
> (IR11 +0.7 K, IR18 10–16 K, condensing 14.8 K above return in cooling).

### IR11 and IR19: outdoor heat exchanger

The separator is the sign against the saturation temperatures from IR21/IR22
(calculated from the pressures, not circular):

| State | IR11 − unit sensor | IR11 − condensing | IR11 − evaporating |
|---|---|---|---|
| Cooling, compressor (1672 min) | +5.2 K | **+0.7 K** (p10 −0.0 / p90 +1.9) | +22.0 K |
| Hot water (622 min) | −7.8 K | −39.2 K | **+5.2 K** (p10 +1.9 / p90 +11.0) |
| Standstill (6326 min) | +1.7 K | — | — |

IR19 mirrors IR11: 85.8 % exactly equal, 95 % within 0.5 K in a ±35 s window.
The deviation is one sampling step (in cooling, IR11 changes by 0.5 K per poll
cycle).

### IR18: compressor shell

Over 2294 minutes of compressor operation:

```
r(IR18, high pressure)           = +0.959
r(IR18, condensing temperature)  = +0.958
r(IR18, compression ratio)       = +0.910
r(IR18, active power)            = +0.689
r(IR18, evaporating temperature) = −0.122
```

| Mode | Active power | IR18 | Condensing | Difference |
|---|---|---|---|---|
| Cooling | 1500–2000 W | 51 °C | 37.4 °C | +12.2 K |
| Hot water | 1500–2000 W | 72 °C | 60.3 °C | +11.5 K |
| Cooling | 2600–3200 W | 58 °C | 41.6 °C | +16.5 K |

- **Not a heat sink:** at twice the power, IR18 is 14 K colder than during hot
  water.
- **Not hot gas:** after a stop from cooling operation, IR18 falls only 2–5 K in
  30 min and holds a plateau 10–18 K above the unit sensor (60 stops). After a
  hot-water charge it falls 20–40 K.

While running, IR18 stays a constant 10–16 K above the condensing temperature;
at standstill it retains the heat: the shell of the high-pressure side. Despite
`multiply: 0.1`, only whole kelvin. Range 33–78 °C.

### IR20: speed

| Mode | IR20 | Active power | W per unit | Pressure ratio |
|---|---|---|---|---|
| Cooling | 15 | 660 W | 44.0 | 1.75 |
| Cooling | 30 | 1351 W | 45.0 | 1.99 |
| Cooling | 42 | 2070 W | 49.3 | 2.28 |
| Cooling | 60 | 3013 W | 50.2 | 2.29 |
| Hot water | 20 | 1690 W | 84.5 | 3.07 |
| Hot water | 36 | 2267 W | 63.0 | 2.92 |

**IR20 = 20 draws 1690 W during hot water, IR20 = 30 draws 1351 W in cooling.**
A power scale cannot do that. Fit over 1072 stable minutes:
`W / IR20 = 25.5 · pressure ratio + 0.6` (r = 0.932), i.e. power ∝ IR20 ×
pressure ratio. The r rests on two clusters (n = 590 around 1.75, n = 166
above 3.0). Range 15–60 with a hard stop at exactly 60 (859 values: 60 27 times,
59 once, 58 twice). Not the expansion valve: constant for 26 min while the
superheat drifted from 0.6 to 6.3 K.

The entity is now named "Compressor Speed".

### DI08: top stage

DI08 is IR20 = 60. Over 56 cycles (07.–16.08.2026):

| | Cycles | IR20max min | IR20max max |
|---|---|---|---|
| with DI08 | 22 | 60 | 60 |
| without DI08 | 34 | 0 | 55 |

At pulse level: 27 phases of IR20 = 60 against 27 DI08 pulses, none without a
counterpart, equal duration in 21 pairs (±1 poll cycle). The offset is
exclusively −14 s or +16 s: both registers are read 14 s apart within the same
30 s poll cycle. This gave rise to the earlier interpretations "start-up" and
"threshold ≥ 42".

DI08 carries nothing that is not already in IR20. It stays included as
independent confirmation, under its old name "Compressor Top Stage".

### DI07: restart lock

Rests at `on` and drops after every end of operation. 133 drop phases in two
windows (02.–16.08.2026): **125 times exactly 180 s**; seven times 210 s (one
poll cycle of sampling), once 360 s.

## Unassigned, but narrowed down

Over 9.34 days (07.–16.08.2026) without any change: IR09, IR10, IR13, IR27,
HR25, HR27, HR28, DI06, DI32, CO5, CO29, CO30.

| Point | Status |
|---|---|
| IR09 | constant 19, a fixed parameter |
| IR13 | constant 12000; the control panel shows the same raw value under "Kältemittel" (refrigerant) |
| IR14 | water temperature between flow and return, [see below](#ir14) |
| IR10 = DI32 | the same state, [see below](#ir10--di32) |
| IR27, HR25, HR27, HR28 | constant 0, even under full load (3013 W) and over 19 hot-water charges |
| DI06 | no edge in cooling (3268 min), during hot water (682 min) or in August. Room-heating operation remains |
| CO5 | meaning open, [warning](#warning-about-coil-5) |
| CO29, CO30 | constantly `off` across all measurement series. Read only, like CO5 |

### IR14

When the compressor stops, the condensing temperature collapses within seconds;
the water does not. Over 23 stops (31.07.–01.08.), IR14 followed the water 16
times and the refrigerant never; seven could not be separated. Example 31.07.
20:55:31: condensing −16.1 K, flow +5.1 K, IR14 ±0.0 K.

IR14 lies between flow and return and leans towards the return:

| Situation | IR14 − flow | IR14 − return |
|---|---|---|
| Cooling, compressor (1672 min) | +0.4 K | −2.8 K |
| Hot water (622 min) | −1.7 K | +3.6 K |
| Standstill (6326 min) | +0.4 K | +0.4 K |

The first measurement series (31.07.–01.08.) showed +2.4 K to the flow in
cooling, otherwise the same direction. IR14 is noisier than both sensors
(5.0 K/min against 1.3 and 0.4 K/min) and ranges from 8.1 to 68.3 °C. Not the
backup heater: 151 while the control panel showed 174–181.

### IR10 = DI32

Over 3264 minutes (30.07.–01.08.):

```
IR10 \ DI32      off      on
   0            3183       0
  14               1      81
```

The deviation is sampling (edge pairs 1–25 s apart). What is evidenced is
simultaneity, not equality of values; so far IR10 has shown only 0 and 14.

Occurred twice (59 and 21 min), each time with HR26 = 0, CO4 off, DI31 on,
< 15 W, 1–6 s after DI31. **Not "system off":** a 456 min shutdown with the same
register state did not trigger it. The difference: that one was shut down from
compressor operation (1215 W), the others from pump operation (96 W). Too few
cases for an interpretation.

## Not exposed at all

Each checked on the control panel and not found in the register space: heating
circuit 2, circuit 2 pump, 3-way valve as a state, mixing circuit, water
pressure, **water flow rate**, backup heater operation, error code.
Configuration on the control panel (including the control mode) is invisible;
only physical quantities and the main setpoints are mirrored. No flow rate, no
COP.

## Measurement windows

| Window | Duration | Generation | Poll cycle |
|---|---|---|---|
| 30.07.–02.08.2026 | 2.3 days | — | 19.5–20 s |
| 02.08. 18:24 – 08.08. 18:11 | 8622 min | one | 30.0 s |
| 07.08. 00:00 – 16.08. 08:13 | 9.34 days, 26591 poll cycles | the same as before | 30.0 s |

- Durations in seconds from the 20 s regime are not comparable with those from
  the 30 s regime; a duration there carries ±30 s.
- In August, HR26 stayed at 3 (Auto) throughout, CO4 on, DI31 off. There is no
  flow setpoint and no room-heating operation in this data.
- Bus in August: first window without a missed poll cycle. Second window with
  four gaps (3 × 90 s, 1 × 120 s, 0.05 % in total).
- Two aborted compressor starts of one poll cycle each (03.08. 01:52, 912 W;
  08.08. 10:27, 574 W), independently evidenced by Shelly, CO3 and IR20. They
  count as 0.5 min cycles in "Shortest Cycle Today".
- The recorder does not reach back before 07.08.; the first August window cannot
  be recomputed.
- CO3 and DI08 were renamed on 31.07.; their findings from July rest on
  28 hours.

## Analysis pitfalls

**1. Request grouping shifts values.** ESPHome merges adjacent registers into
one request; the grouping changes with every generation. Share of impossible
IR11 values (> 120 °C) over seven generations within one day:

| Generation | 1 | 2 | 3 | 4 | 5 | 6 | 7 (individual) |
|---|---|---|---|---|---|---|---|
| > 120 °C | 0 % | 0 % | 100 % | 100 % | 100 % | 8.9 % | 0 % |

In one of generations 3–5, the misassignment "IR11 = hot gas" arose from
comparing readings with the control panel. That is why every register carries
`reuse_previous_range: false` (`force_new_range: true` up to ESPHome 2026.8).

**2. Analyze time series only within one generation.** Otherwise they mix
artifacts and produce convincing, meaningless correlations. That is why
unassigned points carry **no `state_class`** (IR09, IR10, IR27, HR25, HR27,
HR28, Operating Mode Raw, IR13 Refrigerant Constant, the two observation
sensors). Whoever interprets a point assigns one and thereby fixes from when on
the history counts. IR11, IR18, IR19 and IR20 already had it before; they can be
analyzed from the flash on 02.08.2026 18:24 onward.

**3. Home Assistant restarts are not gaps.** All entities briefly go
`unavailable` together while the ESP keeps polling. The firmware's poll-cycle
series is authoritative. Example: a DI07 phase on 12.08. appeared in the history
as 44 s + 135 s (44 + 1 + 135 = 180).

**4. Do not analyze on a minute grid.** Half of the DI08 pulses last one 30 s
poll cycle and vanish in the grid.

## Warning about coil 5

Coil 5 responds. A write attempt had no visible effect, but the bus response
was not recorded:

- Exception → not writable
- Acknowledged, immediate read-back 0 → value discarded, **or** an
  edge-triggered bit that executed and reset itself
- Acknowledged, read-back stays 1, no effect → a precondition is missing

In the official LG map, the neighboring addresses hold emergency stop,
emergency operation and the disinfection cycle (tank at around 70 °C for
hours). That map does not apply here, so it is no evidence. Identify passively
first: "Register Observation" and "Compare with Reference".
