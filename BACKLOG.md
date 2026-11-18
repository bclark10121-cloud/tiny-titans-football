# Tiny Titans Football: backlog

Updated 2026-11-18 for v0.6.1. BC decides the order.

## Done

- v0.6.1 (2026-11-18): start screen music (G5.21, asked for by BC). The title track is its own "Rock on Chicago", now started at once off the web (`_unlock_audio()` from `_ready()`). On Android and desktop it starts with the start screen, in a browser on the first press. No two games share a title track.

### v0.6.0 (2026-11-17: Back at the top, landscape and portrait)

- Back at the top left of every full-screen panel (asked for by BC, G5.30): Settings, slot list, play mode, team, How to play, Records, Change controls. The header never scrolls.
- Plays fully in portrait and landscape (asked for by BC, G6.18). Menus keep their size upright. Teams in one column, play cards three across, Menu row under the scoreboard, banners wrap. Portrait camera keeps the side-to-side view.
- Turning the device mid-game keeps the game.
- How to play text 18 instead of 15 (G5.26), scrolls when long.
- `tests/orient_test.py`: five sizes, every panel, a turn mid-play. `tests/pad_test.py` walks the stacked start screen.
- Pilot for kit 1.13.0.

### v0.5.2 (2026-11-17: Release 7, the standards review pieces, kit 1.12.0)

- Records page with 10 achievements and 6 stats, Change controls with Sprint Hold or Toggle, Picture and Battery saver, backup codes, old-save checks, an error log and crowd sound at one loudness level.

### v0.5.1 (2026-11-17: new music)

- New title music (asked for by BC, picked from three options): "Stage 3" by Juhani Junkala, CC0. Replaces "Rock on Chicago". Loudness matched to the old track.

### v0.5.0 (2026-11-17: new players, run cycle and celebrations)

- New player look (asked for by BC). Built in code to match BC's approved Gemini views (front, side and back in `art_src/reference/`): a big rounded helmet, a face mask cage, a face with eyes, huge rounded shoulder pads, bare arms, big mitten gloves, pants, sock bands and cleats. Low-poly faceted shapes like the reference.
- Team colour zones from the approved art: jersey, pads and sock bands in the team jersey colour. Pants and socks in the team pants colour. The helmet in the team helmet colour. Charcoal face mask, gloves and cleats for every team. Numbers on the chest and back.
- Better run cycle (asked for by BC): two-part legs with a knee fold, arms that pump with bent elbows, a forward lean that grows with the burst and a bob each stride. Blockers lean in with their arms out. The field goal holder kneels on one knee.
- Touchdown celebrations (asked for by BC): jump, flex, spin and a high-knee dance. Each player has one, so the team mixes them up.
- Still one shared mesh per body part: 16 draw calls for every player on the field.
- Shared kit 1.11.0 (unchanged).

### v0.3.3 (standards release: the rules agreed on 2026-11-15)

- Hints follow the device used last: keys, Xbox buttons or touch buttons. The title card shows that device's controls only (G5.14).
- The game pauses when the controller in use disconnects (G5.15).
- The Menu reads Resume, Settings, How to play, Restart, Title (G5.16).
- Copy bug report in Tester tools (G5.10).
- Privacy page. No internet permission in the APK (G6.13).
- A GitHub Release with the APK for every version. The game page keeps the newest two APKs (G2.10, G1.12).
- Shared kit 1.8.0. This game is the pilot for it.

### v0.3.2 (standards release: Settings and save slots)

- One Settings menu, the same in every game from now on (asked for by BC, G5.11). Music and Sound in five levels. Full screen in the browser. Frame rate number. Rumble. Then Auto pass, Players, Quarter length and Controls. Then Text size and Reset settings. Every change saves by itself. No Save button.
- Five save slots (asked for by BC, G5.12). A Slot button on the title card opens the list. Each slot has its own record, season and saved game. Delete on every used slot, with a second press. Your save from v0.3.1 is now slot 1.
- Settings are kept apart from the slots, so deleting a slot never changes them.
- Shared kit 1.7.0. This game is the pilot for it.

### v0.3.1 (standards release, no new football)

