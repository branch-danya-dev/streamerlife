--!nonstrict
local Players = game:GetService("Players")
local Tween = game:GetService("TweenService")
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Strings = require(Shared.Strings)
local T = require(Shared.Theme)(Color3.fromRGB)
local Feedback = require(script.Parent.Feedback)
local layout = require(Shared.Layout)
local UI = { feedback = Feedback }
UI.colors =
	{ bg = T.ink, card = T.cream, muted = T.muted, white = T.ink, mint = T.mint, red = T.red, gold = T.gold }
function UI.make(class, props, parent)
	local object = Instance.new(class)
	for key, value in pairs(props) do
		object[key] = value
	end
	object.Parent = parent
	return object
end
function UI.round(object, radius)
	UI.make("UICorner", { CornerRadius = UDim.new(0, radius or 14) }, object)
end
function UI.label(parent, text, size, position, fontSize, color)
	return UI.make("TextLabel", {
		Size = size,
		Position = position or UDim2.new(),
		BackgroundTransparency = 1,
		Text = text,
		TextColor3 = color or T.ink,
		TextSize = fontSize or 16,
		Font = Enum.Font.GothamMedium,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
	}, parent)
end
function UI.button(parent, text, size, position, callback, color)
	local bg = color or T.cream
	local b = UI.make("TextButton", {
		Size = size,
		Position = position or UDim2.new(),
		BackgroundColor3 = bg,
		BorderSizePixel = 0,
		Text = text,
		TextColor3 = if bg == T.ink then T.cream else T.ink,
		TextSize = 14,
		Font = Enum.Font.GothamBold,
		TextWrapped = true,
		AutoButtonColor = false,
	}, parent)
	UI.round(b, 12)
	UI.make("UIStroke", { Color = T.ink, Transparency = 0.88, Thickness = 1 }, b)
	b.MouseEnter:Connect(function()
		Tween:Create(b, TweenInfo.new(0.12), { BackgroundColor3 = bg:Lerp(T.white, 0.16) }):Play()
	end)
	b.MouseLeave:Connect(function()
		Tween:Create(b, TweenInfo.new(0.12), { BackgroundColor3 = bg }):Play()
	end)
	b.Activated:Connect(function()
		Feedback.cue("tap")
		Feedback.pulse(b, 0.97)
		if callback then
			callback()
		end
	end)
	return b
end
function UI.card(parent, size, position)
	local f = UI.make(
		"Frame",
		{ Size = size, Position = position or UDim2.new(), BackgroundColor3 = T.paper, BorderSizePixel = 0 },
		parent
	)
	UI.round(f, 16)
	UI.make("UIStroke", { Color = T.ink, Transparency = 0.82, Thickness = 1 }, f)
	return f
end
local function short(value)
	if value >= 1000000 then
		return string.format("%.1fm", value / 1000000)
	elseif value >= 10000 then
		return string.format("%.1fk", value / 1000)
	end
	return tostring(value)
end
function UI.setStats(p)
	UI.money.Text, UI.subscribers.Text, UI.views.Text =
		"$" .. short(p.money), short(p.subscribers), short(p.views)
end
function UI.setSession(s, watchName)
	UI.liveBadge.Visible = s ~= nil and (UI.headerWidth or 400) >= 280
	UI.liveBadge.Text = if watchName then "● WATCHING" else "● LIVE"
	UI.primary.BackgroundColor3 = if s and not watchName then T.coral else T.mint
	if s and UI.sessionId ~= s.id then
		Feedback.cue("start")
		Feedback.pulse(UI.primary)
	end
	UI.sessionId = s and s.id
