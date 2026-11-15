# Tiny Titans Football

Arcade 7 on 7 and 11 on 11 football. Call a play, then run it. Built in Godot 4.6 for Android and the browser.

Game page (play in the browser or download the Android APK): https://bclark10121-cloud.github.io/tiny-titans-football/

## Status

v0.1.0, first test build: one exhibition game against the computer, 8 offensive plays, 4 defenses, 4 fictional teams, field goals, extra points, auto punts and a Practice mode.

## Layout

- `project.godot`, `main.tscn`: the Godot project. Compatibility renderer.
- `scripts/main.gd`: the stadium, the rules, the computer players, the camera and the test bot.
- `scripts/player.gd`: one football player, built from simple shapes and animated in code.
- `scripts/hud.gd`: scoreboard, Menu button, play cards, kick meter, panels and touch controls.
- `data/plays.json`: formations, offensive plays and defenses. New plays need no code.
- `data/teams.json`: the four teams with colors and ratings.
- `audio/`: music and hit sounds (see CREDITS.md) and stadium sounds made by `tools/common/make_sfx.py`.
- `tests/web_test.py`: browser check with screenshots. It uses the shared helpers in `tests/common/`.
- `addons/bc_common/`, `tools/common/`, `tests/common/` and `common.lock`: the shared kit, pulled from the private repo `game-standards` (G10). Never edit these here.
- `docs/`: the GitHub Pages site. Game page at the root, the game in `docs/play/`, APKs in `docs/downloads/`.
- `BACKLOG.md`: the backlog.
- `STANDARDS_OVERRIDES.md`: where this game differs from the shared standards. The standards themselves live only in the private repo `game-standards`. This repo holds no copies.

## Controls (v0.1.0)

| Action | Keyboard | Controller (Xbox layout) | Touch |
|---|---|---|---|
| Move | WASD or arrows | Left stick or D-pad | Drag on the left |
| Snap | Space | A | Snap button |
| Pass | 1 to 4 | The button shown on the receiver: A, B, X or Y | Tap the receiver |
| Sprint | Hold Space or Shift | Hold RT | Hold A |
| Juke | E | B | B |
| Dive or tackle | Q | X | C |
| Switch defender | Tab | LB | Snap button |
| Kick meter | Space | A | Tap |
| Menu | Esc | Menu or View button | Menu button |

In v0.1.0 a controller cannot press on-screen buttons (Start, teams, play cards). Godot 4.6 binds no controller button to them. The v0.2.0 work fixes this: A presses the highlighted button.

## Build and test

    godot --headless --path . --import
    godot --headless --path . -- --bot --games=6 --verbose   # the computer plays both sides and prints each game
    godot --headless --path . --export-release Web
    python3 tests/web_test.py <web folder> <shots folder>     # must print: errors []
    bash tools/common/sync_common.sh --check .                # must print: COMMON check ok
    GODOT=godot bash tools/common/sign_android.sh docs/downloads/TinyTitansFootball-v<version>.apk
                                                              # needs the private repo game-signing cloned at ../game-signing
    python3 tests/common/page_check.py https://bclark10121-cloud.github.io/tiny-titans-football/   # after a push
