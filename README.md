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

The game currently uses English; gameplay strings are centralized in `src/shared/Strings.luau`. Visual labels and equipment descriptions also live in `src/client/UI.luau`. Real video, webcam/microphone capture, Robux purchases and arbitrary custom chat are absent.

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
luau tests/persistence.spec.luau
luau tests/latency.spec.luau
luau tests/presentation.spec.luau
luau-analyze src/shared src/server/Persistence.luau tests/domain.spec.luau tests/persistence.spec.luau tests/latency.spec.luau tests/presentation.spec.luau
stylua --check src tests
rojo build tests/studio.project.json -o StreamerLife-QA.rbxlx
```

`scripts/check.ps1` also compiles every game and test script and builds six places: normal, QA, M4 load, Latency, Manual and Visual tour. CI runs the same checks and uploads the places. The fault adapter and all fixture remotes/bots live under `tests/`; none are mapped into the normal place. `Persistence.luau` is the exact runtime save coordinator with injected I/O for deterministic tests, not a second persistence implementation.

The QA place is **test-only**. Open it and select **Test → Server & Clients → 2 clients**. Bots send the same action protocol as the UI; the server checks spawning, forged reward rejection, all three challenges, a recording, studio visits, voting/reactions, social limits, all upgrade categories and a profile save/reacquire round-trip. Look for `QA ALL PASSED` in the server Output. The scenario takes about two minutes. It requires isolated memory mode and refuses published servers. Never publish the QA place.

The QA fixture does not replace manual touch/keyboard checks, actual DataStore failure testing, or performance tests. See [the validation report](docs/VALIDATION.md) for checks actually run and remaining acceptance work.

## Save modes

- **Studio default:** isolated memory storage. A yellow label identifies this mode. Profiles survive a release/reacquire inside the same test server; stopping the server clears them.
- **Published server:** persistent `StreamerLife_v1` DataStore. Load errors fail closed; a blank profile is never substituted after a failed read.
- **Persistent Studio testing:** use a **separate private test experience**, enable Studio API access yourself, and add boolean `UseLiveDataInStudio = true` to ServerScriptService. This selects the separate `StreamerLife_Studio_v1` store. Production data is never used from Studio.

Each profile has a unique connection lease acquired with UpdateAsync. Autosave runs every 45 seconds; leases last 180 seconds. Writes are serialized and use increasing revisions; retries after lost responses are idempotent. Leave/shutdown releases the lease after a final save. If saving cannot renew a lease, actions stop and the player is disconnected before the lease can be reused. A crashed server can delay reconnecting for up to three minutes.

Offline rewards are applied and saved atomically during acquisition. The time cursor never moves backwards. Each absence and each recording have an eight-hour earning cap; cumulative rounding prevents reconnect frequency from changing rewards. A crash can lose progress since the last **successful** save and can count that unsaved interval as offline time. The normal autosave interval is 45 seconds; an outage can make the loss larger. Shutdown waits at most 25 seconds, including in-flight loads; an unresponsive service can outlast that window. These tradeoffs and the published test checklist are documented in [architecture and acceptance](docs/MVP.md).

The persistence design follows Roblox's [UpdateAsync guidance](https://create.roblox.com/docs/cloud-services/data-stores) and [session-locking guidance](https://create.roblox.com/docs/cloud-services/data-stores/player-data-purchasing).

## Boundaries and balance

- Server owns currency, upgrade costs, RNG, challenge results, recording metadata and offline time. Remote handlers accept intentions; no endpoint accepts a reward amount, client score, price or timestamp.
- Timing uses server receipt time minus half the server-measured round-trip ping, sampled when the challenge begins and capped at 250 ms. No client clock/score is accepted. STOP freezes the local pointer immediately while waiting for the server. Asymmetric delay, jitter and latency beyond the cap can still reduce accuracy. [GetNetworkPing](https://create.roblox.com/docs/reference/engine/classes/Player#GetNetworkPing) documents round-trip seconds.
- Don't Fall uses server-driven discrete tile movement and anchors the avatar during the challenge. This is intentional for verifiable results; it is not a free-jumping platformer.
- Reactions have a cooldown. One visitor earns at most one mutual $1 bonus per host stream, with a persistent $30 daily cap per player; votes are limited to one per break. The first three selections offer unfinished games so every stream demonstrates all three.
- Published recording income is deliberately below active play. Camera levels alter free recording odds; PC increases views, Microphone increases cash and subscribers. `Balance.luau` holds the tunable values.
- The city has 16 studio slots. Set the published experience's maximum players to 16 during owner-controlled publication. This setting is not stored in the Rojo place.
- Purchases carry the equipment level displayed to the player. Replaying an old purchase cannot buy another level or spend twice.
- Snapshot replication is bounded at 5 Hz, directory updates at 1 Hz, and render animation uses one client loop. No unbounded chat/video history or external asset downloads are created by gameplay.

## Assets and ownership

All city geometry, equipment and interface elements are original programmatic Roblox primitives. There are no marketplace models, third-party scripts or downloaded textures. Three installed Roblox audio sources form a small set of original cue arrangements; the recordings are referenced, not redistributed. The approved AI-generated concept is a documentation reference, excluded from the playable place. Avatars and their cosmetics are Roblox-provided player content. See [asset notes](docs/ASSETS.md).

MVP development is on `feature/issue-1-mvp`; the separate visual pass is on `feature/issue-4-visual-pass`, stacked on that branch.  `main` starts with the owner-authorized empty baseline. The pull request remains a draft pending acceptance. Do not merge or publish from this repository without the owner's manual acceptance.

## M4 diagnostics and owner gates

Build `tests/m4.project.json`, open the result and choose **Server & Clients → 8**. `Workspace.M4Clients` must match the actual client count (1–8). The scenario takes approximately 6.5 minutes after connection: 15 s warmup, 160 s real-client streams, 170 s with synthetic actors bringing the total profiles to 16, 35 s social interactions and 10 s cleanup observation. Client bots use actual RemoteEvents. Synthetic actors call the same server modules and create real arenas, but **are not network clients**. Logs label both counts and the memory backend. `M4 ALL PASSED` checks lifecycle correctness, not production performance acceptance. `M4_SERVER` and `M4_CLIENT` JSON messages are numbered chunks to avoid Studio disk-log truncation.

Build `tests/latency.project.json` for a one-client Timing diagnostic. Configure Studio's Network Simulator **before Play**; run once with zero added delay and once with 150 ms inbound + 150 ms outbound, zero jitter/loss. Twenty real Stop requests are scored by production Minigames; the test also records the result the old receipt-time rule would have produced. It changes only test cadence and round selection. Keep each condition's `LATENCY_RESULT` separate. This automatic timing driver does not replace manual input testing.

Build `tests/manual.project.json` for a manual Studio session. Its passive observer records first State/Start/Reward, stream reports, purchases and camera offsets. It sends no input, changes no profile and contains no automatic driver. Use mouse/keyboard and the device emulator yourself; retain `MANUAL` log lines. All diagnostic places are Studio-only and must never be published.

See [OWNER-CHECKLIST](docs/OWNER-CHECKLIST.md) for exact private DataStore, physical-phone and 12–16 real-client steps. These remain **NOT VERIFIED — OWNER ACTION** until evidence exists. Publishing, access/API settings, and PR merge remain owner-controlled. A one-minute absence is not guaranteed to show $1: offline payouts are integer with a carried fractional cursor; the checklist computes the necessary wait from the displayed recording rate.

## Visual pass — issue #4

The owner-approved [warm daylight direction](docs/ART_DIRECTION.md) replaces the blockout with a modular creator neighborhood, furnished studios, twelve distinct equipment variants, a responsive cream/ink HUD and brief reward/recording feedback. Existing progression, prices, odds and server authority are preserved. The display label **Hot** uses the existing internal **Popular** tier.

Use **Menu → Sound & Effects** to change sound volume or reduce effects. These are local session preferences. Low effects removes confetti, scale pulses and LIVE blinking and disables decorative studio lights; danger warnings remain visible.

Build `tests/visual.project.json` to inspect the staged visual tour. Press **N** for the next view, **B** for the previous view, **P** for a 30-second rendering sample. The fixture has fixed cameras, held challenges, seeded profiles and neutral display-name labels. It is for comparable screenshots, **not gameplay acceptance**. The normal build excludes this fixture. The QA place additionally checks all equipment levels, instance reuse, clear studio entry paths and bounded client effects.

See [visual validation](docs/VISUAL-VALIDATION.md) for paired screenshots, measured render costs, two-client regression results, a manual stream and the remaining owner checks. The visual PR remains a draft; these local results do not establish physical-phone or 16-client acceptance.
