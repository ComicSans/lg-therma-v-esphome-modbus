#!/bin/bash
# Spiegelt das Arbeitsmodell dieses Projekts auf ein anderes.
#
#   ./scripts/mirror-setup.sh ../peggle-app
#   ./scripts/mirror-setup.sh ../peggle-app --dry-run
#
# Kopiert wird nur, was projektunabhaengig ist: das Arbeitsmodell, die
# Rollendefinitionen, der Startbefehl. Projektwissen (Testkommandos, Gates,
# Domain-Docs) bleibt Sache des Zielprojekts und wird nie ueberschrieben.
#
# Das Skript ist idempotent und ueberschreibt eine vorhandene Datei nur, wenn
# sie sich unterscheidet - dann sagt es das vorher.

set -uo pipefail

QUELLE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ZIEL="${1:-}"
DRY=0
[ "${2:-}" = "--dry-run" ] && DRY=1
[ "${1:-}" = "--dry-run" ] && { echo "Zielprojekt fehlt."; exit 2; }

if [ -z "$ZIEL" ]; then
  echo "Aufruf: $0 <zielprojekt> [--dry-run]"
  echo "Beispiel: $0 ../peggle-app"
  exit 2
fi

if [ ! -d "$ZIEL" ]; then
  echo "FEHLER: $ZIEL existiert nicht."
  exit 1
fi
ZIEL="$(cd "$ZIEL" && pwd)"

if [ "$ZIEL" = "$QUELLE" ]; then
  echo "FEHLER: Quelle und Ziel sind dasselbe Verzeichnis."
  exit 1
fi

if [ ! -d "$ZIEL/.git" ]; then
  echo "FEHLER: $ZIEL ist kein Git-Repository."
  echo "Das Arbeitsmodell setzt voraus, dass Aufgaben und Rollen versioniert sind."
  exit 1
fi

# Ein schmutziger Zielbaum macht nicht nachvollziehbar, was von hier kam.
SCHMUTZ="$(git -C "$ZIEL" status --short 2>/dev/null | head -5)"
if [ -n "$SCHMUTZ" ] && [ "$DRY" -eq 0 ]; then
  echo "WARNUNG: $ZIEL hat uneingecheckte Aenderungen:"
  echo "$SCHMUTZ" | sed 's/^/    /'
  echo
  echo "Committe sie erst, sonst laesst sich hinterher nicht trennen, was von"
  echo "hier kam und was schon da war. Abbruch."
  exit 1
fi

echo "Quelle: $QUELLE"
echo "Ziel:   $ZIEL"
[ "$DRY" -eq 1 ] && echo "(Trockenlauf, es wird nichts geschrieben)"
echo

GEAENDERT=0

kopiere() {
  local rel="$1"
  local von="$QUELLE/$rel"
  local nach="$ZIEL/$rel"
  [ -f "$von" ] || { echo "  FEHLT in der Quelle: $rel"; return 1; }
  if [ -f "$nach" ] && cmp -s "$von" "$nach"; then
    echo "  unveraendert  $rel"
    return 0
  fi
  if [ -f "$nach" ]; then
    echo "  UEBERSCHREIBT $rel  (Zielfassung weicht ab)"
  else
    echo "  neu           $rel"
  fi
  GEAENDERT=1
  [ "$DRY" -eq 1 ] && return 0
  mkdir -p "$(dirname "$nach")"
  cp "$von" "$nach"
}

echo "Arbeitsmodell und Rollen:"
kopiere ".claude/workflow.md"
kopiere ".claude/agents/produktmanager.md"
kopiere ".claude/agents/reviewer.md"
kopiere ".claude/agents/architect.md"
kopiere ".claude/agents/coder.md"
kopiere ".claude/commands/start.md"
kopiere "scripts/mirror-setup.sh"
[ "$DRY" -eq 0 ] && chmod +x "$ZIEL/scripts/mirror-setup.sh" 2>/dev/null

echo
echo "Aufgabenablage:"
if [ -f "$ZIEL/TASKS.md" ]; then
  echo "  vorhanden     TASKS.md  (unberuehrt)"
else
  echo "  neu           TASKS.md"
  GEAENDERT=1
  if [ "$DRY" -eq 0 ]; then
    cat > "$ZIEL/TASKS.md" <<'EOF'
