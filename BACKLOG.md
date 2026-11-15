# Tiny Titans Football: backlog

Updated 2026-11-15 for v0.3.2. Brian decides the order.

## Done

### v0.3.2 (standards release: Settings and save slots)

- One Settings menu, the same in every game from now on (asked for by Brian, G5.11). Music and Sound in five levels. Full screen in the browser. Frame rate number. Rumble. Then Auto pass, Players, Quarter length and Controls. Then Text size and Reset settings. Every change saves by itself. No Save button.
- Five save slots (asked for by Brian, G5.12). A Slot button on the title card opens the list. Each slot has its own record, season and saved game. Delete on every used slot, with a second press. Your save from v0.3.1 is now slot 1.
- Settings are kept apart from the slots, so deleting a slot never changes them.
- Shared kit 1.7.0. This game is the pilot for it.

### v0.3.1 (standards release, no new football)

- Debug menu (asked for by Brian, G5.9). Settings shows Tester tools in test builds. A code opens it. Tools: Home score +7, Away score +7, Quarter, Clock to 10 seconds, Final play, New season at week 1, Jump to week 4, Jump to week 6, Jump to the Title Game, Difficulty, Pretend camera notch, Reset the save, Load the test save, a frame rate and memory readout and game speed x1, x2 and x4. A red DEBUG tag shows while it is unlocked. Works with touch, a keyboard or only an Xbox controller.
- Own app icon set (asked for by Brian, G6.10). One 1024 master. Android launcher icon and adaptive icon set for the first time.
- Source moved to the private repo (Brian, G1.7). The public repo now holds only the game page, builds, release notes and this backlog.
- Game page line reads `Version 0.3.1. Release notes · Backlog` (G1.8).
- Test gate: test what changed (G7.9). The 12 bot games and the bot season no longer run on every release.
- Shared kit 1.6.0. This game is the pilot for it.
- Fixed: `project.godot` said version 0.2.0.

### v0.3.0

- Season mode (asked for by Brian). 6 weeks against the other 3 teams, twice each. The other game each week is simulated from team ratings. Standings with W, L, T, points for and points against. The top 2 meet in the Title Game, which goes to more overtime until someone scores. Saved on the device. End season takes two presses.
- Burst button (asked for by Brian). 2 seconds at 1.3 times top speed, ready again 5 seconds after it ends. F, LT or the Burst button with a gold charge ring. Hold-to-sprint stays on Shift, RT and the Sprint button. A runner on a burst is a little harder to tackle.
- Continue a game. Saved at every play call, kickoff and try. The title card shows the score of the game in progress.
- Pause when the game loses focus. The Menu opens and the clock stops.
- Skip the wait after a play with A, Space or a tap.
- Run it again: the play call opens on your last play, marked Last. Defense too.
- Settings panel on the title card and in the Menu: Music, Sound effects, Vibration, Auto pass, Players and Quarter length (1, 2 or 3 minutes).
- Vibration on tackles, stronger on sacks and fumbles. Phone buzz and controller rumble. Android asks for the vibration permission.
- Clearer team screen: Practice mode and Auto pass show On or Off in words. A Back button.
- B goes back on every screen. The D-pad stays inside each panel and on the play cards. The play card gets the focus back when the Menu closes.
- How to play in two columns so it fits on the screen.
- New tests: `tests/qol_check.gd` (30 steps) and the `--season` bot run. The browser and pretend-controller tests cover Settings, the season screen and the burst.

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

- Brian plays v0.3.0 and reports how it feels. Test checklist: `docs/release-notes/v0.3.0.md`.
- v0.3.0 installs over v0.2.0. Anyone still on v0.1.0 uninstalls it once.

## Next (v0.4.0, Brian picks)

Brian's v0.2.0 and v0.3.0 playtest notes come first. Nothing is planned for v0.4.0 yet. The top candidates:

1. Better character design (asked for by Brian). Helmets, pads, jerseys and numbers that read as football players.
2. Penalties (idea 1).
3. A 7 on 7 playbook (idea 13).

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
- 2026-11-15: v0.3.0 holds the burst button, season mode and the quality of life items together (Brian: "move forward with the next release").
- 2026-11-15: LT is the burst and RT stays hold-to-sprint. Brian asked for RT, then kept LT.

## Judgment calls made in v0.3.0 (Brian to confirm or change)

1. Everything planned shipped in one release: the burst, season mode and the 7 quality of life items.
2. A season is 6 weeks: each rival twice. The top 2 by win share, then point difference, then points scored, play the Title Game. If you miss it, the Title Game is simulated.
3. Games you do not play are simulated from the team ratings in `data/teams.json`, with higher scores in 7 on 7. They never end tied.
4. A tied Title Game goes to more overtime periods until someone scores. Regular season ties count as ties.
5. The burst is 1.3 times top speed for 2 seconds, then 5 seconds to charge. It also lowers the tackle chance a little. The computer never bursts.
6. The burst belongs to whoever you control. It keeps charging between plays.
7. Keyboard burst is F. Controller burst is LT. Touch has a fourth Burst button above Juke.
8. Continue saves at play calls, kickoffs and tries, not mid-play. A game left mid-play picks up at the play call before it.
9. Practice games are never saved for Continue. Starting any new game replaces the saved one. A finished game clears it.
10. Players and Quarter length change from the next game, not the game in progress.
11. The old Sound switch is now Sound effects, with the crowd. Music has its own switch, on for everyone after the update.
12. Vibration is on by default. Tackles that involve the player you control buzz. Sacks and fumbles buzz harder.
13. Skip the wait needs half a second first, so a mashed button does not skip the result banner.
14. Pause on focus loss opens the Menu in any in-game screen, play call included.
15. Run it again also opens the defense on your last defense.
16. The title field now shows the 7 on 7 or 11 on 11 choice.
17. The season screenshot on the game page shows a season after 2 weeks. Every score in it came from the game's own season simulation.

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
