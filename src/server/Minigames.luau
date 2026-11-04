--!nonstrict
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Config = require(Shared.Balance)
local Theme = require(Shared.Theme)(Color3.fromRGB)
local Rules = require(Shared.Rules)
local HttpService = game:GetService("HttpService")
local City = require(script.Parent.City)
local rng = Random.new()
local Minigames = {}

local function placeAvatar(c)
	if c.root and c.root.Parent then
		local x = (c.cell - 1) % 4
		local z = math.floor((c.cell - 1) / 4)
		c.root.CFrame = CFrame.new(c.origin + Vector3.new(x * 5, 4, z * 5))
	end
end

function Minigames.begin(player, kind, now)
	local c = {
		id = HttpService:GenerateGUID(false),
		kind = kind,
		startsAt = now + 0.7,
		endsAt = now + 0.7 + Config.Duration[kind],
		lastInput = -math.huge,
	}
	if kind == "Timing" then
		c.center, c.width = rng:NextNumber(0.25, 0.75), 0.28
		c.inputDelay = Rules.inputDelay(player:GetNetworkPing())
	elseif kind == "Rain" then
		c.lane, c.points, c.possible, c.items = 2, 0, 0, {}
		for i = 1, 10 do
			local good = i % 4 ~= 0
			if good then
				c.possible += 1
			end
			table.insert(c.items, {
				lane = rng:NextInteger(1, 4),
				good = good,
				at = c.startsAt + 2 + (i - 1) * 0.95,
				done = false,
				caught = false,
			})
		end
	else
		local room = City.owners[player]
		local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
		c.cell, c.danger, c.collapsed, c.tiles = 6, {}, {}, {}
		c.origin = room.center + Vector3.new(-7.5, 1, -12)
		c.nextWave = c.startsAt + 0.3
		c.arena = Instance.new("Folder")
		c.arena.Name, c.arena.Parent = "ChallengeArena", room.model
		for cell = 1, 16 do
			local position = c.origin + Vector3.new((cell - 1) % 4 * 5, 0, math.floor((cell - 1) / 4) * 5)
			c.tiles[cell] =
				City.part(c.arena, "Tile" .. cell, Vector3.new(4.6, 0.6, 4.6), position, Theme.mint)
		end
		if root and humanoid and humanoid.Health > 0 then
			c.root, c.humanoid, c.wasAnchored, c.wasAutoRotate =
				root, humanoid, root.Anchored, humanoid.AutoRotate
			humanoid.Sit, humanoid.AutoRotate, root.Anchored = false, false, true
			placeAvatar(c)
		else
			c.score = 0
		end
	end
	return c
end

function Minigames.input(c, verb, value, now)
	local scoredAt = now - (c.inputDelay or 0)
	if c.score ~= nil or scoredAt < c.startsAt or scoredAt >= c.endsAt then
		return
	end
	if not Rules.allowed(c.lastInput, now, if c.kind == "Fall" then 0.18 else 0.1) then
		return
	end
	if c.kind == "Timing" and verb == "Stop" then
		c.score = Rules.timing(scoredAt - c.startsAt, c.center, c.width)
	elseif c.kind == "Rain" and verb == "Lane" and Rules.integer(value, 1, 4) then
		c.lane = value
	elseif c.kind == "Fall" and verb == "Move" and type(value) == "string" then
		local target = Rules.move(c.cell, value, 4)
		if not c.collapsed[target] then
			c.cell = target
			placeAvatar(c)
		end
	else
		return
	end
	c.lastInput = now
end

function Minigames.tick(c, now)
	if c.score ~= nil then
		return c.score
	end
	if now < c.startsAt then
		return nil
	end
	if c.kind == "Rain" then
		for _, item in ipairs(c.items) do
			if not item.done and now >= item.at then
				item.done, item.caught = true, c.lane == item.lane
				if item.caught then
					c.points += if item.good then 1 else -2
				end
			end
		end
	elseif c.kind == "Fall" then
		if not c.root or not c.root.Parent or c.humanoid.Health <= 0 then
			return 0
		end
		if c.resolveAt and now >= c.resolveAt then
			c.collapsed, c.danger = c.danger, {}
			c.resolveAt, c.recoverAt = nil, now + 0.6
			for cell in pairs(c.collapsed) do
				c.tiles[cell].Transparency = 1
			end
			if c.collapsed[c.cell] then
				return math.clamp((now - c.startsAt) / Config.Duration.Fall, 0, 1)
			end
		end
		if c.recoverAt and now >= c.recoverAt then
			c.recoverAt, c.nextWave, c.collapsed = nil, now + 0.2, {}
			for _, tile in ipairs(c.tiles) do
				tile.Transparency, tile.Color = 0, Theme.mint
			end
		end
		if now >= c.nextWave then
			c.nextWave, c.resolveAt, c.danger = math.huge, now + 1.2, {}
			local pool = {}
			for i = 1, 16 do
				table.insert(pool, i)
			end
			for _ = 1, 5 do
				local index = rng:NextInteger(1, #pool)
				c.danger[table.remove(pool, index)] = true
			end
			-- Always leave at least one immediate escape route from the current cell.
			for _, direction in ipairs({ "Left", "Right", "Up", "Down" }) do
				local adjacent = Rules.move(c.cell, direction, 4)
				if adjacent ~= c.cell then
					c.danger[adjacent] = nil
					break
				end
			end
			for cell in pairs(c.danger) do
				c.tiles[cell].Color = Theme.coral
			end
		end
	end
	if now >= c.endsAt + (c.inputDelay or 0) then
		return if c.kind == "Rain"
			then math.clamp(c.points / c.possible, 0, 1)
			elseif c.kind == "Fall" then 1
			else 0
	end
	return nil
end

function Minigames.cleanup(player, c)
	if c.arena then
		c.arena:Destroy()
	end
	if c.root and c.root.Parent then
		c.root.Anchored = c.wasAnchored
	end
	if c.humanoid and c.humanoid.Parent then
		c.humanoid.AutoRotate = c.wasAutoRotate
	end
	if c.kind == "Fall" then
		City.home(player)
	end
end

function Minigames.public(c)
	if not c then
		return nil
	end
	local danger, collapsed = {}, {}
	if c.kind == "Fall" then
		for cell = 1, 16 do
			danger[cell] = c.danger[cell] == true
			collapsed[cell] = c.collapsed[cell] == true
		end
	end
	return {
		id = c.id,
		kind = c.kind,
		startsAt = c.startsAt,
		endsAt = c.endsAt,
		center = c.center,
		width = c.width,
		lane = c.lane,
		items = c.items,
		cell = c.cell,
		danger = danger,
		collapsed = collapsed,
		origin = c.origin,
		points = c.points,
	}
end
return Minigames
