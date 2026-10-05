#!/bin/bash
# Schnelle Tests des Projekts: einheitlicher Einstieg in allen Repos unter
# ~/GitHub (social-video T-101, Tobias 02.10.2026). Läuft über die
# Lauf-Warteschlange von local-ci (ohne Gerät); der pre-push-Hook ruft es auf.
cd "$(dirname "${BASH_SOURCE[0]}")/.." || exit 64
# Ohne local-ci (jeder ausser Tobias) laeuft der Test direkt.
sim_lauf="$HOME/GitHub/local-ci/share/sim-lauf.sh"
if [ -z "${SIM_LAUF_ID:-}" ] && [ -x "$sim_lauf" ]; then
  exec "$sim_lauf" --projekt lg-therma-v-esphome-modbus \
    --zweck "${SIM_LAUF_ZWECK:-test}" --geraet keins -- "$PWD/scripts/test.sh" "$@"
fi
set -euo pipefail
# secrets aus dem Beispiel, falls secrets.yaml fehlt; der API-Schluessel wird
# dabei zufaellig erzeugt, weil der Platzhalter absichtlich ungueltig ist. Die
# so erzeugte Datei wird am Ende wieder geloescht: sie traegt die oeffentlichen
# Platzhalter-Passwoerter und darf nicht versehentlich geflasht werden.
log=$(mktemp)
secrets_erzeugt=""
trap 'rm -f "$log"; [ -n "$secrets_erzeugt" ] && rm -f secrets.yaml' EXIT
if [ ! -f secrets.yaml ]; then
  schluessel=$(python3 -c 'import base64,os;print(base64.b64encode(os.urandom(32)).decode())')
  sed "s|hier-schluessel-erzeugen|$schluessel|" secrets.yaml.example > secrets.yaml
  secrets_erzeugt=1
fi

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
#    Veraltete C++-API in den eigenen Lambdas gilt ebenfalls als Fehler. Der
#    Compiler meldet sie unter der YAML-Zeile (therma-v.yaml:NNN), nicht unter
#    main.cpp, weil ESPHome #line-Marken setzt; eingebundene Header kopiert
#    ESPHome nach src/ und zaehlen dort mit. Der erste Lauf lädt die Toolchain und dauert Minuten, danach
#    baut ESPHome inkrementell. Überspringen: TEST_OHNE_COMPILE=1.
if [ -n "${TEST_OHNE_COMPILE:-}" ]; then
  echo "Kompilieren übersprungen (TEST_OHNE_COMPILE)"
  exit 0
fi
if ! esphome compile therma-v.yaml >"$log" 2>&1; then
  # Nicht nur nach "error" filtern: Netzwerk- und Toolchain-Fehler tragen das
  # Wort oft nicht, und dann stuende hier gar nichts.
  tail -60 "$log"; exit 1
fi
if grep -E '(therma-v\.yaml|src/[^/:]*\.(cpp|h)):[0-9]+:[0-9]+: warning: .*\[-Wdeprecated' "$log"; then
  echo "FEHLER: veraltete ESPHome-API in den Lambdas (siehe oben)" >&2; exit 1
fi
echo "Firmware kompiliert ohne veraltete API"
