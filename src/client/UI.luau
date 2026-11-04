--!nonstrict
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Strings = require(Shared.Strings)
local UI = {}
UI.colors = {
	bg = Color3.fromRGB(20, 24, 39),
	card = Color3.fromRGB(34, 41, 61),
	muted = Color3.fromRGB(174, 185, 204),
	white = Color3.fromRGB(245, 248, 255),
	mint = Color3.fromRGB(98, 255, 194),
	red = Color3.fromRGB(255, 111, 137),
	gold = Color3.fromRGB(255, 211, 98),
}
local colors = UI.colors

function UI.make(class, props, parent)
	local instance = Instance.new(class)
	for key, value in pairs(props) do
		instance[key] = value
	end
	instance.Parent = parent
	return instance
end
function UI.round(object, radius)
	UI.make("UICorner", { CornerRadius = UDim.new(0, radius or 12) }, object)
end
function UI.label(parent, text, size, position, fontSize, color)
	return UI.make("TextLabel", {
		Size = size,
		Position = position or UDim2.new(),
		BackgroundTransparency = 1,
		Text = text,
		TextColor3 = color or colors.white,
		TextSize = fontSize or 16,
		Font = Enum.Font.GothamMedium,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
	}, parent)
end
function UI.button(parent, text, size, position, callback, color)
	local b = UI.make("TextButton", {
		Size = size,
		Position = position or UDim2.new(),
		BackgroundColor3 = color or colors.card,
		Text = text,
		TextColor3 = if color == colors.mint then colors.bg else colors.white,
		TextSize = 15,
		Font = Enum.Font.GothamBold,
		TextWrapped = true,
		AutoButtonColor = true,
	}, parent)
	UI.round(b, 10)
	if callback then
		b.Activated:Connect(callback)
	end
	return b
end
function UI.card(parent, size, position)
	local f = UI.make(
		"Frame",
		{ Size = size, Position = position or UDim2.new(), BackgroundColor3 = colors.bg, BorderSizePixel = 0 },
		parent
	)
	UI.round(f)
	UI.make("UIStroke", { Color = colors.card, Thickness = 1.5 }, f)
	return f
end

