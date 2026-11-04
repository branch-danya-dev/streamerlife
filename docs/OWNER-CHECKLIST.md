# M4 owner checks — NOT VERIFIED — OWNER ACTION

These gates require an owner-controlled private Roblox experience, physical hardware, or additional testers. No game has been published and no access/security setting has been changed by the implementation agent. Keep PR #2 Draft until the results below are recorded.

## Real DataStore in a separate private experience

1. Build **default.project.json**, open the normal place, and check the tested commit in VALIDATION.md. Never publish QA, M4, Latency or Manual places; they contain Studio-only fixtures.
2. The owner uses **File → Publish to Roblox As…** to create a separate test experience, gives it an unmistakable test name, and verifies in Creator Dashboard that its access remains private. Do not overwrite the production experience. Invite only the intended testers through the owner's normal access controls. Set maximum players to 16 for the later load test.
3. Choose one consistent route for this entire test:
   - **Roblox app / private published server:** uses `StreamerLife_v1`, scoped to this new test universe. Studio API access is not needed for the app.
   - **Studio connected to the published test place:** owner enables **Game Settings → Security → Enable Studio Access to API Services** if required, and sets Boolean attribute `UseLiveDataInStudio=true` on ServerScriptService before Play. This uses `StreamerLife_Studio_v1`, a different store. Do not compare balances across the two routes. The yellow MEMORY MODE label must be absent.
4. Enter with a fresh test account/profile. Record the UTC/Moscow time, commit, route, money, subscribers, views, equipment levels and recording list. Complete a stream, buy one affordable upgrade, and complete another stream. Record the new values. Wait more than 45 seconds, then leave normally.
5. Rejoin the **same universe, route and account**. Money, equipment, recordings and counters must match the exit values plus only legitimate offline rewards. Confirm the visible equipment change remains. Do not treat a load-error kick as an empty new profile or reset the store to make the test pass.
6. For offline income, read the recording's displayed cash/hour rate `R`. With a new recording having at least an hour remaining, wait at least `ceil(3600/R)+5` seconds outside the server to guarantee at least $1 from that recording. A one-minute absence can legitimately pay $0 because payouts are integer and carried fractionally. Record departure/rejoin times and Welcome totals.
7. Immediately leave and rejoin again. The previous absence must not be paid again. A small award is allowed only if a new cumulative integer boundary was crossed. For each recording, expected cash is `floor(afterPaidSeconds*rate/3600)-floor(beforePaidSeconds*rate/3600)`. Eight-hour caps apply both to one absence and to a recording's lifetime paid time; making repeated reconnects must not reset either cursor.
8. In a **separate test profile**, exercise abrupt server termination and a rapid rejoin. An unexpired lease can deny entry for up to 180 seconds. After expiry, the last durable profile must load. A crash can lose progress since the last successful save; 45 seconds is the healthy autosave interval, not a guarantee during an outage. The unsaved interval can count as offline time.
9. Capture Output (Studio) or **F9 → Server** Developer Console (owner with server-log access). Record each `Profile storage request failed; attempt N`, load-error/lease-expired message, and any stack trace. Do not publish full logs with account IDs, tokens or unrelated platform data. The deterministic fault tests cover errors and races; real throttling/outage behavior remains NOT VERIFIED until observed in the private test service.
10. Save a small result table with commit, timestamps, backend, before/after balances, upgrade levels, recording count, offline seconds/reward, expected result and PASS/FAIL. If a test fails, retain the profile and logs for diagnosis; do not erase evidence. Revoke temporary test access/API access afterward if the owner no longer needs it.

Optional **read-only** server Command Bar inspection in the private Studio test (never type account credentials):

```luau
local S = require(game.ServerScriptService.Server.ProfileStore)
local P = game.Players:GetPlayers()[1]
local p = P and S.get(P)
if p then
    print("M4 profile", p.money, p.views, p.subscribers, p.lastSeen, #p.videos)
    print("M4 gear", p.upgrades.PC, p.upgrades.Microphone, p.upgrades.Camera)
    for _, v in ipairs(p.videos) do print("M4 video", v.tier, v.cashRate, v.paidSeconds) end
end
print("M4 storage", S.requests, S.failures, S.testMode)
```

## Physical phone — NOT VERIFIED — OWNER ACTION

- Record phone model, OS, network type, commit and session duration. Use the normal private published place.
- Start within 60 seconds; earn a reward within two minutes. Play Timing, Rain and Fall using real touches; confirm STOP freezes immediately, lane buttons respond, warning tiles leave an escape route, and avatar/camera return after the challenge.
- Repeat portrait and landscape; inspect notch/safe areas, 44+ logical-pixel controls, scrollable report/shop, all prices, close buttons and the virtual audience chat. The emulated phone is not evidence of physical touch accuracy.
- Play three full consecutive streams; buy an upgrade with earned cash; verify the visible change and a new stream afterward. Visit another studio, react, vote, return home. Repeat solo with no guests.
- Record typical/minimum FPS and worst stalls during a 10-minute session, temperature/thermal slowdown, audio volume/cues and any missed touches. Repeat with mobile data or elevated latency. Screenshots alone do not establish FPS.
- Also repeat a brief desktop mouse/keyboard pass for immediate STOP feedback, Fall reaction comfort, audible cues and guest-camera framing. The agent's multi-second screenshot/input loop cannot establish human reaction comfort; see the manual-run limits in VALIDATION.md.

## 12–16 connected clients — NOT VERIFIED — OWNER ACTION

Studio's documented local maximum is eight clients. The M4 harness separately reports real clients and synthetic server profiles; synthetic actors do not reproduce 16 connections, avatar render costs or network congestion.

In the private test experience, coordinate 12 then 16 actual clients/testers. Use the same device/network mix at each step; warm up for one minute, run at least five minutes with simultaneous streams, then two minutes of visits/votes/reactions and repeated starts/stops. Include simultaneous Fall arenas and leave/rejoin during a stream. Record client FPS/frame spikes, memory, server Heartbeat/CPU, network send/receive, DataStore errors/budget, peak arena/instance counts and cleanup after streams end. Keep zero-activity, 12-client and 16-client results separate. A reproducible game-script error, leaked arena or profile, lost save, duplicated reward, sustained server-frame degradation or unusable phone controls fails acceptance.

Sources: [Studio testing modes](https://create.roblox.com/docs/studio/testing-modes), [Network Simulator](https://create.roblox.com/docs/studio/network-simulator), [Data stores](https://create.roblox.com/docs/cloud-services/data-stores).
