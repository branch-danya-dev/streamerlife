# StreamerLife / Viral City — MVP

Scope: [issue #1](https://github.com/branch-danya-dev/streamerlife/issues/1). A solo-first Roblox vertical slice; English game UI, no real video or purchases.

## Technical decisions

- Rojo maps shared Luau modules, server services and one client controller into a reproducible place. The city and equipment are original procedural Roblox parts.
- Server owns profiles, challenge clocks, input validation, rewards, popularity rolls, purchases and social allowances. Clients send bounded intentions only.
- Hype Timing uses receipt time; Donation Rain uses a server-controlled catcher lane and scheduled drops; Don't Fall uses a server-controlled avatar on a discrete tile arena. This keeps outcomes verifiable without trusting client physics or submitted scores.
- A 150-second stream alternates short challenges and voting breaks. Each challenge settles once. Early exit grants earned rewards but only a qualified stream produces a recording.
- DataStore UpdateAsync acquires a per-user lease and atomically applies offline income. A unique connection token fences stale writers. Autosave, leaving and shutdown use the same serialized writer. Failed loading never creates a writable blank profile.
- Studio defaults to isolated in-memory data. Published servers always use persistent data. Live-service tests require a separate published test experience.
- A compact plaza, 16 instanced studios, upgrade kiosk and stage share one server. Preset reactions and one ballot per break need a real studio visit; social currency has a persistent daily cap.
- Every game string lives in Shared/Strings. UI uses touch-sized buttons, scrolling panels and a bounded responsive scale. Roblox avatars remain visible.

## Milestones and gates

- [x] M0 implementation: buildable Rojo place, startup map and UI, launch instructions.
- [x] M1 implementation: three complete solo challenges, immediate rewards, three visible upgrades, report.
- [x] M2 implementation: versioned profiles, safe retries/leases, recordings, capped offline income, welcome back. Pure logic and memory persistence pass; published DataStore acceptance remains open.
- [x] M3 implementation: visiting, live directory, reactions, voting, capped social bonuses. Two real Studio clients pass the integration scenario.
- [ ] M4 final acceptance: automatic checks and two-client scenario pass; real-device, live DataStore and 12–16-player performance checks still require acceptance.

Implementation status and actual verification are recorded separately in `docs/VALIDATION.md`. A compiled place is not evidence of a passed interactive acceptance test. Publication and merge require owner acceptance.
