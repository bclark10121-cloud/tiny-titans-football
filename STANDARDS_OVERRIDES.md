# Tiny Titans Football: standards overrides

Standards: `GAME_STANDARDS.md` (rule ids start with G) and `ENGINEERING_STANDARDS.md` (rule ids start with E) in the private repo `bclark10121-cloud/game-standards`. This repo holds no copies.
This file lists where this game does something else, and why. A rule not listed here applies in full.
Order of authority: Brian in the chat, then this file, then the standards.

Last reviewed: 2026-11-15, with v0.2.0.
Checked against: game-standards version 2026-11-15 (commit b2c2865). Shared kit 1.5.0.

On 2026-11-14 Brian told Claude to apply only the standards that fit a sports game and to use its own judgment. Rows agreed under that instruction say "delegated". Brian can change any of them.

## Overrides

| # | Rule | Standard says | This game does | Why | Ends when | Agreed |
|---|---|---|---|---|---|---|
| 1 | G4.1, G4.4 | Calm games, no way to lose, no opponents, personal bests only | A versus game with tackles, a computer opponent and a final score. A win, loss and tie record is saved | Brian asked for a football game in the style of Maximum Football | No end planned | 2026-11-14 |
| 3 | G4.3, G7.2 | Things to find with a counter and journal. A report that every find is reachable | No finds, no journal and no reach report | A football game has no collectibles | Finds are added to the game | 2026-11-14, delegated |
| 4 | G5.2 | Only a status readout, find counter and touch controls on screen | Scoreboard, play cards, kick meter and receiver labels | Football needs the down, distance, clock and play choices | No end planned | 2026-11-14, delegated |
| 5 | G5.3 | Touch steers by dragging on the left half | A virtual stick on the left, action buttons on the right and tap a receiver to pass | The player moves in every direction and has more actions | No end planned | 2026-11-14, delegated |
| 6 | G5.7 | US units: mph and feet | Yards | Football is measured in yards | No end planned | 2026-11-14, delegated |
| 7 | G6.6 | Anything a player can touch has collision | Players push apart and tackle by distance checks. No collision shapes | Up to 22 players stay cheap on phones and results stay predictable | The game moves to physics bodies | 2026-11-14, delegated |
| 8 | G7.1 | A headless driver proves the main route with 0 resets | A test bot plays full games headless: `--bot --games=6` | There is no route to drive | No end planned | 2026-11-14, delegated |
| 9 | E3.4 | `visibility_range_end` on every prop, small details culled at 25 to 45 m, a `VisibleOnScreenEnabler3D` on every animated character | No visibility ranges and no screen enabler on players | The camera always shows the stadium. Stands, walls and posts are merged meshes with no small details. Players are always on or near the screen | The game adds small props or players leave the screen for long stretches | 2026-11-14, delegated |
| 10 | E4.1 | Physics engine: the default is GodotPhysics3D, chosen per game | No physics engine. Players move with plain maths | Same reason as row 7 | The game moves to physics bodies | 2026-11-14, delegated |

A Proposed row is not in force. The standard applies until Brian agrees.

## Open items (rule applies, work not finished)

None. All 15 engineering open items from v0.1.0 and the G7.8, E6.7, G10.1 and G10.4 items were fixed in v0.2.0. They are listed under Rules met.

## Rules met

Checked by reading the code and the repo against commit b2c2865 of game-standards. The bot games (7 on 7 and 11 on 11), the browser test, the pretend-controller browser test, the headless controller and screens checks, the save store check, a G7.8 check and the page check ran. Nothing was measured on a phone or with a real controller.

