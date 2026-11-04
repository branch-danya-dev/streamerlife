# Validation — 4 November 2026

This is a draft MVP for owner acceptance, not an approved production release.

## Executed checks

| Check | Result | Evidence / scope |
| --- | --- | --- |
| Pure economy, probability, offline and lease tests | PASS, 35 cases | `tests/domain.spec.luau`; includes 10,000 stratified popularity rolls and 3,600 one-second reconnect calculations |
| Portable Luau analysis | PASS | Shared modules and domain tests, Luau 0.745; Roblox-dependent scripts are compiled, not fully type-checked |
| Luau syntax/bytecode compilation | PASS, all 16 scripts | Production and test scripts |
| StyLua formatting | PASS | `src`, `tests` |
| Rojo build | PASS | Normal and QA places, Rojo 7.7.1 |
| Studio solo Play | PASS | GO LIVE, challenge cycling and rewards, END STREAM report, recording/trophy; `evidence/manual-report.jpg` |
| Two-client integration | PASS | Two actual local Studio clients and server; action bots use real RemoteEvents; `evidence/studio-qa-results.txt` |
| Studio phone portrait | Checked | Report and all three upgrade rows fit the iPhone 17 Pro preset; device emulation is not a physical-device performance test |

The two-client scenario verifies both players spawn in their own studio; forged Grant/price/score requests do not alter money; Timing, Rain and Fall all settle; the guest visits and sees the host; reactions and ballots arrive; repeated visits/reactions produce exactly one $1 bonus per player for that stream; a repeated Finish action produces only one recording; the three purchases subtract exactly $240; release and reacquisition preserve cash, equipment and the recording with a new lease token. Upgrade checks use an explicitly injected $500 test-only fixture after the earned stream. Actual play earned more than $60 before that fixture.

The automated run completed at 13:28 Moscow time, 4 November 2026, with `QA ALL PASSED (two real Studio clients, memory backend)`. The included scenario is reproducible and never mapped into the normal place.

## Fixes discovered during interactive testing

- Initial character placement could race Roblox's spawn placement. Home placement now waits for the root and the spawn phase; both clients subsequently passed the spawn assertion.
- A high real Roblox user ID exceeded an overly narrow visitor validator. The bound now covers exactly representable integer IDs, while accepting local Studio negative IDs.
- Sparse tile-state maps were converted to dense boolean arrays for remote serialization.
- Compact landscape uses a shorter header and hides secondary chat during challenges; all primary buttons remain at least 44 logical pixels tall.
- Camera direction is reset on arrival/return, and the default player list is hidden to avoid covering the game panels.
- The original proposed local sound filename was not present in this Roblox installation; the build uses the verified packaged `volume_slider.ogg` cue.

## Remaining owner acceptance

- [ ] In a separate **published test experience**, enable API access and verify a real leave/rejoin preserves money, all equipment and recordings. Wait at least a minute to produce visible offline income, rejoin twice and confirm no duplicate award.
- [ ] Exercise real DataStore throttling/outages and abrupt server shutdown. Confirm failed loads never overwrite an existing profile and a stale lease blocks joining until expiry. Pure lease transforms pass; the Roblox network failure paths need live service testing.
- [ ] Complete all three challenges using touch on a physical phone; check portrait/landscape, camera, safe areas and audio. Desktop and emulated interaction do not certify physical hardware.
- [ ] Run 12–16 clients or representative devices. Record client FPS, memory, server frame time and bandwidth during simultaneous streams. This build limits replication and generated objects but has no measured 16-player performance claim.
- [ ] Owner reviews pacing, city appearance and difficulty; accepts the discrete server-driven Don't Fall controls and latency-sensitive Timing scoring.
- [ ] Owner accepts the draft PR before merge or production publication.

Roblox itself emitted account/chat and avatar asset HTTP warnings during local tests. No game-script exception was found in the completed two-client scenario. These platform warnings are not silently counted as product acceptance.

## Known limitations

- The map is built on Play, not visible in the initial edit viewport. Geometry is deliberately simple and there are no imported art packs.
- Memory mode resets when the local server stops. Persistent Studio testing selects an isolated store and must be configured by the owner.
- An ungraceful process termination can lose progress since the last 45-second autosave; its lease can delay reconnecting for up to 180 seconds. The unsaved interval can be counted as offline time after a crash.
- Timing uses server receipt time and has no client timestamp compensation. Don't Fall is an authoritative tile arena with discrete directional movement.
- Server-side validation prevents arbitrary numeric reward requests; it does not claim to prevent input automation or detect every exploit.
- No production publication, monetization, cross-server catalogue, real video, microphone or camera access is implemented.