end
function UI.build(send)
	local gui = UI.make("ScreenGui", {
		Name = "ViralCityUI",
		ResetOnSpawn = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		DisplayOrder = 10,
	}, Players.LocalPlayer:WaitForChild("PlayerGui"))
	UI.gui = gui
	local header = UI.card(gui, UDim2.fromOffset(450, 86), UDim2.fromOffset(12, 8))
	UI.header = header
	UI.label(
		header,
		"VIRAL CITY  /  CREATOR DESK",
		UDim2.new(1, -110, 0, 18),
		UDim2.fromOffset(14, 7),
		10,
		T.muted
	)
	UI.liveBadge = UI.label(header, "● LIVE", UDim2.fromOffset(94, 18), UDim2.new(1, -103, 0, 7), 11, T.red)
	UI.liveBadge.Font, UI.liveBadge.Visible = Enum.Font.GothamBold, false
	for i, entry in ipairs({ { "money", "CASH" }, { "subscribers", "SUBSCRIBERS" }, { "views", "VIEWS" } }) do
		local box = UI.make("Frame", {
			BackgroundTransparency = 1,
			Size = UDim2.new(1 / 3, -12, 0, 47),
			Position = UDim2.new((i - 1) / 3, 12, 0, 26),
		}, header)
		UI[entry[1]] = UI.label(box, "0", UDim2.new(1, 0, 0, 27), nil, if i == 1 then 27 else 23, T.ink)
		UI[entry[1]].Font = Enum.Font.GothamBold
		UI.label(box, entry[2], UDim2.new(1, 0, 0, 14), UDim2.fromOffset(0, 30), 9, T.muted)
	end
	UI.goal = UI.label(gui, Strings.Subtitle, UDim2.fromOffset(450, 28), UDim2.fromOffset(16, 98), 11, T.ink)
	UI.goal.TextStrokeTransparency, UI.goal.TextStrokeColor3 = 0.65, T.paper
	local footer = UI.make(
		"Frame",
		{ Size = UDim2.new(1, -24, 0, 50), Position = UDim2.new(0, 12, 1, -58), BackgroundTransparency = 1 },
		gui
	)
	UI.footer = footer
	UI.button(footer, Strings.Menu, UDim2.new(0.22, -4, 1, 0), nil, function()
		UI.showMenu()
	end)
	UI.primary = UI.button(
		footer,
		Strings.Locked,
		UDim2.new(0.56, -8, 1, 0),
		UDim2.new(0.22, 4, 0, 0),
		function()
			if UI.onPrimary then
				UI.onPrimary()
			end
		end,
		T.mint
	)
	UI.button(footer, Strings.Home, UDim2.new(0.22, -4, 1, 0), UDim2.new(0.78, 4, 0, 0), function()
		send("Home")
		UI.closePanel()
	end)
	UI.test = UI.label(gui, "", UDim2.new(1, -24, 0, 14), UDim2.new(0, 12, 1, -75), 9, T.muted)
	UI.test.TextXAlignment = Enum.TextXAlignment.Center
	UI.game = UI.card(gui, UDim2.fromOffset(360, 285), UDim2.new(1, -372, 0, 110))
	UI.game.Visible = false
	local stripe = UI.make("Frame", {
		Size = UDim2.new(1, -28, 0, 3),
		Position = UDim2.fromOffset(14, 0),
		BackgroundColor3 = T.coral,
		BorderSizePixel = 0,
	}, UI.game)
	UI.round(stripe, 3)
	UI.title = UI.label(UI.game, "", UDim2.new(1, -24, 0, 24), UDim2.fromOffset(12, 10), 16, T.ink)
	UI.title.Font = Enum.Font.GothamBold
	UI.help = UI.label(UI.game, "", UDim2.new(1, -24, 0, 30), UDim2.fromOffset(12, 36), 11, T.muted)
	UI.board = UI.make("Frame", {
		Size = UDim2.new(1, -24, 1, -130),
		Position = UDim2.fromOffset(12, 70),
		BackgroundColor3 = T.cream,
		BorderSizePixel = 0,
		ClipsDescendants = true,
	}, UI.game)
	UI.round(UI.board, 10)
	UI.controls = UI.make(
		"Frame",
		{ Size = UDim2.new(1, -24, 0, 46), Position = UDim2.new(0, 12, 1, -54), BackgroundTransparency = 1 },
		UI.game
	)
	UI.chat = UI.label(gui, Strings.Ready, UDim2.fromOffset(360, 40), UDim2.new(0, 18, 1, -124), 13, T.ink)
	UI.chat.TextStrokeTransparency, UI.chat.TextStrokeColor3 = 0.6, T.paper
	UI.overlay = UI.make("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = T.ink,
		BackgroundTransparency = 0.38,
		Visible = false,
		ZIndex = 5,
		Active = true,
	}, gui)
	UI.panel = UI.card(UI.overlay, UDim2.new(0, 540, 1, -24), UDim2.new(0.5, -270, 0, 12))
	UI.panelTitle = UI.label(UI.panel, "", UDim2.new(1, -126, 0, 42), UDim2.fromOffset(16, 9), 18, T.ink)
	UI.panelTitle.Font = Enum.Font.GothamBold
	UI.button(UI.panel, Strings.Close, UDim2.fromOffset(84, 44), UDim2.new(1, -96, 0, 8), UI.closePanel)
	UI.content = UI.make("ScrollingFrame", {
		Size = UDim2.new(1, -24, 1, -76),
		Position = UDim2.fromOffset(12, 64),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 4,
		ScrollBarImageColor3 = T.mint,
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
	}, UI.panel)
	UI.make("UIListLayout", { Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder }, UI.content)
	UI.make(
		"UIPadding",
		{ PaddingBottom = UDim.new(0, 14), PaddingTop = UDim.new(0, 3), PaddingLeft = UDim.new(0, 3) },
		UI.content
	)
	UI.toastFrame = UI.card(gui, UDim2.fromOffset(400, 66), UDim2.new(0, 12, 1, -200))
	UI.toastFrame.ZIndex, UI.toastFrame.Visible = 20, false
	UI.toastAccent = UI.make("Frame", {
		Size = UDim2.new(0, 4, 1, -20),
		Position = UDim2.fromOffset(10, 10),
		BackgroundColor3 = T.gold,
		BorderSizePixel = 0,
	}, UI.toastFrame)
	UI.round(UI.toastAccent, 4)
	UI.toastLabel = UI.label(UI.toastFrame, "", UDim2.new(1, -36, 1, -12), UDim2.fromOffset(24, 6), 14, T.ink)
	UI.toastLabel.Font = Enum.Font.GothamBold
	local function resize()
		local size = gui.AbsoluteSize
		local l = layout(size.X, size.Y)
		UI.compact, UI.shortPortrait = l.compact, l.shortPortrait
		local function place(object, r)
			object.Position, object.Size = UDim2.fromOffset(r.x, r.y), UDim2.fromOffset(r.w, r.h)
		end
		place(header, l.header)
		place(UI.game, l.game)
		place(UI.toastFrame, l.toast)
		place(UI.footer, l.footer)
		place(UI.chat, l.chat)
		local headerWidth = l.header.w
		UI.liveBadge.Visible = UI.sessionId ~= nil and headerWidth >= 280
		UI.goal.Size = UDim2.fromOffset(headerWidth, 32)
		UI.goal.Visible = not l.compact and not l.shortPortrait
		UI.chat.Visible = not l.compact and not l.shortPortrait
		UI.test.Visible = not l.compact

		local panelWidth = math.min(540, size.X - 24)
		UI.panel.Size = UDim2.new(0, panelWidth, 1, -24)
		UI.panel.Position = UDim2.new(0.5, -panelWidth / 2, 0, 12)
		UI.headerWidth = headerWidth
	end
	gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(resize)
	resize()
	Feedback.init(UI)
