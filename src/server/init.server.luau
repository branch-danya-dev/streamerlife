--!nonstrict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Balance)
local Domain = require(Shared.Domain)(Config)
local Rules = require(Shared.Rules)
local Strings = require(Shared.Strings)
local Store = require(script.ProfileStore)
local City = require(script.City)
local Streams = require(script.Streams)
local Social = require(script.Social)
local remotes = Instance.new("Folder")
remotes.Name, remotes.Parent = "Remotes", ReplicatedStorage
local action = Instance.new("RemoteEvent")
action.Name, action.Parent = "Action", remotes
local event = Instance.new("RemoteEvent")
event.Name, event.Parent = "Event", remotes
local limits, loading = {}, {}

local function emit(player, kind, payload)
	if player.Parent == Players then
		event:FireClient(player, kind, payload)
	end
end
Streams.emit = emit
City.onArrival = function(player, position)
	emit(player, "Arrival", position)
end
local function toast(player, key)
	emit(player, "Toast", Strings[key])
end

local function snapshot(player)
	local profile = Store.get(player)
	if not profile then
		return
	end
	local owner = Social.owner(player)
	emit(player, "State", {
		profile = profile,
		session = Streams.public(owner or player),
		watching = owner and owner.UserId,
		watchName = owner and owner.DisplayName,
		testMode = Store.testMode,
		inStudio = City.inside(player, player),
		room = City.owners[player].index,
	})
end

City.build(function(player, index)
	local owner = City.rooms[index].owner
	if owner then
		Social.visit(player, owner)
	else
		toast(player, "Unavailable")
	end
end, function(player)
	emit(player, "Panel", "Gear")
end, function(player)
	emit(player, "Panel", "Live")
end, function(player)
	toast(player, "StageToast")
end)

local function onPlayer(player)
	if loading[player] or Store.records[player] then
		return
	end
	loading[player] = true
	local ok, profile, welcome = pcall(Store.load, player)
	loading[player] = nil
	if not ok or not profile then
		if player.Parent then
			player:Kick(Strings.LoadFailed)
		end
		return
	end
	local room = City.claim(player)
	if not room then
		player:Kick(Strings.ServerFull)
		Store.save(player, true)
		return
	end
	City.updateEquipment(player, profile)
	local function spawnCharacter(character)
		local root = character:WaitForChild("HumanoidRootPart", 10)
		-- Roblox finishes spawn placement after the root is inserted.
		task.wait(0.5)
		if root and player.Parent and City.owners[player] then
			City.home(player)
			Social.watching[player] = nil
		end
	end
	player.CharacterAdded:Connect(spawnCharacter)
	if player.Character then
		task.spawn(spawnCharacter, player.Character)
	end
	-- Welcome is held until the client's Ready handshake; loading can finish before its listener exists.
	Store.records[player].welcome = welcome
	snapshot(player)
end

local handlers = {}
function handlers.Ready(player)
	snapshot(player)
	local record = Store.records[player]
	if record and record.welcome then
		emit(player, "Welcome", record.welcome)
		record.welcome = nil
	end
end
function handlers.Start(player)
	local ok, reason = Streams.start(player, workspace:GetServerTimeNow())
	if not ok then
		toast(player, reason)
	else
		Social.watching[player] = nil
	end
end
function handlers.Finish(player)
	Streams.finish(player, workspace:GetServerTimeNow(), true)
end
function handlers.Input(player, data)
	Streams.input(player, data, workspace:GetServerTimeNow())
end
function handlers.Buy(player, data)
	if type(data.category) ~= "string" or not Config.Costs[data.category] then
		return
	end
	if Streams.active[player] then
		toast(player, "Busy")
		return
	end
	local p = Store.get(player)
	if p and Domain.buy(p, data.category) then
		City.updateEquipment(player, p)
		toast(player, "Bought")
	else
		toast(player, "NoMoney")
	end
