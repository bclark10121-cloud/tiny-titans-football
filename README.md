# Tiny Titans Football

Arcade 11 on 11 football. Call a play, then run it. Built in Godot 4.6 for Android and the browser.

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
- `audio/`: music and hit sounds (see CREDITS.md) and stadium sounds made by `tools/make_sfx.py`.
- `tests/web_test.py`: browser check with screenshots.
- `docs/`: the GitHub Pages site. Game page at the root, the game in `docs/play/`, APKs in `docs/downloads/`.
- `BACKLOG.md`: the backlog. `handoff/`: the game standards that carry over to every game.

## Build and test

    godot --headless --path . --import
    godot --headless --path . -- --bot --games=6 --verbose   # the computer plays both sides and prints each game
    godot --headless --path . --export-release Web
    python3 tests/web_test.py <web folder> <shots folder>     # must print: errors []
    godot --headless --path . --export-release Android
