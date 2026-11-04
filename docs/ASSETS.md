# Asset provenance

| Asset | Source | Treatment |
| --- | --- | --- |
| City, studios, equipment, stage, planters | Original `src/server/Visuals/` geometry, composed by `City.luau` | Roblox Part / SurfaceGui primitives; no imported models or scripts |
| Challenge arena | Original `src/server/Minigames.luau` geometry | Roblox Parts; gameplay retained |
| Interface, indicators and animation | Original `src/client` implementation | Roblox GUI primitives and TweenService |
| Sound sources | Roblox installation: `content/sounds/volume_slider.ogg`, `action_get_up.mp3`, `action_jump_land.mp3` | Three platform-owned recordings referenced through `rbxasset://sounds/`; no audio file copied or uploaded |
| Sound arrangements | Original `src/shared/SoundPalette.luau` | Different pitch, envelope, timing and layering for taps, start/stop, success/perfect/miss, donations, purchases, reactions, votes and four recording tiers; eight reusable local voices |
| Approved concept reference | Native OpenAI ImageGen, 4 November 2026 | `docs/art/approved-concept.png`; exact prompt in `docs/art/PROVENANCE.md`; reference only, excluded from runtime |
| Player character and cosmetics | Roblox standard character pipeline | No re-upload or custom avatar assets |

No marketplace packages, paid asset providers or third-party runtime scripts are used. The concept was generated; the playable geometry and interface are repository-native code. The project's source does not grant redistribution rights to Roblox's engine recordings. These are platform dependencies, not a separately licensed downloadable sound pack. Replace the three local references with owner-controlled licensed audio assets if Roblox removes them. Roblox documents `rbxasset` as a reference to the installed client content folder: [asset URI documentation](https://create.roblox.com/docs/projects/assets).

Volume (65% / 30% / mute) and reduced effects are local session preferences in Menu → Sound & Effects. Reduced effects removes reward confetti, scale pulses and LIVE blinking, slows no gameplay, retains danger colors and disables studio accent lights. Sound loading is asynchronous; failed playback cannot prevent rewards or controls.