# TASKS

Offene Arbeit. Eine Datei je Aufgabe unter `tasks/`, hier nur der Index.
Erledigtes wird geloescht, nicht abgehakt - die Historie steht im Git-Log.

## P0

## P1

## P2
EOF
    mkdir -p "$ZIEL/tasks"
    [ -f "$ZIEL/tasks/.gitkeep" ] || touch "$ZIEL/tasks/.gitkeep"
  fi
fi

# .claude/ ist ueblicherweise ignoriert. Ungetrackte Rollendateien liegen auf
# genau einer Platte und sind nach einem Neuaufbau weg.
echo
echo "Versionierung von .claude:"
# Gefragt ist, ob git die Datei tatsächlich ignoriert, nicht ob ein bestimmtes
# Muster in der .gitignore steht. Die Musterprüfung kannte nur `.claude/*` und
# ging am 25.08.2026 an `.claude` ohne Anhang vorbei: in sudoku-app und
# logic-squares-app lagen Arbeitsmodell und Rollen danach kopiert, aber
# ungetrackt, und die Meldung sagte "nicht ignoriert". Genau der Zustand, den
# dieser Abschnitt verhindern soll.
if [ -f "$ZIEL/.gitignore" ] \
  && git -C "$ZIEL" check-ignore -q .claude/workflow.md 2>/dev/null; then
  if grep -q '^!\.claude/agents/' "$ZIEL/.gitignore" 2>/dev/null; then
    echo "  vorhanden     Ausnahmen stehen schon in .gitignore"
  else
    # Ein ignoriertes VERZEICHNIS lässt sich nicht per Ausnahme wieder
    # öffnen: git steigt gar nicht erst hinein, `!.claude/workflow.md` bliebe
    # wirkungslos. Deshalb muss ein blankes `.claude` erst zu `.claude/*`
    # werden, das den Inhalt ignoriert statt das Verzeichnis. Gemessen am
    # 25.08.2026 an sudoku-app und logic-squares-app.
    if grep -qE '^\.claude/?$' "$ZIEL/.gitignore" 2>/dev/null; then
      echo "  UMGESCHRIEBEN .claude -> .claude/* in .gitignore (sonst greift keine Ausnahme)"
      GEAENDERT=1
      [ "$DRY" -eq 0 ] && sed -i '' -E 's|^\.claude/?$|.claude/*|' "$ZIEL/.gitignore"
    fi
    echo "  ERGAENZT      Ausnahmen in .gitignore"
    GEAENDERT=1
    if [ "$DRY" -eq 0 ]; then
      cat >> "$ZIEL/.gitignore" <<'EOF'

# Das Arbeitsmodell gehoert ins Repo: Rollen und Startbefehl definieren, wie hier
# gearbeitet wird. Ungetrackt laegen sie auf genau einer Platte.
!.claude/workflow.md
!.claude/agents/
!.claude/agents/*.md
!.claude/commands/
!.claude/commands/*.md
EOF
    fi
  fi
else
  echo "  nichts zu tun (.claude ist nicht ignoriert)"
fi

echo
if [ "$GEAENDERT" -eq 0 ]; then
  echo "Nichts zu tun, das Ziel ist auf demselben Stand."
  exit 0
fi

if [ "$DRY" -eq 1 ]; then
  echo "Trockenlauf beendet. Ohne --dry-run wird geschrieben."
  exit 0
fi

echo "Uebertragen. Was jetzt noch von Hand gehoert, weil es projektspezifisch ist:"
echo
echo "  1. In der CLAUDE.md von $(basename "$ZIEL") einen Abschnitt 'How We Work',"
echo "     der auf .claude/workflow.md verweist und ihn fuer bindend erklaert."
echo "  2. Darunter die Gates DIESES Projekts: welches Lint-Skript Layer 1 ist"
echo "     und was es prueft."
echo "  3. Den Standards-Block aus dem mcp-server entfernen, falls vorhanden:"
echo "     die Marker <!-- msc:standards:start --> bis <!-- msc:standards:end -->."
echo "  4. Pruefen, ob die Modellzuordnung passt. Sie steht in der Frontmatter"
echo "     jeder Rollendatei unter .claude/agents/."
echo
echo "Danach committen - ungetrackt ueberlebt das Setup keinen Neuaufbau."
