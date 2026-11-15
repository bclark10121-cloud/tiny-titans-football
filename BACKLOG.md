# Tiny Titans Football: backlog

Updated 2026-11-15 after v0.2.0. Brian decides the order.

## Done

### v0.2.0

- 7 on 7 is the default game (asked for by Brian). Offense: 3 linemen, a QB, a running back and 2 receivers. Defense: 3 linemen, 2 linebackers and 2 defensive backs. Full 100-yard field. Kickoffs and punts are 7 a side too.
- 11 on 11 stays a choice. Players on the team screen. Saved on the device.
- Full Xbox controller support (G5.8). Every screen works with only a controller. A chooses, B goes back, View or Menu opens the Menu. The game page has a section on pairing an Xbox controller.
- Kickoffs and punts you play, with a kicker, a timing meter and returns. Touchbacks, muffed punts and safeties with a free kick.
- Interceptions and fumbles are live. Run them back for a score.
- Two-point tries after a touchdown. Sudden death overtime when tied after four quarters. Halftime kickoff.
- Playbook: 33 offensive plays on four tabs (Short, Deep, Run, Option) and 20 defenses on four tabs (Man, Zone, Blitz, Run).
- Option plays (asked for by Brian): Speed Option Right, Speed Option Left, Pistol Option, Zone Read and Zone Read Left. Pitch to the back with E, B or the Pitch button.
- More running plays (asked for by Brian): Counter and Stretch Right join the Run tab.
- Auto pass setting (asked for by Brian): the QB throws for you and you take the catcher. On the team screen and in the Menu. Saved on the device.
- Hot routes and audibles before the snap. Tap a receiver's button for a bullet, hold it for a lob.
- Difficulty: Easy, Normal and Hard.
- Jersey numbers, a holder and kicker on field goals, bigger linemen.
- Kick camera shows the kicker, punter and holder. The near goal posts hide when they block the view.
- Players draw as 10 batches. The browser test shows at most 34 draw calls.
- Sound effects as short mono files. Crowd loop and title music.
- Safe area support for phones with a notch. Saves go through the shared save store and survive closing the app.
- Signed with the real key. Shared kit 1.5.0.
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
- Testers uninstall v0.1.0 once before they install v0.2.0.

## Next (planned for v0.3.0)

Brian's v0.2.0 playtest notes come first and outrank this list.

1. Burst button (asked for by Brian, 2026-11-15). A touch button that gives a burst of speed for 2 seconds. Today sprint is a hold: Shift on a keyboard, RT on a controller, the Sprint button on touch. Assumptions to confirm: the burst works again after 5 seconds, hold-to-sprint stays, and keyboard and controller get the burst on a key and a button too.
2. Season mode with standings and a playoff. Brian picked it for v0.2.0. It moved here so v0.2.0 could ship.
3. Quality of life. Picked by Claude on 2026-11-15 at Brian's request. In build order:
   1. Continue a game. The game keeps the score, clock, quarter, down, ball spot, teams and settings when the app goes to the background or closes. The title shows Continue. Why: if Android closes the app in the background, the game in progress is lost today. Season mode needs the same save. Size: medium.
   2. Pause when the game loses focus. The Menu opens and the clock stops when the app or browser tab loses focus mid-game. Why: today a pulled-down notification shade or a click in another window lets the play run on. Size: small.
   3. Skip the wait after a play. After the whistle the game waits 2.3 seconds. A, Space or a tap moves on after half a second. Why: quick downs are a pillar. Size: small.
   4. Run it again. The play call opens on the tab of your last play, with its card highlighted and marked Last. One press calls it again. Fourth down still opens the Kick tab. Why: arcade players repeat plays that work. Today the play call opens on Short, Run or Kick by down and distance. Size: small.
   5. Settings panel. The Menu gets one Settings button with Music, Sound effects, Auto pass, Players (7 on 7 or 11 on 11), Quarter length (1, 2 or 3 minutes) and Vibration. Why: today one Sound switch turns off both music and effects. Players only shows on the team screen. Quarter length lets a game run about 5 to 15 minutes. The Menu row also gets shorter. Size: medium.
   6. Vibration on big hits. A short buzz on the phone and a rumble on the controller for tackles, sacks and big hits, with the switch in Settings. On by default. Why: big hits are a pillar. Size: small.
   7. Clearer switches on the team screen (was idea 13). Practice mode and Auto pass show On or Off in words. Size: small.

## Asked for by Brian, not built yet

1. Player models from Patch.gg. Players are still built in code. Patch.gg has no American football player model.
2. Better character design (2026-11-15). Players that look more like football players: helmet, pads, jersey and number. Goes with item 1. v0.2.0 added jersey numbers and bigger linemen.

## Ideas to choose from (Brian picks by number)

