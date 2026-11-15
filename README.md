# Tiny Titans Football

Arcade 11 on 11 football. Call a play, then run it. Built in Godot 4.6 for Android and the browser.

Game page (play in the browser or download the Android APK): https://bclark10121-cloud.github.io/tiny-titans-football/

## Status

v0.2.0, second test build: an exhibition game against the computer with kickoffs, punts, returns, two-point tries and overtime. 33 offensive plays (including option plays), 20 defenses, hot routes, audibles, an Auto pass setting, three difficulty levels, 4 fictional teams and a Practice mode.

## Layout

- `project.godot`, `main.tscn`: the Godot project. Compatibility renderer.
- `scripts/main.gd`: the stadium, the rules, the computer players, the camera and the test bot.
- `scripts/player.gd`: one football player: movement and pose, worked out in code.
- `scripts/squad_view.gd`: draws all 22 players as 10 batches, one per body part, with jersey numbers.
- `scripts/hud.gd`: scoreboard, Menu button, play cards, kick meter, panels and touch controls.
- `data/plays.json`: formations, offensive plays and defenses. New plays need no code.
- `data/teams.json`: the four teams with colors and ratings.
- `audio/`: music and hit sounds (see CREDITS.md) and stadium sounds made by `tools/make_sfx.py`.
- `tests/web_test.py`: browser check with screenshots.
- `docs/`: the GitHub Pages site. Game page at the root, the game in `docs/play/`, APKs in `docs/downloads/`.
- `BACKLOG.md`: the backlog.
- `handoff/GAME_STANDARDS.md` and `handoff/ENGINEERING_STANDARDS.md`: the standards shared by every game. Master copies live in the private repo `game-standards`. `STANDARDS_OVERRIDES.md`: where this game differs.

## Build and test

    godot --headless --path . --import
    godot --headless --path . -- --bot --games=6 --verbose   # the computer plays both sides and prints each game
    godot --path . -- --demo                                  # the computer plays both sides at normal speed, with full drawing
    # browser test switches: index.html?test&start=punt or ?test&start=fg opens on fourth down with the ball
    godot --headless --path . --export-release Web
    python3 tests/web_test.py <web folder> <shots folder>     # must print: errors []
    godot --headless --path . --export-release Android