end
function handlers.Home(player)
	if Streams.active[player] then
		toast(player, "Busy")
		return
	end
	Social.watching[player] = nil
	City.home(player)
end
function handlers.City(player)
	if Streams.active[player] then
		toast(player, "Busy")
		return
	end
	Social.watching[player] = nil
	City.teleport(player, Vector3.new(0, 4, 10))
end
function handlers.Visit(player, data)
	if not Rules.integer(data.userId, -1_000_000, 9_007_199_254_740_991) then
		return
	end
	local owner = Players:GetPlayerByUserId(data.userId)
	if not owner or not Social.visit(player, owner) then
		toast(player, "Unavailable")
	end
end
function handlers.React(player, data)
	Social.react(player, data.index, workspace:GetServerTimeNow())
end
function handlers.Vote(player, data)
	Social.vote(player, data.choice)
end

action.OnServerEvent:Connect(function(player, verb, data)
	if type(verb) ~= "string" or #verb > 16 or not handlers[verb] or type(data) ~= "table" then
		return
	end
	if not Store.get(player) then
		return
	end
	local now = os.clock()
	local limit = limits[player] or { tokens = 20, at = now, actions = {} }
	limits[player] = limit
	limit.tokens = math.min(20, limit.tokens + (now - limit.at) * 12)
	limit.at = now
	if limit.tokens < 1 then
		return
	end
	limit.tokens -= 1
	local gap = if verb == "Input" then 0.04 elseif verb == "Ready" then 1 else 0.3
	if not Rules.allowed(limit.actions[verb], now, gap) then
		return
	end
	limit.actions[verb] = now
	local ok, err = pcall(handlers[verb], player, data)
	if not ok then
		warn("Action handler failed:", verb, err)
	end
end)

Players.PlayerAdded:Connect(onPlayer)
Players.PlayerRemoving:Connect(function(player)
	Streams.finish(player, workspace:GetServerTimeNow(), false)
	Social.remove(player)
	City.release(player)
	limits[player], Streams.cooldown[player] = nil, nil
	Store.save(player, true)
end)
Store.beforeClose = function()
	for player in pairs(Streams.active) do
		Streams.finish(player, workspace:GetServerTimeNow(), false)
	end
end
Store.start()
for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(onPlayer, player)
end

task.spawn(function()
	local lastState, lastDirectory = 0, 0
	while not Store.closing do
		local now = workspace:GetServerTimeNow()
		for player in pairs(Streams.active) do
			Streams.tick(player, now)
		end
		if now - lastState >= 0.2 then
			lastState = now
			for _, player in ipairs(Players:GetPlayers()) do
				snapshot(player)
			end
		end
		if now - lastDirectory >= 1 then
			lastDirectory = now
			local directory, boardLines = {}, { Strings.Board }
			for _, room in ipairs(City.rooms) do
				local owner = room.owner
				if owner and Store.get(owner) then
					local stream = Streams.public(owner)
					table.insert(directory, {
						userId = owner.UserId,
						name = owner.DisplayName,
						live = stream ~= nil,
						room = room.index,
						viewers = if stream then stream.viewers else 0,
					})
					room.sign.Text = string.format(Strings.StudioOwner, owner.DisplayName)
						.. (
							if stream
								then "\n" .. Strings.LiveBadge .. " · " .. tostring(stream.viewers)
								else ""
						)
					if stream then
						table.insert(boardLines, owner.DisplayName .. " · " .. tostring(stream.viewers))
					end
				end
			end
			if #boardLines == 1 then
				table.insert(boardLines, Strings.NoLive)
			end
			City.board.Text = table.concat(boardLines, "\n")
			event:FireAllClients("Directory", directory)
		end
		for player, record in pairs(Store.records) do
			if not record.closing and os.time() >= record.expires - 10 then
				record.closing = true
				player:Kick(Strings.LeaseLost)
			end
		end
		task.wait(0.05)
	end
end)