end
function UI.clear(parent)
	for _, child in ipairs(parent:GetChildren()) do
		if child:IsA("GuiObject") then
			child:Destroy()
		end
	end
end
function UI.openPanel(title)
	UI.clear(UI.content)
	UI.panelTitle.Text, UI.overlay.Visible = title, true
	UI.content.CanvasPosition = Vector2.zero
	Feedback.pulse(UI.panel, 0.98)
end
function UI.closePanel()
	if UI.overlay then
		UI.overlay.Visible = false
		UI.panelKind = nil
	end
end
function UI.row(text, height, color)
	return UI.label(UI.content, text, UDim2.new(1, -10, 0, height or 64), nil, 14, color)
end
function UI.rowButton(text, callback, color)
	return UI.button(UI.content, text, UDim2.new(1, -10, 0, 60), nil, callback, color)
end
function UI.toast(text, success, silent)
	UI.toastSerial = (UI.toastSerial or 0) + 1
	local serial = UI.toastSerial
	UI.toastLabel.Text, UI.toastFrame.Visible = text, true
	UI.toastAccent.BackgroundColor3 = if success == false then T.coral else T.gold
	Feedback.pulse(UI.toastFrame)
	if not silent then
		Feedback.cue(if success == false then "miss" else "hit")
	end
	task.delay(2.4, function()
		if UI.toastSerial == serial then
			UI.toastFrame.Visible = false
		end
	end)
end
function UI.upgradeRow(category, level, cost, affordable, callback)
	local descriptions = {
		PC = { "Single monitor + tower", "Dual display + speakers", "Triple display + stream deck" },
		Microphone = {
			"Articulated broadcast arm",
			"Pop filter + studio capsule",
			"Shock mount + audio mixer",
		},
		Camera = { "Tripod camera + key light", "Paired softbox lights", "Broadcast rig + backdrop" },
	}
	local b = UI.button(
		UI.content,
		"",
		UDim2.new(1, -10, 0, 108),
		nil,
		callback,
		if affordable then T.mint else T.cream
	)
	UI.label(b, Strings[category], UDim2.new(1, -100, 0, 40), UDim2.fromOffset(12, 7), 13, T.ink).Font =
		Enum.Font.GothamBold
	UI.label(
		b,
		"LEVEL " .. level .. " → " .. (level + 1),
		UDim2.new(1, -24, 0, 16),
		UDim2.fromOffset(12, 47),
		10,
		T.ink
	)
	UI.label(
		b,
		descriptions[category][level + 1],
		UDim2.new(1, -24, 0, 30),
		UDim2.fromOffset(12, 68),
		12,
		T.ink
	)
	local price = UI.label(b, "$" .. cost, UDim2.fromOffset(90, 36), UDim2.new(1, -100, 0, 11), 23, T.ink)
	price.Font, price.TextXAlignment = Enum.Font.GothamBold, Enum.TextXAlignment.Right
	return b
