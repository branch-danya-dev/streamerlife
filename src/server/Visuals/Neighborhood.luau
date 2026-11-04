--!nonstrict
local B = require(script.Parent.Builder)
local T = require(game.ReplicatedStorage.Shared.Theme)(Color3.fromRGB)
local N = {}
local function bench(parent, at)
	B.part(
		parent,
		"BenchSeat",
		Vector3.new(7, 0.35, 2),
		at + Vector3.new(0, 1.5, 0),
		T.oak,
		Enum.Material.Wood
	)
	B.part(parent, "BenchBack", Vector3.new(7, 1.5, 0.3), at + Vector3.new(0, 2.3, 0.9), T.sage)
	for _, x in ipairs({ -2.6, 2.6 }) do
		B.part(parent, "BenchLeg", Vector3.new(0.3, 1.5, 1.8), at + Vector3.new(x, 0.7, 0), T.ink)
	end
end
local function tree(parent, at, scale)
	scale = scale or 1
	B.cylinder(parent, "TreePlanter", 2.4 * scale, 1.1, at + Vector3.new(0, 0.25, 0), T.cream)
	B.cylinder(parent, "TreeSoil", 2.15 * scale, 0.1, at + Vector3.new(0, 0.85, 0), T.sage)
	B.cylinder(
		parent,
		"Trunk",
		0.45 * scale,
		6 * scale,
		at + Vector3.new(0, 3 * scale, 0),
		T.oak,
		Enum.Material.Wood
	)
	for i = 1, 3 do
		local angle = i * math.pi * 2 / 3
		B.ball(
			parent,
			"TreeCrown",
			Vector3.new(6, 6, 5) * scale,
			at + Vector3.new(math.cos(angle) * 1.6, 6.2 + i * 0.45, math.sin(angle) * 1.3) * scale,
			if i == 2 then T.sage else T.leaf
		)
	end
end
local function streetlamp(parent, at)
	B.cylinder(parent, "LampFoot", 0.6, 0.4, at, T.ink)
	B.cylinder(parent, "LampPost", 0.16, 8, at + Vector3.new(0, 4, 0), T.ink)
	B.part(parent, "LampCap", Vector3.new(1.5, 0.2, 1.5), at + Vector3.new(0, 9, 0), T.ink)
	B.part(
		parent,
		"LampGlow",
		Vector3.new(0.85, 1, 0.85),
		at + Vector3.new(0, 8.4, 0),
		T.cream,
		Enum.Material.Neon
	)
	-- Daylight fixtures have no Light instance; mobile cost is geometry only.
