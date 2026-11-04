--!nonstrict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Balance)
local Domain = require(Shared.Domain)(Config)
local Rules = require(Shared.Rules)
local Strings = require(Shared.Strings)
local UI = require(script.UI)
local remote = ReplicatedStorage:WaitForChild("Remotes")
local action, event = remote:WaitForChild("Action"), remote:WaitForChild("Event")
local state, directory, boardKey, visuals = nil, {}, nil, {}
local savedCameraType
local lastPanelSignature
local stoppedId, stoppedAt

local function send(verb, data)
	action:FireServer(verb, data or {})
end
local function input(verb, value)
	local c = state and state.session and state.session.challenge
	if c and not state.watching and not UI.overlay.Visible then
		local now = workspace:GetServerTimeNow()
		if now < c.startsAt or now >= c.endsAt then
			return
		end
		if verb == "Stop" then
			if stoppedId == c.id then
				return
			end
			stoppedId, stoppedAt = c.id, now
		end
		send("Input", { id = c.id, verb = verb, value = value })
	end
end
UI.build(send)
pcall(function()
	game:GetService("StarterGui"):SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, false)
end)

local renderPanel
local function oddsText(profile)
	local lines = {}
	for _, tier in ipairs(Domain.odds(profile)) do
		table.insert(lines, string.format(Strings.OddsLine, Strings[tier.id], tier.weight))
	end
	return string.format(Strings.Odds, table.concat(lines, "  ·  "))
end

renderPanel = function(kind)
	if not state then
		return
	end
	UI.openPanel(Strings[kind] or kind)
	UI.panelKind = kind
	local p = state.profile
	if kind == "Menu" then
		for _, key in ipairs({ "Gear", "Videos", "Live" }) do
			UI.rowButton(Strings[key], function()
				renderPanel(key)
			end)
		end
		UI.rowButton(Strings.City, function()
			send("City")
			UI.closePanel()
		end)
		UI.rowButton(Strings.Home, function()
			send("Home")
			UI.closePanel()
		end)
	elseif kind == "Gear" then
		for _, category in ipairs({ "PC", "Microphone", "Camera" }) do
			local cost = Domain.price(p, category)
			if cost then
				UI.rowButton(
					string.format(
						Strings.Upgrade,
						Strings[category],
						p.upgrades[category],
						p.upgrades[category] + 1,
						cost
					),
					function()
						send("Buy", { category = category, expectedLevel = p.upgrades[category] })
					end,
					if p.money >= cost then UI.colors.mint else nil
				)
			else
				UI.row(string.format(Strings.MaxLevel, Strings[category]), 54)
			end
		end
		UI.row(oddsText(p), 95, UI.colors.muted)
	elseif kind == "Videos" then
		if #p.videos == 0 then
			UI.row(Strings.NoVideos)
		end
		for _, video in ipairs(p.videos) do
			UI.row(
				string.format(
					Strings.VideoLine,
					Strings[video.tier],
					video.views,
					video.cashRate,
					(Config.OfflineCap - video.paidSeconds) / 3600
				),
				76,
				UI.colors.gold
			)
		end
		UI.row(oddsText(p), 100, UI.colors.muted)
	elseif kind == "Live" then
		local live = 0
		for _, studio in ipairs(directory) do
			if studio.live then
				live += 1
			end
		end
		if live == 0 then
			UI.row(Strings.NoLive)
		end
		for _, studio in ipairs(directory) do
			if studio.userId ~= Players.LocalPlayer.UserId then
				UI.rowButton(
					studio.name
						.. "  ·  "
						.. string.format(Strings.Room, studio.room)
						.. (if studio.live
							then "\n" .. string.format(Strings.ViewerLabel, Strings.LiveBadge, studio.viewers)
							else "")
						.. "  ·  "
						.. Strings.Visit,
					function()
						send("Visit", { userId = studio.userId })
						UI.closePanel()
					end,
					if studio.live then UI.colors.mint else nil
				)
			end
		end
	elseif kind == "Social" then
		for index, phrase in ipairs(Strings.Reactions) do
			UI.rowButton(phrase, function()
				send("React", { index = index })
				UI.closePanel()
			end)
		end
		local s = state.session
		if s and not s.challenge then
			UI.row(Strings.Vote, 38, UI.colors.muted)
			for _, choice in ipairs(s.choices) do
				UI.rowButton(
					string.format(Strings.VoteCount, Strings[choice], s.votes[choice] or 0),
					function()
						send("Vote", { choice = choice })
						UI.closePanel()
					end
				)
			end
		end
	end
