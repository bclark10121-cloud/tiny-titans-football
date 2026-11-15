# Tiny Titans Football: standards overrides

Standards: `GAME_STANDARDS.md` (rule ids start with G) and `ENGINEERING_STANDARDS.md` (rule ids start with E) in the private repo `bclark10121-cloud/game-standards`. This repo holds no copies.
This file lists where this game does something else, and why. A rule not listed here applies in full.
Order of authority: Brian in the chat, then this file, then the standards.

Last reviewed: v0.1.0 (2026-11-14).
Checked against: game-standards version 2026-11-14 (commit d116467).

On 2026-11-14 Brian told Claude to apply only the standards that fit a sports game and to use its own judgment. Rows agreed under that instruction say "delegated". Brian can change any of them.

## Overrides

| # | Rule | Standard says | This game does | Why | Ends when | Agreed |
|---|---|---|---|---|---|---|
| 1 | G4.1, G4.4 | Calm games, no way to lose, no opponents, personal bests only | A versus game with tackles, a computer opponent and a final score. A win, loss and tie record is saved | Brian asked for a football game in the style of Maximum Football | No end planned | 2026-11-14 |
| 2 | G6.3 | Sign the APK with `wandervalley.jks` | v0.1.0 is signed with a throwaway test key | The key was not reachable when v0.1.0 was built. Brian chose to keep the test key for now | The next APK. Brian moved the key to `game-signing` on 2026-11-14 and asked for builds with `tools/common/sign_android.sh`. Testers uninstall v0.1.0 once | 2026-11-14 |
| 3 | G4.3, G7.2 | Things to find with a counter and journal. A report that every find is reachable | No finds, no journal and no reach report | A football game has no collectibles | Finds are added to the game | 2026-11-14, delegated |
| 4 | G5.2 | Only a status readout, find counter and touch controls on screen | Scoreboard, play cards, kick meter and receiver labels | Football needs the down, distance, clock and play choices | No end planned | 2026-11-14, delegated |
| 5 | G5.3 | Touch steers by dragging on the left half | A virtual stick on the left, action buttons on the right and tap a receiver to pass | The player moves in every direction and has more actions | No end planned | 2026-11-14, delegated |
| 6 | G5.7 | US units: mph and feet | Yards | Football is measured in yards | No end planned | 2026-11-14, delegated |
| 7 | G6.6 | Anything a player can touch has collision | Players push apart and tackle by distance checks. No collision shapes | 22 players stay cheap on phones and results stay predictable | The game moves to physics bodies | 2026-11-14, delegated |
| 8 | G7.1 | A headless driver proves the main route with 0 resets | A test bot plays full games headless: `--bot --games=6` | There is no route to drive | No end planned | 2026-11-14, delegated |
| 9 | E3.4 | `visibility_range_end` on every prop, small details culled at 25 to 45 m, a `VisibleOnScreenEnabler3D` on every animated character | No visibility ranges and no screen enabler on players | The camera always shows the stadium. Stands, walls and posts are merged meshes with no small details. Players are always on or near the screen | The game adds small props or players leave the screen for long stretches | 2026-11-14, delegated |
| 10 | E4.1 | Physics engine: the default is GodotPhysics3D, chosen per game | No physics engine. Players move with plain maths | Same reason as row 7 | The game moves to physics bodies | 2026-11-14, delegated |

A Proposed row is not in force. The standard applies until Brian agrees.

## Open items (rule applies, work not finished)

Every item below is fixed in the v0.2.0 work, which is built and tested but not released yet.

- G10.1: the game still has its own save code and its own `?test` hook. They move to `addons/bc_common/save_store.gd` and `test_bridge.gd` at the next release, as Brian asked.
- G10.4: the v0.1.0 release notes name no kit version. The next release notes will.
- E1.2: many variables, arrays and dictionaries are untyped.
- E1.3: the HUD runs every frame, including on the title and play call screens.
- E1.5: play-time checks use `distance_to`, not squared distances.
- E2.4: 22 see-through shadow discs under the players.
- E3.1 and E4.6: triangle, draw call and memory budgets are not measured.
- E3.2: each player is about 11 separate mesh nodes. 22 players come to about 240 draw calls.
- E3.4: `mesh_lod_threshold` is not raised (the rest of E3.4 is row 9).
- E4.5: play cards are created and freed on every play call.
- E5.2: 3D render scale is not 0.80 to 0.85 and the frame rate is not capped at 60.
- E5.3: the HUD does not read the display safe area.
- E5.4: movement reads raw keys, not input actions.
- E6.1: browser audio playback type is not set to Sample.
- E6.2: title music starts before the first input.
- E6.3: sound effects are `.ogg`, not mono `.wav`.
- E6.4: Android writes the save directly with no temp file. The browser does not call `JavaScriptBridge.force_fs_sync()`.
- E6.5: no save on pause, focus loss or close.

## Rules met

Checked by reading the code and the repo at commit d116467 of game-standards. The browser test and the page check ran in headless Chrome. Nothing was measured on a phone.

- Game standards: G0.10 (no standards copies in this repo), G0.12, G1.1, G1.2, G1.3, G1.4, G1.5, G1.6, G1.7 (no key or password here, the key lives in `game-signing`), G1.8, G2.1 to G2.6, G3.1 to G3.5, G4.2, G4.6, G5.1, G5.4, G5.5, G5.6, G6.1, G6.2, G6.4, G6.5, G7.3, G7.4, G7.5, G8.1 to G8.4, G10.2, G10.3 (`COMMON check ok: 1.1.0 d116467`), G10.5.
- Proposed rules the game already follows: G4.8, G4.9, G6.7, G7.6.
- Engineering standards: E1.1, E1.4, E2.1, E2.2, E2.3, E2.5, E5.1, E6.6. Browser threads off (part of E6.1).

## Not in use in this game

Finds and journal (row 3), seasonal theme (G4.5), physics timing, colliders and navigation (E4.2, E4.3, E4.4), particles, skeletons and bones, ORM textures, lightmaps, imported `.glb` animations. G10.6 to G10.8 apply to the kit and new games, not to this game's own code.

## How to add an override

1. Flag the conflict to Brian with the options. Do not override by yourself.
2. Add the row as Proposed and list it as a judgment call in the report to Brian.
3. Once he agrees, put the date in the Agreed column.
4. When an override ends, move its row to Ended overrides with the date.
5. When an override fits every game, ask Brian to make it a standard. Then end the override.

## Ended overrides

None yet.
