#!/bin/bash
# Shared Android export and signing (G1.7, G6.2, G6.3). Run from the game repo root.
#   tools/common/sign_android.sh <apk out path>
# Needs: the private repo bclark10121-cloud/game-signing cloned outside every game repo
#   (GAME_SIGNING, default ../game-signing), Godot 4.6 (GODOT, default godot) and the Android build tools
#   (APKSIGNER, default apksigner). Never copies the key or passwords into the game repo.
set -e
OUT="$1"; [ -n "$OUT" ] || { echo "usage: sign_android.sh <apk out path>"; exit 1; }
SIGN="${GAME_SIGNING:-../game-signing}"; GODOT="${GODOT:-godot}"; APKSIGNER="${APKSIGNER:-apksigner}"
[ -f "$SIGN/signing.properties" ] || { echo "game-signing not found at $SIGN. Clone bclark10121-cloud/game-signing outside the game repo"; exit 1; }
prop() { grep "^$1=" "$SIGN/signing.properties" | cut -d= -f2-; }
case "$(cd "$SIGN" && pwd)" in "$(pwd)"*) echo "game-signing must sit outside the game repo"; exit 1;; esac
export GODOT_ANDROID_KEYSTORE_RELEASE_PATH="$(cd "$SIGN" && pwd)/$(prop keystore)"
export GODOT_ANDROID_KEYSTORE_RELEASE_USER="$(prop alias)"
export GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD="$(prop store_password)"
"$GODOT" --headless --path . --export-release Android "$OUT"
WANT="$(prop sha256_starts_with)"
GOT="$("$APKSIGNER" verify --print-certs "$OUT" 2>/dev/null | grep -m1 'SHA-256' | awk '{print $NF}')"
case "$GOT" in "$WANT"*) echo "SIGN ok: $OUT signature $GOT";; *) echo "SIGN FAIL: $OUT signature '$GOT' does not start with $WANT"; exit 1;; esac
