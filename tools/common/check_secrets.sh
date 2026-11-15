#!/bin/bash
# Shared secrets check (G1.2, G1.7, G1.9). Part of every test gate. Run from anywhere:
#   tools/common/check_secrets.sh [repo folder, default .]
# Fails when a file tracked by git is a signing key or settings file, or when a tracked text file
# holds a keystore password or a GitHub token. Prints SECRETS check ok when clean.
# It reads only files git tracks, so an ignored local copy of game-signing never trips it.
cd "${1:-.}"
ROOT="$(git rev-parse --show-toplevel 2>/dev/null)" || { echo "SECRETS check FAIL: not a git repo"; exit 1; }
cd "$ROOT"
bad=0
files="$(git ls-files | grep -Ei '\.(jks|keystore|p12|pfx|pem)$|(^|/)signing\.properties$|(^|/)debug\.keystore$' || true)"
if [ -n "$files" ]; then echo "SECRETS check FAIL: key or signing file in the repo:"; echo "$files" | sed 's/^/  /'; bad=1; fi
# a password written as a value, not read from a variable, a function or a properties lookup
pat="(storePassword|keyPassword)[[:space:]]*[=(]?[[:space:]]*['\"][^'\"\$]+['\"]"
pat="$pat|keystore/(release|debug)_password=\"[^\"]+\""
pat="$pat|GODOT_ANDROID_KEYSTORE_(RELEASE|DEBUG)_PASSWORD=[\"']?[A-Za-z0-9]"
pat="$pat|^[[:space:]]*(store_password|key_password)[[:space:]]*=[[:space:]]*[^[:space:]<]"
pat="$pat|gh[pousr]_[A-Za-z0-9]{30,}|github_pat_[A-Za-z0-9_]{30,}"
hits="$(git grep -nIE "$pat" -- . ':!*check_secrets.sh' 2>/dev/null | cut -d: -f1,2 || true)"
if [ -n "$hits" ]; then echo "SECRETS check FAIL: a password or token is written in these lines (file:line):"; echo "$hits" | sed 's/^/  /'; bad=1; fi
if [ "$bad" = 0 ]; then echo "SECRETS check ok: $(git ls-files | wc -l | tr -d ' ') tracked files"; else echo "Move keys and passwords to the private repo game-signing (G1.9)"; exit 1; fi
