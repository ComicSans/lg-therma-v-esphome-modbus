# CLAUDE.md

Rules for Claude Code in this repo. Structure, wiring and registers are in
`README.md` and `docs/`.

## What this is

ESPHome configuration (`therma-v.yaml`) for the LG Therma V over Modbus RTU with
an ESP32, plus Home Assistant parts (`home-assistant/`). The repo is public
(exception REMOTE in `~/GitHub/local-ci/ausnahmen.tsv`).

## Rules

- `secrets.yaml` stays local and ignored; key changes only in
  `secrets.yaml.example` with placeholders. Never commit WiFi, API or OTA keys.
- Tests: `scripts/test.sh` checks with `esphome config` and `esphome compile`;
  deprecated ESPHome API is an error. It creates `secrets.yaml` from the example
  when needed and deletes it afterwards; the pre-push hook calls it.
- Entity names, code, comments, texts and docs are English. Renaming an entity
  changes its Home Assistant entity ID: update `include/register_list.h` and
  `docs/migration/entities.json` with it.
- Flash the device only on Tobias' instruction.
- `~/.claude/CLAUDE.md` applies globally.