end
function N.build(world, strings)
	B.part(
		world,
		"Ground",
		Vector3.new(218, 2, 214),
		Vector3.new(0, -2, 0),
		T.sage,
		Enum.Material.Grass,
		true
	)
	B.part(
		world,
		"Promenade",
		Vector3.new(45, 0.5, 204),
		Vector3.new(0, -0.7, 0),
		T.paving,
		Enum.Material.Concrete,
		true
	)
	for _, x in ipairs({ -106, 106 }) do
		B.part(world, "GardenBoundary", Vector3.new(1, 1.2, 210), Vector3.new(x, -0.3, 0), T.cream)
		for _, z in ipairs({ -100, 100 }) do
			tree(world, Vector3.new(x * 0.96, -0.1, z), 1.1)
		end
	end
	for _, z in ipairs({ -104, 104 }) do
		B.part(world, "GardenBoundary", Vector3.new(210, 1.2, 1), Vector3.new(0, -0.3, z), T.cream)
	end
	for _, x in ipairs({ -23, 23 }) do
		B.part(world, "PromenadeCurb", Vector3.new(0.7, 0.5, 204), Vector3.new(x, -0.45, 0), T.cream)
	end
	for _, z in ipairs({ -85, -45, -5, 35, 75 }) do
		B.part(
			world,
			"StudioLane",
			Vector3.new(206, 0.35, 8),
			Vector3.new(0, -0.55, z),
			T.paving,
			Enum.Material.Concrete,
			true
		)
		for _, dz in ipairs({ -4, 4 }) do
			B.part(world, "LaneBorder", Vector3.new(206, 0.2, 0.25), Vector3.new(0, -0.3, z + dz), T.cream)
		end
	end
	-- Repeating inlaid strips add human scale without hundreds of individual paving blocks.
	for z = -95, 95, 10 do
		B.part(world, "PavingInlay", Vector3.new(43, 0.025, 0.12), Vector3.new(0, -0.43, z), T.cream)
	end
	B.part(
		world,
		"Plaza",
		Vector3.new(43, 0.4, 55),
		Vector3.new(0, -0.4, 8),
		T.cream,
		Enum.Material.Concrete,
		true
	)
	for _, x in ipairs({ -18, 18 }) do
		for _, z in ipairs({ -75, -35, 46, 84 }) do
			tree(world, Vector3.new(x, -0.1, z), 0.9)
		end
		for _, z in ipairs({ -57, 64 }) do
			streetlamp(world, Vector3.new(x, 0, z))
		end
	end
	bench(world, Vector3.new(-15, 0, 5))
	bench(world, Vector3.new(15, 0, 5))
	local board = B.sign(
		world,
		strings.NoLive,
		Vector3.new(15, 7, 0.5),
		Vector3.new(0, 5, -18),
		T.ink,
		T.cream,
		Enum.NormalId.Back
	)
	for _, x in ipairs({ -8, 8 }) do
		B.part(world, "DirectoryPost", Vector3.new(0.4, 10, 0.4), Vector3.new(x, 4.5, -18), T.oak)
	end
	B.sign(
		world,
		"VIRAL CITY",
		Vector3.new(19, 2.5, 0.4),
		Vector3.new(0, 10, -18),
		T.coral,
		T.ink,
		Enum.NormalId.Back
	)
	B.part(world, "DirectoryCanopy", Vector3.new(20, 0.4, 4), Vector3.new(0, 11.7, -18), T.cream)
	-- Gear shop: a compact, layered storefront with counter and display props.
	local shop = Instance.new("Model")
	shop.Name, shop.Parent = "GearLab", world
	B.part(shop, "ShopBack", Vector3.new(11, 9, 1), Vector3.new(-14, 4.5, 22), T.sage)
	B.part(shop, "ShopRoof", Vector3.new(12, 0.6, 8), Vector3.new(-14, 9.3, 19), T.cream)
	for _, x in ipairs({ -19.5, -8.5 }) do
		B.part(shop, "ShopColumn", Vector3.new(0.5, 8, 0.5), Vector3.new(x, 4, 16), T.oak)
	end
	B.sign(shop, strings.Equipment, Vector3.new(10, 2, 0.3), Vector3.new(-14, 7.7, 15.6), T.ink, T.cream)
	for i = 1, 6 do
		local stripe = B.part(
			shop,
			"AwningStripe",
			Vector3.new(2, 0.18, 4.5),
			Vector3.new(-21 + i * 2, 6.5, 15),
			if i % 2 == 0 then T.cream else T.sage
		)
		stripe.CFrame *= CFrame.Angles(math.rad(12), 0, 0)
	end
	local kiosk = B.part(shop, "UpgradeCounter", Vector3.new(9, 3.2, 2.5), Vector3.new(-14, 1.6, 17), T.oak)
	B.part(shop, "CounterTop", Vector3.new(9.4, 0.25, 2.8), Vector3.new(-14, 3.3, 17), T.cream)
	for i = 1, 3 do
		B.part(
			shop,
			"DisplayBox",
			Vector3.new(1.7, 1.2 + i * 0.2, 1.2),
			Vector3.new(-18 + i * 2, 4, 18),
			({ T.ink, T.coral, T.mint })[i]
		)
	end
	B.plant(shop, Vector3.new(-20, 0, 14), 1.1)
	local stage = B.part(
		world,
		"Stage",
		Vector3.new(17, 1.2, 11),
		Vector3.new(9, 0.2, 29),
		T.oak,
		Enum.Material.Wood,
		true
	)
	B.part(
		world,
		"StageStep",
		Vector3.new(15, 0.5, 2),
		Vector3.new(9, -0.15, 22.5),
		T.cream,
		Enum.Material.Concrete,
		true
	)
	B.part(world, "StageBackdrop", Vector3.new(17, 8, 0.5), Vector3.new(9, 4.5, 34), T.sage)
	B.sign(world, strings.Stage, Vector3.new(14, 2, 0.3), Vector3.new(9, 8.4, 33.7), T.cream, T.ink)
	B.sign(world, "▶", Vector3.new(5, 4, 0.2), Vector3.new(9, 4.6, 33.6), T.cream, T.coral)
	for _, x in ipairs({ 1, 17 }) do
		B.part(world, "StageSpeaker", Vector3.new(1.7, 3.5, 1.7), Vector3.new(x, 2.5, 31), T.ink)
		for _, y in ipairs({ 1.7, 3.1 }) do
			B.ball(world, "SpeakerCone", Vector3.new(1.15, 1.15, 0.15), Vector3.new(x, y, 30.1), T.muted)
		end
	end
	for _, x in ipairs({ -20, 20 }) do
		B.cylinder(world, "BuntingPost", 0.12, 13, Vector3.new(x, 6.5, -8), T.ink)
	end
	for i = 1, 9 do
		local x = -20 + i * 4
		B.part(
			world,
			"Bunting",
			Vector3.new(1.2, 1.8, 0.08),
			Vector3.new(x, 13 - math.sin(i / 10 * math.pi) * 1.4, -8),
			if i % 2 == 0 then T.coral else T.sage
		)
	end
	B.beam(world, "BuntingLine", Vector3.new(-20, 13, -8), Vector3.new(20, 13, -8), 0.05, T.ink)
	return board, kiosk, stage
end
return N
