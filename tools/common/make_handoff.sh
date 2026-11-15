#!/bin/bash
# Shared handoff zip builder (G2.5, G9). Run from the game repo root.
#   tools/common/make_handoff.sh <game-standards folder> [output folder, default ..]
# The zip holds both standards files, the templates, the common kit and the instructions from game-standards,
# plus this game's rules, override file, backlog, credits, release notes, data and common.lock.
# Never includes a signing key or password.
set -e
SRC="$(cd "$1" && pwd)"; OUT="${2:-..}"
[ -f "$SRC/GAME_STANDARDS.md" ] || { echo "usage: make_handoff.sh <game-standards folder> [output folder]"; exit 1; }
GAME="$(basename "$(pwd)")"
S=$(mktemp -d); D="$S/Game_Standards_handoff"
mkdir -p "$D/games/$GAME"
cp "$SRC/GAME_STANDARDS.md" "$SRC/ENGINEERING_STANDARDS.md" "$SRC/README.md" "$D/"
cp -r "$SRC/templates" "$SRC/common" "$SRC/instructions" "$D/"
for f in CLAUDE.md STANDARDS_OVERRIDES.md BACKLOG.md README.md CREDITS.md common.lock; do [ -f "$f" ] && cp "$f" "$D/games/$GAME/"; done
[ -d docs/release-notes ] && cp docs/release-notes/*.md "$D/games/$GAME/" 2>/dev/null || true
[ -d data ] && cp data/*.json "$D/games/$GAME/" 2>/dev/null || true
if find "$D" -name '*.jks' -o -name '*.keystore' -o -name 'signing.properties' | grep -q .; then echo "refusing: a key or password file is in the zip"; exit 1; fi
(cd "$S" && zip -qr handoff.zip Game_Standards_handoff)
cp "$S/handoff.zip" "$OUT/Game_Standards_handoff.zip"
echo "built $OUT/Game_Standards_handoff.zip"
