#!/usr/bin/env bash
# The bot balance report (BR1): seeded headless bot matches on each field, every figure judged against its band and
# its standard error, written to pipeline/out/balance-report.md. Measured, never asserted: the checks and CI don't run
# it; the bug pass reads it (docs/DECISIONS.md › Bots and balance). Each level plays against itself: Normal on 32 seeds
# a map, Easy and Hard on 16, in Elimination and Attack / Defend: Depot and Neon Heights about 80 minutes, Woodland
# (5v5 at night, about 50 s a match) about two hours more; `tools/balance.sh woodland` plays it alone.
# Usage: tools/balance.sh [filter]   (a map id or part of one; SEEDS=n for Normal's seed count, LEVEL_SEEDS=n for the
# other levels', LEVELS=normal,hard to choose the levels, MODES=flag or MODES=elimination for one mode;
# GODOT=/path/to/godot)
set -uo pipefail
GODOT="${GODOT:-godot}"
SEEDS="${SEEDS:-32}"
LEVEL_SEEDS="${LEVEL_SEEDS:-16}"
LEVELS="${LEVELS:-normal,easy,hard}"
MODES="${MODES:-elimination,flag}"
cd "$(dirname "$0")/.."
mkdir -p pipeline/out
OUT="pipeline/out/balance-report.md"
LOG="pipeline/out/balance.log"
COMMIT="$(git rev-parse --short HEAD 2>/dev/null || echo '?')"
if [ -n "$(git status --porcelain 2>/dev/null)" ]; then COMMIT="$COMMIT (with uncommitted changes)"; fi

"$GODOT" --headless --path . --import > "$LOG" 2>&1
rm -f "$OUT"
timeout 18000 "$GODOT" --headless --path . -s res://tests/balance/balance_run.gd -- "$PWD/$OUT" "$COMMIT" "$SEEDS" "${1:-}" \
  "$LEVELS" "$LEVEL_SEEDS" "$MODES" >> "$LOG" 2>&1
status=$?
grep -E "matches in|SCRIPT ERROR|ERROR:" "$LOG" | grep -v "leaked" | head -20
if [ "$status" -ne 0 ] || [ ! -f "$OUT" ]; then
  echo "FAIL: no balance report (exit $status, see $LOG)"; exit 1
fi
sed -n 3p "$OUT"
echo "Written: $OUT"
