#!/usr/bin/env bash
# Unit tests (Gut, addons/gut): runs every test_*.gd under tests/unit headless
# and fails if any test fails. Settings live in .gutconfig.json.
# Usage: tools/unit_tests.sh            (GODOT=/path/to/godot to override)
set -uo pipefail
GODOT="${GODOT:-godot}"
cd "$(dirname "$0")/.."
LOG="${UNIT_LOG:-unit.log}"

# Always import first, so a new class_name or asset is known to the tests whatever ran before.
"$GODOT" --headless --path . --import > import.log 2>&1

# The whole suite takes about ten minutes in CI and up to 880 s on a busy cloud session (DP2); the limit only catches
# a hang, inside the CI job's 20 minutes.
timeout 1080 "$GODOT" --headless --path . -s res://addons/gut/gut_cmdln.gd 2>&1 | tee "$LOG"
status=${PIPESTATUS[0]}
if grep -qE "SCRIPT ERROR|Parse Error" "$LOG"; then
  echo "FAIL: script errors during the unit tests (see $LOG)"; exit 1
fi
if [ "$status" -ne 0 ]; then
  echo "FAIL: unit tests failed (exit $status, see $LOG)"; exit 1
fi
echo "PASS: unit tests"