- Game standards: G0.10 (no standards copies in this repo), G0.12, G1.1 to G1.6, G1.7 (no key or password here, the key lives in `game-signing`), G1.8, G1.9 (`SECRETS check ok`, `signing.properties` and `game-signing/` in `.gitignore`), G1.10 (card on The Game Shelf, footer link to it), G1.11 (no personal names on the game page, the card or the repo description), G2.1 to G2.6, G2.7 (the card is refreshed for v0.2.0 in the same push), G3.1 to G3.5, G4.2, G4.6, G5.1, G5.4, G5.5, G5.6, G6.1, G6.2, G6.3 (v0.2.0 is signed with `wandervalley.jks`, signature `5db69ffb`), G6.4, G6.5, G7.3, G7.4, G7.5, G8.1 to G8.4, G10.2, G10.3 (`COMMON check ok: 1.5.0 b2c2865`), G10.5.
- Proposed rules the game already follows: G4.8, G4.9, G6.7, G7.6.
- Engineering standards: E1.1, E1.4, E2.1, E2.2, E2.3, E2.5, E5.1, E6.6. Browser threads off (part of E6.1).
- Fixed in v0.2.0:
  - G5.8: every screen works with only an Xbox controller. `InputSetup.add_controller_ui()` runs at startup. A chooses, B goes back, View and Menu open and close the Menu. Xbox button names everywhere a player reads them. The game page has the Play with an Xbox controller section. `tests/pad_test.py` plays with the kit's pretend controller and prints `errors []`. `tests/controller_check.gd` and `tests/screens_check.gd` check the same headless.
  - G7.8: `window.ttf` and every browser switch (`bot`, `demo`, `fast`, `start_punt`, `start_fg`, `notch`, `eleven`) need the whole-word `?test` flag, read with the kit's `TestBridge`. The Android build reads no switches. A bot run never writes a save.
  - E6.7 and G10.1: saves go through the kit's `save_store.gd` with limits on every field. `SAVESTORE check ok` is in the test gate.
  - G10.4: the v0.2.0 release notes name kit 1.5.0.
  - E1.2: every declaration is typed. The project treats an untyped declaration as an error.
  - E1.3: the HUD only runs while a banner fades. The pad and kick meter redraw on demand. The game loop runs every frame because the camera and players move every frame.
  - E1.5: checks use squared distances. Real distances are only taken where the value itself is needed, such as pass flight time.
  - E2.4: player shadows are opaque. No see-through layers. Players who sit out in 7 on 7 draw no shadow.
  - E3.1 and E4.6: measured in the browser test. At most 34 draw calls, about 5,500 triangles and 44 MB of video memory. Each player is about 130 triangles.
  - E3.2: players draw as 10 batches, one per body part.
  - E3.4: `mesh_lod_threshold` raised to 3 (the rest of E3.4 is row 9).
  - E4.5: play cards are pooled.
  - E5.2: 3D render scale 0.85 and a 60 frame cap on browser and Android.
  - E5.3: the HUD reads the display safe area. `--notch=80` fakes one for tests.
  - E5.4: all input goes through input actions. Touch controls hide when a key or controller is used.
  - E5.5 (Proposed in the standards): the game already takes up to three smaller steps per frame on slow devices.
  - E6.1: browser audio plays as Sample.
  - E6.2: no sound starts before the first key, tap, click or button.
  - E6.3: sound effects are mono `.wav` at 22.05 or 32 kHz. Crowd loop 96 kbps and music 112 kbps `.ogg`.
  - E6.4: the save store writes a temp file, then renames it. The browser calls `JavaScriptBridge.force_fs_sync()`.
  - E6.5: the game saves on pause, focus loss and close.

## Not in use in this game

Finds and journal (row 3), seasonal theme (G4.5), physics timing, colliders and navigation (E4.2, E4.3, E4.4), particles, skeletons and bones, ORM textures, lightmaps, imported `.glb` animations. G10.6 to G10.8 apply to the kit and new games, not to this game's own code.

## How to add an override

1. Flag the conflict to Brian with the options. Do not override by yourself.
2. Add the row as Proposed and list it as a judgment call in the report to Brian.
3. Once he agrees, put the date in the Agreed column.
4. When an override ends, move its row to Ended overrides with the date.
5. When an override fits every game, ask Brian to make it a standard. Then end the override.

## Ended overrides

| # | Rule | Standard says | This game did | Why | Ended | Agreed |
|---|---|---|---|---|---|---|
| 2 | G6.3 | Sign the APK with `wandervalley.jks` | v0.1.0 was signed with a throwaway test key | The key was not reachable when v0.1.0 was built | 2026-11-15 with v0.2.0, signed with `wandervalley.jks` from `game-signing`. Testers uninstall v0.1.0 once | 2026-11-14 |
