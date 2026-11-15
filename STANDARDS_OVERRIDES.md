# Tiny Titans Football: standards overrides

This game follows `handoff/STANDARDS.md` except where a row below says otherwise.
Order of authority: Brian in the chat, then this file, then the standards.
Status is `Approved` (with the date Brian said yes) or `Proposed` (waiting for Brian).

| Rule | Standard says | This game does | Why | Status |
| --- | --- | --- | --- | --- |
| 4.1 | Calm games. No combat. No way to lose. | A versus game with tackles, an opponent and a final score. | Brian asked for a football game in the style of Maximum Football. | Approved 2026-11-14 |
| 4.4 | Personal bests only. No opponents. | The player faces a computer team. A win, loss and tie record is saved. | Football needs an opponent. | Approved 2026-11-14 |
| 6.3 | Sign the APK with `wandervalley.jks`. | Sign with a throwaway test key. | Brian chose to keep the test key for now. Testers uninstall before each update. | Approved 2026-11-14 |
| 4.3 | Things to find, with a counter and a journal. | No finds and no journal. | A football game has no collectibles. | Proposed |
| 5.2 | Only a status readout, find counter and touch controls on screen. | Scoreboard, sprint bar, play cards, kick meter and receiver labels. | Football needs the down, distance, clock and play choices. | Proposed |
| 5.3 | Touch: steer by dragging on the left half. | A virtual stick on the left, three action buttons on the right and tap a receiver to pass. | The player moves in every direction and has more actions. | Proposed |
| 5.7 | US units: mph and feet. | Yards. | Football is measured in yards. | Proposed |
| 6.1 | Jolt physics. | No physics engine. Players move with plain maths. | 22 players stay cheap on phones and the results stay predictable. | Proposed |
| 6.6 | Anything a player can touch has collision. | Players push apart and tackle by distance checks. No collision shapes. | Follows from the 6.1 override. | Proposed |
| 7.1 | A test driver proves the main route is drivable. | A test bot plays full games headless (`--bot --games=6`). Rule 7.6 covers this. | There is no route to drive. | Proposed |
| 7.2 | A report proves every find is reachable. | Not used. | There are no finds. | Proposed |

## Game-only rules

Rules that apply to this game and have no matching standard.

1. No real league, team or player names. Nothing copied from Maximum Football or any other game.
2. Plays and teams are data in `data/`. New plays need no code.
3. The player always attacks up the screen. The camera always looks down +Z.
