# Game standards (Brian Clark)

Version 2026-11-14. The product and process standards for every game Brian makes.
Start a new game by reading this file first, then `ENGINEERING_STANDARDS.md`.

This file is the same in every game repo. Never edit it for one game.

## G0. How the standards work

- G0.1 Two standards files, kept separate. `handoff/GAME_STANDARDS.md` (this file) covers product and process. `handoff/ENGINEERING_STANDARDS.md` covers the Godot 3D engineering rules.
- G0.2 Rule ids. Rules in this file start with G (`G4.1`). Rules in the engineering file start with E (`E4.1`). Always write the prefix.
- G0.3 One override file per game: `STANDARDS_OVERRIDES.md` at the root of the game's repo. It covers both standards files. The format is in the appendix.
- G0.4 Order of authority: what Brian says in the chat, then the game's override file, then the two standards files.
- G0.5 A rule with no override applies in full. Never skip a rule silently.
- G0.6 Only Brian approves an override or a new standard. A chat proposes it, marks it Proposed and lists it as a judgment call. A Proposed row or rule is not in force.
- G0.7 A rule that applies but is not finished is an open item, not an override. List it under Open items in the override file.
- G0.8 Never renumber a rule. Retire a rule by marking it retired. Add new rules at the end of a section.
- G0.9 Game-only rules and pillars live in the game's `CLAUDE.md`, not in the override file.
- G0.10 The master copy of both standards files lives in the standards repo. Game repos hold copies. A chat never changes a standards file in a game repo. It proposes the change to Brian, and the master changes first.
- G0.11 When an override turns out to fit every game, ask Brian to make it a standard. Then end the override.

## G1. Repos and pages

- G1.1 Every game gets its own public GitHub repo under `bclark10121-cloud`. No shared repos.
- G1.2 Never commit a signing key, keystore or password to a public repo. The Android key `wandervalley.jks` lives in the private repo `keeper-of-the-hollow-source`.
- G1.3 Every game gets a game page on GitHub Pages: `docs/index.html` in the repo, served from `main` `/docs`.
- G1.4 The game page has: a short description, a Play in your browser button, the Android APK download, three screenshots, what kind of game it is, things to do, controls, install steps, a feedback list and links to release notes, backlog and source.
- G1.5 The browser build lives in `docs/play/`. APKs live in `docs/downloads/`. Release notes live in `docs/release-notes/v<version>.md`.
- G1.6 Brian shares the game page with other people and tests from it. Give him the game page link, never a direct link into the game.

## G2. Deliver with every release

- G2.1 Game page link.
- G2.2 GitHub repo link.
- G2.3 APK, named `<GameName>-v<version>.apk`, sent as a file and live on the game page.
- G2.4 Backlog document, updated, sent as a file and linked.
- G2.5 Game standards handoff zip, sent as a file. It holds both standards files, the game's override file, the templates and the reusable code.
- G2.6 Game page updated: version line, what is new, APK link. Release notes with a test checklist.

## G3. Reporting to Brian

- G3.1 Lead with the links and files.
- G3.2 Segment the answer. Short active sentences. No em dashes, no semicolons, no Oxford comma.
- G3.3 Say plainly what was tested and where, and what was not tested.
- G3.4 List every judgment call.
- G3.5 When Brian reports a bug from a screenshot, fix it before new features.

## G4. Game design defaults

- G4.1 Calm games. No combat. No way to lose. A reset never costs anything.
- G4.2 Write the pillars in the repo's `CLAUDE.md`. Flag any request that changes a pillar, then reword the pillar once Brian confirms.
- G4.3 Things to find, with a counter, a journal and a save file. Finds show a short message near the top third of the screen.
- G4.4 Records and achievements are personal bests only. No leaderboards, no opponents.
- G4.5 A seasonal theme (Christmas) is a toggle that stays off until turned on.
- G4.6 Keep a `BACKLOG.md`: Done, Now, Asked for by Brian, Ideas to choose from, Later, Not planned and Decisions. Offer numbered ideas so Brian picks by number.
- G4.7 Retired 2026-11-14. Game-specific exceptions live in each game's `STANDARDS_OVERRIDES.md`.
- G4.8 Proposed. A new game based on another game's style: review the reference first, then deliver a plan and backlog doc before any build. Borrow structure, never content. Check the name for overlaps and tell Brian what you found.
- G4.9 Proposed. Keep game content as data (finds, plays, teams, levels) so new content needs no code.

## G5. Interface standards

- G5.1 Top menu: one Menu button at the top right. It opens every option in a row across the top. It reads Close while open. Esc on a keyboard and Back on a controller toggle it.
- G5.2 Nothing else sits on screen while playing except the speed or status readout, the find counter and touch controls.
- G5.3 Touch layout: steer by dragging on the left half. Action buttons on the right. When touch controls show and hide is set by E5.4.
- G5.4 Controller and keyboard always work. Show the keys on the title card.
- G5.5 Title card: name, version line, one line on what the game is, controls and a Start button.
- G5.6 Settings and progress save on the device. Only add fields to a save file, each with a safe default. Never rename or remove a saved id. How the file is written is set by E6.4 and E6.5.
- G5.7 US units: mph and feet.

