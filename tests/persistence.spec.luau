--!nonstrict
-- Deterministic, yielding UpdateAsync adapter. Only this test supplies faults.
local Config = require("../src/shared/Balance")
local Domain = require("../src/shared/Domain")(Config)
local Lease = require("../src/shared/Lease")(Config, Domain)
local Persistence = require("../src/server/Persistence")
local passed = 0
local function test(name, body)
	body()
	passed += 1
	print("PASS " .. name)
end
local function equal(a, b)
	assert(a == b, tostring(a) .. " ~= " .. tostring(b))
end
local function fixture()
	local f = { time = 1000, tasks = {}, bank = {}, faults = {}, calls = 0, warnings = 0, serial = 0 }
	function f.spawn(fn)
		table.insert(f.tasks, { co = coroutine.create(fn), at = f.time })
	end
	function f.wait(seconds)
		return coroutine.yield(seconds)
	end
	function f.run(untilTime)
		while #f.tasks > 0 do
			table.sort(f.tasks, function(a, b)
				return a.at < b.at
			end)
			if untilTime and f.tasks[1].at > untilTime then
				f.time = untilTime
				return
			end
			local job = table.remove(f.tasks, 1)
			f.time = job.at
			local ok, delay = coroutine.resume(job.co)
			assert(ok, tostring(delay))
			if coroutine.status(job.co) ~= "dead" then
				job.at = f.time + delay
				table.insert(f.tasks, job)
			end
		end
	end
	function f.store()
		return Persistence(Config, Domain, Lease, {
			now = function()
				return math.floor(f.time)
			end,
			clock = function()
				return f.time
			end,
			wait = f.wait,
			spawn = f.spawn,
			token = function()
				f.serial += 1
				return "token" .. f.serial
			end,
			present = function(p)
				return p.Parent ~= nil
			end,
			failed = function()
				f.warnings += 1
			end,
			kick = function(p)
				p.kicked = true
			end,
			update = function(key, transform)
				f.calls += 1
				local fault = table.remove(f.faults, 1) or {}
				if fault.delay then
					f.wait(fault.delay)
				end
				if fault.before then
					error("injected throttle/read failure")
				end
				if fault.repeatCallback then
					transform(Domain.copy(f.bank[key]))
				end
				local result = transform(Domain.copy(f.bank[key]))
				if result ~= nil then
					f.bank[key] = Domain.copy(result)
				end
				if fault.after then
					error("injected lost response after commit")
				end
				return Domain.copy(result)
			end,
		})
	end
	f.player = { UserId = 1, Parent = true }
	function f.seed()
		local p = Domain.new(0)
		Domain.publish(p, { money = 180, views = 800 }, 0, "saved-video", 0)
		p.money = 123
		f.bank.player_1 = { data = p }
	end
	function f.call(fn)
		local result
		f.spawn(function()
			result = fn()
		end)
		f.run()
		return result
	end
	return f
end

