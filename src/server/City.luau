--!nonstrict
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Config = require(Shared.Balance)
local Strings = require(Shared.Strings)
local City = { rooms = {}, owners = {} }
local palette = {
	dark = Color3.fromRGB(25, 28, 46),
	wall = Color3.fromRGB(53, 60, 80),
	mint = Color3.fromRGB(96, 255, 190),
	pink = Color3.fromRGB(255, 104, 171),
	gold = Color3.fromRGB(255, 209, 92),
}

function City.part(parent, name, size, position, color, material)
	local part = Instance.new("Part")
	part.Name, part.Size, part.Position = name, size, position
	part.Anchored, part.Color = true, color or palette.wall
	part.Material = material or Enum.Material.SmoothPlastic
	part.TopSurface, part.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
	part.Parent = parent
	return part
end

local function sign(parent, title, size, position, color)
	local panel = City.part(parent, "Sign", size, position, palette.dark)
	local surface = Instance.new("SurfaceGui")
	surface.Face, surface.SizingMode, surface.PixelsPerStud =
		Enum.NormalId.Front, Enum.SurfaceGuiSizingMode.PixelsPerStud, 35
	surface.Parent = panel
	local text = Instance.new("TextLabel")
	text.Size, text.BackgroundTransparency = UDim2.fromScale(1, 1), 1
	text.Font, text.TextScaled, text.TextWrapped = Enum.Font.GothamBold, true, true
	text.TextColor3, text.Text = color or palette.mint, title
	text.Parent = surface
	return text
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
	City.part(world, "Ground", Vector3.new(210, 2, 210), Vector3.new(0, -2, 0), Color3.fromRGB(62, 84, 82))
	City.part(
		world,
		"Promenade",
		Vector3.new(44, 0.3, 200),
		Vector3.new(0, -0.8, 0),
		Color3.fromRGB(166, 160, 160)
	)
	City.part(
		world,
		"Crosswalk",
		Vector3.new(200, 0.3, 15),
		Vector3.new(0, -0.6, 0),
		Color3.fromRGB(166, 160, 160)
	)
	City.part(world, "Plaza", Vector3.new(42, 1, 45), Vector3.new(0, -0.4, 2), palette.wall)
	local spawn = Instance.new("SpawnLocation")
	spawn.Name, spawn.Size, spawn.Position = "PlazaSpawn", Vector3.new(8, 1, 8), Vector3.new(0, 0, 12)
	spawn.Anchored, spawn.Neutral, spawn.Duration, spawn.Transparency = true, true, 0, 1
	spawn.Parent = world
	sign(world, Strings.Plaza, Vector3.new(23, 4, 1), Vector3.new(0, 8, -20))
	City.board = sign(world, Strings.NoLive, Vector3.new(18, 10, 1), Vector3.new(0, 6, -18))
	prompt(City.board.Parent.Parent, Strings.Board, onBoard)
	local kiosk =
		City.part(world, "UpgradeKiosk", Vector3.new(7, 5, 5), Vector3.new(-14, 2, 17), palette.pink)
	sign(world, Strings.Equipment, Vector3.new(10, 3, 1), Vector3.new(-14, 7, 17))
	prompt(kiosk, Strings.Kiosk, onKiosk)
	local stage = City.part(world, "Stage", Vector3.new(16, 2, 12), Vector3.new(8, 0, 31), palette.dark)
	sign(world, Strings.Stage, Vector3.new(18, 3, 1), Vector3.new(8, 6, 36), palette.gold)
	prompt(stage, Strings.StageAction, onStage)
	for index = 1, Config.MaxPlayers do
		local column = (index - 1) % 4
		local row = math.floor((index - 1) / 4)
		local x = ({ -73, -40, 40, 73 })[column + 1]
		local z = -65 + row * 40
		local center = Vector3.new(x, 0, z)
		local model = Instance.new("Model")
		model.Name, model.Parent = "Studio" .. index, world
		City.part(model, "Floor", Vector3.new(29, 1, 32), center, palette.dark)
		City.part(model, "Back", Vector3.new(29, 10, 1), center + Vector3.new(0, 5, 16), palette.wall)
		City.part(model, "Left", Vector3.new(1, 10, 32), center + Vector3.new(-14, 5, 0), palette.wall)
		City.part(model, "Right", Vector3.new(1, 10, 32), center + Vector3.new(14, 5, 0), palette.wall)
		local trim = City.part(
			model,
			"Neon",
			Vector3.new(28, 0.3, 0.3),
			center + Vector3.new(0, 7, 15.3),
			palette.mint,
			Enum.Material.Neon
		)
		local roomSign =
			sign(model, Strings.EmptyRoom, Vector3.new(26, 3, 0.5), center + Vector3.new(0, 9, -14))
		local door =
			City.part(model, "Door", Vector3.new(7, 0.2, 3), center + Vector3.new(0, 0.7, -15), palette.mint)
		prompt(door, Strings.Enter, function(player)
			onDoor(player, index)
		end)
		City.part(
			model,
			"Desk",
			Vector3.new(10, 0.7, 4),
			center + Vector3.new(0, 3, 7),
			Color3.fromRGB(124, 92, 76)
		)
		for _, dx in ipairs({ -4, 4 }) do
			City.part(model, "DeskLeg", Vector3.new(0.5, 3, 3), center + Vector3.new(dx, 1.5, 7))
		end
		local pc = City.part(
			model,
			"PC",
			Vector3.new(4, 2.5, 0.5),
			center + Vector3.new(0, 4.8, 8),
			Color3.fromRGB(75, 98, 126)
		)
		local mic = City.part(
			model,
			"Microphone",
			Vector3.new(0.5, 1.5, 0.5),
			center + Vector3.new(-3, 4, 6.5),
			palette.wall
		)
		local camera =
			City.part(model, "Camera", Vector3.new(1, 0.7, 0.6), center + Vector3.new(3, 4, 7), palette.wall)
		local light = Instance.new("PointLight")
		light.Range, light.Brightness, light.Color, light.Parent = 16, 0.5, palette.mint, camera
		local trophy =
			sign(model, "", Vector3.new(6, 2, 0.5), center + Vector3.new(-8, 5, 15.2), palette.gold)
		local seat = Instance.new("Seat")
		seat.Name, seat.Size, seat.Position, seat.Anchored, seat.Color =
			"CreatorChair", Vector3.new(3, 0.6, 3), center + Vector3.new(0, 1.5, 3.7), true, palette.pink
		seat.Parent = model
		City.rooms[index] = {
			model = model,
			center = center,
			sign = roomSign,
			equipment = { PC = pc, Microphone = mic, Camera = camera },
			trim = trim,
			light = light,
			trophy = trophy,
		}
	end
	for _, x in ipairs({ -22, 22 }) do
		for _, z in ipairs({ -80, -40, 50, 85 }) do
			City.part(world, "Planter", Vector3.new(5, 2, 5), Vector3.new(x, 0, z), palette.wall)
			City.part(world, "Tree", Vector3.new(1, 5, 1), Vector3.new(x, 3, z), Color3.fromRGB(112, 76, 55))
			local top = City.part(
				world,
				"Canopy",
				Vector3.new(7, 7, 7),
				Vector3.new(x, 7, z),
				Color3.fromRGB(87, 157, 115)
			)
			top.Shape = Enum.PartType.Ball
		end
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
	for category, part in pairs(room.equipment) do
		local level = profile.upgrades[category]
		part.Color = ({ palette.wall, palette.mint, palette.pink, palette.gold })[level + 1]
		part.Material = if level > 1 then Enum.Material.Neon else Enum.Material.SmoothPlastic
		if category == "PC" then
			part.Size = Vector3.new(4 + level * 0.7, 2.5 + level * 0.3, 0.5)
		end
	end
	room.light.Brightness = 0.5 + profile.upgrades.Camera
	room.trophy.Text = if #profile.videos > 0
		then string.format(Strings.Trophy, Strings[profile.cosmetics.trophy])
		else ""
end
return City
