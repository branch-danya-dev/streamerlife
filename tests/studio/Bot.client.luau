--!nonstrict
assert(game:GetService("RunService"):IsStudio(), "QA bot must never run outside Studio")
local Players = game:GetService("Players")
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Rules = require(Shared.Rules)
local remotes = game:GetService("ReplicatedStorage"):WaitForChild("Remotes")
local action = remotes:WaitForChild("Action")
local state
remotes.Event.OnClientEvent:Connect(function(kind, data)
	if kind == "State" then
		state = data
	end
end)
local function send(verb, data)
	action:FireServer(verb, data or {})
end
local phase, lastVisit, lastReact, lastVote, lastInput, bought = nil, 0, 0, nil, 0, false
local stopIds = {}
local begun = false
while workspace:GetAttribute("QAPhase") ~= "Done" do
	task.wait(0.05)
	if not state then
		send("Ready")
		continue
	end
	local nextPhase = workspace:GetAttribute("QAPhase")
	local hostId = workspace:GetAttribute("QAHost")
	local isHost = hostId == Players.LocalPlayer.UserId
	local now = workspace:GetServerTimeNow()
	if nextPhase == "Security" and phase ~= nextPhase then
		send("Grant", { money = 1e30, subscribers = 1e30 })
		send("Buy", { category = "PC", price = -9999, userId = hostId })
		send("Input", { id = "forged", verb = "Reward", value = 1e30 })
	elseif nextPhase == "Stream" then
		local s = state.session
		if isHost then
			if not begun then
				send("Start")
				begun = true
			end
			if s and now - s.startsAt > 90 then
				send("Finish")
			end
			local c = s and s.challenge
			if c and now >= c.startsAt and now - lastInput > 0.22 then
				local verb, value
				if
					c.kind == "Timing"
					and not stopIds[c.id]
					and Rules.timing(now - c.startsAt, c.center, c.width) > 0.8
				then
					verb = "Stop"
					stopIds[c.id] = true
				elseif c.kind == "Rain" then
					for _, item in ipairs(c.items) do
						if not item.done and item.at > now and item.at - now < 0.8 then
							verb = "Lane"
							value = if item.good then item.lane else item.lane % 4 + 1
							break
						end
					end
				elseif c.kind == "Fall" and c.danger[c.cell] then
					for _, direction in ipairs({ "Left", "Right", "Up", "Down" }) do
						local cell = Rules.move(c.cell, direction, 4)
						if cell ~= c.cell and not c.danger[cell] and not c.collapsed[cell] then
							verb, value = "Move", direction
							break
						end
					end
				end
				if verb then
					send("Input", { id = c.id, verb = verb, value = value })
					lastInput = now
				end
			end
		else
			if now - lastVisit > 5 then
				send("Visit", { userId = hostId })
				lastVisit = now
			end
			if state.watching then
				if now - lastReact > 0.5 then
					send("React", { index = 1 })
					lastReact = now
				end
				if s and not s.challenge and s.nextAt ~= lastVote then
					lastVote = s.nextAt
					send("Vote", { choice = s.choices[#s.choices] })
				end
			end
		end
	elseif nextPhase == "Buy" and isHost and not bought then
		bought = true
		for _, category in ipairs({ "PC", "Microphone", "Camera" }) do
			send("Buy", { category = category, expectedLevel = 0 })
			task.wait(0.4)
		end
	end
	phase = nextPhase
end
print("QA client completed", Players.LocalPlayer.UserId)
