--!nonstrict
-- Model only; observed player sessions are recorded separately.
local Config = require("../src/shared/Balance")
local Domain = require("../src/shared/Domain")(Config)
print("model_score,streams,cash,views,first_affordable_seconds")
for _, score in ipairs({ 0, 0.5, 0.75, 1 }) do
	local p = Domain.new(0)
	local time, first = 0, nil
	for stream = 1, 3 do
		local elapsed, combo, rotation = 2, 0, 1
		while elapsed < 150 do
			local kind = Config.ChallengeNames[rotation]
			elapsed += 0.7 + (if kind == "Timing" and score > 0 then 0.6 else Config.Duration[kind])
			if elapsed >= 150 then
				break
			end
			combo = if score >= 0.5 then math.min(5, combo + 1) else 0
			Domain.grant(p, Domain.reward(p, score, combo, kind))
			if not first and p.money >= 70 then
				first = time + elapsed
			end
			elapsed += 6
			rotation = rotation % 3 + 1
		end
		time += 155
	end
	print(string.format("%.2f,3,%d,%d,%.1f", score, p.money, p.views, first or -1))
end
for camera = 0, 3 do
	local p = Domain.new(0)
	p.upgrades.Camera = camera
	local expected = 0
	for _, tier in ipairs(Domain.odds(p)) do
		expected += tier.weight / 100 * tier.multiplier
	end
	print(string.format("camera=%d expected_popularity_multiplier=%.3f", camera, expected))
end
