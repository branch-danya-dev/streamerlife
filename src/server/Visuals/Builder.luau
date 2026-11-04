--!nonstrict
local T = require(game.ReplicatedStorage.Shared.Theme)(Color3.fromRGB)
local B = {}
function B.part(parent, name, size, position, color, material, solid)
	local p = Instance.new("Part")
	p.Name, p.Size, p.Position = name, size, position
	p.Anchored, p.CanCollide, p.CanTouch, p.CanQuery = true, solid == true, false, solid == true
	p.CastShadow, p.Color, p.Material =
		solid == true, color or T.cream, material or Enum.Material.SmoothPlastic
	p.TopSurface, p.BottomSurface, p.Parent = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth, parent
	return p
end
function B.cylinder(parent, name, radius, height, position, color, material)
	local p = B.part(parent, name, Vector3.new(height, radius * 2, radius * 2), position, color, material)
	p.Shape = Enum.PartType.Cylinder
	p.CFrame = CFrame.new(position) * CFrame.Angles(0, 0, math.pi / 2)
	return p
end
function B.ball(parent, name, size, position, color)
	local p = B.part(parent, name, size, position, color)
	p.Shape = Enum.PartType.Ball
	return p
end
function B.beam(parent, name, from, to, width, color)
	local p = B.part(parent, name, Vector3.new(width, width, (to - from).Magnitude), (from + to) / 2, color)
	p.CFrame = CFrame.lookAt((from + to) / 2, to)
	return p
end
function B.sign(parent, text, size, position, bg, fg, face)
	local p = B.part(parent, "Sign", size, position, bg or T.ink)
	local gui = Instance.new("SurfaceGui")
	gui.Face, gui.SizingMode, gui.PixelsPerStud =
		face or Enum.NormalId.Front, Enum.SurfaceGuiSizingMode.PixelsPerStud, 36
	gui.LightInfluence, gui.Parent = 0.3, p
	local label = Instance.new("TextLabel")
	label.Size, label.BackgroundTransparency = UDim2.fromScale(1, 1), 1
	label.Text, label.TextColor3 = text, fg or T.cream
	label.Font, label.TextScaled, label.TextWrapped, label.Parent = Enum.Font.GothamBold, true, true, gui
	return label
end
function B.plant(parent, position, scale)
	scale = scale or 1
	B.cylinder(
		parent,
		"CeramicPot",
		0.65 * scale,
		1.2 * scale,
		position + Vector3.new(0, 0.6 * scale, 0),
		T.cream
	)
	B.cylinder(parent, "Soil", 0.57 * scale, 0.12 * scale, position + Vector3.new(0, 1.23 * scale, 0), T.ink)
	for i = 1, 4 do
		local angle = i * math.pi / 2
		local leaf = B.ball(
			parent,
			"Leaf",
			Vector3.new(0.7, 1.8, 0.45) * scale,
			position + Vector3.new(math.cos(angle) * 0.5, 1.8, math.sin(angle) * 0.5) * scale,
			if i % 2 == 0 then T.sage else T.leaf
		)
		leaf.CFrame *= CFrame.Angles(math.cos(angle) * 0.5, angle, math.sin(angle) * 0.5)
	end
end
return B
