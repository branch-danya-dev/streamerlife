# Asset provenance

| Asset | Source | Treatment |
| --- | --- | --- |
| City, studios, equipment, stage, planters, arena | Original `src/server/City.luau` and `Minigames.luau` geometry | Roblox Part / Seat / SurfaceGui primitives |
| Interface, indicators and animation | Original `src/client` implementation | Roblox GUI primitives and TweenService |
| Reward / notification sound | Roblox installation: `content/sounds/volume_slider.ogg` | Referenced with `rbxasset://sounds/volume_slider.ogg`, no copied audio file |
| Player character and cosmetics | Roblox standard character pipeline | No re-upload or custom avatar assets |

No marketplace packages, image generators, paid providers or third-party scripts are used. The project's source does not grant redistribution rights to Roblox's engine assets. Replace the built-in cue with an owner-controlled licensed audio asset if the platform removes the local cue in a future client.
