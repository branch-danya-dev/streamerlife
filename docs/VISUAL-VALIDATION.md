# Visual & Game Feel — validation

Issue [#4](https://github.com/branch-danya-dev/streamerlife/issues/4), stacked [Draft PR #5](https://github.com/branch-danya-dev/streamerlife/pull/5), based on [PR #2](https://github.com/branch-danya-dev/streamerlife/pull/2). Owner approved the warm daylight concept on 4 November 2026. The concept in ART_DIRECTION is a generated reference; every image below is an actual Studio capture.

## Evidence revisions

- Baseline runtime: `eca81cd1b87920a74a7e49d6d89ffba5199f9628`.
- Comparable visual tour and render samples: `2d27e170d7907637cdb259a927b8fade7001520a`; `Visual-Review.rbxlx` SHA-256 `3f25be4bfa04ec2a445fdee4e3864fc8b8253fa9bb20b1b98fc53cdcf66aa396`.
- Initial two-client and manual runtime: `88705d131f142bf4c2753275d4b478949c41800c`. Changes since the render samples raise/offset the normal Fall camera, lower the arrival camera below the facade awning and hide proximity prompts while a stream is shown. Final runtime `dffdad97fecb108c99d859b2c58e9abff850199a` also reverses the Fall camera's viewing side so world movement agrees with the control grid and hides the matching studio roof using the arena position. World geometry, lighting, UI layout, sounds and all economy modules match the render samples. The fixed tour camera deliberately remains the baseline camera for comparison.
- Two-client QA also checks twelve equipment variants, cached updates, clear entry lanes, all sixteen studios at maximum gear, HUD state, sound-source loading, mute and bounded effects. Final run results follow below.

The tour is **staged, not a successful gameplay run**: profile values, rarity rolls and camera transforms are fixed; challenge clocks are held. Rain lanes remain random. Fall danger colors are held at the original fixture colors. Names are replaced with a neutral label for screenshots. The door prompt in remote city shots belongs to the avatar still standing at its studio. These fixtures are excluded from the normal place.

## Matching views

Desktop viewport: 833 × 635. Phone: Studio iPhone 17 Pro emulator, landscape, same panel/window size. Captures retain the Studio frame and fixture label; they are not retouched. The phone emulator is not evidence of physical-device performance.

| Scene | Desktop baseline | Desktop updated | Phone baseline | Phone updated |
| --- | --- | --- | --- | --- |
| studio | [PC before](evidence/visual-before/pc-studio.jpg) | [PC after](evidence/visual-after/pc-studio.jpg) | [Phone before](evidence/visual-before/phone-studio.jpg) | [Phone after](evidence/visual-after/phone-studio.jpg) |
| street | [PC before](evidence/visual-before/pc-street.jpg) | [PC after](evidence/visual-after/pc-street.jpg) | [Phone before](evidence/visual-before/phone-street.jpg) | [Phone after](evidence/visual-after/phone-street.jpg) |
| plaza | [PC before](evidence/visual-before/pc-plaza.jpg) | [PC after](evidence/visual-after/pc-plaza.jpg) | [Phone before](evidence/visual-before/phone-plaza.jpg) | [Phone after](evidence/visual-after/phone-plaza.jpg) |
| live | [PC before](evidence/visual-before/pc-live.jpg) | [PC after](evidence/visual-after/pc-live.jpg) | [Phone before](evidence/visual-before/phone-live.jpg) | [Phone after](evidence/visual-after/phone-live.jpg) |
| timing | [PC before](evidence/visual-before/pc-timing.jpg) | [PC after](evidence/visual-after/pc-timing.jpg) | [Phone before](evidence/visual-before/phone-timing.jpg) | [Phone after](evidence/visual-after/phone-timing.jpg) |
| rain | [PC before](evidence/visual-before/pc-rain.jpg) | [PC after](evidence/visual-after/pc-rain.jpg) | [Phone before](evidence/visual-before/phone-rain.jpg) | [Phone after](evidence/visual-after/phone-rain.jpg) |
| fall | [PC before](evidence/visual-before/pc-fall.jpg) | [PC after](evidence/visual-after/pc-fall.jpg) | [Phone before](evidence/visual-before/phone-fall.jpg) | [Phone after](evidence/visual-after/phone-fall.jpg) |
| report | [PC before](evidence/visual-before/pc-report.jpg) | [PC after](evidence/visual-after/pc-report.jpg) | [Phone before](evidence/visual-before/phone-report.jpg) | [Phone after](evidence/visual-after/phone-report.jpg) |
| videos | [PC before](evidence/visual-before/pc-videos.jpg) | [PC after](evidence/visual-after/pc-videos.jpg) | [Phone before](evidence/visual-before/phone-videos.jpg) | [Phone after](evidence/visual-after/phone-videos.jpg) |
| gear | [PC before](evidence/visual-before/pc-gear.jpg) | [PC after](evidence/visual-after/pc-gear.jpg) | [Phone before](evidence/visual-before/phone-gear.jpg) | [Phone after](evidence/visual-after/phone-gear.jpg) |

Equipment sequence: [level 0](evidence/visual-after/pc-studio.jpg), [level 1](evidence/visual-after/pc-level1.jpg), [level 2](evidence/visual-after/pc-level2.jpg), [level 3](evidence/visual-after/pc-level3.jpg). [Additional front view of the social plaza](evidence/visual-after/pc-plaza-front.jpg). [Portrait shop baseline](evidence/visual-before/phone-portrait-gear.jpg) and [updated](evidence/visual-after/phone-portrait-gear.jpg).

## Rendering comparison

Same Windows machine, Studio 0.745.462.7451125, Ryzen 5 7600X (12 logical threads), approximately 31 GiB RAM; one local Play client with memory storage, same camera and viewport, LAN without added impairment. Studio graphics settings were left unchanged: automatic QualityLevel/EditQualityLevel = 0, GraphicsMode = 1, SavedQualityLevel = 0, FramerateCap = -1. Two Studio editor processes were open in each comparison. Lighting changes are part of the visual pass. Other desktop activity was not controlled. These are capped foreground rendering observations, **not a GPU benchmark or a mobile/16-client performance claim**.

Thirty seconds per scene, 29 approximately one-second samples. Memory is `Stats:GetTotalMemoryUsageMb()` for the Studio process, not isolated asset memory. Worst frame is the largest RenderStepped interval. [Raw baseline aggregates](evidence/visual-before/metrics.json) and [updated aggregates](evidence/visual-after/metrics.json).

| Metric | Studio before | Studio after | Plaza before | Plaza after |
| --- | ---: | ---: | ---: | ---: |
| Mean FPS | 60.002 | 60.002 | 60.003 | 60.004 |
| Minimum 1-second FPS | 59.925 | 59.946 | 59.952 | 59.942 |
| Worst frame, ms | 18.274 | 18.555 | 18.503 | 18.637 |
| Mean memory, MB | 2382.62 | 2455.34 | 2391.54 | 2445.44 |
| Peak memory, MB | 2382.87 | 2457.59 | 2392.83 | 2446.88 |
| BaseParts, including avatar | 293 | 2161 | 293 | 2161 |
| Lights | 16 | 16 | 16 | 16 |
| Persistent particle emitters | 0 | 0 | 0 | 0 |
| Mean Stats send, Kbps | 0.537 | 0.488 | 0.512 | 0.497 |

Studio mean memory increased by 72.72 MB (3.05%); plaza by 53.90 MB (2.25%). The 60 FPS cap hides unused rendering headroom. Stats receive reported zero in all four local runs; this counter is uninformative here and does not mean no replication. No network savings are claimed. Snapshot/directory cadence remains unchanged.

## Engine regression and direct interaction

On 4 November 2026, 13:55–13:57 UTC, final runtime `dffdad9`, **two actual Studio clients** completed the full automated cycle with isolated memory storage: forged remote rejection; all three challenges; recording; visit, vote and capped social rewards; all three purchases; save/reacquire; twelve equipment variants; unchanged-category caching; and sixteen clear entry corridors. Both clients passed HUD, mute, reduced effects, 24-particle cap/cleanup, eight-voice limit and loading of all three sound sources. [Extracted application log](evidence/visual-after/two-client.txt). The host also passed projection checks for Right/Up and visibility of its arena roof. The run began in desktop mode and the host switched to iPhone 17 Pro landscape during the stream. Studio emitted avatar wrap-deformer mesh-fetch warnings; no project-script error was found. These are real local clients driven by test bots, not human players or real DataStore. The earlier phone-emulator run on `88705d1` is retained [separately](evidence/visual-after/two-client-88705d1.txt).

With every one of the sixteen studios temporarily fitted with maximum gear, the engine measured **2,959 BaseParts, 16 lights and 16 glass panes**, below the fixture limits (3,600 / 16 / 16). This is a content budget check, not a 16-network-client load result. The old eight-client mixed M4 run in VALIDATION.md was not repeated for this visual pass; its timing numbers are not asserted for the new city.

The passive manual fixture (no bots) completed one full 150-second stream at 13:24:33–13:27:03 UTC: ten challenges, $57 (including $19 donations), 153 views, 16 subscribers and one Normal recording. [Observer log](evidence/visual-after/manual.txt), [actual mobile report](evidence/visual-after/manual-phone-report.jpg). Direct pointer actions started the stream, closed its report, opened Menu and enabled reduced effects. A phone-emulator tap changed Rain from lane 2 to lane 4: [captured response](evidence/visual-after/manual-phone-rain-tap.jpg). The held comparison report also scrolled to its upgrade button and odds: [scrolled report](evidence/visual-after/phone-report-scrolled.jpg). Tool input latency prevents a credible human reaction-time/Timing-quality assessment; failed or late key presses are not counted as successful challenge control.

Manual play exposed the arrival camera intersecting the facade sign. Lowering its pitch fixed the initial spawn and three subsequent Fall returns. [Actual arrival](evidence/visual-after/manual-arrival.jpg), [actual Fall camera](evidence/visual-after/manual-fall-before-key.jpg), [return](evidence/visual-after/manual-return.jpg), [reward toast beside the challenge panel](evidence/visual-after/manual-reward-toast.jpg), [reduced setting](evidence/visual-after/manual-settings-reduced.jpg). The passive camera measurements agree across spawn/returns. No continuous video was recorded; these are separate observed frames.

All 51 existing portable checks plus two presentation groups pass: six safe-area layouts/44-pixel targets and bounded sound arrangements. Portable analysis, formatting, compilation of every Luau source/test and all six Rojo projects pass. [Check output](evidence/visual-after/automated.txt). The source diff confirms Balance, Domain, Rules, Lease, Persistence, ProfileStore, Social and server remote dispatch are unchanged.

Final camera and roof validation: [desktop arena](evidence/visual-after/final-fall-camera.jpg), [phone arena](evidence/visual-after/final-phone-fall-camera.jpg), [two players after return and upgrades](evidence/visual-after/final-two-client-return.jpg). These captures use final runtime `dffdad9`; the earlier manual Fall shot above predates the direction correction. The corresponding normal place SHA-256 is `534231049191e65e03504fe340c783e371cb91ee82fa45f89df89aa7ff926d8f`; the final QA fixture SHA-256 is `f3aa425999c5f35ace8eb7656130404cb9405379731428f8ceabeae3f20e6a2c`. [Runtime CI passed](https://github.com/branch-danya-dev/streamerlife/actions/runs/41842342722).

## Implementation limits and review

Direct keyboard checks used the held visual fixture (`2d27e1`) to separate key handling from tool latency: Space froze the Timing pointer ([before](evidence/visual-after/keyboard-timing-before.jpg), [stopped](evidence/visual-after/keyboard-timing-stopped.jpg)); D moved Rain from lane 2 to 3 ([before](evidence/visual-after/keyboard-rain-before.jpg), [after](evidence/visual-after/keyboard-rain-after.jpg)); D moved the Fall grid marker from cell 6 to 7 ([before](evidence/visual-after/keyboard-fall-before.jpg), [after](evidence/visual-after/keyboard-fall-after.jpg)). These are binding checks, not normal-cadence wins. This last check exposed reversed world framing: the old fixed tour view makes +X move left on screen. Runtime `dcc40f9` fixes that camera side and adds an engine projection regression check for both Right and Up. The comparison tour deliberately retains its old camera, so those two keyboard-Fall captures show the pre-fix framing.

Desktop wheel scrolling reaches the last Menu row at the compact 640 × 480 preset: [actual scrolled menu](evidence/visual-after/manual-menu-scrolled.jpg), final runtime `88705d1`. Injected wheel/drag actions in the phone emulator did not reliably move Menu. Changing the canvas calculation did not resolve that observation, so those speculative runtime changes were discarded. **Touch scrolling is NOT VERIFIED**, explicitly included in the physical-phone owner gate; the successful desktop/report scroll is not a touch-scroll pass.

Rewards use at most 24 short-lived local GUI particles and eight reused Sound voices. All three sources are engine-installed recordings with original cue arrangements; no file is redistributed. Mute and reduced effects are separate local session preferences. Reduced effects removes confetti, scale animation and LIVE blinking, preserves static danger markers, and disables decorative lights. The 16 studio windows are the only glass panes. Small props have no collision/touch/query and no shadows. Only changed equipment categories rebuild. A five-Hz local roof visibility update keeps interiors visible without removing exterior roofs.

The price/reward/probability/offline/lease modules and remote validation are unchanged from the base. The server adds only grade/combo presentation metadata to existing reward events and changes arena colors. The display name Hot keeps the internal Popular tier and its weights. The generated style concept and all provenance are documented in [ASSETS](ASSETS.md).

## Owner-only gates

Live DataStore outage/reconnect behavior, physical-phone controls/thermal performance and 12–16 real network clients remain **NOT VERIFIED — OWNER ACTION**, as in [OWNER-CHECKLIST](OWNER-CHECKLIST.md). Subjective audio balance, human reaction comfort and final art acceptance require owner playtesting. Loaded sound files and automated bots do not establish those subjective results. No game publication or PR merge was performed.
