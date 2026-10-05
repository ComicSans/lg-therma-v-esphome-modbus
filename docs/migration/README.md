# Migrating to the English release (v2026.11)

From v2026.11 every entity name, select option, climate preset and secrets key
is English. ESPHome derives an entity's unique ID from its name, so Home
Assistant sees **new entities** after the flash. Without the steps below, the
old entities are removed (or turn unavailable) and the new ones start without
history.
[`entities.json`](entities.json) is the complete machine-readable mapping
(104 entities, the operating-mode options, the climate preset, the secrets keys).

The procedure below was verified on the original installation (Home Assistant
2026.9, all 104 entities): history and long-term statistics continued under the
new IDs.

## Steps

1. **Back up Home Assistant.**
2. **Rename the keys in `secrets.yaml`** (values stay):
   `wlan_ssid` → `wifi_ssid`, `wlan_passwort` → `wifi_password`,
   `ap_passwort` → `ap_password`, `api_schluessel` → `api_key`,
   `ota_passwort` → `ota_password`. If there is no `api_schluessel` (release
   before v2026.10), add `api_key` with a new key (`openssl rand -base64 32`)
   and an `ota_password`.
3. **Find every reference** to the old entity IDs and option strings:
   dashboards, automations, scripts, templates, helpers, the energy dashboard,
   and anything else that controls the heat pump (e.g. HEMS). The old ID is
   `<domain>.<device prefix>_<old_object_id>`; the device prefix is the device
   name in Home Assistant.
4. **Note the values of the settings** (`number` entities such as Observation
   Threshold or Max Bus Gap). Values kept with `restore_value` are stored per
   entity or global ID in the device's flash; renamed ones start from their
   initial values once and need to be set again. The same applies to the
   operating statistics kept on the device (Compressor Operating Hours, daily
   starts and hot water charges, delta T statistics, Bus Silence Minutes): they
   restart from zero
   and cannot be set. Note the current Operating Hours if you need them; the
   long-term statistics in Home Assistant continue, as the sensor is
   `total_increasing`.
5. **Pause controllers** that write the heat pump (e.g. set HEMS to observe)
   until step 10.
6. **Rename every old entity ID to its new ID** (`…_ir09_kennwert` →
   `…_ir09_constant`, see `entities.json`), in the entity registry (UI, or the
   WebSocket command `config/entity_registry/update` with `new_entity_id`).
   History and statistics move with the ID.
7. **Update the references from step 3 to the new IDs.** IDs now work with both
   firmware versions. Option strings do not: they change at the flash
   (`Aus / nur Warmwasser` → `Off / Hot Water Only`, `Kühlen` → `Cool`,
   `Heizen` → `Heat`, `Auto` stays; climate preset `Anlage` → `Unit`). Either
   accept both strings for the window (e.g. `modus in ['Heat', 'Heizen']`) or
   switch them right after the flash.
8. **Flash.** Coming from a release before v2026.10 (no API encryption; the
   old `secrets.yaml` had no `api_schluessel`), Home Assistant asks for the
   API key (`api_key`); until it is entered, the device stays unavailable.
9. **Check the registry.** On reconnect the ESPHome integration removes the old
   registry entries itself (their unique IDs are no longer reported), and the
   new entities take the target IDs directly; new states continue the existing
   history. On the original installation the only gap was the reboot (about
   two minutes unavailable). If an entity ended up with a different ID (e.g. a
   `_2` suffix), delete the old entry if it is still there and rename the new
   one to the target ID; do it within a few minutes, before Home Assistant
   compiles statistics under the interim ID.
10. **Finish:** switch remaining option strings, re-enter the settings from
    step 4, resume the controllers, and check that no unavailable entities of
    this device remain, the operating mode can be set, and history is
    continuous for a few sampled entities.
