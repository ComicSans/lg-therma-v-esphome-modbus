# CLAUDE.md

Regeln für Claude Code in diesem Repo. Aufbau, Verkabelung und Register stehen in
`README.md` und `docs/`.

## Was das ist

ESPHome-Konfiguration (`therma-v.yaml`) für die LG Therma V über Modbus RTU mit
einem ESP32, dazu Home-Assistant-Teile (`home-assistant/`). Das Repo ist öffentlich
(Ausnahme REMOTE in `~/GitHub/local-ci/ausnahmen.tsv`).

## Regeln

- `secrets.yaml` bleibt lokal und ignoriert; Änderungen an Schlüsseln nur in
  `secrets.yaml.example` mit Platzhaltern. Nie WLAN-, API- oder OTA-Schlüssel
  einchecken.
- Tests: `scripts/test.sh` prüft die Konfiguration mit `esphome config` (legt bei
  Bedarf `secrets.yaml` aus dem Beispiel an); der pre-push-Hook ruft es auf.
- Flashen auf das Gerät nur auf Tobias' Auftrag.
- Global gilt `~/.claude/CLAUDE.md`.
