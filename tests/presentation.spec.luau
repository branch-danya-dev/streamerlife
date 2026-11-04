--!nonstrict
local layout = require("../src/shared/Layout")
local sounds = require("../src/shared/SoundPalette")
local function overlap(a, b)
	return a.x < b.x + b.w and b.x < a.x + a.w and a.y < b.y + b.h and b.y < a.y + a.h
end
for _, size in ipairs({ { 320, 422 }, { 390, 720 }, { 852, 330 }, { 833, 577 }, { 720, 577 }, { 1280, 662 } }) do
	local l = layout(size[1], size[2])
	for _, key in ipairs({ "header", "game", "toast", "footer" }) do
		local r = l[key]
		assert(
			r.x >= 0 and r.y >= 0 and r.x + r.w <= size[1] and r.y + r.h <= size[2],
			key .. " outside safe area"
		)
	end
	assert(not overlap(l.toast, l.game), "reward covers game controls")
	assert(not overlap(l.toast, l.footer), "reward covers primary action")
	assert(not overlap(l.game, l.footer), "game covers primary action")
	assert(not overlap(l.game, l.header), "game covers currency")
	assert((l.game.w - 24) / 4 - 4 >= 44, "four lane touch targets below 44px")
	if not l.compact and not l.shortPortrait then
		assert(not overlap(l.chat, l.toast), "chat covers reward")
	end
end
print("PASS safe-area layout and 44px touch targets at six desktop/phone sizes")
for name, notes in pairs(sounds.cues) do
	assert(#notes > 0 and #notes <= 5, name .. " unbounded cue")
	for _, n in ipairs(notes) do
		assert(sounds.sources[n[2]], "unknown audio source")
		assert(n[1] >= 0 and n[1] + n[5] <= 1.2, "long cue blocks game feel")
		assert(n[3] > 0 and n[3] <= 3 and n[4] > 0 and n[4] <= 1, "invalid audio parameters")
	end
end
print("PASS every audio arrangement uses bounded voices, gain and duration")
