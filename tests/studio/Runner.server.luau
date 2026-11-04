--!nonstrict
-- Test-only fixture, never included by default.project.json. Run with two local clients.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
assert(RunService:IsStudio(), "QA fixture must never run in a published server")
local server = game:GetService("ServerScriptService"):WaitForChild("Server")
local Store = require(server:WaitForChild("ProfileStore"))
local City = require(server.City)
local Streams = require(server.Streams)
local Social = require(server.Social)
assert(Store.testMode, "QA requires isolated in-memory data")
local deadline = os.clock() + 60
repeat
	task.wait(0.2)
until #Players:GetPlayers() >= 2 or os.clock() > deadline
assert(#Players:GetPlayers() >= 2, "QA requires two clients (Test > Server & Clients)")
local people = Players:GetPlayers()
table.sort(people, function(a, b)
	return a.UserId > b.UserId
end)
local host, guest = people[1], people[2]
repeat
	task.wait(0.2)
until Store.get(host) and Store.get(guest) and City.inside(host, host) and City.inside(guest, guest)
	or os.clock() > deadline
assert(
	City.inside(host, host) and City.inside(guest, guest),
	"both clients must spawn inside their own studios"
)
workspace:SetAttribute("QAHost", host.UserId)
workspace:SetAttribute("QAPhase", "Security")
task.wait(2)
assert(Store.get(host).money == 0 and Store.get(guest).money == 0, "forged rewards changed profile")
assert(Store.get(host).upgrades.PC == 0, "unfunded purchase changed profile")
print("QA PASS spawn and forged remote rejection")
workspace:SetAttribute("QAPhase", "Stream")
local seen = {}
local visitorSeen, voteSeen, reactionSeen = false, false, false
deadline = os.clock() + 180
repeat
	task.wait(0.1)
	local s = Streams.active[host]
	if s then
		for kind in pairs(s.completedKinds) do
			seen[kind] = true
		end
		if Social.owner(guest) == host then
			visitorSeen = true
		end
		if s.votes[guest.UserId] then
			voteSeen = true
		end
		if Social.lastReaction[guest] then
			reactionSeen = true
		end
	end
until #Store.get(host).videos > 0 or os.clock() > deadline
assert(seen.Timing and seen.Rain and seen.Fall, "not all games settled")
assert(visitorSeen and voteSeen and reactionSeen, "social flow did not complete")
assert(
	Store.get(host).socialEarned == 1 and Store.get(guest).socialEarned == 1,
	"repeated visits/reactions duplicated the session bonus"
)
assert(
	#Store.get(host).videos == 1 and Store.get(host).stats.streams == 1,
	"recording was missing or duplicated"
)
assert(Store.get(host).money > 60 and Store.get(host).subscribers > 0, "solo progress missing")
print("QA PASS three games, recording, visit, vote, reactions and capped social rewards")
Store.get(host).money = 500 -- Explicit test fixture for all three equipment paths.
workspace:SetAttribute("QAPhase", "Buy")
task.wait(3)
for _, key in ipairs({ "PC", "Microphone", "Camera" }) do
	assert(Store.get(host).upgrades[key] == 1, "upgrade missing: " .. key)
end
assert(Store.get(host).money == 260, "upgrade transaction totals are wrong")
local oldToken = Store.records[host].token
assert(Store.save(host, true), "release failed")
local loaded = Store.load(host)
assert(
	loaded and loaded.money == 260 and loaded.upgrades.Camera == 1 and #loaded.videos == 1,
	"profile round-trip lost progress"
)
assert(Store.records[host].token ~= oldToken, "connection token was reused")
print("QA PASS three visible upgrade paths and profile save/reacquire round-trip")
workspace:SetAttribute("QAPhase", "Done")
print("QA ALL PASSED (two real Studio clients, memory backend)")