- Debug menu (asked for by BC, G5.9). Settings shows Tester tools in test builds. A code opens it. Tools: Home score +7, Away score +7, Quarter, Clock to 10 seconds, Final play, New season at week 1, Jump to week 4, Jump to week 6, Jump to the Title Game, Difficulty, Pretend camera notch, Reset the save, Load the test save, a frame rate and memory readout and game speed x1, x2 and x4. A red DEBUG tag shows while it is unlocked. Works with touch, a keyboard or only an Xbox controller.
- Own app icon set (asked for by BC, G6.10). One 1024 master. Android launcher icon and adaptive icon set for the first time.
- Source moved to the private repo (BC, G1.7). The public repo now holds only the game page, builds, release notes and this backlog.
- Game page line reads `Version 0.3.1. Release notes · Backlog` (G1.8).
- Test gate: test what changed (G7.9). The 12 bot games and the bot season no longer run on every release.
- Shared kit 1.6.0. This game is the pilot for it.
- Fixed: `project.godot` said version 0.2.0.

### v0.3.0

- Season mode (asked for by BC). 6 weeks against the other 3 teams, twice each. The other game each week is simulated from team ratings. Standings with W, L, T, points for and points against. The top 2 meet in the Title Game, which goes to more overtime until someone scores. Saved on the device. End season takes two presses.
- Burst button (asked for by BC). 2 seconds at 1.3 times top speed, ready again 5 seconds after it ends. F, LT or the Burst button with a gold charge ring. Hold-to-sprint stays on Shift, RT and the Sprint button. A runner on a burst is a little harder to tackle.
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

- 7 on 7 is the default game (asked for by BC). Offense: 3 linemen, a QB, a running back and 2 receivers. Defense: 3 linemen, 2 linebackers and 2 defensive backs. Full 100-yard field. Kickoffs and punts are 7 a side too.
- 11 on 11 stays a choice. Players on the team screen. Saved on the device.
- Full Xbox controller support (G5.8). Every screen works with only a controller. A chooses, B goes back, View or Menu opens the Menu. The game page has a section on pairing an Xbox controller.
- Kickoffs and punts you play, with a kicker, a timing meter and returns. Touchbacks, muffed punts and safeties with a free kick.
- Interceptions and fumbles are live. Run them back for a score.
- Two-point tries after a touchdown. Sudden death overtime when tied after four quarters. Halftime kickoff.
- Playbook: 33 offensive plays on four tabs (Short, Deep, Run, Option) and 20 defenses on four tabs (Man, Zone, Blitz, Run).
- Option plays (asked for by BC): Speed Option Right, Speed Option Left, Pistol Option, Zone Read and Zone Read Left. Pitch to the back with E, B or the Pitch button.
- More running plays (asked for by BC): Counter and Stretch Right join the Run tab.
- Auto pass setting (asked for by BC): the QB throws for you and you take the catcher. On the team screen and in the Menu. Saved on the device.
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
- v0.3.4 (2026-11-16), sound fix (BC 2026-11-16: no music in the browser). The Music and Sfx buses come from `default_bus_layout.tres` instead of `AudioServer.add_bus()` at runtime, which left every sound silent in the browser build. New `tests/audio_test.py` measures the page's real sound output. Version code 7.
- v0.3.5 (2026-11-16), sound effects in the browser. Found while fixing Tiny Tailwind's silent laser (BC said "yes" to the fix). Every sound effect had been silent in the browser: the Sfx bus in `default_bus_layout.tres` named no send, and with `default_playback_type.web=1` (sample playback) the browser plays such a bus nowhere. Music has a send, so it played. The Sfx bus now sends to Master. `tests/audio_test.py` now also checks that every bus names a send. A recording of the page with the music cut: one faint blip on v0.3.4, clear whistle and clicks on v0.3.5. Android was not affected. Version code 8.

## Now

- BC plays v0.3.0 and reports how it feels. Test checklist: `docs/release-notes/v0.3.0.md`.
- v0.3.0 installs over v0.2.0. Anyone still on v0.1.0 uninstalls it once.

## Next (v0.6.0, BC picks)

BC's v0.2.0 and v0.3.0 playtest notes come first. Nothing is planned for v0.4.0 yet. The top candidates:

1. Penalties (idea 1).
2. A 7 on 7 playbook (idea 13).
3. Release 7 standards update for this game (PLAN.md): kit 1.12.0, achievements, stats, remapping and the rest.

## Asked for by BC, not built yet