function UI.build(send)
	local gui = UI.make("ScreenGui", {
		Name = "ViralCityUI",
		ResetOnSpawn = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		DisplayOrder = 10,
	}, Players.LocalPlayer:WaitForChild("PlayerGui"))
	UI.gui = gui
	local header = UI.card(gui, UDim2.new(1, -24, 0, 80), UDim2.fromOffset(12, 8))
	UI.label(header, Strings.Title, UDim2.new(1, -24, 0, 19), UDim2.fromOffset(12, 5), 14, colors.mint)
	UI.stats = UI.label(header, Strings.Loading, UDim2.new(1, -24, 0, 25), UDim2.fromOffset(12, 25), 16)
	UI.goal = UI.label(
		header,
		Strings.Subtitle,
		UDim2.new(1, -24, 0, 22),
		UDim2.fromOffset(12, 51),
		12,
		colors.muted
	)
	UI.test = UI.label(gui, "", UDim2.new(1, -24, 0, 16), UDim2.new(0, 12, 1, -76), 10, colors.gold)
	UI.test.TextXAlignment = Enum.TextXAlignment.Center
	local footer = UI.make(
		"Frame",
		{ Size = UDim2.new(1, -24, 0, 50), Position = UDim2.new(0, 12, 1, -58), BackgroundTransparency = 1 },
		gui
	)
	UI.button(footer, Strings.Menu, UDim2.new(0.23, -4, 1, 0), UDim2.new(), function()
		UI.showMenu()
	end)
	UI.primary = UI.button(
		footer,
		Strings.Locked,
		UDim2.new(0.54, -8, 1, 0),
		UDim2.new(0.23, 4, 0, 0),
		function()
			if UI.onPrimary then
				UI.onPrimary()
			end
		end,
		colors.mint
	)
	UI.button(footer, Strings.Home, UDim2.new(0.23, -4, 1, 0), UDim2.new(0.77, 4, 0, 0), function()
		send("Home")
		UI.closePanel()
	end)
	UI.game = UI.card(gui, UDim2.new(1, -24, 0, 300), UDim2.fromOffset(12, 98))
	UI.game.Visible = false
	UI.title = UI.label(UI.game, "", UDim2.new(1, -24, 0, 25), UDim2.fromOffset(12, 8), 17, colors.mint)
	UI.help = UI.label(UI.game, "", UDim2.new(1, -24, 0, 32), UDim2.fromOffset(12, 34), 12, colors.muted)
	UI.board = UI.make("Frame", {
		Size = UDim2.new(1, -24, 1, -126),
		Position = UDim2.fromOffset(12, 68),
		BackgroundColor3 = colors.card,
		BorderSizePixel = 0,
		ClipsDescendants = true,
	}, UI.game)
	UI.round(UI.board, 8)
	UI.controls = UI.make(
		"Frame",
		{ Size = UDim2.new(1, -24, 0, 46), Position = UDim2.new(0, 12, 1, -54), BackgroundTransparency = 1 },
		UI.game
	)
	UI.chat =
		UI.label(gui, Strings.Ready, UDim2.new(1, -32, 0, 36), UDim2.new(0, 16, 1, -116), 13, colors.white)
	UI.chat.TextXAlignment = Enum.TextXAlignment.Center
	UI.overlay = UI.make("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.new(),
		BackgroundTransparency = 0.25,
		Visible = false,
		ZIndex = 5,
		Active = true,
	}, gui)
	UI.panel = UI.card(UI.overlay, UDim2.new(1, -24, 1, -28), UDim2.fromOffset(12, 14))
	UI.panelTitle =
		UI.label(UI.panel, "", UDim2.new(1, -126, 0, 44), UDim2.fromOffset(16, 8), 19, colors.mint)
	UI.button(UI.panel, Strings.Close, UDim2.fromOffset(90, 44), UDim2.new(1, -102, 0, 8), UI.closePanel)
	UI.content = UI.make("ScrollingFrame", {
		Size = UDim2.new(1, -24, 1, -72),
		Position = UDim2.fromOffset(12, 62),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 4,
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
	}, UI.panel)
	UI.make("UIListLayout", { Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder }, UI.content)
	UI.toastLabel = UI.label(gui, "", UDim2.new(1, -48, 0, 58), UDim2.fromOffset(24, 96), 17, colors.gold)
	UI.toastLabel.TextXAlignment, UI.toastLabel.ZIndex, UI.toastLabel.Visible =
		Enum.TextXAlignment.Center, 20, false
	local sound = UI.make("Sound", { SoundId = "rbxasset://sounds/volume_slider.ogg", Volume = 0.3 }, gui)
	UI.sound = sound
	local function resize()
		local size = gui.AbsoluteSize
		UI.compact = size.Y < 500
		header.Size = UDim2.new(1, -24, 0, if UI.compact then 60 else 80)
		UI.goal.Visible = not UI.compact
		UI.test.Visible = not UI.compact
		local width = math.min(600, size.X - 24)
		UI.game.Size = UDim2.fromOffset(width, math.min(330, size.Y - (if UI.compact then 144 else 216)))
		UI.game.Position = UDim2.new(0.5, -width / 2, 0, if UI.compact then 76 else 98)
		local panelWidth = math.min(560, size.X - 24)
		UI.panel.Size = UDim2.new(0, panelWidth, 1, -28)
		UI.panel.Position = UDim2.new(0.5, -panelWidth / 2, 0, 14)
	end
	gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(resize)
	resize()
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
end
function UI.closePanel()
	if UI.overlay then
		UI.overlay.Visible = false
		UI.panelKind = nil
	end
end
function UI.row(text, height, color)
	local row = UI.label(UI.content, text, UDim2.new(1, -8, 0, height or 64), nil, 15, color)
	return row
end
function UI.rowButton(text, callback, color)
	return UI.button(UI.content, text, UDim2.new(1, -8, 0, 64), nil, callback, color)
end
function UI.toast(text, success)
	UI.toastSerial = (UI.toastSerial or 0) + 1
	local serial = UI.toastSerial
	UI.toastLabel.Text, UI.toastLabel.Visible, UI.toastLabel.TextTransparency = text, true, 0
	UI.toastLabel.TextStrokeTransparency, UI.toastLabel.TextStrokeColor3 = 0.25, colors.bg
	UI.sound.PlaybackSpeed = if success == false then 0.8 else 1.15
	UI.sound:Play()
	TweenService:Create(UI.toastLabel, TweenInfo.new(0.22, Enum.EasingStyle.Back), { TextSize = 19 }):Play()
	task.delay(2.5, function()
		if UI.toastSerial == serial then
			UI.toastLabel.Visible = false
		end
	end)
end
return UI
