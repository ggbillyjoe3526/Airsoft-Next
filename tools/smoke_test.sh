#!/usr/bin/env bash
# Headless smoke test: imports the project, then runs the game with --smoke and fails if Godot logged any script
# error or the game never reported. Once bots exist, --smoke plays a headless match instead.
# Usage: tools/smoke_test.sh            (GODOT=/path/to/godot to override)
set -uo pipefail
GODOT="${GODOT:-godot}"
cd "$(dirname "$0")/.."
LOG="${SMOKE_LOG:-smoke.log}"

"$GODOT" --headless --path . --import > import.log 2>&1
if grep -E "SCRIPT ERROR|Parse Error" import.log; then
  echo "FAIL: script errors while importing (see import.log)"; exit 1
fi

timeout 600 "$GODOT" --headless --path . -- --smoke > "$LOG" 2>&1
status=$?
if grep -E "SCRIPT ERROR|Parse Error|Failed to load script" "$LOG"; then
  echo "FAIL: script errors during the smoke run (see $LOG)"; exit 1
fi
if ! grep -q "^\[smoke\] ok" "$LOG"; then
  echo "FAIL: the game never reported (exit $status, see $LOG)"; tail -20 "$LOG"; exit 1
fi
if [ "$status" -ne 0 ]; then
  echo "FAIL: the game exited with $status after reporting (see $LOG)"; tail -20 "$LOG"; exit 1
fi
if grep -E "^(USER )?ERROR:" "$LOG" | grep -vE "leaked at exit|were leaked"; then
  echo "FAIL: errors during the smoke run (see $LOG)"; exit 1
fi
echo "PASS: smoke run with zero script errors ($(grep '^\[smoke\] ok' "$LOG"))"
