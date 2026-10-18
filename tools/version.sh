#!/usr/bin/env bash
# The version, in every form the release needs, from a name ("0.1 Dev 1", "0.1 Beta 2", "0.1", "0.1.1") or a tag
# ("0.1-dev.1", "0.1-beta.2", "0.1.0", "0.1.1"). docs/PROCESS.md › Versioning has the scheme; game/core/version.gd is
# the same rule inside the game. Prints one per line:
#   name=0.1 Dev 1     what players see (title screen, installer, release title "Airsoft 0.1 Dev 1")
#   tag=0.1-dev.1      the owner's git tag, also used in the download file names
#   number=0.1.1.1     Windows version number: four numbers that always go up
#   prerelease=true    Dev and Beta builds are GitHub pre-releases
# Usage: tools/version.sh               (reads config/version in project.godot)
#        tools/version.sh "0.1 Beta 2"  or  tools/version.sh 0.1-beta.2
set -euo pipefail
cd "$(dirname "$0")/.."
IN="${1-$(sed -n 's/^config\/version="\(.*\)"$/\1/p' project.godot)}"
N='(0|[1-9][0-9]{0,3})'
P='([1-9][0-9]{0,3})'
if [[ "$IN" =~ ^$N\.$N\ (Dev|Beta)\ $P$ ]] || [[ "$IN" =~ ^$N\.$N-(dev|beta)\.$P$ ]]; then
  MAJOR="${BASH_REMATCH[1]}"; MINOR="${BASH_REMATCH[2]}"; STAGE="${BASH_REMATCH[3],,}"; B="${BASH_REMATCH[4]}"
  NAME="$MAJOR.$MINOR ${STAGE^} $B"; TAG="$MAJOR.$MINOR-$STAGE.$B"; PRE=true
  if [ "$STAGE" = dev ]; then NUMBER="$MAJOR.$MINOR.0.$B"; else NUMBER="$MAJOR.$MINOR.1.$B"; fi
elif [[ "$IN" =~ ^$N\.$N(\.0)?$ ]]; then
  MAJOR="${BASH_REMATCH[1]}"; MINOR="${BASH_REMATCH[2]}"
  NAME="$MAJOR.$MINOR"; TAG="$MAJOR.$MINOR.0"; NUMBER="$MAJOR.$MINOR.2.0"; PRE=false
elif [[ "$IN" =~ ^$N\.$N\.$P$ ]]; then
  MAJOR="${BASH_REMATCH[1]}"; MINOR="${BASH_REMATCH[2]}"; PATCH="${BASH_REMATCH[3]}"
  NAME="$MAJOR.$MINOR.$PATCH"; TAG="$NAME"; NUMBER="$MAJOR.$MINOR.2.$PATCH"; PRE=false
else
  echo "::error::'$IN' is not a version like '0.1 Dev 1', '0.1 Beta 2', '0.1' or a tag like '0.1-dev.1', '0.1.0' (docs/PROCESS.md › Versioning)" >&2
  exit 1
fi
printf 'name=%s\ntag=%s\nnumber=%s\nprerelease=%s\n' "$NAME" "$TAG" "$NUMBER" "$PRE"