1. Player models from Patch.gg. Patch.gg has no American football player model. v0.5.0 built the players in code from BC's Gemini views instead (BC's pick, 2026-11-17).
2. A Meshy 3D model of the Gemini player, rigged, as a later option. Heavier on phones than the code-built players.
3. Suno music, second in line (BC, 2026-11-16, G8.7 now in force). Menu and halftime music, or a custom title track. v0.5.1 replaced "Rock on Chicago" with "Stage 3" from Patch.gg (BC's pick). Replaces idea 11 (more music from Patch.gg).

## Ideas to choose from (BC picks by number)

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

## Unfinished standards items (2026-11-15)

From the Open items in `STANDARDS_OVERRIDES.md`, plus what has not been tried on a real device. Each line comes off when it is done. BC picks when.

- G5.14: two short hints still name more than one device: the audible list and the choice after a touchdown.
- G5.18: time from opening the page to the first picture, measured on a phone.
- Real device check: a phone, the Retroid, an Xbox controller and sound. Nothing has been tried on a real device yet (G7.10 is not in use, BC tries each build).

## Later

- Google Play release.
- Online play.

## Not planned

- Real league, team or player names.
- Anything copied from Maximum Football or another game.

## Decisions from BC

- 2026-11-16: "yes" to fixing the silent sound effects found in Tiny Tailwind wherever the same route was missing. Shipped here as v0.3.5.
- 2026-11-14: Focus on on-field play. Godot for Android and browser. Angled camera with low-poly 3D.
- 2026-11-14: 11 on 11. Arcade feel. Use Patch.gg.
- 2026-11-14: Name is Tiny Titans Football. BC kept the name after seeing the overlap notes (DC Comics "Tiny Titans", Tennessee Titans).
- 2026-11-14: Keep the test signing key for now. Ended in v0.2.0: it uses the real key.
- 2026-11-14: Game standards and engineering standards are two separate files. Rule ids carry G and E prefixes. One `STANDARDS_OVERRIDES.md` per game. The master copy lives in the private repo `game-standards`.
- 2026-11-14: Fix the engineering open items in `STANDARDS_OVERRIDES.md` as part of v0.2.
- 2026-11-14: v0.2 scope picked: kicking game and returns, feel and polish, bigger playbook, season mode.
- 2026-11-14: Apply only the standards that fit a sports game. Claude uses its judgment and BC tests the result.
- 2026-11-14: Add more running plays with option runs and an auto pass setting.
- 2026-11-14: One source. The standards live only in the private repo `game-standards`. The shared kit is pulled into this repo with `sync_common.sh`. The signing key lives in the private repo `game-signing`.
- 2026-11-15: 7 on 7 is the default game in v0.2.0 and 11 on 11 stays a choice. Option plays ship in v0.2.0. The 2 second burst button comes in v0.3.0.
- 2026-11-15: 7 on 7 offense: 3 linemen, 1 QB, 1 RB and 2 WR. Defense: 3 linemen, 2 linebackers and 2 defensive backs. Full field.
- 2026-11-15: Controller passing stays on A, B, X and Y, the button shown on each receiver. Shoulder buttons stay for sprint, switch and hot routes.
- 2026-11-15: Tag line is "Arcade 7 on 7 and 11 on 11 football".
- 2026-11-15: Every release updates The Game Shelf card with every relevant change, in the same push.
- 2026-11-15: Xbox controller support per G5.8, with Xbox button names and a pretend-controller browser test.
- 2026-11-15: Claude picks the quality of life items for v0.3.0 (BC: "use your best judgement").
- 2026-11-15: v0.3.0 holds the burst button, season mode and the quality of life items together (BC: "move forward with the next release").
- 2026-11-15: LT is the burst and RT stays hold-to-sprint. BC asked for RT, then kept LT.

## Judgment calls made in v0.3.5 (BC to confirm or change)

1. A patch number (v0.3.5) for the sound route fix only. Nothing else rides along.
2. Shipped with the Tiny Tailwind fix (BC's "yes" there), since it is the same bug. BC named Lo-Fi League and The Scenic Route, but those two turned out fine: they use the default stream playback, where a bus with no send still reaches the speakers. This game uses sample playback, like Tiny Tailwind.
3. Sample playback (`default_playback_type.web=1`) stays. Changing the playback mode is a bigger change for BC to decide.
4. The Game Shelf picture stays as it is: nothing on screen changed.

## Judgment calls made in v0.3.4 (BC to confirm or change)

1. A patch number (v0.3.4) for a sound fix only. No other change rides along.
2. The engineering rule Home by Dusk proposed (E6.8: buses come from `default_bus_layout.tres`, never `AudioServer.add_bus()` at runtime, and every release measures real page sound) stays Proposed. Not in force until BC approves it.
3. The sound test lives in this game's `tests/` for now, not in the shared kit. Moving it to the kit is a kit change for BC to approve.
4. The sound test checks one moment: the first click and Enter on the title card. It does not walk every area.

## Judgment calls made in v0.3.0 (BC to confirm or change)

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

## Judgment calls made in v0.2.0 (BC to confirm or change)

1. Season mode moved to v0.3.0. v0.2.0 was already large, so it ships now for testing.
2. Option plays have their own Option tab. The Run tab gained Counter and Stretch Right.
3. The zone read is automatic. The QB reads the end, then you control whoever has the ball.
4. On the pitch option, the juke button pitches until the QB passes the line. The QB cannot juke before then.
5. Auto pass: you control nobody from the snap until the catch. If the QB scrambles, you take the QB. Hot routes and audibles still work before the snap.
6. Tap a receiver for a bullet, hold for a lob. The old idea list had it the other way round.
7. When your team kicks, the camera sits higher and farther back so the kicker and the whole line show.
8. The Menu labels got shorter (Help, Restart, Title) so all options fit in one row.
9. Standards rows decided under BC's instruction are marked Delegated in `STANDARDS_OVERRIDES.md`. Row 9 (E3.4): no per-prop cull distances, because the whole stadium is always in view.
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

## v0.4.0 (2026-11-17, Release 6)

- Shipped: the shared start screen (G5.21, kit 1.10.0) with this game's own painted scene (`scripts/title_art.gd`). Continue only when there is something to continue, Play opens the slot list, Settings, Quit off the web. Long key lists, tips and credits left the start screen.

### Judgment calls in v0.4.0 (BC to confirm)

1. The controls line on the start screen is cut to the main keys and buttons. How to play keeps the full list.
2. The Game Shelf card shows gameplay (BC, 2026-11-17: picked from three options).
3. Play, then a slot, leads to a new How do you want to play screen. Continue goes straight there for the slot in use. B goes back to the title card.

## v0.5.0 (2026-11-17, new players)

### Judgment calls in v0.5.0 (BC to confirm)

1. Version 0.5.0, a feature release on kit 1.11.0. Release 7 (kit 1.12.0) is still to come for this game.
2. Gloves, face mask and cleats stay charcoal for every team, as in the approved views. Team colour shows on the helmet, jersey, pads, sock bands and pants.
3. No helmet stripe or logo. The approved views have a plain helmet. The old helmet stripe is gone.
4. Shoulder pads are a little narrower than in the art (about 1.6 times the body width) so linemen 2 yards apart do not merge.
5. Celebration style is set by the player's number in the line-up, not picked at random, so tests repeat.
6. The Game Shelf card picture is unchanged. BC picks from three new gameplay options first (rule from 2026-11-17).
7. The game page's three pictures are new gameplay shots with the new players.
8. `tests/web_test.py` stops at the start screen from v0.4.0 (it still looks for the old title card buttons). It fails the same way on the v0.4.0 build. New `tests/play_shots.py` took the gameplay pictures in the browser instead. Fixing `web_test.py` is an open item.

## v0.5.1 (2026-11-17, new music)

### Judgment calls in v0.5.1 (BC to confirm)

1. The new track is set to the old track's loudness (about -17 LUFS). It came in much louder.
2. The track plays whole as a 60-second loop. It is a loop by design, so it was not trimmed.
3. It is CC0, so no credit is required. The credit stays in the game and on the page anyway.

## v0.6.0 (2026-11-17, Back at the top and both orientations)

### Judgment calls in v0.6.0 (BC to confirm)

1. The season screen keeps its Play week, End season and Title buttons in one row at the bottom. Title is an action there, not a Back. It fits upright.
2. The game over panel keeps Play again and Title. It is a result card, not a menu.
3. Upright, the camera keeps a 62 degree side-to-side view and sits 35 percent higher. Players look smaller than in landscape. BC to judge on a phone.
4. The APK turns with the phone but follows Android's rotation lock (fullUser).
5. Version 0.6.0 on top of v0.5.2 from BC's other chat (Release 7).
6. `tests/pad_test.py` failed on v0.5.2 too (it walked the old title card). Fixed in this release the same way v0.5.2 fixed `web_test.py`.
