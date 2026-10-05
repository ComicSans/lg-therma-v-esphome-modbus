#!/bin/bash
# Fast project tests: the common entry point for all repos under ~/GitHub
# (social-video T-101, Tobias 02.10.2026). Runs through the local-ci run queue
# (no device); the pre-push hook calls it.
cd "$(dirname "${BASH_SOURCE[0]}")/.." || exit 64
# Without local-ci (anyone but Tobias) the test runs directly. The sim-lauf
# options are local-ci's interface and stay as they are.
sim_lauf="$HOME/GitHub/local-ci/share/sim-lauf.sh"
if [ -z "${SIM_LAUF_ID:-}" ] && [ -x "$sim_lauf" ]; then
  exec "$sim_lauf" --projekt lg-therma-v-esphome-modbus \
    --zweck "${SIM_LAUF_ZWECK:-test}" --geraet keins -- "$PWD/scripts/test.sh" "$@"
fi
set -euo pipefail
# Secrets from the example if secrets.yaml is missing; the API key is generated
# at random because the placeholder is deliberately invalid. A file created
# this way is deleted again at the end: it carries the public placeholder
# passwords and must not end up on a device by accident.
log=$(mktemp)
secrets_created=""
trap 'rm -f "$log"; [ -n "$secrets_created" ] && rm -f secrets.yaml' EXIT
if [ ! -f secrets.yaml ]; then
  key=$(python3 -c 'import base64,os;print(base64.b64encode(os.urandom(32)).decode())')
  sed "s|generate-a-key-here|$key|" secrets.yaml.example > secrets.yaml
  secrets_created=1
fi

# 1. Validate the configuration. Deprecated options (such as force_new_range)
#    count as errors: ESPHome removes them after a few releases, and then the
#    configuration no longer builds (issue #1).
if ! esphome config therma-v.yaml >"$log" 2>&1 "$@"; then
  cat "$log"; exit 1
fi
if grep -E '^(WARNING|ERROR).*deprecated' "$log"; then
  echo "ERROR: deprecated ESPHome options in therma-v.yaml (see above)" >&2; exit 1
fi
echo "ESPHome configuration valid"

# 1b. include/register_list.h must name exactly the modbus_controller entities
#     of therma-v.yaml. A renamed entity would otherwise silently drop out of
#     the bus-outage handling, the observation and "Registers Without Response".
python3 - <<'PY'
import re, sys
yaml_txt = open('therma-v.yaml', encoding='utf-8').read()
names_yaml = set()
for block in re.split(r'\n(?=  - platform: )', yaml_txt):
    if block.startswith('  - platform: modbus_controller') and 'internal: true' not in block:
        m = re.search(r'^    name: "([^"]+)"', block, re.M)
        if m:
            names_yaml.add(m.group(1))
h = open('include/register_list.h', encoding='utf-8').read()
names_h = set(re.findall(r'^\s+"([^"]+)",', h, re.M))
if names_yaml != names_h:
    print("ERROR: include/register_list.h does not match therma-v.yaml", file=sys.stderr)
    print("  only in YAML:", sorted(names_yaml - names_h), file=sys.stderr)
    print("  only in header:", sorted(names_h - names_yaml), file=sys.stderr)
    sys.exit(1)
print(f"Register list matches ({len(names_h)} entities)")
PY

# 2. Compile. `esphome config` only checks the YAML, not the C++ lambdas; the
#    breakage from issue #1 (changed Modbus API) only shows up here. Deprecated
#    C++ API in our own lambdas counts as an error too. The compiler reports it
#    at the YAML line (therma-v.yaml:NNN), not at main.cpp, because ESPHome
#    emits #line markers; included headers are copied to src/ and count there.
#    The first run downloads the toolchain and takes minutes, later builds are
#    incremental. Skip with TEST_SKIP_COMPILE=1 (TEST_OHNE_COMPILE still works).
if [ -n "${TEST_SKIP_COMPILE:-${TEST_OHNE_COMPILE:-}}" ]; then
  echo "Compile skipped (TEST_SKIP_COMPILE)"
  exit 0
fi
if ! esphome compile therma-v.yaml >"$log" 2>&1; then
  # Don't just filter for "error": network and toolchain failures often lack
  # the word, and then nothing would be shown here.
  tail -60 "$log"; exit 1
fi
if grep -E '(therma-v\.yaml|src/[^/:]*\.(cpp|h)):[0-9]+:[0-9]+: warning: .*\[-Wdeprecated' "$log"; then
  echo "ERROR: deprecated ESPHome API in the lambdas (see above)" >&2; exit 1
fi
echo "Firmware compiles without deprecated API"
