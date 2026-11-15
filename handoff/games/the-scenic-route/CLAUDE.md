# The Scenic Route: project rules

The Scenic Route is Brian Clark's calm rally driving game. Godot 4.6, Android and browser. This repo is public.

## Pillars (never break these)

1. No opponents. No battles.
2. No way to lose. No damage, no fuel, no countdowns. Lap circuits are optional and timed against your own best only (Brian asked for them on 2026-11-14).
3. Driving through scenery is the reward.
4. A reset always puts the car back on a road with no penalty.

## Rules

- Read `handoff/GAME_STANDARDS.md`: the standards for every game Brian makes. New standards from Brian go there.
- Top menu: one Menu button at the top right opens all options in a row across the top.
- This repo is public. Never commit a signing key, keystore or password. The Android signing key lives in the private repo `keeper-of-the-hollow-source`.
- Original cars, names and art only. Nothing copied from art of rally or any other game.
- The car's front is +Z. Positive `steer_in` turns right.
- `--bot` must show `up_min` near 1.00 on every line (the car never rolls over).
- `--drive` and `--drive --auto` must each finish a lap with `resets 0`.
- `--reach` must print `bad 0` and the full find count (198 in v0.5).
- `--drive --track0` to `--track5` must each print a timed lap. Aim for `resets 0`. A reset from running wide into a bridge railing is a known limit of the test driver.
- Roads are raised beds with their own collision (`_ribbons`). The ground under a road sits `ROAD_BED` lower. Never draw a road as a thin layer on the ground: it flickers and tears on phones.
- Railings never cross another road (`_on_other_road`).
- `--jump` must print `rolled 0`. Never rename or remove a find id in `data/finds.json` (saves list found ids).
- Save file is `user://scenic_route.json`, format `v: 1`. Only add fields, each with a safe default.
- Every outside asset goes in `CREDITS.md` with its licence.
- `tests/web_m1.py` must print `errors []`. View the screenshots.
- `docs/` is the GitHub Pages site: landing page at the root, the game in `docs/play/`, APKs in `docs/downloads/`.

## Deliver every time (every release)

1. The game page link: https://bclark10121-cloud.github.io/the-scenic-route/ (landing page with Play and Download buttons). Give Brian this link, not the direct play link.
2. The GitHub repo link: https://github.com/bclark10121-cloud/the-scenic-route
3. The APK, named `TheScenicRoute-v<version>.apk`, in `docs/downloads/` and sent to Brian as a file. Package id `com.brianclark.thescenicroute`. Raise `version/code` by one on every build. Sign with `wandervalley.jks` from the private repo (signature SHA-256 starts with `5db69ffb`).
4. The backlog: `BACKLOG.md`, updated, linked and sent to Brian as a file.
5. `docs/index.html` updated: version line, APK link and what is new. Add `docs/release-notes/v<version>.md` with a test checklist.
6. The browser build goes in `docs/play/`.
7. The game standards handoff zip: update `handoff/GAME_STANDARDS.md` with any new standard, run `tools/make_handoff.sh` and send `Game_Standards_handoff.zip` to Brian as a file.

## Reporting to Brian

Lead with the link or file to test. Segment the answer. Short active sentences. No em dashes, no semicolons, no Oxford comma. State plainly what was tested and where. List every judgment call.
