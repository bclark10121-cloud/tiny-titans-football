# Tiny Titans Football: project rules

Tiny Titans Football is Brian's arcade football game. Godot 4.6, Android and browser. This repo is public.

## Standards (G0.10, G10)

- Read `GAME_STANDARDS.md` (rule ids start with G) and `ENGINEERING_STANDARDS.md` (rule ids start with E) first. Both live only in the private repo `bclark10121-cloud/game-standards`. Clone it outside this repo (for example `../game-standards`). This repo holds no copies.
- Overrides, open items and the standards version this game was checked against live in `STANDARDS_OVERRIDES.md`. Order of authority: Brian in the chat, then `STANDARDS_OVERRIDES.md`, then the standards.
- Never edit a standards file. Propose a change to Brian. It changes in `game-standards` first. A football-only exception goes in `STANDARDS_OVERRIDES.md` as Proposed until Brian approves it.
- The shared kit is pulled into `addons/bc_common/`, `tools/common/` and `tests/common/` with `bash ../game-standards/common/sync_common.sh ../game-standards .`. `common.lock` records the version and commit. Never edit those files here. Propose changes to Brian for `game-standards/common`.
- Signing: the key `wandervalley.jks` and its settings live in the private repo `bclark10121-cloud/game-signing` (G1.7). Clone it outside this repo (for example `../game-signing`). Build the APK with `tools/common/sign_android.sh`. The signature must start with `5db69ffb`. Never commit a key, a password or `signing.properties`, and never write a password in a build file, a doc or a reply (G1.9). Re-clone `game-signing` when Brian says its settings changed.
- Do not change other game repos or `game-standards` unless Brian asks. In `bclark10121-cloud.github.io` change only this game's card.
- No personal names on public pages: the game page, the dashboard card and the repo description (G1.11).

## Pillars (never break these)

1. Call it, then run it. The player picks a play, then controls one player.
2. Arcade pace: big hits, fast players, quick downs. A full game takes about 10 minutes.
3. Football rules people know: four downs, first downs, touchdowns, field goals, turnovers.
4. Original everything. Fictional teams, our own plays and art. No real league, team or player names. Nothing copied from Maximum Football or any other game.

Note: this game has an opponent and a final score. `STANDARDS_OVERRIDES.md` records that and every other place this game differs from the standards.

## Rules

- Top menu: one Menu button at the top right opens all options in a row across the top.
- 7 on 7 is the default game. 11 on 11 is a choice on the team screen, saved as `mode`. Role order in `OFF_ROLES` and `DEF_ROLES` decides who plays in 7 on 7: the first 7 of each.
- Xbox controller (G5.8): every screen works with only a controller. `InputSetup.add_controller_ui()` runs at startup. A chooses, B goes back, View and Menu open the Menu. Name buttons by their Xbox labels: View and Menu, never Back or Start.
- Field units are yards. The field runs along Z. Goal lines sit at z = -50 and z = +50. Side 0 (the player) always attacks +Z and the camera always looks down +Z.
- Plays are data in `data/plays.json`, written in the offense frame: x is yards to the offense's right, z is yards downfield.
- Players move with plain maths, not physics bodies. `main.gd` sets `want` and `player.gd` eases toward it.
- Field lines and numbers are painted into one field texture. Never lay a thin layer on the grass: it flickers on phones.
- Save file is `user://tiny_titans.json`, format `v: 1`. Only add fields, each with a safe default and a limit in `_load_save()`. It is read and written with `addons/bc_common/save_store.gd` (E6.7).
- Test hooks stay off for players (G7.8). The browser build publishes `window.ttf` only with the whole-word `?test` flag, through `addons/bc_common/test_bridge.gd`. Every other browser switch (`bot`, `demo`, `fast`, `start_punt`, `start_fg`, `notch`, `eleven`) is read with `TestBridge.has_flag` and only together with `?test`. The Android build reads no switches. Command line switches (`--bot`, `--demo`, `--fast`, `--verbose`, `--games=`, `--seed=`, `--start=`, `--notch=`, `--mode=`) are for desktop and headless runs. A test hook never writes a save outside test mode. A bot run never writes a save.
- Every outside asset goes in `CREDITS.md` with its licence. Music comes from the Patch.gg library (`tools/common/patch_assets.py`).