end
function UI.videoRow(video, cap)
	local color = T.rarity[video.tier] or T.mint
	local row = UI.card(UI.content, UDim2.new(1, -10, 0, 103))
	local badge = UI.make("Frame", {
		Size = UDim2.fromOffset(5, 75),
		Position = UDim2.fromOffset(9, 14),
		BackgroundColor3 = color,
		BorderSizePixel = 0,
	}, row)
	UI.round(badge, 4)
	UI.label(
		row,
		string.upper(Strings[video.tier]),
		UDim2.new(1, -32, 0, 27),
		UDim2.fromOffset(22, 8),
		19,
		T.ink
	).Font =
		Enum.Font.GothamBold
	UI.label(
		row,
		short(video.views) .. " views  ·  $" .. video.cashRate .. " / hour",
		UDim2.new(1, -32, 0, 23),
		UDim2.fromOffset(22, 37),
		14,
		T.ink
	)
	UI.label(
		row,
		string.format("%.1f hours of income left", (cap - video.paidSeconds) / 3600),
		UDim2.new(1, -32, 0, 23),
		UDim2.fromOffset(22, 66),
		11,
		T.muted
	)
end
function UI.report(report, video, odds, onGear)
	UI.openPanel(Strings.Report)
	UI.panelKind = nil
	local tier = video and video.tier
	local banner = UI.card(UI.content, UDim2.new(1, -10, 0, 96))
	banner.BackgroundColor3 = if tier then T.rarity[tier] or T.mint else T.cream
	local title = UI.label(
		banner,
		if tier then string.upper(Strings[tier]) .. " RECORDING" else "STREAM WRAPPED",
		UDim2.new(1, -24, 0, 43),
		UDim2.fromOffset(12, 10),
		22,
		T.ink
	)
	title.Font = Enum.Font.GothamBold
	UI.label(
		banner,
		if tier then "Your next audience starts here." else Strings.TooShort,
		UDim2.new(1, -24, 0, 30),
		UDim2.fromOffset(12, 56),
		12,
		T.ink
	)
	local score = UI.card(UI.content, UDim2.new(1, -10, 0, 120))
	UI.label(score, "+$" .. report.money, UDim2.new(1, -24, 0, 49), UDim2.fromOffset(12, 8), 38, T.ink).Font =
		Enum.Font.GothamBold
	UI.label(
		score,
		"EARNED  ·  includes $" .. report.donations .. " donations",
		UDim2.new(1, -24, 0, 23),
		UDim2.fromOffset(12, 58),
		11,
		T.muted
	)
	UI.label(
		score,
		"+" .. report.views .. " views    +" .. report.subscribers .. " subscribers",
		UDim2.new(1, -24, 0, 25),
		UDim2.fromOffset(12, 88),
		14,
		T.ink
	)
	UI.row(report.successes .. " / " .. report.challenges .. " challenges cleared", 34, T.muted)
	UI.rowButton(Strings.Gear, onGear, T.mint)
	UI.row(odds or "", 100, T.muted)
	Feedback.cue(
		if tier == "Legendary"
			then "legendary"
			elseif tier == "Viral" then "viral"
			elseif tier == "Popular" then "hot"
			elseif tier then "normal"
			else "finish"
	)
	Feedback.pulse(banner, 0.93)
	if tier == "Legendary" or tier == "Viral" then
		Feedback.burst(UDim2.new(0.5, 0, 0, 130), T.rarity[tier], if tier == "Legendary" then 20 else 12)
	end
end
function UI.settings()
	UI.openPanel("YOUR COMFORT")
	UI.panelKind = "Settings"
	UI.row("Choose your local sound and visual feedback.", 52, T.muted)
	UI.rowButton("SOUND  ·  " .. math.floor(Feedback.volume * 100) .. "%", function()
		Feedback.setVolume(if Feedback.volume > 0.4 then 0.3 elseif Feedback.volume > 0 then 0 else 0.65)
		UI.settings()
	end, T.mint)
	UI.rowButton("EFFECTS  ·  " .. (if Feedback.reduced then "REDUCED" else "FULL"), function()
		Feedback.setReduced(not Feedback.reduced)
		UI.settings()
	end)
	UI.row(
		"Reduced effects removes confetti and decorative motion, and disables studio accent lights. Game warnings stay visible.",
		110,
		T.muted
	)
end
return UI
