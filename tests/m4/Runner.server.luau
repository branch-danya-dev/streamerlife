--!nonstrict
local Players = game:GetService("Players")
local Run = game:GetService("RunService")
local Stats = game:GetService("Stats")
local Http = game:GetService("HttpService")
assert(Run:IsStudio(), "M4 fixture must never run in a published server")
local server = game:GetService("ServerScriptService"):WaitForChild("Server")
local Store = require(server:WaitForChild("ProfileStore"))
local City = require(server.City)
local Streams = require(server.Streams)
local Games = require(server.Minigames)
local Social = require(server.Social)
local fixtures = game:GetService("ReplicatedStorage"):WaitForChild("M4")
local Metrics = require(fixtures.Metrics)
local drive = require(fixtures.Driver)
assert(Store.testMode, "M4 requires isolated memory storage")
local expected = workspace:GetAttribute("M4Clients") or 2
local deadline = os.clock() + 120
repeat
	task.wait(0.2)
until #Players:GetPlayers() >= expected or os.clock() > deadline
assert(#Players:GetPlayers() == expected, "M4 expected client count not connected")
local people = Players:GetPlayers()
table.sort(people, function(a, b)
	return a.UserId > b.UserId
end)
repeat
	task.wait(0.2)
	local ready = true
	for _, p in ipairs(people) do
		if not Store.get(p) or not City.inside(p, p) then
			ready = false
		end
	end
	if ready then
		break
	end
until os.clock() > deadline
for _, p in ipairs(people) do
	assert(Store.get(p) and City.inside(p, p), "M4 spawn failed")
end
local synthetic, lasts = {}, {}
local metrics, phase = {}, "Warmup"
local inbound = 0
local tickTotal, tickCount = 0, 0
local oldTick = Streams.tick
Streams.tick = function(...)
	local before = os.clock()
	local result = oldTick(...)
	local ms = (os.clock() - before) * 1000
	Metrics.add(metrics, "stream_tick_ms", ms)
	tickTotal += ms
	tickCount += 1
	return result
end
local oldGameTick = Games.tick
Games.tick = function(...)
	local before = os.clock()
	local result = oldGameTick(...)
	Metrics.add(metrics, "minigame_tick_ms", (os.clock() - before) * 1000)
	return result
end
local oldInput = Games.input
Games.input = function(c, verb, value, now)
	oldInput(c, verb, value, now)
	if c.kind == "Timing" and c.score ~= nil then
		Metrics.add(metrics, "timing_score", c.score)
		Metrics.add(metrics, "timing_compensation_ms", (c.inputDelay or 0) * 1000)
	end
end
local inboundConnection = game:GetService("ReplicatedStorage").Remotes.Action.OnServerEvent:Connect(function()
	inbound += 1
end)
local heartbeat = Run.Heartbeat:Connect(function(dt)
	Metrics.add(metrics, "heartbeat_interval_ms", dt * 1000)
	if tickCount > 0 then
		Metrics.add(metrics, "stream_tick_batch_ms", tickTotal)
	end
	tickTotal, tickCount = 0, 0
end)
local sampling = true
local function arenaCount()
	local arenas, tiles = 0, 0
	for _, room in ipairs(City.rooms) do
		local a = room.model:FindFirstChild("ChallengeArena")
		if a then
			arenas += 1
			tiles += #a:GetChildren()
		end
	end
	return arenas, tiles
end
task.spawn(function()
	while sampling do
		task.wait(1)
		Metrics.add(metrics, "memory_mb", Stats:GetTotalMemoryUsageMb())
		Metrics.add(metrics, "send_kbps", Stats.DataSendKbps)
		Metrics.add(metrics, "receive_kbps", Stats.DataReceiveKbps)
		Metrics.add(metrics, "heartbeat_cpu_ms", Stats.HeartbeatTime * 1000)
		Metrics.add(metrics, "instances", Stats.InstanceCount)
		local arenas, tiles = arenaCount()
		Metrics.add(metrics, "arenas", arenas)
		Metrics.add(metrics, "tiles", tiles)
	end
end)
local function runPhase(name, seconds)
	phase = name
	metrics = {}
	inbound = 0
	local requests = Store.requests
	workspace:SetAttribute("M4Phase", name)
	local begin = os.clock()
	local sampleAt = 0
	while os.clock() - begin < seconds do
		task.wait(0.05)
		local now = workspace:GetServerTimeNow()
		for _, p in ipairs(synthetic) do
			if name == "Mixed" then
				if not Streams.active[p] then
					City.home(p)
					Streams.start(p, now)
				end
				local s = Streams.public(p)
				local data = drive(s and s.challenge, now, lasts[p])
				if data then
					Streams.input(p, data, now)
				end
			end
		end
		if os.clock() - sampleAt > 30 then
			sampleAt = os.clock()
			print("M4_PROGRESS " .. name .. " " .. math.floor(os.clock() - begin) .. "s")
		end
	end
	Metrics.print("M4_SERVER", {
		phase = name,
		seconds = os.clock() - begin,
		realClients = #Players:GetPlayers(),
		syntheticProfiles = #synthetic,
		metrics = Metrics.report(metrics),
		incomingActions = inbound,
		storageRequests = Store.requests - requests,
		storageFailures = Store.failures,
		backend = "memory",
	})
end
workspace:SetAttribute("M4Host", people[1].UserId)
runPhase("Warmup", 15)
runPhase("Real", 160)
for i = #people + 1, 16 do
	local model = Instance.new("Model")
	model.Name = "SyntheticM4" .. i
	local root = Instance.new("Part")
	root.Name = "HumanoidRootPart"
	root.Size = Vector3.new(2, 2, 1)
	root.Anchored = true
	root.Parent = model
	local humanoid = Instance.new("Humanoid")
	humanoid.Parent = model
	model.PrimaryPart = root
	model.Parent = workspace
	local p = { UserId = -(1000 + i), DisplayName = "Synthetic" .. i, Parent = true, Character = model }
	function p:GetNetworkPing()
		return 0
	end
	function p:Kick()
		error("Synthetic profile unexpectedly lost lease")
	end
	assert(Store.load(p))
	assert(City.claim(p))
	City.home(p)
	table.insert(synthetic, p)
	lasts[p] = {}
end
runPhase("Mixed", 170)
for _, p in ipairs(synthetic) do
	Streams.finish(p, workspace:GetServerTimeNow(), false)
end
runPhase("Social", 35)
local host = people[1]
for i = 2, #people do
	assert(Social.owner(people[i]) == host, "visitor not watching host")
	assert(Social.lastReaction[people[i]], "reaction not delivered")
end
assert(Store.get(host).socialEarned > 0, "social rewards absent")
-- Real engine cleanup checks: mid-Fall finish, death, then synthetic departure.
for _, p in ipairs(people) do
	Streams.finish(p, workspace:GetServerTimeNow(), true)
	local c = Games.begin(p, "Fall", workspace:GetServerTimeNow())
	Games.cleanup(p, c)
	assert(
		c.root.Anchored == c.wasAnchored and c.humanoid.AutoRotate == c.wasAutoRotate,
		"real avatar cleanup failed"
	)
	City.home(p)
end
for _, p in ipairs(synthetic) do
	City.home(p)
	local c = Games.begin(p, "Fall", workspace:GetServerTimeNow() - 1)
	c.humanoid.Health = 0
	assert(Games.tick(c, workspace:GetServerTimeNow()) == 0, "dead avatar did not end Fall")
	Games.cleanup(p, c)
	assert(
		c.root.Anchored == c.wasAnchored and c.humanoid.AutoRotate == c.wasAutoRotate,
		"avatar state not restored"
	)
	assert(Store.save(p, true))
	Social.remove(p)
	City.release(p)
	p.Character:Destroy()
	Streams.cooldown[p] = nil
end
local arenas, tiles = arenaCount()
assert(arenas == 0 and tiles == 0, "arena leak after cleanup")
local profiles = 0
for _ in pairs(Store.records) do
	profiles += 1
end
assert(profiles == #people, "synthetic profiles leaked")
for _, p in ipairs(people) do
	assert(Store.get(p).stats.streams >= 2, "consecutive streams did not publish")
	assert(City.inside(p, p), "player did not return home")
end
print("M4_CLEANUP " .. Http:JSONEncode({
	arenas = arenas,
	tiles = tiles,
	profiles = profiles,
	realClients = #people,
	deathCleanup = true,
}))
runPhase("Cooldown", 10)
sampling = false
heartbeat:Disconnect()
inboundConnection:Disconnect()
workspace:SetAttribute("M4Phase", "Done")
print("M4 ALL PASSED (real clients plus explicitly synthetic server profiles; memory backend)")
