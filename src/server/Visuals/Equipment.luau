--!nonstrict
local B = require(script.Parent.Builder)
local T = require(game.ReplicatedStorage.Shared.Theme)(Color3.fromRGB)
local E = {}
local function screen(parent, at, width, height, accent)
	B.part(parent, "MonitorHousing", Vector3.new(width + 0.3, height + 0.3, 0.35), at, T.ink)
	local display =
		B.part(parent, "Display", Vector3.new(width, height, 0.05), at - Vector3.new(0, 0, 0.2), T.sky)
	local gui = Instance.new("SurfaceGui")
	gui.Face, gui.CanvasSize, gui.LightInfluence, gui.Parent =
		Enum.NormalId.Front, Vector2.new(480, 270), 0, display
	local bg = Instance.new("Frame")
	bg.Size, bg.BackgroundColor3, bg.BorderSizePixel, bg.Parent = UDim2.fromScale(1, 1), T.ink, 0, gui
	local title = Instance.new("TextLabel")
	title.Size, title.Position, title.Text =
		UDim2.fromScale(0.8, 0.2), UDim2.fromScale(0.1, 0.06), "CREATOR DESK"
	title.BackgroundTransparency, title.TextColor3, title.Font, title.TextScaled, title.Parent =
		1, T.cream, Enum.Font.GothamBold, true, bg
	for i = 1, 5 do
		local bar = Instance.new("Frame")
		bar.Size, bar.Position =
			UDim2.fromScale(0.1, 0.1 + i * 0.07),
			UDim2.fromScale(0.1 + (i - 1) * 0.16, 0.85 - (0.1 + i * 0.07))
		bar.BackgroundColor3, bar.BorderSizePixel, bar.Parent = if i == 5 then T.coral else accent, 0, bg
	end
	B.part(
		parent,
		"MonitorStem",
		Vector3.new(0.3, 0.9, 0.3),
		at - Vector3.new(0, height / 2 + 0.35, 0),
		T.ink
	)
	B.part(
		parent,
		"MonitorFoot",
		Vector3.new(2, 0.12, 1.2),
		at - Vector3.new(0, height / 2 + 0.8, 0.1),
		T.ink
	)
end
local function keyboard(parent, at)
	B.part(parent, "Keyboard", Vector3.new(3.6, 0.18, 1.2), at, T.ink)
	for row = 1, 3 do
		B.part(
			parent,
			"KeyRow",
			Vector3.new(3.15, 0.06, 0.22),
			at + Vector3.new(0, 0.13, (row - 2) * 0.3),
			T.cream
		)
	end
	B.ball(parent, "Mouse", Vector3.new(0.55, 0.24, 0.8), at + Vector3.new(2.4, 0.03, 0), T.ink)
end
function E.PC(parent, center, level)
	local at = center + Vector3.new(0, 6.2, 10.6)
	if level <= 1 then
		screen(parent, at, if level == 0 then 4.4 else 6.2, 2.7, T.mint)
	elseif level == 2 then
		for _, x in ipairs({ -3.1, 3.1 }) do
			screen(parent, at + Vector3.new(x, 0, 0), 5.5, 2.8, T.mint)
		end
	else
		for _, x in ipairs({ -4.6, 0, 4.6 }) do
			screen(parent, at + Vector3.new(x, if x == 0 then 0.5 else 0, 0), 4.2, 2.8, T.gold)
		end
	end
	keyboard(parent, center + Vector3.new(0, 3.92, 8.4))
	if level >= 1 then
		local atTower = center + Vector3.new(5, 1.8, 10)
		B.part(parent, "DesktopTower", Vector3.new(2.1, 2.7, 3), atTower, T.ink)
		B.part(parent, "TowerPanel", Vector3.new(1.8, 2.4, 0.08), atTower + Vector3.new(0, 0, -1.55), T.cream)
		for y = 0, level do
			local fan = B.cylinder(
				parent,
				"VentFan",
				0.44,
				0.12,
				atTower + Vector3.new(0, 0.65 - y * 0.55, -1.62),
				T.mint
			)
			fan.CFrame *= CFrame.Angles(math.pi / 2, 0, 0)
		end
	end
	if level >= 2 then
		for _, x in ipairs({ -6.3, 6.3 }) do
			B.part(parent, "Speaker", Vector3.new(0.8, 1.6, 0.8), center + Vector3.new(x, 4.6, 10.3), T.ink)
			B.ball(
				parent,
				"SpeakerCone",
				Vector3.new(0.56, 0.56, 0.08),
				center + Vector3.new(x, 4.7, 9.86),
				T.sage
			)
		end
	end
	if level == 3 then
		B.part(
			parent,
			"StreamDeck",
			Vector3.new(1.5, 0.25, 1.1),
			center + Vector3.new(-3.4, 3.95, 8.3),
			T.ink
		)
		for i = 1, 4 do
			B.part(
				parent,
				"DeckKey",
				Vector3.new(0.4, 0.08, 0.3),
				center + Vector3.new(-3.75 + ((i - 1) % 2) * 0.7, 4.11, 8 + math.floor((i - 1) / 2) * 0.5),
				if i % 2 == 0 then T.coral else T.mint
			)
		end
	end
