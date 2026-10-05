# Migrating to the English release (v2026.11)

From v2026.11 every entity name, select option, climate preset and secrets key
is English. ESPHome derives an entity's unique ID from its name, so Home
Assistant sees **new entities** after the flash. The old ones turn unavailable
and keep their history. This page is the upgrade path;
[`entities.json`](entities.json) is the complete machine-readable mapping
(104 entities, the operating-mode options, the climate preset, the secrets keys).

## Before the flash

1. **Back up Home Assistant.**
2. **Rename the keys in `secrets.yaml`** (values stay):
   `wlan_ssid` → `wifi_ssid`, `wlan_passwort` → `wifi_password`,
   `ap_passwort` → `ap_password`, `api_schluessel` → `api_key`,
   `ota_passwort` → `ota_password`.
3. **Find every reference** to the old entity IDs: dashboards, automations,
   scripts, templates, helpers, the energy dashboard, and anything else that
   controls the heat pump (e.g. HEMS). The old ID is
   `<domain>.<device prefix>_<old_object_id>`; the device prefix is the device
   name in Home Assistant.
4. **Plan a short window.** Between the flash and the updated references, a
   controller that writes the operating mode points at an entity that no longer
   exists, and the select options changed: `Aus / nur Warmwasser` → `Off / Hot
   Water Only`, `Kühlen` → `Cool`, `Heizen` → `Heat`, `Auto` stays.

## Keeping the history

Home Assistant moves recorded history and long-term statistics with an entity
ID when the ID is renamed. Candidate procedure per entity — **test it on one
unimportant entity first** (e.g. `IR09 Kennwert` → `IR09 Constant`) and check
that history and statistics are continuous before doing the rest:

1. Before the flash, rename the old entity ID to the new one
   (`…_ir09_kennwert` → `…_ir09_constant`). History moves with it.
2. Flash. The new entity cannot take its ID, which is still held by the old
   registry entry, so Home Assistant registers it as `…_ir09_constant_2`.
3. Delete the old, now unavailable entity from the registry. Recorded states
   are not deleted with it.
4. Rename `…_ir09_constant_2` to `…_ir09_constant`. New states continue under
   the existing history; the few minutes recorded under `_2` stay behind.

If the test shows a gap or duplicate statistics, stop and adjust before
migrating the other 103 entities.

## After the flash

- Update dashboards, automations, scripts and controllers to the new IDs and
  option strings.
- Climate preset `Anlage` is now `Unit`.
- Check: no unavailable entities of this device remain, the operating mode can
  be set, and history is continuous for a few sampled entities.
