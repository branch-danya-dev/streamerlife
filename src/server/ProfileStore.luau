--!nonstrict
local DataStoreService = game:GetService("DataStoreService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Config = require(Shared.Balance)
local Domain = require(Shared.Domain)(Config)
local Lease = require(Shared.Lease)(Config, Domain)
local Strings = require(Shared.Strings)
local testMode = RunService:IsStudio()
	and game:GetService("ServerScriptService"):GetAttribute("UseLiveDataInStudio") ~= true
local memory = {}
local backend = if testMode
	then nil
	else DataStoreService:GetDataStore(
		if RunService:IsStudio() then "StreamerLife_Studio_v1" else "StreamerLife_v1"
	)

local function update(key, transform)
	if testMode then
		local value = transform(Domain.copy(memory[key]))
		if value ~= nil then
			memory[key] = Domain.copy(value)
		end
		return value
	end
	return backend:UpdateAsync(key, transform)
end

local Store = require(script.Parent.Persistence)(Config, Domain, Lease, {
	update = update,
	now = os.time,
	clock = os.clock,
	wait = task.wait,
	spawn = task.spawn,
	token = function()
		return HttpService:GenerateGUID(false)
	end,
	present = function(player)
		return player.Parent ~= nil
	end,
	failed = function(attempt)
		warn("Profile storage request failed; attempt", attempt)
	end,
	kick = function(player)
		player:Kick(Strings.LeaseLost)
	end,
})
Store.testMode = testMode
function Store.start()
	task.spawn(function()
		while not Store.closing do
			task.wait(Config.AutosaveSeconds)
			if Store.closing then
				break
			end
			for player in pairs(Store.records) do
				task.spawn(Store.save, player, false)
			end
		end
	end)
	game:BindToClose(Store.close)
end
return Store
