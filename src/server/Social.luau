--!nonstrict
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Config = require(Shared.Balance)
local Domain = require(Shared.Domain)(Config)
local Rules = require(Shared.Rules)
local Strings = require(Shared.Strings)
local Store = require(script.Parent.ProfileStore)
local City = require(script.Parent.City)
local Streams = require(script.Parent.Streams)
local Social = { watching = {}, lastReaction = {} }

function Social.visit(visitor, owner)
	if not Store.get(visitor) or not Store.get(owner) or Streams.active[visitor] then
		return false
	end
	if visitor == owner then
		Social.watching[visitor] = nil
		City.home(visitor)
		return true
	end
	local room = City.owners[owner]
	if not room then
		return false
	end
	Social.watching[visitor] = owner
	City.teleport(visitor, room.center + Vector3.new(9, 4, -5))
	return true
end
function Social.owner(visitor)
	local owner = Social.watching[visitor]
	if owner and Store.get(owner) and City.inside(visitor, owner) then
		return owner
	end
	Social.watching[visitor] = nil
	return nil
end
local function bonus(visitor, owner, session)
	if session.social[visitor.UserId] then
		return
	end
	session.social[visitor.UserId] = true
	for _, player in ipairs({ visitor, owner }) do
		local p = Store.get(player)
		if p and Domain.social(p, os.time()) then
			Streams.emit(player, "Toast", Strings.SocialReward)
		end
	end
end
function Social.react(visitor, index, now)
	if not Rules.integer(index, 1, #Strings.Reactions) then
		return
	end
	local owner = Social.owner(visitor)
	local session = owner and Streams.active[owner]
	if not session or not Rules.allowed(Social.lastReaction[visitor], now, Config.ReactionCooldown) then
		return
	end
	Social.lastReaction[visitor] = now
	Streams.emit(owner, "Reaction", { name = visitor.DisplayName, index = index })
	Streams.emit(visitor, "Reaction", { name = visitor.DisplayName, index = index })
	bonus(visitor, owner, session)
end
function Social.vote(visitor, choice)
	local owner = Social.owner(visitor)
	local session = owner and Streams.active[owner]
	if not session or session.challenge or type(choice) ~= "string" then
		return
	end
	if Rules.ballot(session.votes, visitor.UserId, choice, session.choices) then
		Streams.emit(visitor, "Toast", Strings.Voted)
		bonus(visitor, owner, session)
	end
end
function Social.remove(player)
	Social.watching[player], Social.lastReaction[player] = nil, nil
	for visitor, owner in pairs(Social.watching) do
		if owner == player then
			Social.watching[visitor] = nil
			City.home(visitor)
		end
	end
end
return Social
