# Validation — M4, 4 November 2026

**Draft engineering baseline. M4 is not fully accepted.** Real DataStore/service failures, a physical phone and 12–16 actual network clients remain **NOT VERIFIED — OWNER ACTION**. The owner steps are in [OWNER-CHECKLIST](OWNER-CHECKLIST.md). No publication, access-setting change or merge was performed.

The gameplay/persistence code exercised below is commit `9148426a544fe1a997f2aa3fa9ae15f147e0a4ad`. Later changes in this acceptance pass add evidence, documentation and diagnostic log formatting. The final PR head and its CI run are recorded in PR #2; evidence rows identify the tested code instead of pretending that a document can contain its own commit hash.

## Acceptance matrix

| Scope | Status | Date / environment / exact tested code | Evidence and limit |
| --- | --- | --- | --- |
| Economy, offline caps, rounding, rewards, lease transforms | PASS | 2026-11-04; Luau 0.745; `9148426a544fe1a997f2aa3fa9ae15f147e0a4ad` | 35 domain tests; [automated log](evidence/m4-automated.txt) |
| Persistence I/O failures and concurrency | PASS | Same date/code; deterministic yielding adapter executing runtime Persistence | 13 tests: load failures, throttling/retry, lost responses, two servers, duplicate load, autosave/exit overlap, expiry/takeover, shutdown/in-flight load, hanging service, disconnect and reconnect |
| Purchase replay and bounded Timing calculation | PASS | Same date/code; Luau CLI | 3 regression groups; malformed ping, 0–250 ms delay, old-level replay; model is separate from real network experiment |
| Eight actual local clients | PASS, bounded scenario | 14:14–14:21 Moscow; Studio 0.745.462.7451125 / Windows; same code | [raw server log](evidence/m4-load-server.txt), [complete measurements](evidence/m4-load.json); 160 s real-client phase |
| Sixteen server profiles | PASS, synthetic component | Same run/code; 8 actual clients + 8 synthetic actors for 170 s | Actual production stream/minigame code and arena Instances; does not reproduce 16 network connections |
| Cleanup / consecutive streams / social load | PASS | Same run/code; memory backend | 35 s visits/reactions/votes; at least two recordings per real player; death and mid-Fall cleanup; 0 arenas, 0 tiles, 8 real profiles left |
| Timing with actual network impairment | PASS, bounded conditions | 14:23–14:26 Moscow; one real local Studio client; same gameplay code | [40 Stop intentions](evidence/m4-latency.txt); 20 at zero added delay, 20 at 150 ms each way, zero jitter/loss |
| Two-client regression | PASS | 14:28–14:30 Moscow; two actual Studio clients; same code; memory backend | [QA ALL PASSED](evidence/m4-two-client.txt): three games, recordings, repeated Finish/visits/reactions, voting, all three purchase paths, save/reacquire |
| Manual solo lifecycle and emulator layouts | PASS for observed interactions; human reaction/audio quality NOT VERIFIED | 14:33–14:44 Moscow; same code; passive Manual fixture, no bots; Windows / iPhone 17 Pro emulator portrait + landscape / desktop viewport | [observer log](evidence/m4-manual.txt); three full 150 s streams, earned upgrade, report/recordings, repeated starts, Rain button and Fall keyboard movement; input-tool delay limits fast reaction assessment |
| Local checks and five reproducible builds | PASS | 2026-11-04; Luau 0.745, StyLua 2.6.0, Rojo 7.7.1; production code unchanged from SHA above | [check log](evidence/m4-automated.txt); 51 test/check groups, portable analysis, formatting, every Luau file compiled; final-head GitHub Actions link in PR #2 |
| Real Roblox DataStore and service outage behavior | NOT VERIFIED — OWNER ACTION | No private experience published | Fault injection is not a live Roblox service test |
| 12–16 actually connected clients | NOT VERIFIED — OWNER ACTION | Local Studio supports at most 8 | Private multi-device/tester load gate; synthetic actors are explicitly excluded from this claim |
| Physical smartphone and sustained thermal/FPS behavior | NOT VERIFIED — OWNER ACTION | No physical phone controlled | Emulator layout and local rendering do not establish touch accuracy or hardware performance |

## Findings and fixes

