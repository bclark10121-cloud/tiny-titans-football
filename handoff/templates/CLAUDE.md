# <Game Name>: project rules

<Game Name> is Brian Clark's <one line>. Godot 4.6, Android and browser. This repo is public.
Read `handoff/GAME_STANDARDS.md` first. It holds the standards for every game.

## Pillars (never break these)

1. No opponents. No battles.
2. No way to lose.
3. <what the reward is>
4. A reset never costs anything.

## Rules

- This repo is public. Never commit a signing key, keystore or password.
- Original names and art only.
- Save file is `user://<game>.json`, format `v: 1`. Only add fields, each with a safe default.
- Every outside asset goes in `CREDITS.md` with its licence.
- <test gate lines: what each check must print>

## Deliver every time (every release)

1. Game page link: https://bclark10121-cloud.github.io/<repo>/
2. GitHub repo link: https://github.com/bclark10121-cloud/<repo>
3. The APK, named `<GameName>-v<version>.apk`, in `docs/downloads/` and sent to Brian as a file.
4. The backlog: `BACKLOG.md`, updated, linked and sent as a file.
5. The game standards handoff zip, rebuilt with `tools/make_handoff.sh` and sent as a file.
6. `docs/index.html` updated and `docs/release-notes/v<version>.md` added with a test checklist.

## Reporting to Brian

Lead with the links and files. Segment the answer. Short active sentences. No em dashes, no semicolons, no Oxford comma. State plainly what was tested and where. List every judgment call.
