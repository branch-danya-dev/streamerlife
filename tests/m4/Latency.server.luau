--!nonstrict
-- Studio-only repeated Timing rounds. Network conditions are applied in Studio's Network Simulator.
local Run = game:GetService("RunService")
assert(Run:IsStudio())
local Players = game:GetService("Players")
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Rules = require(Shared.Rules)
local server = game:GetService("ServerScriptService"):WaitForChild("Server")
local Store = require(server:WaitForChild("ProfileStore"))
local Streams = require(server.Streams)
local Games = require(server.Minigames)
local Metrics = require(game.ReplicatedStorage.M4.Metrics)
local Http = game:GetService("HttpService")
assert(Store.testMode)
local samples, metrics = 0, {}
local oldInput = Games.input
Games.input = function(c, verb, value, now)
	local previous = c.score
	oldInput(c, verb, value, now)
	if c.kind == "Timing" and verb == "Stop" and previous == nil and c.score ~= nil then
		samples += 1
		Metrics.add(metrics, "score", c.score)
		Metrics.add(metrics, "without_compensation", Rules.timing(now - c.startsAt, c.center, c.width))
		Metrics.add(metrics, "compensation_ms", c.inputDelay * 1000)
		print("LATENCY_SAMPLE " .. Http:JSONEncode({
			sample = samples,
			score = c.score,
			oldScore = Rules.timing(now - c.startsAt, c.center, c.width),
			delay = c.inputDelay,
		}))
	end
end
workspace:SetAttribute("M4Phase", "Real")
local began = os.clock()
while os.clock() - began < 180 and samples < 20 do
	task.wait(0.05)
	for _, p in ipairs(Players:GetPlayers()) do
		local s = Streams.active[p]
		if s and not s.challenge then
			-- Force Timing only and shorten inter-round wait for this diagnostic.
			s.choices = { "Timing" }
			s.nextKind = "Timing"
			s.nextAt = workspace:GetServerTimeNow()
		end
	end
end
workspace:SetAttribute("M4Phase", "Done")
for p in pairs(Streams.active) do
	Streams.finish(p, workspace:GetServerTimeNow(), true)
end
assert(samples == 20, "latency test did not receive 20 Stop intentions")
print("LATENCY_RESULT " .. Http:JSONEncode({
	samples = samples,
	metrics = Metrics.report(metrics),
	seconds = os.clock() - began,
}))