- **Shutdown/load race:** previously BindToClose waited only for profiles already in `records`; a pending acquisition could complete after that loop. The runtime coordinator now tracks in-flight loads and waits for their release, with a 25-second shutdown bound. A test delays acquisition by five seconds while closing and proves the lease is released. A 40-second service hang explicitly times out instead of claiming durability.
- **Purchase replay:** a purchase request now names the displayed equipment level. After buying level 1, replaying the same request cannot spend again on level 2. The server still chooses the price and validates available money.
- **Latency scoring:** Timing subtracts half the server-measured round-trip ping, sampled once at challenge start and capped at 250 ms. It accepts no client timestamp, score or reward. The local pointer freezes on STOP immediately, and the settled challenge remains single-use. Jitter/asymmetric routing and delay beyond the cap remain limits.
- **Honest crash bound:** 45 seconds is the healthy autosave interval, not the maximum possible loss during storage failure. A crash/final-save failure loses progress since the last successful save; that interval may be counted as offline time. An unreleased lease can delay re-entry for up to 180 seconds. Documentation now states these limits and explains why one minute offline can legitimately pay $0.
- **Diagnostic log truncation:** Studio's disk logger truncated long JSON prints. Full server data were recovered from LogService history and MessageOut in 650-character chunks. The reproducible harness now emits bounded chunks itself. No gameplay data were changed during extraction.

## Load measurements

Host: AMD Ryzen 5 7600X, 12 logical threads, 31.112 GiB usable RAM, Windows, Studio 0.745.462.7451125. Eight separate Studio clients plus the local server ran on the same host; phone viewport preset iPhone 17 Pro landscape. No manual network impairment was added. All storage below is **memory**, not real DataStore. Warmup 15 s; real-client phase 160.011 s; mixed phase 170.009 s; social 35.015 s; cleanup observation 10.023 s.

| Metric | 8 actual clients: mean / worst | 8 actual + 8 synthetic: mean / worst |
| --- | --- | --- |
| All stream ticks in a sampled Heartbeat, ms | 0.032 / 1.357 | 0.055 / 1.194 |
| One stream tick, ms | 0.004 / 1.098 | 0.004 / 0.844 |
| One minigame tick, ms | 0.003 / 0.205 | 0.003 / 0.237 |
| Heartbeat interval, ms | 16.666 / 19.614 | 16.668 / 46.018 |
| Stats Heartbeat CPU, ms | 0.149 / 0.305 | 0.132 / 0.352 |
| Server memory, MB as reported by Stats | 1579.749 / 1591.930 | 1579.377 / 1585.055 |
| Stats.DataSendKbps | 5.184 / 11.060 | 7.079 / 12.048 |
| Peak arenas / tiles | 8 / 128 | 16 / 256 |
| Incoming actual Action RemoteEvents | 1223 total | 1440 total |
| Storage update attempts / failures | 24 / 0 | 64 / 0 |

The test wraps production `Streams.tick` and `Minigames.tick` with `os.clock`; batch time sums their work between Heartbeats. It samples Stats/memory/objects once per second. This is a short local run, not a long-session leak proof or published-server benchmark. Zero arena/tile counts and removal of synthetic profiles were asserted after cleanup. Memory after cleanup averaged 1585.819 MB versus 1579.740 MB during warmup; no unbounded growth was observed in this run, and no speculative performance refactor was made.

Seven background clients averaged about 15 FPS (Studio background throttling). The foreground client averaged 60.002 FPS in the real-client phase. Its mixed-phase mean was 46.096 FPS because focus moved to the server during log extraction; it is not a stable foreground benchmark. The worst mixed-phase frame observed across clients was 290.446 ms, on a background client. These editor/process/scheduling effects prevent treating the measurements as phone FPS acceptance. Full min/mean/max/sample counts are retained for every client and phase.

`Stats.DataReceiveKbps` returned zero despite observed Action traffic; this metric is uninformative in this local run and is not reported as proof of zero bandwidth. Storage request counts measure calls to the memory adapter. They do not measure Roblox request budgets, network retries or throttling. All actual clients' first Start occurred 16.2–39.0 s after their recorder began; first Reward 19.4–42.5 s, including harness waiting/warmup. These are bot-driven timings, separate from manual onboarding.

## Timing experiment

The test uses real Action RemoteEvents and a client driver that presses when the displayed server-time slider score exceeds 0.93. Only test cadence/round selection is shortened. The server records both production compensated score and the counterfactual old receipt-time score for each same input.

| Applied condition | Samples | Compensated mean / minimum | Old rule mean / minimum | Mean compensation |
| --- | --- | --- | --- | --- |
| 0 ms inbound + 0 ms outbound | 20 | 0.943 / 0.880 | 0.942 / 0.879 | 0.168 ms |
| 150 ms inbound + 150 ms outbound | 20 | 0.942 / 0.881 | 0.052 / 0.000 | 151.373 ms |