end
UI.showMenu = function()
	renderPanel("Menu")
end
UI.onPrimary = function()
	if not state then
		return
	end
	if state.watching then
		renderPanel("Social")
	elseif state.session then
		send("Finish")
	else
		UI.closePanel()
		send("Start")
	end
end

local function restoreCamera()
	if savedCameraType then
		workspace.CurrentCamera.CameraType = savedCameraType
		local humanoid = Players.LocalPlayer.Character
			and Players.LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			workspace.CurrentCamera.CameraSubject = humanoid
		end
		savedCameraType = nil
	end
end

local function buildBoard(c)
	UI.clear(UI.board)
	UI.clear(UI.controls)
	visuals = {}
	restoreCamera()
	if not c then
		visuals.breakText = UI.label(UI.board, "", UDim2.fromScale(1, 1), nil, 18, UI.colors.mint)
		visuals.breakText.TextXAlignment = Enum.TextXAlignment.Center
		UI.button(
			UI.controls,
			if state.watching then Strings.Vote else Strings.Gear,
			UDim2.fromScale(1, 1),
			nil,
			function()
				renderPanel(if state.watching then "Social" else "Gear")
			end
		)
		return
	end
	if c.kind == "Timing" then
		visuals.target = UI.make("Frame", {
			Size = UDim2.fromScale(c.width, 0.5),
			Position = UDim2.fromScale(c.center - c.width / 2, 0.25),
			BorderSizePixel = 0,
			BackgroundColor3 = UI.colors.mint,
		}, UI.board)
		UI.round(visuals.target, 8)
		visuals.pointer = UI.make("Frame", {
			Size = UDim2.new(0, 6, 0.8, 0),
			Position = UDim2.fromScale(0, 0.1),
			BorderSizePixel = 0,
			BackgroundColor3 = UI.colors.white,
			ZIndex = 2,
		}, UI.board)
		if not state.watching then
			UI.button(UI.controls, Strings.Stop, UDim2.fromScale(1, 1), nil, function()
				input("Stop")
			end, UI.colors.mint)
		end
	elseif c.kind == "Rain" then
		visuals.items = {}
		for lane = 1, 4 do
			UI.make("Frame", {
				Size = UDim2.new(0, 1, 1, 0),
				Position = UDim2.fromScale((lane - 1) / 4, 0),
				BackgroundColor3 = UI.colors.muted,
				BackgroundTransparency = 0.7,
				BorderSizePixel = 0,
			}, UI.board)
			if not state.watching then
				UI.button(
					UI.controls,
					tostring(lane),
					UDim2.new(0.25, -4, 1, 0),
					UDim2.fromScale((lane - 1) / 4, 0),
					function()
						input("Lane", lane)
					end
				)
			end
		end
		for index, item in ipairs(c.items) do
			local dot = UI.make("Frame", {
				Size = UDim2.fromOffset(22, 22),
				AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundColor3 = if item.good then UI.colors.gold else UI.colors.red,
				BorderSizePixel = 0,
			}, UI.board)
			UI.round(dot, if item.good then 12 else 2)
			UI.label(dot, if item.good then "$" else "×", UDim2.fromScale(1, 1), nil, 17, UI.colors.bg).TextXAlignment =
				Enum.TextXAlignment.Center
			visuals.items[index] = dot
		end
		visuals.catcher = UI.make("Frame", {
			Size = UDim2.new(0.2, 0, 0, 12),
			AnchorPoint = Vector2.new(0.5, 0),
			BackgroundColor3 = UI.colors.mint,
			BorderSizePixel = 0,
		}, UI.board)
		UI.round(visuals.catcher, 6)
	else
		visuals.tiles = {}
		for cell = 1, 16 do
			local tile = UI.make("Frame", {
				Size = UDim2.new(0.25, -4, 0.25, -4),
				Position = UDim2.new((cell - 1) % 4 / 4, 2, math.floor((cell - 1) / 4) / 4, 2),
				BackgroundColor3 = UI.colors.mint,
				BorderSizePixel = 0,
			}, UI.board)
			UI.round(tile, 5)
			visuals.tiles[cell] = tile
		end
		visuals.avatar = UI.label(UI.board, "●", UDim2.fromScale(0.25, 0.25), nil, 23, UI.colors.bg)
		visuals.avatar.TextXAlignment, visuals.avatar.ZIndex = Enum.TextXAlignment.Center, 3
		if not state.watching then
			for i, direction in ipairs({ "Left", "Up", "Down", "Right" }) do
				UI.button(
					UI.controls,
					({ "←", "↑", "↓", "→" })[i],
					UDim2.new(0.25, -4, 1, 0),
					UDim2.fromScale((i - 1) / 4, 0),
					function()
						input("Move", direction)
					end
				)
			end
			savedCameraType = workspace.CurrentCamera.CameraType
			workspace.CurrentCamera.CameraType = Enum.CameraType.Scriptable
			local center = c.origin + Vector3.new(7.5, 0, 7.5)
			workspace.CurrentCamera.CFrame = CFrame.lookAt(center + Vector3.new(0, 30, -23), center)
		end
	end
	if state.watching then
		UI.button(UI.controls, Strings.Social, UDim2.fromScale(1, 1), nil, function()
			renderPanel("Social")
		end, UI.colors.mint)
	end
