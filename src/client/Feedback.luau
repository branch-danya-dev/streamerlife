--!nonstrict
local Tween = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local Palette = require(game.ReplicatedStorage.Shared.SoundPalette)
local F = { reduced = false, volume = 0.65, activeParticles = 0, maxParticles = 24 }
local ui, voices, last, cursor = nil, {}, {}, 0
local roofs, roofPoll = {}, 0
function F.roofs(now, arenaCenter)
	if now < roofPoll then
		return
	end
	roofPoll = now + 0.2
	if #roofs < 16 then
		roofs = {}
		local city = workspace:FindFirstChild("ViralCity")
		if city then
			for _, room in ipairs(city:GetChildren()) do
				local roof = room:FindFirstChild("CameraRoof")
				if roof then
					table.insert(roofs, roof)
				end
			end
		end
	end
	local at = workspace.CurrentCamera.CFrame.Position
	for _, roof in ipairs(roofs) do
		local delta = at - roof:GetAttribute("StudioCenter")
		local inside = math.abs(delta.X) < 17 and math.abs(delta.Z) < 19 and delta.Y < 18
		-- Match the arena to its studio independently of the overhead camera's viewing side.
		local arenaDelta = arenaCenter and arenaCenter - roof:GetAttribute("StudioCenter")
		local arena = arenaDelta and math.abs(arenaDelta.X) < 14 and math.abs(arenaDelta.Z) < 16
		roof.LocalTransparencyModifier = if inside or arena then 1 else 0
	end
end
function F.init(interface)
	ui = interface
	local group = Instance.new("SoundGroup")
	group.Name, group.Volume, group.Parent = "CreatorCues", F.volume, game:GetService("SoundService")
	F.group = group
	for i = 1, 8 do
		local sound = Instance.new("Sound")
		sound.Name, sound.SoundGroup, sound.Parent = "CueVoice" .. i, group, ui.gui
		voices[i] = { sound = sound, serial = 0 }
	end
	-- Preload one reusable voice per bundled source without blocking game startup.
	task.spawn(function()
		local assets = {}
		local i = 0
		for _, source in pairs(Palette.sources) do
			i += 1
			voices[i].sound.SoundId = source
			table.insert(assets, voices[i].sound)
		end
		pcall(function()
			game:GetService("ContentProvider"):PreloadAsync(assets)
		end)
	end)
end
function F.cue(name)
	if not ui or F.volume == 0 or os.clock() - (last[name] or 0) < 0.08 then
		return
	end
	last[name] = os.clock()
	for _, note in ipairs(Palette.cues[name] or Palette.cues.tap) do
		task.delay(note[1], function()
			if not ui.gui.Parent or F.volume == 0 then
				return
			end
			cursor = cursor % #voices + 1
			local voice = voices[cursor]
			voice.serial += 1
			local serial, sound = voice.serial, voice.sound
			sound:Stop()
			sound.SoundId = Palette.sources[note[2]]
			sound.PlaybackSpeed, sound.Volume, sound.TimePosition = note[3], note[4], 0
			sound:Play()
			task.delay(note[5], function()
				if voice.serial == serial then
					sound:Stop()
				end
			end)
		end)
	end
end
function F.setVolume(value)
	F.volume = math.clamp(value, 0, 1)
	if F.group then
		F.group.Volume = F.volume
	end
end
function F.setReduced(value)
	F.reduced = value
	for _, light in ipairs(workspace:GetDescendants()) do
		if light:IsA("Light") and light.Name == "AccentLight" then
			light.Enabled = not value
		end
	end
end
function F.pulse(object, amount)
	if F.reduced then
		return
	end
	local scale = object:FindFirstChild("FeedbackScale")
	if not scale then
		scale = Instance.new("UIScale")
		scale.Name, scale.Parent = "FeedbackScale", object
	end
	if scale:GetAttribute("Busy") then
		return
	end
	scale:SetAttribute("Busy", true)
	scale.Scale = amount or 0.96
	local tween = Tween:Create(scale, TweenInfo.new(0.22, Enum.EasingStyle.Back), { Scale = 1 })
	tween:Play()
	tween.Completed:Once(function()
		if scale.Parent then
			scale:SetAttribute("Busy", false)
		end
	end)
end
function F.burst(position, color, count)
	if F.reduced or not ui then
		return
	end
	count = math.min(count or 8, F.maxParticles - F.activeParticles)
	for i = 1, count do
		F.activeParticles += 1
		local dot = ui.make("Frame", {
			Name = "RewardParticle",
			Size = UDim2.fromOffset(5 + i % 3 * 2, 5 + i % 3 * 2),
			Position = position,
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundColor3 = color,
			BorderSizePixel = 0,
			ZIndex = 25,
			Rotation = i * 37,
		}, ui.gui)
		ui.round(dot, if i % 2 == 0 then 10 else 2)
		local a = i * math.pi * 2 / count
		Tween:Create(dot, TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Position = position + UDim2.fromOffset(math.cos(a) * 55, math.sin(a) * 38 - 20),
			BackgroundTransparency = 1,
			Rotation = i * 37 + 80,
		}):Play()
		Debris:AddItem(dot, 0.65)
		task.delay(0.65, function()
			F.activeParticles = math.max(0, F.activeParticles - 1)
		end)
	end
end
function F.reward(reward, success, grade, combo)
	F.cue(if grade == "Perfect" then "perfect" elseif success then "hit" else "miss")
	if reward.donations and reward.donations > 0 then
		F.cue("donate")
	end
	if success then
		F.burst(
			ui.toastFrame.Position + UDim2.fromOffset(ui.toastFrame.AbsoluteSize.X / 2, 20),
			ui.colors.gold,
			if (combo or 0) > 1 then 12 else 7
		)
	end
end
return F