Settings evidence: [baseline](evidence/m4-network-baseline.jpg), [150 + 150 ms applied](evidence/m4-network-150ms.jpg). All 20 delayed rounds cleared. The test does not certify arbitrary packet loss/jitter; network controls were restored to zero afterward. The same receipt-time cap and single-use challenge still apply against replay/forged result fields.

## Manual lifecycle and qualitative UX

The Manual fixture is only an event observer. Every stream start and purchase was made through the normal UI, with no bot, money grant or shortened challenge. A fresh profile became ready at 11:33:11.860 UTC; first GO LIVE was at +11.408 s, first reward at +21.058 s. The first stream ended at +161.303 s. The Microphone was bought at +338.695 s for $70: money changed $76 → $6 and level 0 → 1; its model changed to the mint upgraded microphone. The intervening pause was review/inspection by the operator, not a game-enforced wait. Second-to-third restart took 9.8 s. No pause/restart of the simulation was used between streams.

| Manual stream | Duration from Start to Report | Challenges / successes | Money / views / subscribers | Recording |
| --- | --- | --- | --- | --- |
| 1 | 149.895 s | 10 / 2 | $76 / 206 / 21 | Yes |
| 2 | 149.977 s | 10 / 0 | $67 / 157 / 20 | Yes |
| 3 | 149.928 s | 9 / 2 | $80 / 191 / 25 | Yes (Viral, a single random outcome) |

Durations use client receipt times for Start/Report and differ slightly from the server's 150 s duration. The final balance was $153 after the $70 purchase. This is a sparse-input agent playthrough with missed/idle rounds, not a representative human balance sample. The first improved equipment remained present through subsequent streams. Virtual audience text continued with no guests.

Observed UI checks: [landscape report](evidence/m4-manual-first-report.jpg), [earned purchase and next price](evidence/m4-manual-upgrade.jpg), [portrait Rain](evidence/m4-manual-portrait.jpg), [desktop Fall warnings](evidence/m4-manual-pc-fall.jpg), [third report](evidence/m4-manual-third-report.jpg), [three recordings and their rates](evidence/m4-manual-recordings.jpg). Rain's numbered button moved the catcher from lane 2 to lane 1; keyboard movement changed the Fall cell during the first stream. Fall returned the avatar and camera to the studio repeatedly, with consistent recorded camera/root offsets. Report/shop close controls and all three prices remained accessible in the inspected layouts.

Remaining qualitative observations (not P0/P1 regressions established by this run): the transient reward toast overlaps the challenge heading; feedback is plain text/color plus one generic sound; rapid bot visits sometimes leave the guest camera looking at the studio front sign. Arrival/return remains functional, but guest camera composition merits another human look. The remote computer-control loop takes several seconds between observation and input, so attempted STOP presses sometimes arrived after the challenge and opened the break's shop in the same button position. **Immediate STOP freeze, human Timing/Fall reaction comfort and audible cue quality are NOT VERIFIED by this manual pass.** The automated real-network Timing experiment establishes scoring behavior only. Include these in the owner phone/desktop playtest; do not infer human accuracy or sound quality from screenshots.

## Balance proposals (no formula changes)

[Deterministic model](evidence/m4-balance-model.csv), fresh equipment, three 150-second streams, fixed per-challenge score, rotation and 5-second restart allowance: score 0 earns $81 across three streams; 0.50 earns $390; 0.75 earns $540; 1.00 earns $690. First $70 occurs at 408.2 / 85.4 / 48.0 / 48.0 seconds respectively. The model assumes a 0.6-second Timing response for nonzero scores and excludes social/offline income; it is not a human playtest forecast.

Keep the first Microphone price at $70 until owner testing: a moderately successful solo player can reach it in about 1.5 minutes in the model. Consider an optional later balance experiment if consistently missing players take too long; do not increase passive rewards based only on bots. Camera levels raise the expected popularity multiplier from 1.405 to 1.450 / 1.495 / 1.540 (about 9.6% total); price/value may feel weaker than Microphone. Observe purchases before changing free viral odds. The six-second inter-challenge interval gives time to read rewards/vote; test human pacing before shortening it. No economy formulas or new content were added in M4.

## Remaining scope limits

Map and assets remain original programmatic primitives; this pass is technical acceptance, not visual production. The map is generated on Play. Memory mode resets when the local server ends. Runtime Roblox-dependent scripts are bytecode-compiled; portable modules and deterministic tests are also statically analyzed. No full Roblox type-check, physical-phone test, live DataStore outage test, public release, monetization or cross-server catalogue is claimed.