## G6. Build standards (Godot 4.6)

- G6.1 Landscape, 1280 x 720 base. The renderer and stretch settings are set by E2.1 and E5.1. The physics engine is set by E4.1 and is chosen per game.
- G6.2 Exports: Web (no threads) and Android (arm64, package `com.brianclark.<game>`). Raise the version code by one on every build.
- G6.3 Sign the APK with `wandervalley.jks`. The signature SHA-256 starts with `5db69ffb`.
- G6.4 Build the world in code where possible. Repeated scenery follows E3.2.
- G6.5 Phones draw depth coarsely. Never lay a road or decal as a thin layer on the ground. Give it its own raised mesh and collision, or paint it into the ground texture.
- G6.6 Anything a player can touch has collision. Anything on a road can be knocked over or driven round.
- G6.7 Proposed. Never fetch the signing key unless Brian says so in the chat. Without it, sign a test build with a throwaway key, say so plainly and note that testers must uninstall before the real key is used.
- G6.8 Retired 2026-11-14. It was football-only and moved to that game's `CLAUDE.md`. G6.5 now covers painted ground markings.
- G6.9 Retired 2026-11-14. Proposed as a new rule in the engineering standards: on slow devices, cap the frame step and take up to three smaller steps per frame.

## G7. Test gate before every release

- G7.1 A headless test driver proves the main route is drivable with 0 resets.
- G7.2 A report proves every find is reachable.
- G7.3 A browser test loads the web build in headless Chrome with `errors []`, and the screenshots are viewed.
- G7.4 The live game page and APK link are checked after the push.
- G7.5 State what could not be tested (real devices, sound).
- G7.6 Proposed. Games with rules (sports, puzzles): a test bot plays full games headless and prints each result. The browser test reads the game state from the page instead of guessing wait times.
- G7.7 Proposed. Tick the release checklist at the end of `ENGINEERING_STANDARDS.md` and confirm `STANDARDS_OVERRIDES.md` is up to date: every override still needed, every open item still true.

## G8. Assets

- G8.1 Music: tracks from the Patch.gg library only. Prefer CC0. The search API needs no login: `https://patch.gg/api/v1/assets/search?q=<words>&type=music`.
- G8.2 Extra pictures and sounds: Patch.gg library. Check each batch by eye. Styles vary a lot. Loose keyword searches return mismatched art. Pull a whole themed pack from one maker instead (for example the Kenney fish pack) so a batch shares one style.
- G8.3 Every outside asset goes in `CREDITS.md` with its source and licence.
- G8.4 Original names, characters, vehicles and art only. Inspiration from other games stays as ideas.

## G9. What is in the handoff zip

- `GAME_STANDARDS.md`: this file.
- `ENGINEERING_STANDARDS.md`: the Godot 3D engineering standards.
- `templates/`: starting points for a new game (`CLAUDE.md`, `STANDARDS_OVERRIDES.md`, game page, backlog, release notes, credits, Godot project and export settings, `.gitignore`).
- `reusable/`: code that carries over (HUD with the Menu button, touch pads and messages. Browser test. Sound maker. Patch.gg asset fetcher).
- `games/`: each game's current rules, override file, backlog and credits for reference.

## Appendix: the override file format

Every game's `STANDARDS_OVERRIDES.md` uses this layout.

```markdown
# <Game Name>: standards overrides

Standards: `handoff/GAME_STANDARDS.md` (rule ids start with G) and `handoff/ENGINEERING_STANDARDS.md` (rule ids start with E).
This file lists where this game does something else, and why. A rule not listed here applies in full.
Order of authority: Brian in the chat, then this file, then the standards.

Last reviewed: v<version> (<date>).

## Overrides

| # | Rule | Standard says | This game does | Why | Ends when | Agreed |
|---|---|---|---|---|---|---|
| 1 | G4.1 | | | | | <date Brian agreed>, or Proposed |

A Proposed row is not in force. The standard applies until Brian agrees.

## Open items (rule applies, work not finished)

- <rule id>: <what is not done yet>

## Rules met

<Rule ids checked and met at the last review.>

## Not in use in this game

<Parts of the standards with nothing to apply to, such as navigation or finds.>

## How to add an override

1. Flag the conflict to Brian with the options. Do not override by yourself.
2. Add the row as Proposed and list it as a judgment call in the report to Brian.
3. Once he agrees, put the date in the Agreed column.
4. When an override ends, move its row to Ended overrides with the date.
5. When an override fits every game, ask Brian to make it a standard. Then end the override.

## Ended overrides

None yet.
```

## Change log

- 2026-11-14: Combined from three game chats. Added G0, the G prefix and the override format. Trimmed G5.3, G5.6, G6.1 and G6.4 to point at the engineering standards where the two files overlapped. Removed "Jolt physics" from G6.1: the engine is chosen per game under E4.1. Widened G6.5 and G8.4. Retired G4.7, G6.8 and G6.9. Proposed G4.8, G4.9, G6.7, G7.6 and G7.7.
