#!/usr/bin/env bash
# The match guards (tests/guards, MG1): whole bot matches over 16 seeds on each field, headless. A few minutes, so they
# run as a CI job of their own and not in tools/check.sh's unit tests. Prints failures and totals.
# Usage: tools/match_guards.sh            (GODOT=/path/to/godot to override)
set -uo pipefail
GODOT="${GODOT:-godot}"
cd "$(dirname "$0")/.."
LOG="${GUARDS_LOG:-guards.log}"

"$GODOT" --headless --path . --import > import.log 2>&1

timeout 1500 "$GODOT" --headless --path . -s res://addons/gut/gut_cmdln.gd -gdir=res://tests/guards -gprefix=test_ \
  -gsuffix=.gd -gexit > "$LOG" 2>&1
status=$?
grep -E "\[Failed\]|rounds over|Passing Tests|Failing Tests" "$LOG" | head -40
if grep -qE "SCRIPT ERROR|Parse Error" "$LOG"; then
  echo "FAIL: script errors during the match guards (see $LOG)"; exit 1
fi
if [ "$status" -ne 0 ]; then
  echo "FAIL: match guards failed (exit $status, see $LOG)"; exit 1
fi
echo "PASS: match guards"
