# Tiny Titans Football: standards overrides

Standards: `handoff/GAME_STANDARDS.md` (rule ids start with G) and `handoff/ENGINEERING_STANDARDS.md` (rule ids start with E).
This file lists where this game does something else, and why. A rule not listed here applies in full.
Order of authority: Brian in the chat, then this file, then the standards.

Last reviewed: v0.1.0 (2026-11-14), against both standards files version 2026-11-14.

## Overrides

| # | Rule | Standard says | This game does | Why | Ends when | Agreed |
|---|---|---|---|---|---|---|
| 1 | G4.1, G4.4 | Calm games, no way to lose, no opponents, personal bests only | A versus game with tackles, a computer opponent and a final score. A win, loss and tie record is saved | Brian asked for a football game in the style of Maximum Football | No end planned | 2026-11-14 |
| 2 | G6.3 | Sign the APK with `wandervalley.jks` | Signed with a throwaway test key | Brian chose to keep the test key for now. Testers uninstall before each update | Brian says to use his signing key | 2026-11-14 |
| 3 | G4.3, G7.2 | Things to find with a counter and journal. A report that every find is reachable | No finds, no journal and no reach report | A football game has no collectibles | Finds are added to the game | Proposed |
| 4 | G5.2 | Only a status readout, find counter and touch controls on screen | Scoreboard, sprint bar, play cards, kick meter and receiver labels | Football needs the down, distance, clock and play choices | No end planned | Proposed |
| 5 | G5.3 | Touch steers by dragging on the left half | A virtual stick on the left, three action buttons on the right and tap a receiver to pass | The player moves in every direction and has more actions | No end planned | Proposed |
| 6 | G5.7 | US units: mph and feet | Yards | Football is measured in yards | No end planned | Proposed |
| 7 | G6.6 | Anything a player can touch has collision | Players push apart and tackle by distance checks. No collision shapes | 22 players stay cheap on phones and results stay predictable | The game moves to physics bodies | Proposed |
| 8 | G7.1 | A headless driver proves the main route with 0 resets | A test bot plays full games headless: `--bot --games=6` | There is no route to drive | No end planned | Proposed |
| 9 | E3.2 | Repeated props use `MultiMeshInstance3D` or are merged by material | Each player is about 11 separate mesh nodes with moving arms and legs. 22 players come to about 240 draw calls | Limbs animate per player, so they cannot share one multimesh as built | Players become single skinned meshes | Proposed |
| 10 | E4.1 | Physics engine: the default is GodotPhysics3D, chosen per game | No physics engine. Players move with plain maths | 22 players stay cheap on phones and results stay predictable. Same reason as row 7 | The game moves to physics bodies | Proposed |

A Proposed row is not in force. The standard applies until Brian agrees.

## Open items (rule applies, work not finished)

- E1.2: many variables, arrays and dictionaries are untyped.
- E1.3: the game loop and the HUD run every frame, including on the title and play call screens.
- E1.5: play-time checks use `distance_to`, not squared distances.
- E2.4: 22 see-through shadow discs under the players. Overdraw is not measured.
- E3.1 and E4.6: triangle, draw call and memory budgets are not measured. Draw calls are likely near or over the 300 limit (see row 9).
- E3.4: no `visibility_range_end` on the stands and no `mesh_lod_threshold` set.
- E4.5: play cards are created and freed on every play call. Not pooled.
- E5.2: 3D render scale is not set to 0.80 to 0.85 and the frame rate is not capped at 60.
- E5.3: the HUD does not read the display safe area.
- E5.4: movement reads raw keys, not input actions. Touch controls do not hide when a key or gamepad is used.
- E6.1: browser audio playback type is not confirmed as Sample.
- E6.2: title music starts before the first input.
- E6.3: sound effects are `.ogg`, not mono `.wav`. Music bitrate is not checked.
- E6.4: Android writes the save directly, with no temp file and rename. The browser writes directly but does not call `JavaScriptBridge.force_fs_sync()`.
- E6.5: no save on pause, focus loss or close. No browser file sync call.

## Rules met

Checked by reading the code and the repo at v0.1.0. Nothing was measured on a device.

- Game standards: G1.1 to G1.6, G2.1 to G2.6, G4.2, G4.6, G5.1, G5.4, G5.5, G5.6, G6.1, G6.2, G6.4, G6.5, G7.3, G7.4, G7.5, G8.1, G8.2, G8.3, G8.4.
- Engineering standards: E1.1, E1.4, E2.1, E2.2, E2.3, E2.5, E5.1, E6.6, browser threads off.

## Not in use in this game

Finds and journal, seasonal theme (G4.5), physics timing and colliders (E4.2, E4.3), navigation (E4.4), particles, skeletons, ORM textures, lightmaps.

## How to add an override

1. Flag the conflict to Brian with the options. Do not override by yourself.
2. Add the row as Proposed and list it as a judgment call in the report to Brian.
3. Once he agrees, put the date in the Agreed column.
4. When an override ends, move its row to Ended overrides with the date.
5. When an override fits every game, ask Brian to make it a standard. Then end the override.

## Ended overrides

None yet.
