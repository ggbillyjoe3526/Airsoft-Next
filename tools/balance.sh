#!/usr/bin/env bash
# The bot balance report (BR1): seeded headless bot matches on each field, every figure judged against its band and
# its standard error, written to pipeline/out/balance-report.md. Measured, never asserted: the checks and CI don't run
# it; the bug pass reads it (docs/DECISIONS.md › Bots and balance). About 15 minutes at the default 32 seeds a map.
# Usage: tools/balance.sh [filter]   (a map id or part of one; SEEDS=n to change the seed count; GODOT=/path/to/godot)
set -uo pipefail
GODOT="${GODOT:-godot}"
SEEDS="${SEEDS:-32}"
cd "$(dirname "$0")/.."
mkdir -p pipeline/out
OUT="pipeline/out/balance-report.md"
LOG="pipeline/out/balance.log"
COMMIT="$(git rev-parse --short HEAD 2>/dev/null || echo '?')"
if [ -n "$(git status --porcelain 2>/dev/null)" ]; then COMMIT="$COMMIT (with uncommitted changes)"; fi

"$GODOT" --headless --path . --import > "$LOG" 2>&1
rm -f "$OUT"
timeout 3600 "$GODOT" --headless --path . -s res://tests/balance/balance_run.gd -- "$PWD/$OUT" "$COMMIT" "$SEEDS" "${1:-}" \
  >> "$LOG" 2>&1
status=$?
grep -E "matches in|SCRIPT ERROR|ERROR:" "$LOG" | grep -v "leaked" | head -20
if [ "$status" -ne 0 ] || [ ! -f "$OUT" ]; then
  echo "FAIL: no balance report (exit $status, see $LOG)"; exit 1
fi
sed -n 3p "$OUT"
echo "Written: $OUT"