end
function E.Microphone(parent, center, level)
	local base = center + Vector3.new(-4.3, 3.9, 8)
	local head = base + Vector3.new(0, 1.2, 0)
	if level == 0 then
		B.cylinder(parent, "DeskStand", 0.55, 0.13, base, T.ink)
		B.cylinder(parent, "MicrophoneStem", 0.08, 0.8, base + Vector3.new(0, 0.45, 0), T.ink)
	else
		local mount = base + Vector3.new(-1.8, 0, 1.8)
		head = base + Vector3.new(0, 1.7, -0.1)
		B.part(parent, "DeskClamp", Vector3.new(0.45, 0.7, 0.55), mount, T.ink)
		local elbow = mount + Vector3.new(0.3, 2.8, -0.3)
		B.beam(parent, "BoomLower", mount, elbow, 0.14, T.ink)
		B.beam(parent, "BoomUpper", elbow, head + Vector3.new(0, 0.3, 0), 0.14, T.ink)
		B.ball(parent, "BoomJoint", Vector3.one * 0.32, elbow, T.oak)
	end
	B.cylinder(parent, "MicrophoneBody", if level == 0 then 0.24 else 0.32, 0.85, head, T.ink)
	B.ball(
		parent,
		"MeshCapsule",
		Vector3.new(0.62, 0.72, 0.62),
		head + Vector3.new(0, 0.4, 0),
		if level >= 2 then T.sage else T.muted
	)
	for i = 1, 3 do
		B.cylinder(parent, "GrilleBand", 0.32, 0.035, head + Vector3.new(0, 0.2 + i * 0.13, 0), T.ink)
	end
	if level >= 2 then
		local filter = B.cylinder(parent, "PopFilter", 0.48, 0.09, head + Vector3.new(0, 0.3, -0.7), T.ink)
		filter.CFrame *= CFrame.Angles(math.pi / 2, 0, 0)
		B.beam(
			parent,
			"FilterStem",
			head - Vector3.new(0, 0.5, 0),
			head + Vector3.new(0, 0.1, -0.7),
			0.06,
			T.ink
		)
	end
	if level == 3 then
		B.cylinder(parent, "ShockMount", 0.48, 0.12, head - Vector3.new(0, 0.2, 0), T.gold)
		B.part(parent, "AudioMixer", Vector3.new(2, 0.3, 1.3), base + Vector3.new(1, 0, -0.3), T.ink)
		for i = 1, 3 do
			B.cylinder(
				parent,
				"MixerKnob",
				0.12,
				0.16,
				base + Vector3.new(0.4 + i * 0.35, 0.25, -0.3),
				T.gold
			)
		end
	end
end
local function tripod(parent, at, height)
	B.cylinder(parent, "TripodMast", 0.08, height, at + Vector3.new(0, height / 2, 0), T.ink)
	for i = 1, 3 do
		local angle = i * math.pi * 2 / 3
		B.beam(
			parent,
			"TripodLeg",
			at + Vector3.new(0, 1.4, 0),
			at + Vector3.new(math.cos(angle) * 1.1, 0.1, math.sin(angle) * 1.1),
			0.12,
			T.ink
		)
	end
end
local function softbox(parent, at, height, warm)
	tripod(parent, at, height)
	B.part(parent, "SoftboxHousing", Vector3.new(2.5, 2.5, 0.5), at + Vector3.new(0, height, 0), T.ink)
	B.part(
		parent,
		"SoftboxDiffuser",
		Vector3.new(2.25, 2.25, 0.07),
		at + Vector3.new(0, height, -0.28),
		if warm then T.cream else T.sky,
		Enum.Material.Neon
	)
end
function E.Camera(parent, center, level)
	if level == 0 then
		B.part(parent, "WebcamClip", Vector3.new(0.8, 0.15, 0.6), center + Vector3.new(0, 7.78, 10.6), T.ink)
		B.part(parent, "Webcam", Vector3.new(0.85, 0.36, 0.4), center + Vector3.new(0, 8, 10.6), T.ink)
		B.ball(parent, "Lens", Vector3.new(0.23, 0.23, 0.1), center + Vector3.new(0, 8, 10.35), T.sky)
		return
	end
	local at = center + Vector3.new(9.5, 0.6, 9)
	tripod(parent, at, 5)
	B.part(parent, "CameraBody", Vector3.new(1.5, 1, 0.8), at + Vector3.new(0, 5, 0), T.ink)
	B.ball(parent, "CameraLens", Vector3.new(0.8, 0.8, 0.6), at + Vector3.new(0, 5, -0.6), T.muted)
	B.ball(parent, "OpticalGlass", Vector3.new(0.55, 0.55, 0.1), at + Vector3.new(0, 5, -0.93), T.sky)
	softbox(parent, center + Vector3.new(-10, 0.6, 7), 6.2, true)
	if level >= 2 then
		softbox(parent, center + Vector3.new(11, 0.6, 3), 6.2, false)
	end
	if level == 3 then
		B.part(parent, "CameraTopHandle", Vector3.new(1.2, 0.15, 0.3), at + Vector3.new(0, 5.8, 0), T.gold)
		B.part(parent, "CameraFlipScreen", Vector3.new(1, 0.7, 0.12), at + Vector3.new(-1, 5.2, -0.1), T.sky)
		B.part(
			parent,
			"BackdropAccent",
			Vector3.new(9, 0.15, 0.15),
			center + Vector3.new(0, 9.5, 15.1),
			T.gold,
			Enum.Material.Neon
		)
	end
end
function E.build(room, profile)
	room.visualLevels = room.visualLevels or {}
	for _, category in ipairs({ "PC", "Microphone", "Camera" }) do
		local level = profile.upgrades[category]
		if room.visualLevels[category] ~= level then
			if room.equipment[category] then
				room.equipment[category]:Destroy()
			end
			local model = Instance.new("Model")
			model.Name, model.Parent = category .. "_Level" .. level, room.model
			model:SetAttribute("EquipmentLevel", level)
			E[category](model, room.center, level)
			room.equipment[category], room.visualLevels[category] = model, level
		end
	end
end
return E