test("failed reads never create or overwrite an existing profile", function()
	local f = fixture()
	f.seed()
	local s = f.store()
	for _ = 1, 4 do
		table.insert(f.faults, { before = true })
	end
	equal(
		f.call(function()
			return s.load(f.player)
		end),
		nil
	)
	equal(f.calls, 4)
	equal(f.warnings, 4)
	equal(f.bank.player_1.data.money, 123)
	equal(f.bank.player_1.lock, nil)
	equal(s.records[f.player], nil)
	equal(next(s.loading), nil)
end)
test("load recovers after throttling; callback retries pay offline once", function()
	local f = fixture()
	f.seed()
	f.time = 3600
	f.faults = { { before = true }, { before = true }, { repeatCallback = true } }
	local s = f.store()
	local p = f.call(function()
		return s.load(f.player)
	end)
	equal(p.money, 129)
	equal(f.calls, 3)
	equal(f.bank.player_1.data.money, 129)
end)
test("lost acquisition response reuses token and arrival award", function()
	local f = fixture()
	f.seed()
	f.time = 3600
	f.faults = { { after = true } }
	local s = f.store()
	equal(
		f.call(function()
			return s.load(f.player)
		end).money,
		129
	)
	equal(f.serial, 1)
	equal(f.calls, 2)
end)
test("two servers racing delayed acquisition grant only one lease", function()
	local f = fixture()
	f.seed()
	f.faults = { { delay = 2 } }
	local a, b = f.store(), f.store()
	local x, y
	f.spawn(function()
		x = a.load(f.player)
	end)
	f.spawn(function()
		y = b.load(f.player)
	end)
	f.run()
	assert((x ~= nil) ~= (y ~= nil))
	equal(f.serial, 2)
end)
test("duplicate load on the same server never creates a second token", function()
	local f = fixture()
	local s = f.store()
	f.faults = { { delay = 2 } }
	f.spawn(function()
		assert(s.load(f.player))
	end)
	f.spawn(function()
		equal(s.load(f.player), nil)
	end)
	f.run()
	equal(f.serial, 1)
	equal(f.calls, 1)
end)
test("autosave failure preserves live progress and a later save recovers", function()
	local f = fixture()
	local s = f.store()
	f.call(function()
		return s.load(f.player)
	end).money = 200
	for _ = 1, 4 do
		table.insert(f.faults, { before = true })
	end
	equal(
		f.call(function()
			return s.save(f.player, false)
		end),
		false
	)
	equal(s.get(f.player).money, 200)
	equal(f.bank.player_1.data.money, 0)
	assert(f.call(function()
		return s.save(f.player, false)
	end))
	equal(f.bank.player_1.data.money, 200)
end)
test("serialized exit waits for autosave then captures latest progress", function()
	local f = fixture()
	local s = f.store()
	local p = f.call(function()
		return s.load(f.player)
	end)
	p.money = 20
	f.faults = { { delay = 3 }, { after = true } }
	f.spawn(function()
		assert(s.save(f.player, false))
	end)
	f.spawn(function()
		f.wait(1)
		p.money = 70
		assert(s.save(f.player, true))
	end)
	f.run()
	equal(f.bank.player_1.data.money, 70)
	equal(f.bank.player_1.lock, nil)
	equal(s.records[f.player], nil)
end)
test("failed release cannot unlock or silently save an empty profile", function()
	local f = fixture()
	local s = f.store()
	f.call(function()
		return s.load(f.player)
	end).money = 90
	for _ = 1, 4 do
		table.insert(f.faults, { before = true })
	end
	equal(
		f.call(function()
			return s.save(f.player, true)
		end),
		false
	)
	local b = f.store()
	equal(
		f.call(function()
			return b.load(f.player)
		end),
		nil
	)
	f.time = 1181
	-- Expected crash tradeoff: unsaved 90 is lost, the last durable 0 survives.
	equal(
		f.call(function()
			return b.load(f.player)
		end).money,
		0
	)
end)
test("stale writer after expiry cannot overwrite a new server", function()
	local f = fixture()
	local a, b = f.store(), f.store()
	local old = f.call(function()
		return a.load(f.player)
	end)
	old.money = 999
	f.time = 1181
	equal(a.get(f.player), nil)
	f.call(function()
		return b.load(f.player)
	end).money = 42
	assert(f.call(function()
		return b.save(f.player, false)
	end))
	equal(
		f.call(function()
			return a.save(f.player, false)
		end),
		false
	)
	equal(f.bank.player_1.data.money, 42)
	assert(f.player.kicked)
end)
test("shutdown waits for in-flight acquisition and releases its lease", function()
	local f = fixture()
	local s = f.store()
	f.faults = { { delay = 5 } }
	local closedAt
	f.spawn(function()
		equal(s.load(f.player), nil)
	end)
	f.spawn(function()
		f.wait(0.1)
		assert(s.close())
		closedAt = f.time
	end)
	f.run()
	assert(closedAt >= 1005 and closedAt < 1006)
	equal(f.bank.player_1.lock, nil)
	equal(next(s.records), nil)
end)
test("shutdown has a bounded wait when the service hangs", function()
	local f = fixture()
	local s = f.store()
	f.faults = { { delay = 40 } }
	local result, closedAt
	f.spawn(function()
		s.load(f.player)
	end)
	f.spawn(function()
		f.wait(0.1)
		result = s.close()
		closedAt = f.time
	end)
	f.run(1030)
	equal(result, false)
	assert(closedAt >= 1025 and closedAt < 1026)
	equal(f.bank.player_1, nil) -- Still no response; cannot promise a final save.
	f.run()
	equal(f.bank.player_1.lock, nil)
end)
test("disconnect during acquisition releases without exposing a profile", function()
	local f = fixture()
	local s = f.store()
	f.faults = { { delay = 2 } }
	f.spawn(function()
		equal(s.load(f.player), nil)
	end)
	f.spawn(function()
		f.wait(1)
		f.player.Parent = nil
	end)
	f.run()
	equal(f.bank.player_1.lock, nil)
	equal(next(s.loading), nil)
end)
test("repeated reconnect at the same time cannot repeat offline payout", function()
	local f = fixture()
	f.seed()
	f.time = 3600
	for _ = 1, 10 do
		local s = f.store()
		equal(
			f.call(function()
				return s.load(f.player)
			end).money,
			129
		)
		assert(f.call(function()
			return s.save(f.player, true)
		end))
	end
	equal(f.bank.player_1.data.videos[1].paidSeconds, 3600)
end)
print(string.format("%d persistence fault/race tests passed", passed))
