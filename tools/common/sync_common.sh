#!/bin/bash
# Pulls the shared kit from game-standards into a game repo (G10.2), or checks a game's pulled copy (G10.3).
#   sync_common.sh <game-standards folder> <game repo folder>   copy common into the game and write common.lock
#   sync_common.sh --check [game repo folder]                    fail if a pulled file was edited in the game
# Where the files go in the game:
#   common/godot/*  ->  addons/bc_common/
#   common/tools/*  ->  tools/common/       (this script is copied there too)
#   common/tests/*  ->  tests/common/
set -e
if [ "$1" = "--check" ]; then
  cd "${2:-.}"
  if [ ! -f common.lock ]; then echo "COMMON check FAIL: no common.lock. Run sync_common.sh first"; exit 1; fi
  if grep -v '^#' common.lock | sha256sum -c --quiet - ; then
    echo "COMMON check ok: $(grep '^# version' common.lock | cut -d' ' -f3) $(grep '^# commit' common.lock | cut -d' ' -f3)"
  else
    echo "COMMON check FAIL: a pulled file was edited in this game. Change it in game-standards first (G10.3)"; exit 1
  fi
  exit 0
fi
SRC="$(cd "$1" && pwd)"; G="$(cd "$2" && pwd)"
[ -f "$SRC/common/VERSION" ] || { echo "not a game-standards folder: $SRC"; exit 1; }
VER="$(cat "$SRC/common/VERSION")"
COMMIT="$(git -C "$SRC" rev-parse --short HEAD 2>/dev/null || echo unknown)"
for pair in "godot:addons/bc_common" "tools:tools/common" "tests:tests/common"; do
  from="$SRC/common/${pair%%:*}"; to="$G/${pair##*:}"
  rm -rf "$to"; mkdir -p "$to"; cp -r "$from"/. "$to"/
done
cp "$SRC/common/sync_common.sh" "$G/tools/common/sync_common.sh"
cp "$SRC/common/VERSION" "$G/addons/bc_common/VERSION"
cd "$G"
{ echo "# Shared kit pulled from bclark10121-cloud/game-standards/common (G10.2). Never edit these files here (G10.3)."
  echo "# version $VER"
  echo "# commit $COMMIT"
  echo "# pulled $(date -u +%Y-%m-%d)"
  find addons/bc_common tools/common tests/common -type f ! -name '*.uid' ! -name '*.pyc' ! -path '*/__pycache__/*' | sort | xargs sha256sum
} > common.lock
echo "pulled common $VER ($COMMIT) into $G"
