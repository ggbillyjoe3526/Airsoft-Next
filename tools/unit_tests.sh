#!/usr/bin/env bash
# Unit tests (Gut, addons/gut): the test_*.gd under tests/unit, headless, in two parts of about the same time (CI1):
# part 1 the files before test_f (test_a* to test_e*, test_bots.gd's whole bot matches among them), part 2 the rest.
# Each part is a Godot run of its own with its own limit; CI runs them as two jobs side by side. Settings live in
# .gutconfig.json. Prints each failure as "FAIL: <file> <test>: <message>" and the totals, the whole output in
# unit-<part>.log; fails if any test fails or any script error is printed.
# Usage: tools/unit_tests.sh [1|2]      (both parts in turn without one; GODOT=/path/to/godot to override)
set -uo pipefail
GODOT="${GODOT:-godot}"
cd "$(dirname "$0")/.."

if [ -z "${1:-}" ]; then
  failed=0
  "$0" 1 || failed=1
  "$0" 2 || failed=1
  exit $failed
fi
part="$1"
if [ "$part" != 1 ] && [ "$part" != 2 ]; then
  echo "FAIL: no unit test part '$part' (1 or 2)"; exit 1
fi
LOG="unit-$part.log"

# This part's files by name: part 1 sorts before test_f, part 2 from it on.
files=()
while IFS= read -r f; do
  name="$(basename "$f")"
  if [[ "$name" < test_f ]]; then in_part=1; else in_part=2; fi
  if [ "$in_part" = "$part" ]; then files+=("res://$f"); fi
done < <(find tests/unit -name 'test_*.gd' | LC_ALL=C sort)
if [ "${#files[@]}" -eq 0 ]; then
  echo "FAIL: no test files in unit test part $part"; exit 1
fi
list="$(IFS=,; echo "${files[*]}")"

# Always import first, so a new class_name or asset is known to the tests whatever ran before.
"$GODOT" --headless --path . --import > import.log 2>&1

# A part takes about six minutes on a cloud session (CI1); the limit only catches a hang, inside the CI job's 20
# minutes.
timeout 1080 "$GODOT" --headless --path . -s res://addons/gut/gut_cmdln.gd -gdir= -gtest="$list" > "$LOG" 2>&1
status=$?

# Each failed test with its file (GUT's run summary), each script error with the file that was running, and the file a
# run stopped in if it never reached its totals.
awk '
  /^res:\/\/tests\// { file = $0 }
  /^= Run Summary/ { summary = 1 }
  summary && /^- / { test = substr($0, 3) }
  summary && /\[Failed\]/ { sub(/^ *\[Failed\]: */, ""); print "FAIL: " file " " test ": " $0 }
  !summary && /SCRIPT ERROR|Parse Error/ { print "FAIL: " file ": " $0 }
  /^Totals/ { totals = 1 }
  END { if (!totals) print "FAIL: the run stopped in " (file ? file : "its start") }
' "$LOG" | head -40
grep -E "^(Tests|Passing Tests|Failing Tests)" "$LOG" | tr -s ' ' | paste -sd ' ' - | sed "s/^/part $part: /"
if grep -qE "SCRIPT ERROR|Parse Error" "$LOG"; then
  echo "FAIL: script errors during the unit tests (see $LOG)"; exit 1
fi
if [ "$status" -ne 0 ]; then
  echo "FAIL: unit tests failed (exit $status, see $LOG)"; exit 1
fi
echo "PASS: unit tests, part $part"