## Test gate

- `bash tools/common/sync_common.sh --check .` must print `COMMON check ok`.
- `bash tools/common/check_secrets.sh` must print `SECRETS check ok` (G1.9).
- `godot --headless --path . -- --bot --games=6` (7 on 7) and the same with `--mode=11` must finish every game and print `BOT done`. Typical final scores sit between 0 and 50 a side in 7 on 7 and between 0 and 40 in 11 on 11.
- `godot --headless --path . -s res://tests/controller_check.gd` must print `JOY020 check ok`. `godot --headless --path . -s res://tests/screens_check.gd` must print `SCREENS check ok` (G5.8).
- `python3 tests/web_test.py <web build folder> <shots folder>` must print `errors []`. It opens `index.html?test`. View the screenshots.
- `python3 tests/pad_test.py <web build folder> <shots folder>` must print `errors []`. It plays with the kit's pretend Xbox controller (G5.8).
- Test hooks run only with the whole-word `?test` flag and never in the APK (G7.8). Without `?test` the page has no `window.ttf` and `?bot` or `?fast` do nothing.
- `godot --headless --path . -s res://tests/common/save_store_check.gd` must print `SAVESTORE check ok` (E6.7).
- `python3 tests/common/page_check.py https://bclark10121-cloud.github.io/tiny-titans-football/` after every push must print `errors []`.

## Deliver every time (every release)

1. The game page link: https://bclark10121-cloud.github.io/tiny-titans-football/ (give Brian this link, not the direct play link).
2. The GitHub repo link: https://github.com/bclark10121-cloud/tiny-titans-football
3. The APK, named `TinyTitansFootball-v<version>.apk`, built with `tools/common/sign_android.sh`, in `docs/downloads/` and sent to Brian as a file. Package id `com.brianclark.tinytitansfootball`. Raise `version/code` by one on every build.
4. The backlog: `BACKLOG.md`, updated, linked and sent to Brian as a file.
5. `docs/index.html` updated: the version line under the buttons (G1.8) and the APK link. Add `docs/release-notes/v<version>.md` with what is new, the kit version and a test checklist.
6. The browser build goes in `docs/play/`.
7. The handoff zip: update `STANDARDS_OVERRIDES.md`, run `tools/common/make_handoff.sh ../game-standards` and send `Game_Standards_handoff.zip` to Brian as a file.
8. The Game Shelf card (G1.10, G2.7). Brian's standing rule (2026-11-15): every release updates The Game Shelf with every relevant change, in the same push as the release. In the public repo `bclark10121-cloud.github.io`, replace `images/tiny-titans-football.jpg` with a fresh 960 x 540 screenshot of the new build. Update the card text in `index.html` (name, tag line, description, platforms, link) and the picture's alt text whenever any of them changed. Keep the GitHub repo description in step with the tag line. Change only this game's card. The version fills itself from the game page line (G1.8). After the push, open https://bclark10121-cloud.github.io/ and check the card shows the new version and its links answer. Give Brian the dashboard link with the game page link.

## Android signing

Every APK is signed with `wandervalley.jks` from `game-signing` (G6.3). v0.1.0 used a throwaway test key, so testers uninstall v0.1.0 once before they install v0.2.0. Later versions install over the old copy.

## Reporting to Brian

Lead with the game page link, the dashboard link (https://bclark10121-cloud.github.io/) and the files to test. Segment the answer. Short active sentences. No em dashes, no semicolons, no Oxford comma. State plainly what was tested and where. List every judgment call.
