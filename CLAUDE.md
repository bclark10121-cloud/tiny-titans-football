# Tiny Titans Football: project rules

Tiny Titans Football is Brian Clark's arcade football game. Godot 4.6, Android and browser. This repo is public.

## Standards (G0.10, G10)

- Read `GAME_STANDARDS.md` (rule ids start with G) and `ENGINEERING_STANDARDS.md` (rule ids start with E) first. Both live only in the private repo `bclark10121-cloud/game-standards`. Clone it outside this repo (for example `../game-standards`). This repo holds no copies.
- Overrides, open items and the standards version this game was checked against live in `STANDARDS_OVERRIDES.md`. Order of authority: Brian in the chat, then `STANDARDS_OVERRIDES.md`, then the standards.
- Never edit a standards file. Propose a change to Brian. It changes in `game-standards` first. A football-only exception goes in `STANDARDS_OVERRIDES.md` as Proposed until Brian approves it.
- The shared kit is pulled into `addons/bc_common/`, `tools/common/` and `tests/common/` with `bash ../game-standards/common/sync_common.sh ../game-standards .`. `common.lock` records the version and commit. Never edit those files here. Propose changes to Brian for `game-standards/common`.
- Signing: the key `wandervalley.jks` and its settings live in the private repo `bclark10121-cloud/game-signing` (G1.7). Clone it outside this repo (for example `../game-signing`). Build the APK with `tools/common/sign_android.sh`. The signature must start with `5db69ffb`. Never commit a key, a password or `signing.properties`.
- Do not change other game repos or `game-standards` unless Brian asks.

## Pillars (never break these)

1. Call it, then run it. The player picks a play, then controls one player.
2. Arcade pace: big hits, fast players, quick downs. A full game takes about 10 minutes.
3. Football rules people know: four downs, first downs, touchdowns, field goals, turnovers.
4. Original everything. Fictional teams, our own plays and art. No real league, team or player names. Nothing copied from Maximum Football or any other game.

Note: this game has an opponent and a final score. `STANDARDS_OVERRIDES.md` records that and every other place this game differs from the standards.

## Rules

- Top menu: one Menu button at the top right opens all options in a row across the top.
- Field units are yards. The field runs along Z. Goal lines sit at z = -50 and z = +50. Side 0 (the player) always attacks +Z and the camera always looks down +Z.
- Plays are data in `data/plays.json`, written in the offense frame: x is yards to the offense's right, z is yards downfield.
- Players move with plain maths, not physics bodies. `main.gd` sets `want` and `player.gd` eases toward it.
- Field lines and numbers are painted into one field texture. Never lay a thin layer on the grass: it flickers on phones.
- Save file is `user://tiny_titans.json`, format `v: 1`. Only add fields, each with a safe default. From the next release it is written with `addons/bc_common/save_store.gd`.
- The `?test` state moves to `addons/bc_common/test_bridge.gd` on the next release.
- Every outside asset goes in `CREDITS.md` with its licence. Music comes from the Patch.gg library (`tools/common/patch_assets.py`).

## Test gate

- `bash tools/common/sync_common.sh --check .` must print `COMMON check ok`.
- `godot --headless --path . -- --bot --games=6` must finish every game and print `BOT done`. Typical final scores sit between 0 and 40 a side.
- `python3 tests/web_test.py <web build folder> <shots folder>` must print `errors []`. View the screenshots.
- `python3 tests/common/page_check.py https://bclark10121-cloud.github.io/tiny-titans-football/` after every push must print `errors []`.

## Deliver every time (every release)

1. The game page link: https://bclark10121-cloud.github.io/tiny-titans-football/ (give Brian this link, not the direct play link).
2. The GitHub repo link: https://github.com/bclark10121-cloud/tiny-titans-football
3. The APK, named `TinyTitansFootball-v<version>.apk`, built with `tools/common/sign_android.sh`, in `docs/downloads/` and sent to Brian as a file. Package id `com.brianclark.tinytitansfootball`. Raise `version/code` by one on every build.
4. The backlog: `BACKLOG.md`, updated, linked and sent to Brian as a file.
5. `docs/index.html` updated: the version line under the buttons (G1.8) and the APK link. Add `docs/release-notes/v<version>.md` with what is new, the kit version and a test checklist.
6. The browser build goes in `docs/play/`.
7. The handoff zip: update `STANDARDS_OVERRIDES.md`, run `tools/common/make_handoff.sh ../game-standards` and send `Game_Standards_handoff.zip` to Brian as a file.

## Open item: Android signing

v0.1.0 is signed with a throwaway test key (override G6.3, agreed 2026-11-14). The next APK is signed with `wandervalley.jks` from `game-signing`. Testers uninstall v0.1.0 once before they install it. After that, updates install over the old copy.

## Reporting to Brian

Lead with the link or file to test. Segment the answer. Short active sentences. No em dashes, no semicolons, no Oxford comma. State plainly what was tested and where. List every judgment call.
