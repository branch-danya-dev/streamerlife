# StreamerLife / Viral City

Solo-first Roblox MVP for [issue #1](https://github.com/branch-danya-dev/streamerlife/issues/1). Start a stream, play three short challenges, earn views/subscribers/cash, upgrade your studio and publish virtual recordings. Visitors can watch, react and vote; solo players never need a partner.

## Open the game

The delivered `StreamerLife.rbxlx` opens directly in Roblox Studio. Press **Play / F5**. The city is generated at runtime, so the edit viewport is initially empty. No API access, external assets or Rojo plugin is needed to play this local build.

1. Spawn in your studio and press **GO LIVE**.
2. **Hype Timing:** stop in the mint target with Space or the STOP button.
3. **Donation Rain:** tap one of four lanes, or use A/D or left/right arrows. Gold pays; red subtracts points.
4. **Don't Fall:** move your avatar on the tile arena with WASD/arrows or the four on-screen buttons. Leave flashing tiles before they vanish.
5. A stream lasts 150 seconds. **END STREAM** finishes early; a recording requires 30 seconds and at least one completed challenge. Earned challenge rewards are retained.
6. **MENU → UPGRADES** buys PC, Microphone and Camera/Lighting levels. **RECORDINGS** shows the last five recordings, remaining earning time and free popularity odds.
7. **MENU → LIVE NOW** lists all occupied studios. Visit a live creator, then use **REACTIONS** to react or vote between challenges. **MY STUDIO** returns home.

UI and gameplay strings are centralized in `src/shared/Strings.luau`; the game currently uses English. Real video, webcam/microphone capture, Robux purchases and arbitrary custom chat are absent.

## Build and synchronize

Install [Rokit](https://github.com/rojo-rbx/rokit) and run `rokit install` in this directory, or download the pinned portable tools from their official releases:

- [Rojo 7.7.1](https://github.com/rojo-rbx/rojo/releases/tag/v7.7.1)
- [Luau 0.745](https://github.com/luau-lang/luau/releases/tag/0.745)
- [StyLua 2.6.0](https://github.com/JohnnyMorganz/StyLua/releases/tag/v2.6.0)

```sh
rojo build default.project.json -o StreamerLife.rbxlx
rojo serve default.project.json
```

For live sync, install the matching Rojo Studio plugin (`rojo plugin install`), open the generated place and connect the plugin to `localhost:34872`. Stop Play before synchronizing script changes. See [Rojo installation](https://rojo.space/docs/v7/getting-started/installation/).

## Tests

```sh
luau tests/domain.spec.luau
luau-analyze src/shared tests/domain.spec.luau
stylua --check src tests
rojo build tests/studio.project.json -o StreamerLife-QA.rbxlx
```

`scripts/check.ps1` also compiles every game and test script and builds both places. CI runs the same logic checks and uploads the normal place.

The QA place is **test-only**. Open it and select **Test → Server & Clients → 2 clients**. Bots send the same action protocol as the UI; the server checks spawning, forged reward rejection, all three challenges, a recording, studio visits, voting/reactions, social limits, all upgrade categories and a profile save/reacquire round-trip. Look for `QA ALL PASSED` in the server Output. The scenario takes about two minutes. It requires isolated memory mode and refuses published servers. Never publish the QA place.

The QA fixture does not replace manual touch/keyboard checks, actual DataStore failure testing, or performance tests. See [the validation report](docs/VALIDATION.md) for checks actually run and remaining acceptance work.

## Save modes

- **Studio default:** isolated memory storage. A yellow label identifies this mode. Profiles survive a release/reacquire inside the same test server; stopping the server clears them.
- **Published server:** persistent `StreamerLife_v1` DataStore. Load errors fail closed; a blank profile is never substituted after a failed read.
- **Persistent Studio testing:** use a **separate private test experience**, enable Studio API access yourself, and add boolean `UseLiveDataInStudio = true` to ServerScriptService. This selects the separate `StreamerLife_Studio_v1` store. Production data is never used from Studio.

Each profile has a unique connection lease acquired with UpdateAsync. Autosave runs every 45 seconds; leases last 180 seconds. Writes are serialized and use increasing revisions; retries after lost responses are idempotent. Leave/shutdown releases the lease after a final save. If saving cannot renew a lease, actions stop and the player is disconnected before the lease can be reused. A crashed server can delay reconnecting for up to three minutes.

Offline rewards are applied and saved atomically during acquisition. The time cursor never moves backwards. Each absence and each recording have an eight-hour earning cap; cumulative rounding prevents reconnect frequency from changing rewards. A crash can lose up to the autosave interval and can count the interval since the last save as offline time. These tradeoffs and the published test checklist are documented in [architecture and acceptance](docs/MVP.md).

The persistence design follows Roblox's [UpdateAsync guidance](https://create.roblox.com/docs/cloud-services/data-stores) and [session-locking guidance](https://create.roblox.com/docs/cloud-services/data-stores/player-data-purchasing).

## Boundaries and balance

- Server owns currency, upgrade costs, RNG, challenge results, recording metadata and offline time. Remote handlers accept intentions; no endpoint accepts a reward amount, client score, price or timestamp.
- Timing is scored at **server receipt time**. High latency therefore affects accuracy. The initial 700 ms announcement lead and 28% timing zone provide tolerance without trusting client clocks.
- Don't Fall uses server-driven discrete tile movement and anchors the avatar during the challenge. This is intentional for verifiable results; it is not a free-jumping platformer.
- Reactions have a cooldown. One visitor earns at most one mutual $1 bonus per host stream, with a persistent $30 daily cap per player; votes are limited to one per break. The first three selections offer unfinished games so every stream demonstrates all three.
- Published recording income is deliberately below active play. Camera levels alter free recording odds; PC increases views, Microphone increases cash and subscribers. `Balance.luau` holds the tunable values.
- The city has 16 studio slots. Set the published experience's maximum players to 16 during owner-controlled publication. This setting is not stored in the Rojo place.
- Snapshot replication is bounded at 5 Hz, directory updates at 1 Hz, and render animation uses one client loop. No unbounded chat/video history or external asset downloads are created by gameplay.

## Assets and ownership

All city geometry, equipment and interface elements are original programmatic Roblox primitives. There are no marketplace models, third-party scripts or downloaded textures. The notification sound references Roblox's installed `rbxasset://sounds/volume_slider.ogg`; it is not redistributed. Avatars and their cosmetics are Roblox-provided player content. See [asset notes](docs/ASSETS.md).

Development is on `feature/issue-1-mvp`; `main` starts with the owner-authorized empty baseline. The pull request remains a draft pending acceptance. Do not merge or publish from this repository without the owner's manual acceptance.
