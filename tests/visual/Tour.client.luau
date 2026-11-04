--!nonstrict
assert(game:GetService("RunService"):IsStudio())
local Players = game:GetService("Players")
local Run = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local Stats = game:GetService("Stats")
local Http = game:GetService("HttpService")
local remote = game.ReplicatedStorage:WaitForChild("VisualTour")
local player = Players.LocalPlayer
local UI = require(player.PlayerScripts:WaitForChild("Client"):WaitForChild("UI"))
while not UI.gui do
	task.wait(0.2)
end
local camera, shot = nil, "Loading"
local labelGui = Instance.new("ScreenGui")
labelGui.Name, labelGui.DisplayOrder, labelGui.Parent = "VisualFixtureLabel", 100, player.PlayerGui
local label = Instance.new("TextLabel")
label.Size, label.Position = UDim2.new(1, 0, 0, 18), UDim2.new(0, 0, 1, -18)
label.BackgroundColor3, label.TextColor3 = Color3.fromRGB(20, 35, 40), Color3.new(1, 1, 1)
label.TextSize, label.Parent = 10, labelGui
remote.OnClientEvent:Connect(function(data)
	camera, shot = data.camera, data.name
	UI.closePanel()
	UI.gui.Enabled = not data.hide
	label.Text = "STAGED VISUAL FIXTURE | " .. shot .. " | N next / B back / P 30s metrics"
end)
local measuring, frames, elapsed, worst, samples, began = false, 0, 0, 0, {}, 0
UIS.InputBegan:Connect(function(input, processed)
	if UIS:GetFocusedTextBox() then
		return
	end
	if input.KeyCode == Enum.KeyCode.N then
		remote:FireServer("Next")
	elseif input.KeyCode == Enum.KeyCode.B then
		remote:FireServer("Previous")
	elseif input.KeyCode == Enum.KeyCode.P and not measuring then
		measuring, frames, elapsed, worst, samples, began = true, 0, 0, 0, {}, os.clock()
		print("VISUAL_METRICS_BEGIN " .. shot)
	end
end)
Run:BindToRenderStep("VisualTourCamera", Enum.RenderPriority.Camera.Value + 1, function(dt)
	if camera then
		workspace.CurrentCamera.CameraType = Enum.CameraType.Scriptable
		workspace.CurrentCamera.CFrame = camera
	end
	if not measuring then
		return
	end
	frames += 1
	elapsed += dt
	worst = math.max(worst, dt * 1000)
	if elapsed >= 1 then
		table.insert(samples, {
			fps = frames / elapsed,
			memoryMB = Stats:GetTotalMemoryUsageMb(),
			sendKbps = Stats.DataSendKbps,
			receiveKbps = Stats.DataReceiveKbps,
		})
		frames, elapsed = 0, 0
	end
	if os.clock() - began >= 30 then
		measuring = false
		local parts, lights, emitters = 0, 0, 0
		for _, child in ipairs(workspace:GetDescendants()) do
			if child:IsA("BasePart") then
				parts += 1
			elseif child:IsA("Light") then
				lights += 1
			elseif child:IsA("ParticleEmitter") then
				emitters += 1
			end
		end
		local minFPS, sumFPS, sumMB, maxMB, send, receive = math.huge, 0, 0, 0, 0, 0
		for _, sample in ipairs(samples) do
			minFPS = math.min(minFPS, sample.fps)
			sumFPS += sample.fps
			sumMB += sample.memoryMB
			maxMB = math.max(maxMB, sample.memoryMB)
			send += sample.sendKbps
			receive += sample.receiveKbps
		end
		print("VISUAL_METRICS " .. Http:JSONEncode({
			scene = shot,
			seconds = os.clock() - began,
			samples = #samples,
			meanFPS = sumFPS / #samples,
			minFPS = minFPS,
			worstFrameMs = worst,
			meanMemoryMB = sumMB / #samples,
			maxMemoryMB = maxMB,
			meanSendKbps = send / #samples,
			meanReceiveKbps = receive / #samples,
			parts = parts,
			lights = lights,
			emitters = emitters,
			viewport = tostring(workspace.CurrentCamera.ViewportSize),
		}))
	end
end)
task.wait(2)
remote:FireServer("Ready")
