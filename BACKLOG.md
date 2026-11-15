# Tiny Titans Football: backlog

Updated 2026-11-15. Brian decides the order.

## Done

- v0.1.0: 11 on 11 exhibition game against the computer. Four 2-minute quarters.
- 8 offensive plays (4 pass, 4 run) and 4 defenses, stored as data.
- Play call screen with play diagrams.
- Pass to four receivers, sprint, juke, dive, tackle and switch defender.
- Downs, first downs, touchdowns, safeties, interceptions, fumbles and turnovers on downs.
- Field goals and extra points with a timing meter. Auto punt on fourth down.
- 4 fictional teams with colors and ratings.
- Practice mode: offense only, no clock, no score.
- Keyboard, controller and touch controls. Menu button at the top right.
- Stadium, crowd, whistle, hits and title music.
- Win, loss and tie record saved on the device.

## Now

- Brian plays v0.1.0 and reports how it feels.

## Next

- v0.2.0: 7 on 7 becomes the default game. 11 on 11 stays as a choice. Plus the option plays already built in the v0.2.0 work (decided by Brian 2026-11-15).
- v0.3.0: the 2 second burst button.

## Asked for by Brian, not built yet

1. Player models from Patch.gg. v0.1.0 uses players built in code. Patch.gg has no American football player model.
2. Better character design (2026-11-15). Players that look more like football players: helmet, pads, jersey and number. Goes with item 1. v0.2.0 adds jersey numbers and bigger linemen.
3. 7 on 7 option (2026-11-15). Planned for v0.2.0 as the default game, with 11 on 11 still a choice. It was idea 9. To confirm with Brian before building: 7 a side with linemen and the run game, or passing only with no linemen. Full field or a shorter one.
4. Option plays (2026-11-15). Built in the v0.2.0 work, ships in v0.2.0: Speed Option Right and Left, Pistol Option, Zone Read and Zone Read Left, with a pitch button.
5. Burst button (2026-11-15). Planned for v0.3.0. A touch button that gives a burst of speed for 2 seconds. Today sprint is a hold: Space or Shift on a keyboard, A or RT on a controller, the A button on touch. Assumptions to confirm: the burst can be used again after 5 seconds, hold-to-sprint stays, and keyboard and controller get the burst on a key and a button too.

## Ideas to choose from (Brian picks by number)

1. Punts and kickoffs you play, with returns.
2. Interception and fumble returns (today the play ends at the spot).
3. Bigger playbooks: 20 or more plays a side.
4. Audibles and hot routes before the snap.
5. Penalties: offside, holding and pass interference.
6. Difficulty levels and gameplay sliders.
7. Season mode with standings and a playoff.
8. Team and uniform editor.
9. Weather and night games.
10. Instant replay.
11. Two players on one device.
12. Fatigue and substitutions.
13. Play designer.
14. Jersey numbers, a kicker and a holder on kicks, sideline players and referees.
15. Spectate mode (computer against computer).
16. Two-point conversions and overtime.
17. More music from Patch.gg for menus and halftime.
18. Throw power: tap for a lob, hold for a bullet pass.

## Later

- Google Play release.
- Online play.

## Not planned

- Real league, team or player names.
- Anything copied from Maximum Football or another game.

## Decisions from Brian

- 2026-11-14: Focus on on-field play. Godot for Android and browser. Angled camera with low-poly 3D.
- 2026-11-14: 11 on 11. Arcade feel. Use Patch.gg.
- 2026-11-14: Name is Tiny Titans Football. Brian kept the name after seeing the overlap notes (DC Comics "Tiny Titans", Tennessee Titans).

- 2026-11-14: Keep the test signing key for now.
- 2026-11-14: Game standards and engineering standards are two separate files. Rule ids carry G and E prefixes. One `STANDARDS_OVERRIDES.md` per game. The master copy lives in the private repo `game-standards`.
- 2026-11-14: Fix the engineering open items in `STANDARDS_OVERRIDES.md` as part of v0.2.
- 2026-11-14: v0.2 scope picked: kicking game and returns, feel and polish, bigger playbook, season mode.
- 2026-11-14: One source. The standards live only in the private repo `game-standards`. The shared kit is pulled into this repo with `sync_common.sh`. The signing key lives in the private repo `game-signing`.
- 2026-11-15: 7 on 7 is the default game in v0.2.0 and 11 on 11 stays a choice. Option plays ship in v0.2.0. The 2 second burst button comes in v0.3.0.

## Judgment calls made in v0.1.0 (Brian to confirm or change)

1. Players are built in code, not taken from Patch.gg.
2. Auto punt added on fourth down so the computer is not forced to go for it.
3. Interceptions and fumbles end the play at the spot.
4. A tackle in bounds runs 15 seconds off the clock.
5. Ties stand. No overtime.
6. The player always attacks up the screen. Teams do not switch ends.
7. The APK is signed with a test key.
