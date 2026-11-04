--!nonstrict
-- Staged screenshot fixture, not a gameplay acceptance test. Never mapped into the normal place.
assert(game:GetService("RunService"):IsStudio())
local Players = game:GetService("Players")
local Replicated = game:GetService("ReplicatedStorage")
local Server = game:GetService("ServerScriptService"):WaitForChild("Server")
local Store = require(Server:WaitForChild("ProfileStore"))
local City = require(Server.City)
local Streams = require(Server.Streams)
local Games = require(Server.Minigames)
local Domain = require(Replicated.Shared.Domain)(require(Replicated.Shared.Balance))
-- Screenshot privacy: the normal runtime still uses actual display names.
require(Replicated.Shared.Strings).StudioOwner = "CREATOR STUDIO"
assert(Store.testMode, "Visual tour requires memory mode")
local remote = Instance.new("RemoteEvent")
remote.Name, remote.Parent = "VisualTour", Replicated
local event = Replicated:WaitForChild("Remotes"):WaitForChild("Event")
local scenes = {
	"Studio",
	"Street",
	"Plaza",
	"Live",
	"Timing",
	"Rain",
	"Fall",
	"Report",
	"Videos",
	"Gear",
	"Level1",
	"Level2",
	"Level3",
	"PlazaFront",
}
local positions, selected = {}, {}
local oldTick = Games.tick
Games.tick = function(c, now)
	if c.visualHold then
		return nil
	end
	return oldTick(c, now)
end
local function show(player, index)
	local p, room = Store.get(player), City.owners[player]
	if not p or not room then
		return
	end
	local s = Streams.active[player]
	if s and s.challenge then
		Games.cleanup(player, s.challenge)
	end
	Streams.active[player], Streams.cooldown[player] = nil, nil
	local name = scenes[index]
	selected[player] = index
	local level = tonumber(name:match("Level(%d)")) or 0
	p.upgrades = { PC = level, Microphone = level, Camera = level }
	p.money, p.views, p.subscribers = 420, 1280, 96
	City.updateEquipment(player, p)
	City.home(player)
	room.sign.Text = "CREATOR STUDIO"
	local origin = room.center
	local camera = CFrame.lookAt(origin + Vector3.new(10, 9, -10), origin + Vector3.new(0, 4, 7))
	local hide = name == "Street" or name == "Plaza" or name == "PlazaFront"
	if name == "Street" then
		camera = CFrame.lookAt(origin + Vector3.new(29, 19, -35), origin + Vector3.new(0, 4, -3))
	elseif name == "Plaza" then
		camera = CFrame.lookAt(Vector3.new(32, 26, 52), Vector3.new(0, 3, 3))
	elseif name == "PlazaFront" then
		camera = CFrame.lookAt(Vector3.new(-24, 18, -6), Vector3.new(0, 3, 24))
	elseif table.find({ "Live", "Timing", "Rain", "Fall" }, name) then
		local now = workspace:GetServerTimeNow()
		Streams.start(player, now)
		s = Streams.active[player]
		s.endsAt, s.nextAt = now + 3600, now + 3600
		if name ~= "Live" then
			local c = Games.begin(player, name, now)
			c.startsAt, c.endsAt, c.visualHold = now - 1, now + 3600, true
			if name == "Timing" then
				c.center, c.width = 0.55, 0.28
			end
			if name == "Fall" then
				c.danger = { [2] = true, [6] = true, [11] = true, [15] = true }
				for cell in pairs(c.danger) do
					c.tiles[cell].Color = Color3.fromRGB(255, 104, 130)
				end
				local target = c.origin + Vector3.new(7.5, 0, 7.5)
				camera = CFrame.lookAt(target + Vector3.new(0, 30, -23), target)
			end
			s.challenge = c
		end
	end
	positions[player] = camera
	task.delay(0.7, function()
		remote:FireClient(player, { name = name, index = index, camera = camera, hide = hide })
		if name == "Report" then
			event:FireClient(player, "Report", {
				report = {
					money = 186,
					views = 810,
					subscribers = 72,
					donations = 55,
					successes = 7,
					challenges = 9,
				},
				video = { tier = "Viral" },
			})
		elseif name == "Videos" then
			p.videos = {}
			for i, roll in ipairs({ 0.4, 0.9, 0.98, 0.999 }) do
				Domain.publish(
					p,
					{ views = 810, subscribers = 72, money = 186 },
					os.time(),
					"visual-" .. i,
					roll
				)
			end
			task.wait(0.4)
			event:FireClient(player, "Panel", "Videos")
		elseif name == "Gear" then
			event:FireClient(player, "Panel", "Gear")
		end
	end)
	print("VISUAL_SCENE " .. name)
end
remote.OnServerEvent:Connect(function(player, verb)
	if verb == "Next" then
		show(player, (selected[player] or 0) % #scenes + 1)
	elseif verb == "Previous" then
		show(player, ((selected[player] or 2) - 2) % #scenes + 1)
	elseif verb == "Ready" then
		show(player, 1)
	end
end)
Players.PlayerRemoving:Connect(function(player)
	selected[player], positions[player] = nil, nil
end)
task.spawn(function()
	while task.wait(0.2) do
		for player, index in pairs(selected) do
			local s = Streams.active[player]
			if s then
				local now = workspace:GetServerTimeNow()
				s.endsAt, s.nextAt = now + 120, now + 6
				local c = s.challenge
				if c then
					c.endsAt = now + 7
					if c.kind == "Rain" then
						for i, item in ipairs(c.items) do
							item.at, item.done = now + 0.15 + (i % 4) * 0.5, false
						end
					end
				end
			end
		end
	end
end)
