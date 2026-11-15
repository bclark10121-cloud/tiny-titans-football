# Tiny Titans Football: project rules

Tiny Titans Football is Brian Clark's arcade football game. Godot 4.6, Android and browser. This repo is public.

## Pillars (never break these)

1. Call it, then run it. The player picks a play, then controls one player.
2. Arcade pace: big hits, fast players, quick downs. A full game takes about 10 minutes.
3. Football rules people know: four downs, first downs, touchdowns, field goals, turnovers.
4. Original everything. Fictional teams, our own plays and art. No real league, team or player names. Nothing copied from Maximum Football or any other game.

Note: this game has an opponent and a final score. `STANDARDS_OVERRIDES.md` records that and every other place this game differs from the standards.

## Rules

- Read `handoff/STANDARDS.md` (the standards for every game Brian makes), then `STANDARDS_OVERRIDES.md` (where this game differs). Order of authority: Brian in the chat, then the overrides, then the standards.
- A new shared standard from Brian goes in `handoff/STANDARDS.md`. A football-only exception goes in `STANDARDS_OVERRIDES.md` as `Proposed` until Brian approves it.
- Do not sync the standards into other game repos unless Brian asks.
- Top menu: one Menu button at the top right opens all options in a row across the top.
- This repo is public. Never commit a signing key, keystore or password.
- Field units are yards. The field runs along Z. Goal lines sit at z = -50 and z = +50. Side 0 (the player) always attacks +Z and the camera always looks down +Z.
- Plays are data in `data/plays.json`, written in the offense frame: x is yards to the offense's right, z is yards downfield.
- Players move with plain maths, not physics bodies. `main.gd` sets `want` and `player.gd` eases toward it.
- Field lines and numbers are painted into one field texture. Never lay a thin layer on the grass: it flickers on phones.
- `--bot --games=6` must finish every game and print `BOT done`. Typical final scores sit between 0 and 40 a side.
- `tests/web_test.py` must print `errors []`. View the screenshots.
- Save file is `user://tiny_titans.json`, format `v: 1`. Only add fields, each with a safe default.
- Every outside asset goes in `CREDITS.md` with its licence. Music comes from the Patch.gg library.

## Deliver every time (every release)

1. The game page link: https://bclark10121-cloud.github.io/tiny-titans-football/ (give Brian this link, not the direct play link).
2. The GitHub repo link: https://github.com/bclark10121-cloud/tiny-titans-football
3. The APK, named `TinyTitansFootball-v<version>.apk`, in `docs/downloads/` and sent to Brian as a file. Package id `com.brianclark.tinytitansfootball`. Raise `version/code` by one on every build.
4. The backlog: `BACKLOG.md`, updated, linked and sent to Brian as a file.
5. `docs/index.html` updated: version line, APK link and what is new. Add `docs/release-notes/v<version>.md` with a test checklist.
6. The browser build goes in `docs/play/`.
7. The game standards handoff zip: update `handoff/STANDARDS.md` and `STANDARDS_OVERRIDES.md`, run `tools/make_handoff.sh` and send `Game_Standards_handoff.zip` to Brian as a file.

## Open item: Android signing

v0.1.0 is signed with a throwaway test key. Brian's key `wandervalley.jks` lives in a private repo and was not reachable when v0.1.0 was built. Brian chose to keep the test key for now (2026-11-14, override 6.3). Once the real key is used, testers must uninstall v0.1.0 first.

## Reporting to Brian

Lead with the link or file to test. Segment the answer. Short active sentences. No em dashes, no semicolons, no Oxford comma. State plainly what was tested and where. List every judgment call.
