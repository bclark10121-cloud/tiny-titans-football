# Tiny Titans Football: backlog

Updated 2026-11-14 for v0.2.0. Brian decides the order.

## Done

### v0.2.0

- Kickoffs and punts you play, with a kicker, a timing meter and returns. Touchbacks, muffed punts and safeties with a free kick.
- Interceptions and fumbles are live. Run them back for a score.
- Two-point tries after a touchdown. Sudden death overtime when tied after four quarters. Halftime kickoff.
- Playbook: 33 offensive plays on four tabs (Short, Deep, Run, Option) and 20 defenses on four tabs (Man, Zone, Blitz, Run).
- Option plays (asked for by Brian): Speed Option Right, Speed Option Left, Pistol Option, Zone Read and Zone Read Left. Pitch to the back with E, B or the Pitch button.
- More running plays (asked for by Brian): Counter and Stretch Right join the Run tab.
- Auto pass setting (asked for by Brian): the QB throws for you and you take the catcher. On the team screen and in the Menu. Saved on the device.
- Hot routes and audibles before the snap. Tap a receiver for a bullet, hold for a lob.
- Difficulty: Easy, Normal and Hard.
- Jersey numbers, a holder and kicker on field goals, bigger linemen.
- Kick camera shows the kicker, punter and holder. The near goal posts hide when they block the view.
- Players draw as 10 batches. The browser test shows at most 36 draw calls.
- Sound effects as short mono files. Crowd loop and title music.
- Safe area support for phones with a notch. Saves survive closing the app.
- All 15 engineering open items from v0.1.0 fixed (see `STANDARDS_OVERRIDES.md`).

### v0.1.0

- 11 on 11 exhibition game against the computer. Four 2-minute quarters.
- 8 offensive plays and 4 defenses with play diagrams.
- Pass to four receivers, sprint, juke, dive, tackle and switch defender.
- Downs, first downs, touchdowns, safeties, interceptions, fumbles and turnovers on downs.
- Field goals and extra points with a timing meter.
- 4 fictional teams. Practice mode. Keyboard, controller and touch controls.
- Win, loss and tie record saved on the device.

## Now

- Brian plays v0.2.0 and reports how it feels. Test checklist: `docs/release-notes/v0.2.0.md`.

## Next (planned for v0.3.0)

1. Season mode with standings and a playoff. Brian picked it for v0.2.0. It moved here so v0.2.0 could ship (judgment call 1 below).

## Asked for by Brian, not built yet

1. Player models from Patch.gg. Players are still built in code. Patch.gg has no American football player model.

## Ideas to choose from (Brian picks by number)

1. Penalties: offside, holding and pass interference.
2. Gameplay sliders (speed, tackle strength, pass accuracy).
3. Team and uniform editor.
4. 7 on 7 quick-play option.
5. Weather and night games.
6. Instant replay.
7. Two players on one device.
8. Fatigue and substitutions.
9. Play designer.
10. Sideline players and referees.
11. Spectate mode: the computer plays both sides. The `--demo` test switch already does this.
12. More music from Patch.gg for menus and halftime.
13. Onside kicks.
14. Clearer checkboxes on the team screen.

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
- 2026-11-14: Apply only the standards that fit a sports game. Claude uses its judgment and Brian tests the result.
- 2026-11-14: Add more running plays with option runs and an auto pass setting.

## Judgment calls made in v0.2.0 (Brian to confirm or change)

1. Season mode moved to v0.3.0. v0.2.0 was already large, so it ships now for testing.
2. Option plays have their own Option tab. The Run tab gained Counter and Stretch Right.
3. The zone read is automatic. The QB reads the end, then you control whoever has the ball.
4. On the pitch option, the juke button pitches until the QB passes the line. The QB cannot juke before then.
5. Auto pass: you control nobody from the snap until the catch. If the QB scrambles, you take the QB. Hot routes and audibles still work before the snap.
6. Tap a receiver for a bullet, hold for a lob. The old idea list had it the other way round.
7. When your team kicks, the camera sits higher and farther back so the kicker and the whole line show.
8. The Menu labels got shorter (Help, Restart, Title) so all six options fit in one row.
9. Standards rows decided under Brian's instruction are marked Delegated in `STANDARDS_OVERRIDES.md`. New row 9 (E3.4): no per-prop cull distances, because the whole stadium is always in view.
10. Test switches added: `--demo` (the computer plays both sides with full drawing) and `--start=punt` or `--start=fg` (opens on fourth down). Not shown in the game.

## Judgment calls made in v0.1.0

1. Players are built in code, not taken from Patch.gg.
2. Auto punt on fourth down. Replaced in v0.2.0 by a Kick tab and computer punts.
3. Interceptions and fumbles ended the play at the spot. Replaced in v0.2.0 by returns.
4. A tackle in bounds runs 15 seconds off the clock.
5. Ties stood with no overtime. Replaced in v0.2.0 by sudden death overtime.
6. The player always attacks up the screen. Teams do not switch ends.
7. The APK is signed with a test key.
