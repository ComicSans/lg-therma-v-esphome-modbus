#!/bin/bash
# Schnelle Tests des Projekts: einheitlicher Einstieg in allen Repos unter
# ~/GitHub (social-video T-101, Tobias 02.10.2026). Läuft über die
# Lauf-Warteschlange von local-ci (ohne Gerät); der pre-push-Hook ruft es auf.
cd "$(dirname "${BASH_SOURCE[0]}")/.." || exit 64
[ -n "${SIM_LAUF_ID:-}" ] || exec "$HOME/GitHub/local-ci/share/sim-lauf.sh" --projekt lg-therma-v-esphome-modbus \
  --zweck "${SIM_LAUF_ZWECK:-test}" --geraet keins -- "$PWD/scripts/test.sh" "$@"
set -euo pipefail
# secrets aus dem Beispiel, falls secrets.yaml fehlt.
[ -f secrets.yaml ] || cp secrets.yaml.example secrets.yaml
log=$(mktemp)
trap 'rm -f "$log"' EXIT

# 1. Konfiguration prüfen. Veraltete Optionen (etwa force_new_range) gelten
#    als Fehler: ESPHome entfernt sie nach einigen Versionen, und dann baut
#    die Konfiguration nicht mehr (Issue #1).
if ! esphome config therma-v.yaml >"$log" 2>&1 "$@"; then
  cat "$log"; exit 1
fi
if grep -E '^(WARNING|ERROR).*deprecated' "$log"; then
  echo "FEHLER: veraltete ESPHome-Optionen in therma-v.yaml (siehe oben)" >&2; exit 1
fi
echo "ESPHome-Konfiguration gültig"

# 2. Kompilieren. `esphome config` prüft nur das YAML, nicht die C++-Lambdas;
#    der Bruch aus Issue #1 (geänderte Modbus-API) fällt erst hier auf.
#    Veraltete C++-API in den eigenen Lambdas (src/main.cpp) gilt ebenfalls
#    als Fehler. Der erste Lauf lädt die Toolchain und dauert Minuten, danach
#    baut ESPHome inkrementell. Überspringen: TEST_OHNE_COMPILE=1.
if [ -n "${TEST_OHNE_COMPILE:-}" ]; then
  echo "Kompilieren übersprungen (TEST_OHNE_COMPILE)"
  exit 0
fi
if ! esphome compile therma-v.yaml >"$log" 2>&1; then
  grep -E 'error|Error|ERROR' "$log" | tail -40; exit 1
fi
if grep -E 'src/main\.cpp:.*\[-Wdeprecated' "$log"; then
  echo "FEHLER: veraltete ESPHome-API in den Lambdas (siehe oben)" >&2; exit 1
fi
echo "Firmware kompiliert ohne veraltete API"
