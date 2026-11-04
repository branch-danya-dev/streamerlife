--!nonstrict
local B = require(script.Parent.Builder)
local T = require(game.ReplicatedStorage.Shared.Theme)(Color3.fromRGB)
local Studio = {}
function Studio.build(world, index, center)
	local m = Instance.new("Model")
	m.Name, m.Parent = "Studio" .. index, world
	local function part(name, size, offset, color, material, solid)
		return B.part(m, name, size, center + offset, color, material, solid)
	end
	local accent = ({ T.sage, T.coral, T.sky, T.oak })[(index - 1) % 4 + 1]
	part("Floor", Vector3.new(29, 1, 32), Vector3.zero, T.oak, Enum.Material.WoodPlanks, true)
	part("Back", Vector3.new(29, 12, 1), Vector3.new(0, 6.5, 16), T.cream, Enum.Material.Concrete, true)
	part("Right", Vector3.new(1, 12, 32), Vector3.new(14, 6.5, 0), T.cream, Enum.Material.Concrete, true)
	-- A genuine side-window opening, framed in geometry. No hidden collision pane.
	part(
		"LeftFront",
		Vector3.new(1, 12, 10),
		Vector3.new(-14, 6.5, -11),
		T.cream,
		Enum.Material.Concrete,
		true
	)
	part(
		"LeftRear",
		Vector3.new(1, 12, 13),
		Vector3.new(-14, 6.5, 9.5),
		T.cream,
		Enum.Material.Concrete,
		true
	)
	part("WindowBase", Vector3.new(1, 3, 9), Vector3.new(-14, 2, -1.5), T.cream, Enum.Material.Concrete, true)
	part(
		"WindowHeader",
		Vector3.new(1, 3, 9),
		Vector3.new(-14, 11, -1.5),
		T.cream,
		Enum.Material.Concrete,
		true
	)
	local glass =
		part("Window", Vector3.new(0.12, 6, 9), Vector3.new(-14, 6.5, -1.5), T.sky, Enum.Material.Glass)
	glass.Transparency = 0.55
	for _, z in ipairs({ -6.1, -1.5, 3.1 }) do
		part("WindowMullion", Vector3.new(0.55, 6.5, 0.18), Vector3.new(-13.8, 6.5, z), T.oak)
	end
	for _, y in ipairs({ 3.3, 6.5, 9.7 }) do
		part("WindowRail", Vector3.new(0.55, 0.18, 9.6), Vector3.new(-13.8, y, -1.5), T.oak)
	end
	part("WindowSill", Vector3.new(1.3, 0.3, 10), Vector3.new(-13.3, 3.3, -1.5), T.oak)
	part("BackSkirting", Vector3.new(28, 0.35, 0.2), Vector3.new(0, 0.8, 15.4), T.oak)
	part("RearBase", Vector3.new(29, 1.2, 0.2), Vector3.new(0, 1.1, 16.6), accent)
	for _, x in ipairs({ -10, 0, 10 }) do
		part("RearPilaster", Vector3.new(0.45, 10.5, 0.3), Vector3.new(x, 6.5, 16.65), T.cream)
	end
	part("RightSkirting", Vector3.new(0.2, 0.35, 31), Vector3.new(13.4, 0.8, 0), T.oak)
	-- Open-front dollhouse facade: camera and entry corridor remain clear.
	for _, x in ipairs({ -11.8, 11.8 }) do
		part(
			"FacadePier",
			Vector3.new(4.5, 12, 1.2),
			Vector3.new(x, 6.5, -15),
			accent,
			Enum.Material.Concrete,
			true
		)
		part("FacadeFoot", Vector3.new(4.8, 0.5, 1.6), Vector3.new(x, 0.8, -15), T.cream)
	end
	part("FacadeLintel", Vector3.new(29.5, 1.2, 1.7), Vector3.new(0, 12.1, -15), T.cream)
	part("Cornice", Vector3.new(30, 0.4, 2.1), Vector3.new(0, 12.9, -15), T.oak)
	part("RoofBack", Vector3.new(30, 0.6, 5), Vector3.new(0, 12.9, 13.8), T.cream)
	local roof = part("CameraRoof", Vector3.new(27, 0.6, 28), Vector3.new(0, 12.9, -0.5), T.sage)
	roof:SetAttribute("StudioCenter", center)
	for i = 1, 6 do
		part(
			"EntryAwning",
			Vector3.new(3, 0.2, 3),
			Vector3.new(-10.5 + i * 3, 10.7, -16.2),
			if i % 2 == 0 then T.cream else accent
		)
	end
	for _, x in ipairs({ -14, 14 }) do
		part("RoofEdge", Vector3.new(1.5, 0.6, 29), Vector3.new(x, 12.9, 0), T.cream)
	end
	local sign = B.sign(
		m,
		"CREATOR STUDIO",
		Vector3.new(17, 2, 0.3),
		center + Vector3.new(0, 12.1, -16),
		T.ink,
		T.cream
	)
	B.sign(
		m,
		string.format("%02d", index),
		Vector3.new(2.5, 2.5, 0.15),
		center + Vector3.new(-11.7, 7, -15.7),
		T.cream,
		T.ink
	)
	local door = part("Door", Vector3.new(7, 0.15, 3), Vector3.new(0, 0.65, -15), T.mint)
	local status = part("StatusPill", Vector3.new(3, 0.25, 0.15), Vector3.new(10.7, 8, -15.7), T.sage)
	part("EntryMat", Vector3.new(9, 0.08, 4), Vector3.new(0, 0.6, -10), T.sage, Enum.Material.Fabric)
	part("RugBorder", Vector3.new(18, 0.08, 13), Vector3.new(0, 0.56, 6.5), T.sage, Enum.Material.Fabric)
	part("Rug", Vector3.new(16.8, 0.09, 11.8), Vector3.new(0, 0.6, 6.5), T.cream, Enum.Material.Fabric)
	-- Desk with actual drawer pedestal, leg frame, keyboard space and chair.
	part("DeskTop", Vector3.new(14, 0.45, 5.5), Vector3.new(0, 3.6, 9), T.oak, Enum.Material.Wood)
	part("DeskEdge", Vector3.new(14.2, 0.13, 5.6), Vector3.new(0, 3.88, 9), T.cream)
	part("DrawerCabinet", Vector3.new(2.6, 2.9, 4.4), Vector3.new(-5.3, 1.95, 9), T.oak, Enum.Material.Wood)
	for i = 1, 3 do
		part("DrawerFront", Vector3.new(2.35, 0.8, 0.12), Vector3.new(-5.3, 0.95 + i * 0.8, 6.7), T.cream)
		part("DrawerHandle", Vector3.new(0.8, 0.09, 0.12), Vector3.new(-5.3, 1.1 + i * 0.8, 6.58), T.ink)
	end
	for _, z in ipairs({ 7, 11 }) do
		part("DeskLeg", Vector3.new(0.3, 3, 0.3), Vector3.new(6, 2, z), T.ink)
	end
	part("DeskBrace", Vector3.new(0.3, 0.2, 4), Vector3.new(6, 0.7, 9), T.ink)
	local chairAt = center + Vector3.new(0, 0.6, 4.8)
	B.cylinder(m, "ChairPost", 0.13, 1.35, chairAt + Vector3.new(0, 0.8, 0), T.ink)
	for i = 1, 5 do
		local angle = i * math.pi * 2 / 5
		local endAt = chairAt + Vector3.new(math.cos(angle) * 1.3, 0.15, math.sin(angle) * 1.3)
		B.beam(m, "ChairSpoke", chairAt + Vector3.new(0, 0.3, 0), endAt, 0.16, T.ink)
		B.ball(m, "ChairWheel", Vector3.one * 0.28, endAt, T.ink)
	end
	part("ChairSeat", Vector3.new(2.7, 0.5, 2.6), Vector3.new(0, 2.2, 4.8), T.sage, Enum.Material.Fabric)
	local back =
		part("ChairBack", Vector3.new(2.7, 2.5, 0.45), Vector3.new(0, 3.5, 3.5), T.sage, Enum.Material.Fabric)
	back.CFrame *= CFrame.Angles(math.rad(-8), 0, 0)
	for _, x in ipairs({ -1.5, 1.5 }) do
		part("ChairArm", Vector3.new(0.22, 0.2, 2), Vector3.new(x, 2.9, 4.8), T.ink)
	end
	for i = 1, 7 do
		part(
			"AcousticPanel",
			Vector3.new(1.15, 4.8, 0.35),
			Vector3.new(-1.8 + (i - 1) * 1.25, 7, 15.2),
			T.sage,
			Enum.Material.Fabric
		)
	end
	for _, y in ipairs({ 6, 9 }) do
		part(
			"FloatingShelf",
			Vector3.new(5, 0.25, 1.4),
			Vector3.new(-8.6, y, 14.6),
			T.oak,
			Enum.Material.Wood
		)
		for i = 1, 3 do
			part(
				"Book",
				Vector3.new(0.42, 1 + i * 0.15, 0.8),
				Vector3.new(-10 + i * 0.55, y + 0.75, 14.5),
				({ T.coral, T.sky, T.cream })[i]
			)
		end
	end
	B.plant(m, center + Vector3.new(-7, 9.15, 14.5), 0.55)
	B.plant(m, center + Vector3.new(-10.5, 0.6, 9), 1.5)
	part("PinboardFrame", Vector3.new(4.6, 3.8, 0.2), Vector3.new(9.8, 7.5, 15.2), T.oak)
	B.sign(
		m,
		"MAKE\nSOMETHING\nGREAT",
		Vector3.new(4.1, 3.3, 0.1),
		center + Vector3.new(9.8, 7.5, 15),
		T.cream,
		T.ink
	)
	local trophy =
		B.sign(m, "", Vector3.new(6, 1.3, 0.1), center + Vector3.new(0, 10.8, 15.2), T.cream, T.ink)
	local lamp = part("DeskLamp", Vector3.new(0.4, 1.1, 0.4), Vector3.new(-6, 4.5, 10.3), T.oak)
	B.ball(m, "LampShade", Vector3.new(1.2, 0.9, 1.2), center + Vector3.new(-6, 5.2, 10.3), T.cream)
	local light = Instance.new("PointLight")
	light.Name, light.Brightness, light.Range, light.Color, light.Shadows, light.Parent =
		"AccentLight", 0.65, 12, T.cream, false, lamp
	return {
		model = m,
		center = center,
		index = index,
		sign = sign,
		door = door,
		trim = status,
		light = light,
		trophy = trophy,
		equipment = {},
	}
end
return Studio
