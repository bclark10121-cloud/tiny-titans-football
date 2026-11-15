# Tiny Titans Football: standards overrides

Standards: `handoff/GAME_STANDARDS.md` (rule ids start with G) and `handoff/ENGINEERING_STANDARDS.md` (rule ids start with E).
This file lists where this game does something else, and why. A rule not listed here applies in full.
Order of authority: Brian in the chat, then this file, then the standards.

Last reviewed: v0.2.0 (2026-11-14), against both standards files version 2026-11-14.

On 2026-11-14 Brian asked Claude to apply only the standards that fit a sports game and to use its own judgment. Rows marked "Delegated" were decided under that instruction. Brian can change any of them.

## Overrides

| # | Rule | Standard says | This game does | Why | Ends when | Agreed |
|---|---|---|---|---|---|---|
| 1 | G4.1, G4.4 | Calm games, no way to lose, no opponents, personal bests only | A versus game with tackles, a computer opponent and a final score. A win, loss and tie record is saved | Brian asked for a football game in the style of Maximum Football | No end planned | 2026-11-14 |
| 2 | G6.3 | Sign the APK with `wandervalley.jks` | Signed with a throwaway test key | Brian chose to keep the test key for now. Testers uninstall before each update | Brian says to use his signing key | 2026-11-14 |
| 3 | G4.3, G7.2 | Things to find with a counter and journal. A report that every find is reachable | No finds, no journal and no reach report | A football game has no collectibles | Finds are added to the game | Delegated 2026-11-14 |
| 4 | G5.2 | Only a status readout, find counter and touch controls on screen | Scoreboard, sprint bar, play cards, kick meter and receiver labels | Football needs the down, distance, clock and play choices | No end planned | Delegated 2026-11-14 |
| 5 | G5.3 | Touch steers by dragging on the left half | A virtual stick on the left, three action buttons on the right and tap a receiver to pass | The player moves in every direction and has more actions | No end planned | Delegated 2026-11-14 |
| 6 | G5.7 | US units: mph and feet | Yards | Football is measured in yards | No end planned | Delegated 2026-11-14 |
| 7 | G6.6 | Anything a player can touch has collision | Players push apart and tackle by distance checks. No collision shapes | 22 players stay cheap on phones and results stay predictable | The game moves to physics bodies | Delegated 2026-11-14 |
| 8 | G7.1 | A headless driver proves the main route with 0 resets | A test bot plays full games headless: `--bot --games=6` | There is no route to drive | No end planned | Delegated 2026-11-14 |
| 9 | E3.4 | `visibility_range_end` on every prop, a 25 to 45 m cutoff for small details, and a `VisibleOnScreenEnabler3D` on every animated character | No visibility ranges. Players have no screen enabler | The camera always shows the stadium. Stands, walls and posts are merged meshes with no small details. Players draw as batches, so a per-player cutoff does nothing. `mesh_lod_threshold` is 3.0 as the rule asks | The game adds small props or players leave the screen for long stretches | Delegated 2026-11-14 |
| 10 | E4.1 | Physics engine: the default is GodotPhysics3D, chosen per game | No physics engine. Players move with plain maths | 22 players stay cheap on phones and results stay predictable. Same reason as row 7 | The game moves to physics bodies | Delegated 2026-11-14 |

A Proposed row is not in force. The standard applies until Brian agrees. A Delegated row is in force. Brian can overturn it at any time.

## Open items (rule applies, work not finished)

None. All 15 open items from v0.1.0 were fixed in v0.2.0. They are listed under Rules met.

## Rules met

Checked by reading the code and by the browser test in headless Chrome at v0.2.0. Nothing was measured on a phone.

- Game standards: G1.1 to G1.6, G2.1 to G2.6, G4.2, G4.6, G5.1, G5.4, G5.5, G5.6, G6.1, G6.2, G6.4, G6.5, G7.3, G7.4, G7.5, G8.1, G8.2, G8.3, G8.4.
- Engineering standards: E1.1, E1.4, E2.1, E2.2, E2.3, E2.5, E5.1, E6.6, browser threads off.
- Fixed in v0.2.0:
  - E1.2: every declaration is typed. The project treats an untyped declaration as an error.
  - E1.3: the HUD only runs while a banner fades. The pad and kick meter redraw on demand. The game loop runs every frame because the camera and players move every frame.
  - E1.5: checks use squared distances. Real distances are only taken where the value itself is needed, such as pass flight time.
  - E2.4: player shadows are opaque. No see-through layers.
  - E3.1 and E4.6: measured in the browser test. At most 36 draw calls, about 5,700 to 9,600 triangles and 44 MB of video memory. Each player is about 130 triangles.
  - E3.2: players draw as 10 batches, one per body part. This ended override row 9 from v0.1.0.
  - E4.5: play cards are pooled.
  - E5.2: 3D render scale 0.85 and a 60 frame cap on browser and Android.
  - E5.3: the HUD reads the display safe area. `--notch=80` fakes one for tests.
  - E5.4: all input goes through input actions. Touch controls hide when a key or gamepad is used.
  - E5.5 (Proposed in the standards): the game already takes up to three smaller steps per frame on slow devices.
  - E6.1: browser audio plays as Sample.
  - E6.2: no sound starts before the first key, tap or click.
  - E6.3: sound effects are mono `.wav` at 22.05 or 32 kHz. Crowd loop 96 kbps and music 112 kbps `.ogg`.
  - E6.4: Android writes a temp file, then renames it. The browser calls `JavaScriptBridge.force_fs_sync()`.
  - E6.5: the game saves on pause, focus loss and close.

## Not in use in this game

Finds and journal, seasonal theme (G4.5), physics timing and colliders (E4.2, E4.3), navigation (E4.4), particles, skeletons, ORM textures, lightmaps.

## How to add an override

1. Flag the conflict to Brian with the options. Do not override by yourself.
2. Add the row as Proposed and list it as a judgment call in the report to Brian.
3. Once he agrees, put the date in the Agreed column.
4. When an override ends, move its row to Ended overrides with the date.
5. When an override fits every game, ask Brian to make it a standard. Then end the override.

## Ended overrides

| # | Rule | What the override was | Ended | Why it ended |
|---|---|---|---|---|
| 9 (v0.1.0) | E3.2 | Each player was about 11 separate mesh nodes, about 240 draw calls for 22 players | v0.2.0, 2026-11-14 | Players now draw as 10 batches, one per body part |
