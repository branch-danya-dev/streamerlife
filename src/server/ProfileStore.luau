--!nonstrict
local DataStoreService = game:GetService("DataStoreService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Config = require(Shared.Balance)
local Domain = require(Shared.Domain)(Config)
local Lease = require(Shared.Lease)(Config, Domain)
local Strings = require(Shared.Strings)
local Store = { records = {}, closing = false }
Store.testMode = RunService:IsStudio()
	and game:GetService("ServerScriptService"):GetAttribute("UseLiveDataInStudio") ~= true
local memory = {}
local backend = if Store.testMode
	then nil
	else DataStoreService:GetDataStore(
		if RunService:IsStudio() then "StreamerLife_Studio_v1" else "StreamerLife_v1"
	)

local function update(key, transform)
	if Store.testMode then
		local value = transform(Domain.copy(memory[key]))
		if value ~= nil then
			memory[key] = Domain.copy(value)
		end
		return value
	end
	return backend:UpdateAsync(key, transform)
end

local function retry(callback)
	for attempt = 1, Config.SaveAttempts do
		local ok, value = pcall(callback)
		if ok then
			return value
		end -- nil is an explicit rejected lease, not a network failure.
		warn("Profile storage request failed; attempt", attempt)
		if attempt < Config.SaveAttempts then
			task.wait(0.5 * 2 ^ (attempt - 1))
		end
	end
	return nil
end

function Store.load(player)
	if Store.closing or Store.records[player] then
		return nil
	end
	local token = HttpService:GenerateGUID(false)
	local key = "player_" .. tostring(player.UserId)
	local result = retry(function()
		return update(key, function(old)
			return Lease.acquire(old, token, os.time())
		end)
	end)
	if not result or not result.lock or result.lock.token ~= token then
		return nil
	end
	local record = {
		profile = result.data,
		token = token,
		key = key,
		expires = result.lock.expires,
		revision = result.revision,
		saving = false,
		closing = false,
	}
	Store.records[player] = record
	if Store.closing or not player.Parent then
		Store.save(player, true)
		return nil
	end
	return record.profile, result.arrival
end

function Store.get(player)
	local record = Store.records[player]
	if not record or record.closing or os.time() >= record.expires - 10 then
		return nil
	end
	return record.profile
end

function Store.save(player, release)
	local record = Store.records[player]
	if not record then
		return true
	end
	if release then
		record.closing = true
	end
	while record.saving do
		task.wait(0.05)
	end
	if Store.records[player] ~= record then
		return true
	end
	if record.closing and not release then
		return false
	end
	record.saving = true
	record.revision += 1
	local revision = record.revision
	local snapshot = Domain.copy(record.profile)
	local result = retry(function()
		return update(record.key, function(old)
			return Lease.save(old, record.token, revision, snapshot, os.time(), release)
		end)
	end)
	record.saving = false
	if result then
		record.profile.lastSeen = math.max(record.profile.lastSeen, result.data.lastSeen)
		if result.lock then
			record.expires = result.lock.expires
		end
	end
	if release then
		Store.records[player] = nil
	elseif not result and os.time() >= record.expires - 30 then
		record.closing = true
		player:Kick(Strings.LeaseLost)
	end
	return result ~= nil
end

function Store.start()
	task.spawn(function()
		while not Store.closing do
			task.wait(Config.AutosaveSeconds)
			for player in pairs(Store.records) do
				task.spawn(Store.save, player, false)
			end
		end
	end)
	game:BindToClose(function()
		if Store.beforeClose then
			Store.beforeClose()
		end
		Store.closing = true
		local pending = 0
		for player in pairs(Store.records) do
			pending += 1
			task.spawn(function()
				Store.save(player, true)
				pending -= 1
			end)
		end
		local deadline = os.clock() + 25
		while pending > 0 and os.clock() < deadline do
			task.wait(0.1)
		end
	end)
end
return Store
