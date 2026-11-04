--!nonstrict
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Config = require(Shared.Balance)
local Strings = require(Shared.Strings)
local Theme = require(Shared.Theme)(Color3.fromRGB)
local B = require(script.Parent.Visuals.Builder)
local Studio = require(script.Parent.Visuals.Studio)
local Equipment = require(script.Parent.Visuals.Equipment)
local Neighborhood = require(script.Parent.Visuals.Neighborhood)
local City = { rooms = {}, owners = {} }

function City.part(parent, name, size, position, color, material)
	return B.part(parent, name, size, position, color, material, true)
end
local function prompt(part, text, callback)
	local p = Instance.new("ProximityPrompt")
	p.ActionText, p.ObjectText, p.HoldDuration = text, Strings.Title, 0
	p.MaxActivationDistance, p.RequiresLineOfSight = 12, false
	p.Parent = part
	p.Triggered:Connect(function(player)
		local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		if root and (root.Position - part.Position).Magnitude <= 16 then
			callback(player)
		end
	end)
end
function City.build(onDoor, onKiosk, onBoard, onStage)
	local world = Instance.new("Folder")
	world.Name, world.Parent = "ViralCity", workspace
	City.world = world
	local lighting = game:GetService("Lighting")
	lighting.ClockTime, lighting.Brightness = 14.2, 2.2
	lighting.Ambient, lighting.OutdoorAmbient = Color3.fromRGB(152, 145, 130), Color3.fromRGB(177, 181, 172)
	lighting.EnvironmentDiffuseScale, lighting.EnvironmentSpecularScale = 0.65, 0.35
	local correction = Instance.new("ColorCorrectionEffect")
	correction.Name, correction.Saturation, correction.Contrast = "CreatorDaylight", 0.04, 0.02
	correction.TintColor, correction.Parent = Color3.fromRGB(255, 249, 238), lighting
	local board, kiosk, stage = Neighborhood.build(world, Strings)
	City.board = board
	prompt(board.Parent.Parent, Strings.Board, onBoard)
	prompt(kiosk, Strings.Kiosk, onKiosk)
	prompt(stage, Strings.StageAction, onStage)
	local spawn = Instance.new("SpawnLocation")
	spawn.Name, spawn.Size, spawn.Position = "PlazaSpawn", Vector3.new(8, 1, 8), Vector3.new(0, 0, 12)
	spawn.Anchored, spawn.Neutral, spawn.Duration, spawn.Transparency = true, true, 0, 1
	spawn.CanCollide, spawn.CanTouch, spawn.Parent = false, false, world
	for index = 1, Config.MaxPlayers do
		local column, row = (index - 1) % 4, math.floor((index - 1) / 4)
		local center = Vector3.new(({ -73, -40, 40, 73 })[column + 1], 0, -65 + row * 40)
		local room = Studio.build(world, index, center)
		City.rooms[index] = room
		room.sign.Text = Strings.EmptyRoom
		prompt(room.door, Strings.Enter, function(player)
			onDoor(player, index)
		end)
		Equipment.build(room, { upgrades = { PC = 0, Microphone = 0, Camera = 0 } })
		room.sign:GetPropertyChangedSignal("Text"):Connect(function()
			local live = string.find(room.sign.Text, Strings.LiveBadge, 1, true) ~= nil
			room.trim.Color = if live then Theme.coral elseif room.owner then Theme.mint else Theme.sage
			room.trim.Material = if live then Enum.Material.Neon else Enum.Material.SmoothPlastic
		end)
	end
end
function City.claim(player)
	for index, room in ipairs(City.rooms) do
		if not room.owner then
			room.owner, City.owners[player] = player, room
			room.index = index
			room.sign.Text = string.format(Strings.StudioOwner, player.DisplayName)
			return room
		end
	end
	return nil
end
function City.release(player)
	local room = City.owners[player]
	if room then
		room.owner = nil
		room.sign.Text = Strings.EmptyRoom
		room.trophy.Text = ""
		Equipment.build(room, { upgrades = { PC = 0, Microphone = 0, Camera = 0 } })
	end
	City.owners[player] = nil
end
function City.teleport(player, position)
	if player.Character then
		local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid.Sit = false
		end
		player.Character:PivotTo(CFrame.lookAt(position, position + Vector3.new(0, 0, 1)))
		if City.onArrival then
			City.onArrival(player, position)
		end
	end
end
function City.home(player)
	local room = City.owners[player]
	if room then
		City.teleport(player, room.center + Vector3.new(0, 4, -7))
	end
end
function City.inside(player, owner)
	local room = City.owners[owner]
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if not room or not root then
		return false
	end
	local delta = root.Position - room.center
	return math.abs(delta.X) <= 14 and math.abs(delta.Z) <= 17 and delta.Y > -3 and delta.Y < 18
end
function City.updateEquipment(player, profile)
	local room = City.owners[player]
	if not room then
		return
	end
	Equipment.build(room, profile)
	room.trophy.Text = if #profile.videos > 0
		then string.format(Strings.Trophy, Strings[profile.cosmetics.trophy])
		else ""
	room.trophy.TextColor3 = Theme.rarity[profile.cosmetics.trophy] or Theme.ink
end
return City
