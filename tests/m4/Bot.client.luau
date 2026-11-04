--!nonstrict
local Run = game:GetService("RunService")
assert(Run:IsStudio(), "M4 fixtures are Studio-only")
local Players = game:GetService("Players")
local Stats = game:GetService("Stats")
local Http = game:GetService("HttpService")
local fixtures = game:GetService("ReplicatedStorage"):WaitForChild("M4")
local Metrics = require(fixtures.Metrics)
local drive = require(fixtures.Driver)
local remotes = game:GetService("ReplicatedStorage"):WaitForChild("Remotes")
local state, phase, metrics, last = {}, nil, {}, {}
local received, sent, frames, frameSeconds, worstFrame = 0, 0, 0, 0, 0
local started = os.clock()
local firstStart, firstReward
local reports = 0
local function send(verb, data)
	sent += 1
	remotes.Action:FireServer(verb, data or {})
end
remotes.Event.OnClientEvent:Connect(function(kind, payload)
	received += 1
	if kind == "State" then
		state = payload
	end
	if kind == "Reward" and not firstReward then
		firstReward = os.clock() - started
	end
	if kind == "Report" then
		reports += 1
	end
end)
local frameConnection = Run.RenderStepped:Connect(function(dt)
	frames += 1
	frameSeconds += dt
	worstFrame = math.max(worstFrame, dt)
end)
local sampling = true
task.spawn(function()
	while sampling do
		task.wait(1)
		if frameSeconds > 0 then
			Metrics.add(metrics, "fps_1s", frames / frameSeconds)
		end
		Metrics.add(metrics, "worst_frame_ms", worstFrame * 1000)
		Metrics.add(metrics, "memory_mb", Stats:GetTotalMemoryUsageMb())
		Metrics.add(metrics, "receive_kbps", Stats.DataReceiveKbps)
		Metrics.add(metrics, "send_kbps", Stats.DataSendKbps)
		Metrics.add(metrics, "ping_rtt_ms", Players.LocalPlayer:GetNetworkPing() * 1000)
		frames, frameSeconds, worstFrame = 0, 0, 0
	end
end)
local lastAction, lastVisit, lastReact, lastVote = 0, 0, 0, nil
while true do
	task.wait(0.016)
	local nextPhase = workspace:GetAttribute("M4Phase")
	if phase ~= nextPhase then
		if phase then
			Metrics.print("M4_CLIENT", {
				phase = phase,
				metrics = Metrics.report(metrics),
				received = received,
				sent = sent,
				reports = reports,
				firstStartSeconds = firstStart,
				firstRewardSeconds = firstReward,
			})
		end
		phase = nextPhase
		metrics = {}
		received, sent = 0, 0
	end
	if phase == "Done" then
		break
	end
	local now = workspace:GetServerTimeNow()
	if not state.profile then
		if now - lastAction > 1 then
			send("Ready")
			lastAction = now
		end
		continue
	end
	local hostId = workspace:GetAttribute("M4Host")
	if phase == "Social" and Players.LocalPlayer.UserId ~= hostId then
		if now - lastVisit > 3 then
			send("Finish")
			task.wait(0.35)
			send("Visit", { userId = hostId })
			lastVisit = now
		end
		if state.watching then
			if now - lastReact > 0.5 then
				send("React", { index = 1 })
				lastReact = now
			end
			local s = state.session
			if s and not s.challenge and lastVote ~= s.nextAt then
				send("Vote", { choice = s.choices[#s.choices] })
				lastVote = s.nextAt
			end
		end
	elseif phase == "Real" or phase == "Mixed" or phase == "Social" then
		local s = state.session
		if not s and now - lastAction > 1 then
			send("Start")
			lastAction = now
			if not firstStart then
				firstStart = os.clock() - started
			end
		elseif s then
			local data = drive(s.challenge, now, last)
			if data then
				send("Input", data)
			end
		end
	end
end
sampling = false
frameConnection:Disconnect()
print("M4 CLIENT DONE")
