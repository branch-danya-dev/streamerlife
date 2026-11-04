--!nonstrict
local Config = require("../src/shared/Balance")
local Domain = require("../src/shared/Domain")(Config)
local Rules = require("../src/shared/Rules")
local Lease = require("../src/shared/Lease")(Config, Domain)
local passed = 0
local function test(name, body)
	local ok, message = pcall(body)
	if not ok then
		error("FAIL " .. name .. ": " .. tostring(message))
	end
	passed += 1
	print("PASS " .. name)
end
local function equal(actual, expected)
	assert(actual == expected, "expected " .. tostring(expected) .. ", got " .. tostring(actual))
end
local function recording(now)
	local p = Domain.new(now)
	Domain.publish(p, { money = 180, views = 800 }, now, "video", 0.1)
	return p
end

test("fresh player can progress without visitors", function()
	local p = Domain.new(1000)
	for _ = 1, 5 do
		Domain.grant(p, Domain.reward(p, 1, 1, "Timing"))
	end
	assert(Domain.buy(p, "PC"))
	equal(p.upgrades.PC, 1)
end)
test("insufficient purchase is atomic", function()
	local p = Domain.new(0)
	assert(not Domain.buy(p, "PC"))
	equal(p.money, 0)
	equal(p.upgrades.PC, 0)
end)
test("invalid category and max level cannot spend", function()
	local p = Domain.new(0)
	p.money = 5000
	assert(not Domain.buy(p, "arbitrary"))
	for _ = 1, 3 do
		assert(Domain.buy(p, "PC"))
	end
	local before = p.money
	assert(not Domain.buy(p, "PC"))
	equal(p.money, before)
end)
test("three categories have finite reachable upgrade prices", function()
	local p = Domain.new(0)
	p.money = 10000
	for _, category in ipairs({ "PC", "Microphone", "Camera" }) do
		for level = 1, 3 do
			assert(Domain.buy(p, category))
			equal(p.upgrades[category], level)
		end
	end
end)
test("NaN infinity negative values never enter currency", function()
	local p = Domain.new(0)
	for _, value in ipairs({ -1, 0 / 0, math.huge, -math.huge }) do
		Domain.grant(p, { money = value, views = value, subscribers = value })
	end
	equal(p.money, 0)
	equal(p.views, 0)
	equal(p.subscribers, 0)
	Domain.grant(p, { money = 1e30 })
	equal(p.money, Config.MaxValue)
	Domain.grant(p, { money = 999 })
	equal(p.money, Config.MaxValue)
end)
test("malformed persisted fields normalize to bounded schema", function()
	local p = Domain.normalize({
		money = 0 / 0,
		views = -999,
		upgrades = { PC = 200 },
		videos = { false, { id = "x", tier = "Exploit" } },
		stats = 2,
	}, 50)
	equal(p.version, 1)
	equal(p.money, 0)
	equal(p.views, 0)
	equal(p.upgrades.PC, 3)
	equal(#p.videos, 0)
end)
test("reward clamps score and combo", function()
	local p = Domain.new(0)
	equal(Domain.reward(p, 9999, 999, "Timing").money, Domain.reward(p, 1, 5, "Timing").money)
	equal(Domain.reward(p, 0 / 0, 0, "Timing").money, Domain.reward(p, 0, 0, "Timing").money)
	equal(Domain.reward(p, -200, -1, "Timing").money, 3)
end)
test("donation report is included in money, not paid twice", function()
	local p = Domain.new(0)
	local r = Domain.reward(p, 1, 0, "Rain")
	Domain.grant(p, r)
	equal(r.donations, r.money)
	equal(p.money, r.money)
end)
test("upgrade effects increase their intended rewards", function()
	local p = Domain.new(0)
	local before = Domain.reward(p, 1, 0, "Rain")
	p.upgrades.PC = 3
	p.upgrades.Microphone = 3
	local after = Domain.reward(p, 1, 0, "Rain")
	assert(
		after.views > before.views and after.money > before.money and after.subscribers > before.subscribers
	)
end)
test("all camera probabilities sum to 100 and stay positive", function()
	local p = Domain.new(0)
	for level = 0, 3 do
		p.upgrades.Camera = level
		local sum = 0
		for _, tier in ipairs(Domain.odds(p)) do
			assert(tier.weight > 0)
			sum += tier.weight
		end
		assert(math.abs(sum - 100) < 1e-9)
	end
end)
test("popularity boundaries select correct categories", function()
	local p = Domain.new(0)
	equal(Domain.roll(p, 0).id, "Normal")
	equal(Domain.roll(p, 0.78).id, "Popular")
	equal(Domain.roll(p, 0.95).id, "Viral")
	equal(Domain.roll(p, 0.995).id, "Legendary")
	equal(Domain.roll(p, 1).id, "Legendary")
end)
test("exhaustive stratified rolls reproduce configured weights", function()
	local p = Domain.new(0)
	local counts = { Normal = 0, Popular = 0, Viral = 0, Legendary = 0 }
	for i = 0, 9999 do
		local tier = Domain.roll(p, (i + 0.5) / 10000)
		counts[tier.id] += 1
	end
	equal(counts.Normal, 7800)
	equal(counts.Popular, 1700)
	equal(counts.Viral, 450)
	equal(counts.Legendary, 50)
end)
test("recording library is bounded and trophy never downgrades", function()
	local p = Domain.new(0)
	for i = 1, 20 do
		Domain.publish(p, { money = 100, views = 100 }, 0, tostring(i), if i == 1 then 1 else 0)
	end
	equal(#p.videos, 5)
	equal(p.videos[1].id, "20")
	equal(p.cosmetics.trophy, "Legendary")
end)
test("offline income pays only elapsed time once", function()
	local p = recording(1000)
	local result = Domain.offline(p, 4600)
	equal(result.money, 6)
	equal(result.views, 100)
	equal(Domain.offline(p, 4600).money, 0)
	equal(p.money, 6)
end)
test("eight hour cap survives long absences and reconnects", function()
	local p = recording(1000)
	equal(Domain.offline(p, 1000 + 86400).money, 48)
	equal(Domain.offline(p, 1000 + 2 * 86400).money, 0)
	equal(p.videos[1].paidSeconds, 28800)
end)
test("clock rollback cannot replay paid time", function()
	local p = recording(1000)
	Domain.offline(p, 4600)
	equal(Domain.offline(p, 2000).money, 0)
	equal(p.lastSeen, 4600)
	equal(Domain.offline(p, 4600).money, 0)
end)
test("fractional income is independent of reconnect frequency", function()
	local a, b = recording(1000), recording(1000)
	Domain.offline(a, 4600)
	for i = 1, 3600 do
		Domain.offline(b, 1000 + i)
	end
	equal(a.money, b.money)
	equal(a.views, b.views)
end)
test("new videos cannot earn before creation", function()
	local p = recording(1000)
	p.lastSeen = 0
	equal(Domain.offline(p, 1000).money, 0)
end)
test("no recordings means no offline farm", function()
	local p = Domain.new(0)
	equal(Domain.offline(p, 86400).money, 0)
end)
test("social rewards cap persists across normalization and clock rollback", function()
	local p = Domain.new(86400)
	for _ = 1, Config.SocialDailyCap do
		assert(Domain.social(p, 86400))
	end
	assert(not Domain.social(p, 86400))
	assert(not Domain.social(p, 0))
	p = Domain.normalize(p, 86410)
	assert(not Domain.social(p, 86410))
	assert(Domain.social(p, 172800))
	equal(p.socialEarned, 1)
end)
test("timing uses bounded server-time accuracy", function()
	equal(Rules.timing(0.6, 0.5, 0.2), 1)
	equal(Rules.timing(0, 0.5, 0.2), 0)
	for i = 0, 1000 do
		local score = Rules.timing(i / 100, 0.5, 0.2)
		assert(score >= 0 and score <= 1)
	end
end)
test("tile moves cannot wrap across rows or leave arena", function()
	equal(Rules.move(1, "Left", 4), 1)
	equal(Rules.move(4, "Right", 4), 4)
	equal(Rules.move(1, "Up", 4), 1)
	equal(Rules.move(16, "Down", 4), 16)
	equal(Rules.move(6, "Up", 4), 2)
	equal(Rules.move(6, "Teleport", 4), 6)
end)
test("invalid remote number shapes are rejected", function()
	for _, value in ipairs({ 0 / 0, math.huge, -1, 0, 1.1, 5, "1", {} }) do
		assert(not Rules.integer(value, 1, 4))
	end
	assert(Rules.integer(4, 1, 4))
end)
test("one ballot per visitor and only offered choices", function()
	local votes = {}
	assert(not Rules.ballot(votes, 1, "Hack", Config.ChallengeNames))
	assert(Rules.ballot(votes, 1, "Rain", Config.ChallengeNames))
	assert(not Rules.ballot(votes, 1, "Fall", Config.ChallengeNames))
	equal(Rules.winner(votes, Config.ChallengeNames, "Timing"), "Rain")
end)
test("ties use the deterministic rotation", function()
	equal(Rules.winner({ [1] = "Timing", [2] = "Rain" }, Config.ChallengeNames, "Rain"), "Rain")
end)
test("rate limit rejects replay and backwards clocks", function()
	assert(Rules.allowed(nil, 1, 1))
	assert(not Rules.allowed(1, 1.1, 1))
	assert(not Rules.allowed(1, 0, 1))
	assert(Rules.allowed(1, 2, 1))
end)
test("lease acquisition is exclusive between servers", function()
	local first = Lease.acquire(nil, "A", 1000)
	assert(first and first.lock.token == "A")
	equal(Lease.acquire(first, "B", 1001), nil)
end)
test("lost acquisition response retries without duplicating offline award", function()
	local first = Lease.acquire({ data = recording(1000) }, "A", 4600)
	local retry = Lease.acquire(first, "A", 4601)
	equal(first.data.money, 6)
	equal(retry.data.money, 6)
	equal(retry.arrival.money, 6)
end)
test("expired lease takeover fences old writes", function()
	local old = Lease.acquire(nil, "A", 1000)
	local nextLease = Lease.acquire(old, "B", 1200)
	assert(nextLease and nextLease.lock.token == "B")
	equal(Lease.save(nextLease, "A", 1, old.data, 1201, false), nil)
end)
test("writer cannot revive an expired lease", function()
	local old = Lease.acquire(nil, "A", 1000)
	equal(Lease.save(old, "A", 1, old.data, 1180, false), nil)
end)
test("out-of-order revisions cannot overwrite new progress", function()
	local old = Lease.acquire(nil, "A", 1000)
	local p = Domain.copy(old.data)
	p.money = 100
	local saved = Lease.save(old, "A", 2, p, 1001, false)
	equal(Lease.save(saved, "A", 1, old.data, 1002, false), nil)
	equal(saved.data.money, 100)
end)
test("release retry after a lost response is idempotent", function()
	local old = Lease.acquire(nil, "A", 1000)
	local saved = Lease.save(old, "A", 1, old.data, 1010, true)
	assert(saved and saved.lock == nil)
	local retried = Lease.save(saved, "A", 1, old.data, 1011, true)
	assert(retried)
	equal(retried.data.lastSeen, 1010)
end)
test("old release retry cannot overwrite next session", function()
	local old = Lease.acquire(nil, "A", 1000)
	local saved = Lease.save(old, "A", 1, old.data, 1010, true)
	local nextLease = Lease.acquire(saved, "B", 1011)
	equal(Lease.save(nextLease, "A", 1, old.data, 1012, true), nil)
end)
test("future or invalid schema fails closed", function()
	local p = Domain.new(0)
	p.version = 999
	equal(Lease.acquire({ data = p }, "A", 1), nil)
	equal(Lease.acquire({}, "A", 1), nil)
end)
test("UpdateAsync callbacks do not mutate their input", function()
	local old = { data = recording(1000) }
	local first = Lease.acquire(old, "A", 4600)
	equal(old.data.money, 0)
	equal(old.data.lastSeen, 1000)
	Lease.save(first, "A", 1, first.data, 4601, true)
	assert(first.lock)
	equal(first.data.lastSeen, 4600)
end)

print(string.format("%d tests passed", passed))
