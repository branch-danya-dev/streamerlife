--!nonstrict
-- Passive observer: never sends inputs, changes a profile, or starts a stream.
assert(game:GetService("RunService"):IsStudio())
local Http = game:GetService("HttpService")
local event = game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("Event")
local began, sessionId, gear = nil, nil, nil
local streams, rewards = 0, 0
event.OnClientEvent:Connect(function(kind, payload)
	if kind == "Arrival" then
		task.delay(1, function()
			local camera = workspace.CurrentCamera
			local character = game.Players.LocalPlayer.Character
			local root = character and character:FindFirstChild("HumanoidRootPart")
			print(
				"MANUAL CAMERA",
				tostring(camera.CFrame.Position - payload),
				tostring(camera.Focus.Position - payload),
				root and tostring(root.Position - payload)
			)
		end)
	end
	if kind == "State" then
		if not began then
			began = os.clock()
			print("MANUAL READY")
		end
		local s = payload.session
		if s and s.id ~= sessionId and not payload.watching then
			sessionId = s.id
			streams += 1
			print("MANUAL START " .. Http:JSONEncode({ stream = streams, seconds = os.clock() - began }))
		end
		local p = payload.profile
		local nextGear = tostring(p.upgrades.PC) .. ":" .. p.upgrades.Microphone .. ":" .. p.upgrades.Camera
		if gear and gear ~= nextGear then
			print(
				"MANUAL UPGRADE "
					.. Http:JSONEncode({ seconds = os.clock() - began, money = p.money, levels = p.upgrades })
			)
		end
		gear = nextGear
	elseif kind == "Reward" then
		rewards += 1
		print("MANUAL REWARD " .. Http:JSONEncode({
			seconds = os.clock() - (began or os.clock()),
			number = rewards,
			reward = payload.reward,
			success = payload.success,
		}))
	elseif kind == "Report" then
		print("MANUAL REPORT " .. Http:JSONEncode({
			seconds = os.clock() - (began or os.clock()),
			stream = streams,
			report = payload.report,
			recording = payload.video ~= nil,
		}))
	end
end)
