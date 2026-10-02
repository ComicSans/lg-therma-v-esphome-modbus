#!/bin/bash
# Schnelle Tests des Projekts: einheitlicher Einstieg in allen Repos unter
# ~/GitHub (social-video T-101, Tobias 02.10.2026). Läuft über die
# Lauf-Warteschlange von local-ci (ohne Gerät); der pre-push-Hook ruft es auf.
cd "$(dirname "${BASH_SOURCE[0]}")/.." || exit 64
[ -n "${SIM_LAUF_ID:-}" ] || exec "$HOME/GitHub/local-ci/share/sim-lauf.sh" --projekt lg-therma-v-esphome-modbus \
  --zweck "${SIM_LAUF_ZWECK:-test}" --geraet keins -- "$PWD/scripts/test.sh" "$@"
set -euo pipefail
# Prüft die ESPHome-Konfiguration (ohne Kompilieren); secrets aus dem Beispiel, falls secrets.yaml fehlt.
[ -f secrets.yaml ] || cp secrets.yaml.example secrets.yaml
esphome config therma-v.yaml >/dev/null "$@"
echo "ESPHome-Konfiguration gültig"
