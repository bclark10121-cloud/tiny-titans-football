#!/bin/bash
# Builds the game standards handoff zip from this repo. Run from the repo root: tools/make_handoff.sh [output folder]
# Never include a signing key or password.
set -e
OUT="${1:-..}"
S=$(mktemp -d)
D="$S/Game_Standards_handoff"
mkdir -p "$D/templates/godot" "$D/templates/game-page" "$D/reusable" "$D/games/tiny-titans-football" "$D/games/the-scenic-route"
cp handoff/STANDARDS.md "$D/"
cp handoff/templates/* "$D/templates/"
cp project.godot export_presets.cfg .gitignore "$D/templates/godot/"
cp docs/index.html "$D/templates/game-page/index.html"
cp CREDITS.md "$D/templates/CREDITS.md"
cp scripts/hud.gd "$D/reusable/hud_football.gd"
cp tests/web_test.py "$D/reusable/web_test_states.py"
cp tools/make_sfx.py "$D/reusable/make_sfx_stadium.py"
cp tools/patch_assets.py tools/make_handoff.sh "$D/reusable/"
cp CLAUDE.md STANDARDS_OVERRIDES.md BACKLOG.md README.md CREDITS.md data/plays.json data/teams.json "$D/games/tiny-titans-football/"
cp docs/release-notes/*.md "$D/games/tiny-titans-football/" 2>/dev/null || true
cp handoff/games/the-scenic-route/* "$D/games/the-scenic-route/" 2>/dev/null || true
(cd "$S" && zip -qr handoff.zip Game_Standards_handoff)
cp "$S/handoff.zip" "$OUT/Game_Standards_handoff.zip"
echo "built $OUT/Game_Standards_handoff.zip"
