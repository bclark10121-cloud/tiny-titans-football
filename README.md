# Tiny Titans Football

Arcade 7 on 7 and 11 on 11 football. Call a play, then run it. Built in Godot 4.6 for Android and the browser.

Game page (play in the browser or download the Android APK): https://bclark10121-cloud.github.io/tiny-titans-football/

## Status

v0.2.0, second test build: an exhibition game against the computer, 7 on 7 by default or 11 on 11, with kickoffs, punts, returns, two-point tries and overtime. Full Xbox controller support. 33 offensive plays (including option plays), 20 defenses, hot routes, audibles, an Auto pass setting, three difficulty levels, 4 fictional teams and a Practice mode.

## Layout

- `project.godot`, `main.tscn`: the Godot project. Compatibility renderer.
- `scripts/main.gd`: the stadium, the rules, the computer players, the camera and the test bot.
- `scripts/player.gd`: one football player: movement and pose, worked out in code.
- `scripts/squad_view.gd`: draws the players as 10 batches, one per body part, with jersey numbers. Players who sit out in 7 on 7 draw nothing.
- `scripts/hud.gd`: scoreboard, Menu button, play cards, kick meter, panels and touch controls.
- `data/plays.json`: formations, offensive plays and defenses. New plays need no code.
- `data/teams.json`: the four teams with colors and ratings.
- `audio/`: music and hit sounds (see CREDITS.md) and stadium sounds made by `tools/common/make_sfx.py`.
- `tests/web_test.py`: browser check with screenshots. It uses the shared helpers in `tests/common/`.
- `tests/pad_test.py`: browser check with the kit's pretend Xbox controller (G5.8).
- `tests/controller_check.gd` and `tests/screens_check.gd`: headless checks that every screen works with only a controller.
- `addons/bc_common/`, `tools/common/`, `tests/common/` and `common.lock`: the shared kit, pulled from the private repo `game-standards` (G10). Never edit these here.
- `docs/`: the GitHub Pages site. Game page at the root, the game in `docs/play/`, APKs in `docs/downloads/`.
- `BACKLOG.md`: the backlog.
- `STANDARDS_OVERRIDES.md`: where this game differs from the shared standards. The standards themselves live only in the private repo `game-standards`. This repo holds no copies.

## Controls (v0.2.0)

| Action | Keyboard | Xbox controller | Touch |
|---|---|---|---|
| Move, or move between buttons | WASD or arrows | Left stick or D-pad | Drag on the left |
| Choose a button | Enter or Space | A | Tap it |
| Close the Menu or go back | Esc | B | Close |
| Snap | Space | A | Snap button |
| Pass: tap for a bullet, hold for a lob | 1 to 4 | The button shown on the receiver: A, B, X or Y | Tap the receiver |
| Sprint | Hold Shift, or Space after the throw | Hold RT | Hold Sprint |
| Juke, or pitch on option plays | E | B | Juke or Pitch |
| Dive or tackle | Q | X | Dive or Tackle |
| Switch defender | Tab | LB | Switch |
| Audible | R | Y | Audible |
| Hot route | 1 to 4 before the snap | RB plus the receiver's button | |
| Change play tabs | Q and E | LB and RB | Tap the tab |
| Kick meter | Space | A | Tap |
| Menu | Esc | View or Menu | Menu button |

## Build and test

    godot --headless --path . --import
    godot --headless --path . -- --bot --games=6 --verbose   # the computer plays both sides and prints each game
    godot --path . -- --demo                                  # the computer plays both sides at normal speed, with full drawing
    # browser test switches need ?test: index.html?test&start_punt or ?test&start_fg opens on fourth down with the ball
    godot --headless --path . -- --bot --games=6 --mode=11  # the same in 11 on 11
    godot --headless --path . --export-release Web
    python3 tests/web_test.py <web folder> <shots folder>     # must print: errors []
    python3 tests/pad_test.py <web folder> <shots folder>     # pretend Xbox controller, must print: errors []
    godot --headless --path . -s res://tests/controller_check.gd       # must print: JOY020 check ok
    godot --headless --path . -s res://tests/screens_check.gd          # must print: SCREENS check ok
    godot --headless --path . -s res://tests/common/save_store_check.gd  # must print: SAVESTORE check ok
    bash tools/common/check_secrets.sh                        # must print: SECRETS check ok
    bash tools/common/sync_common.sh --check .                # must print: COMMON check ok
    GODOT=godot bash tools/common/sign_android.sh docs/downloads/TinyTitansFootball-v<version>.apk
                                                              # needs the private repo game-signing cloned at ../game-signing
    python3 tests/common/page_check.py https://bclark10121-cloud.github.io/tiny-titans-football/   # after a push