1. Penalties: offside, holding and pass interference.
2. Gameplay sliders (speed, tackle strength, pass accuracy).
3. Team and uniform editor.
4. Weather and night games.
5. Instant replay.
6. Two players on one device.
7. Fatigue and substitutions.
8. Play designer.
9. Sideline players and referees.
10. Spectate mode: the computer plays both sides. The `--demo` test switch already does this.
11. More music from Patch.gg for menus and halftime.
12. Onside kicks.
13. 7 on 7 playbook: plays drawn for 7 a side. Today 7 on 7 uses the 11 on 11 plays with the extra players taken out.
14. Open receiver colours. Each receiver's button label turns green when open and red when covered. A help for new players.
15. Box score at the end of the game: passing and rushing yards, completions and the longest play. Today the end screen shows total yards and turnovers.

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
- 2026-11-14: Keep the test signing key for now. Ended in v0.2.0: it uses the real key.
- 2026-11-14: Game standards and engineering standards are two separate files. Rule ids carry G and E prefixes. One `STANDARDS_OVERRIDES.md` per game. The master copy lives in the private repo `game-standards`.
- 2026-11-14: Fix the engineering open items in `STANDARDS_OVERRIDES.md` as part of v0.2.
- 2026-11-14: v0.2 scope picked: kicking game and returns, feel and polish, bigger playbook, season mode.
- 2026-11-14: Apply only the standards that fit a sports game. Claude uses its judgment and Brian tests the result.
- 2026-11-14: Add more running plays with option runs and an auto pass setting.
- 2026-11-14: One source. The standards live only in the private repo `game-standards`. The shared kit is pulled into this repo with `sync_common.sh`. The signing key lives in the private repo `game-signing`.
- 2026-11-15: 7 on 7 is the default game in v0.2.0 and 11 on 11 stays a choice. Option plays ship in v0.2.0. The 2 second burst button comes in v0.3.0.
- 2026-11-15: 7 on 7 offense: 3 linemen, 1 QB, 1 RB and 2 WR. Defense: 3 linemen, 2 linebackers and 2 defensive backs. Full field.
- 2026-11-15: Controller passing stays on A, B, X and Y, the button shown on each receiver. Shoulder buttons stay for sprint, switch and hot routes.
- 2026-11-15: Tag line is "Arcade 7 on 7 and 11 on 11 football".
- 2026-11-15: Every release updates The Game Shelf card with every relevant change, in the same push.
- 2026-11-15: Xbox controller support per G5.8, with Xbox button names and a pretend-controller browser test.
- 2026-11-15: Claude picks the quality of life items for v0.3.0 (Brian: "use your best judgement").

## Judgment calls made in v0.2.0 (Brian to confirm or change)

1. Season mode moved to v0.3.0. v0.2.0 was already large, so it ships now for testing.
2. Option plays have their own Option tab. The Run tab gained Counter and Stretch Right.
3. The zone read is automatic. The QB reads the end, then you control whoever has the ball.
4. On the pitch option, the juke button pitches until the QB passes the line. The QB cannot juke before then.
5. Auto pass: you control nobody from the snap until the catch. If the QB scrambles, you take the QB. Hot routes and audibles still work before the snap.
6. Tap a receiver for a bullet, hold for a lob. The old idea list had it the other way round.
7. When your team kicks, the camera sits higher and farther back so the kicker and the whole line show.
8. The Menu labels got shorter (Help, Restart, Title) so all options fit in one row.
9. Standards rows decided under Brian's instruction are marked Delegated in `STANDARDS_OVERRIDES.md`. Row 9 (E3.4): no per-prop cull distances, because the whole stadium is always in view.
10. Test switches added: `--demo` (the computer plays both sides with full drawing), `--start=punt` or `--start=fg` (opens on fourth down) and `--mode=7` or `--mode=11`. Not shown in the game.
11. 7 on 7 uses the same playbook. Routes for the tight end and the third receiver drop off. Pass plays go to the 2 receivers and the running back, so there are 3 targets. If a play has no route for the back, he runs a swing route.
12. In 7 on 7, a defender assigned man coverage on a receiver who is not on the field plays a short zone instead.
13. 7 on 7 scores run higher than 11 on 11 (17 to 47 a side in the bot games, against 0 to 21). The bot range in `CLAUDE.md` now reads 0 to 50 a side.
14. An old save with no Players choice starts in 7 on 7, the new default.
15. On a controller, B goes back: it closes How to play first, then the Menu. B still jukes and passes during a play.
16. The APK was rebuilt after a last fix (no shadow under players sitting out). It keeps version code 2, because no v0.2.0 APK went out before it.

## Judgment calls made in v0.1.0

1. Players are built in code, not taken from Patch.gg.
2. Auto punt on fourth down. Replaced in v0.2.0 by a Kick tab and computer punts.
3. Interceptions and fumbles ended the play at the spot. Replaced in v0.2.0 by returns.
4. A tackle in bounds runs 15 seconds off the clock.
5. Ties stood with no overtime. Replaced in v0.2.0 by sudden death overtime.
6. The player always attacks up the screen. Teams do not switch ends.
7. The APK is signed with a test key. Replaced in v0.2.0 by the real key.