end

local function updateState(nextState)
	state = nextState
	local p, s = state.profile, state.session
	UI.stats.Text = string.format(Strings.Stats, p.money, p.subscribers, p.views)
	UI.primary.Text = if state.watching then Strings.Social elseif s then Strings.EndStream else Strings.GoLive
	UI.test.Text = if state.testMode then Strings.TestMode else ""
	local cheapest, category = math.huge, nil
	for _, key in ipairs({ "PC", "Microphone", "Camera" }) do
		local price = Domain.price(p, key)
		if price and price < cheapest then
			cheapest, category = price, key
		end
	end
	UI.goal.Text = if state.watching
		then string.format(Strings.Watch, state.watchName)
		elseif category then string.format(Strings.Goal, Strings[category], cheapest)
		else Strings.Maxed
	UI.game.Visible = s ~= nil
	UI.chat.Visible = not (UI.compact and s ~= nil)
	local c = s and s.challenge
	local key = (if c then c.id elseif s then "break:" .. tostring(s.nextAt) else "idle")
		.. tostring(state.watching)
	if key ~= boardKey then
		boardKey = key
		buildBoard(c)
	end
	local signature = tostring(p.money)
		.. ":"
		.. tostring(#p.videos)
		.. ":"
		.. tostring(p.upgrades.PC)
		.. tostring(p.upgrades.Microphone)
		.. tostring(p.upgrades.Camera)
	if signature ~= lastPanelSignature then
		lastPanelSignature = signature
		if UI.panelKind == "Gear" or UI.panelKind == "Videos" then
			renderPanel(UI.panelKind)
		end
	end
end

event.OnClientEvent:Connect(function(kind, payload)
	if kind == "State" then
		updateState(payload)
	elseif kind == "Arrival" then
		restoreCamera()
		workspace.CurrentCamera.CFrame =
			CFrame.lookAt(payload + Vector3.new(0, 8, -5), payload + Vector3.new(0, 2, 5))
	elseif kind == "Directory" then
		directory = payload
	elseif kind == "Toast" then
		UI.toast(payload)
	elseif kind == "Panel" then
		renderPanel(payload)
	elseif kind == "Chat" then
		UI.chat.Text = payload
	elseif kind == "Reaction" then
		UI.chat.Text = string.format(Strings.Reaction, payload.name, Strings.Reactions[payload.index])
		UI.toast(Strings.Reactions[payload.index])
	elseif kind == "Reward" then
		local reward = payload.reward
		UI.toast(
			(if payload.success then Strings.Success else Strings.Miss)
				.. "\n"
				.. string.format(Strings.Reward, reward.money, reward.views, reward.subscribers),
			payload.success
		)
	elseif kind == "Report" then
		restoreCamera()
		UI.openPanel(Strings.Report)
		UI.panelKind = nil
		local r = payload.report
		UI.row(
			string.format(
				Strings.ReportStats,
				r.views,
				r.subscribers,
				r.money,
				r.donations,
				r.successes,
				r.challenges
			),
			110
		)
		UI.row(
			if payload.video
				then string.format(Strings.Published, Strings[payload.video.tier])
				else Strings.TooShort,
			74,
			UI.colors.gold
		)
		if state then
			UI.row(oddsText(state.profile), 90, UI.colors.muted)
		end
		UI.rowButton(Strings.Gear, function()
			renderPanel("Gear")
		end, UI.colors.mint)
	elseif kind == "Welcome" and (payload.money > 0 or payload.views > 0) then
		UI.openPanel(Strings.Welcome)
		UI.panelKind = nil
		UI.row(string.format(Strings.Offline, payload.money, payload.views), 140, UI.colors.gold)
		UI.rowButton(Strings.GoLive, function()
			UI.closePanel()
			send("Start")
		end, UI.colors.mint)
	end
end)

UserInputService.InputBegan:Connect(function(key, processed)
	if processed or UserInputService:GetFocusedTextBox() or UI.overlay.Visible then
		return
	end
	local c = state and state.session and state.session.challenge
	if not c or state.watching then
		return
	end
	if c.kind == "Timing" and key.KeyCode == Enum.KeyCode.Space then
		input("Stop")
	else
		local direction = ({
			[Enum.KeyCode.A] = "Left",
			[Enum.KeyCode.Left] = "Left",
			[Enum.KeyCode.D] = "Right",
			[Enum.KeyCode.Right] = "Right",
			[Enum.KeyCode.W] = "Up",
			[Enum.KeyCode.Up] = "Up",
			[Enum.KeyCode.S] = "Down",
			[Enum.KeyCode.Down] = "Down",
		})[key.KeyCode]
		if direction then
			if c.kind == "Fall" then
				input("Move", direction)
			elseif c.kind == "Rain" and (direction == "Left" or direction == "Right") then
				input("Lane", math.clamp(c.lane + (if direction == "Left" then -1 else 1), 1, 4))
			end
		end
	end
end)

RunService.RenderStepped:Connect(function()
	local s = state and state.session
	if not s then
		return
	end
	local now, c = workspace:GetServerTimeNow(), s.challenge
	if not c then
		UI.title.Text =
			string.format(Strings.StreamStats, math.max(0, math.ceil(s.endsAt - now)), s.viewers, s.combo)
		UI.help.Text = if state.watching then Strings.Vote else Strings.Subtitle
		if visuals.breakText then
			local ballots = {}
			for _, choice in ipairs(s.choices) do
				table.insert(ballots, string.format(Strings.VoteCount, Strings[choice], s.votes[choice] or 0))
			end
			visuals.breakText.Text = string.format(Strings.Break, math.max(0, math.ceil(s.nextAt - now)))
				.. "\n"
				.. table.concat(ballots, "  ·  ")
		end
		return
	end
	UI.title.Text = string.format(Strings.ChallengeTime, Strings[c.kind], math.max(0, c.endsAt - now))
	UI.help.Text = if now < c.startsAt then Strings.Waiting else Strings[c.kind .. "Help"]
	if c.kind == "Timing" and visuals.pointer then
		local pointerTime = if stoppedId == c.id then stoppedAt else now
		visuals.pointer.Position = UDim2.new(Rules.slider(pointerTime - c.startsAt), -3, 0.1, 0)
	elseif c.kind == "Rain" and visuals.items then
		for index, item in ipairs(c.items) do
			local fraction = (now - (item.at - 2)) / 2
			local dot = visuals.items[index]
			dot.Visible = fraction >= 0 and fraction <= 1 and not item.done
			dot.Position = UDim2.fromScale((item.lane - 0.5) / 4, fraction * 0.8)
		end
		visuals.catcher.Position = UDim2.fromScale((c.lane - 0.5) / 4, 0.8)
	elseif c.kind == "Fall" and visuals.tiles then
		for cell, tile in ipairs(visuals.tiles) do
			tile.BackgroundColor3 = if c.danger[cell] then UI.colors.red else UI.colors.mint
			tile.BackgroundTransparency = if c.collapsed[cell]
				then 1
				elseif c.danger[cell] then 0.2 + math.abs(math.sin(now * 10)) * 0.4
				else 0
		end
		visuals.avatar.Position = UDim2.fromScale((c.cell - 1) % 4 / 4, math.floor((c.cell - 1) / 4) / 4)
	end
end)

task.spawn(function()
	while not state do
		send("Ready")
		task.wait(1.2)
	end
	-- A final handshake delivers a welcome that may have been queued after the initial state.
	task.wait(1.2)
	send("Ready")
end)
