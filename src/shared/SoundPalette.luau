--!strict
-- Original cue arrangements. Source recordings belong to the installed Roblox engine;
-- they are referenced, never copied or redistributed. See docs/ASSETS.md.
return table.freeze({
	sources = {
		tone = "rbxasset://sounds/volume_slider.ogg",
		soft = "rbxasset://sounds/action_get_up.mp3",
		tick = "rbxasset://sounds/action_jump_land.mp3",
	},
	-- Each note: delay, source, playback speed, gain, maximum duration.
	cues = {
		tap = { { 0, "tick", 1.8, 0.13, 0.07 } },
		start = {
			{ 0, "soft", 1.6, 0.18, 0.16 },
			{ 0.09, "tone", 1.2, 0.2, 0.18 },
			{
				0.19,
				"tone",
				1.5,
				0.15,
				0.2,
			},
		},
		stop = { { 0, "tick", 1.5, 0.18, 0.09 } },
		finish = { { 0, "soft", 1.25, 0.18, 0.2 }, { 0.12, "tone", 1, 0.16, 0.23 } },
		hit = { { 0, "tick", 2.1, 0.1, 0.07 }, { 0, "tone", 1.5, 0.15, 0.15 } },
		perfect = {
			{ 0, "tone", 1.25, 0.17, 0.17 },
			{ 0.09, "tone", 1.5, 0.17, 0.17 },
			{
				0.18,
				"tone",
				1.9,
				0.16,
				0.2,
			},
		},
		miss = { { 0, "soft", 0.85, 0.16, 0.2 } },
		donate = { { 0, "tick", 2.3, 0.14, 0.06 }, { 0.06, "tone", 1.7, 0.18, 0.14 } },
		purchase = {
			{ 0, "soft", 1.5, 0.16, 0.16 },
			{ 0.08, "tone", 1.1, 0.2, 0.18 },
			{
				0.2,
				"tone",
				1.65,
				0.18,
				0.24,
			},
		},
		reaction = { { 0, "soft", 1.9, 0.13, 0.13 } },
		vote = { { 0, "tick", 1.8, 0.14, 0.09 }, { 0.08, "tone", 1.3, 0.1, 0.12 } },
		normal = { { 0, "tone", 1.1, 0.15, 0.25 } },
		hot = { { 0, "tone", 1.1, 0.15, 0.2 }, { 0.13, "tone", 1.4, 0.15, 0.22 } },
		viral = {
			{ 0, "soft", 1.3, 0.16, 0.2 },
			{ 0.1, "tone", 1.1, 0.18, 0.2 },
			{ 0.24, "tone", 1.4, 0.18, 0.2 },
			{ 0.38, "tone", 1.8, 0.16, 0.28 },
		},
		legendary = {
			{ 0, "soft", 1.1, 0.18, 0.22 },
			{ 0.08, "tone", 0.9, 0.18, 0.22 },
			{ 0.22, "tone", 1.2, 0.18, 0.22 },
			{ 0.36, "tone", 1.5, 0.17, 0.22 },
			{ 0.5, "tone", 1.8, 0.16, 0.3 },
		},
	},
})
