--!nonstrict
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Config = require(Shared.Balance)
local Domain = require(Shared.Domain)(Config)
local Rules = require(Shared.Rules)
local Strings = require(Shared.Strings)
local Store = require(script.Parent.ProfileStore)
local City = require(script.Parent.City)
local Minigames = require(script.Parent.Minigames)
local HttpService = game:GetService("HttpService")
local rng = Random.new()
local Streams = { active = {}, cooldown = {} }

function Streams.start(player, now)
	local p = Store.get(player)
	if not p or Streams.active[player] then
		return false, "Busy"
	end
	if not City.inside(player, player) then
		return false, "NotHome"
	end
	if now < (Streams.cooldown[player] or 0) then
		return false, "Cooldown"
	end
	Streams.active[player] = {
		id = HttpService:GenerateGUID(false),
		startsAt = now,
		endsAt = now + Config.StreamSeconds,
		nextAt = now + 2,
		nextKind = "Timing",
		choices = { "Timing" },
		votes = {},
		rotation = 1,
		completedKinds = {},
		combo = 0,
		report = { money = 0, views = 0, subscribers = 0, donations = 0, successes = 0, challenges = 0 },
		social = {},
		chatAt = now,
	}
	return true
end

function Streams.finish(player, now, notify)
	local session = Streams.active[player]
	if not session then
		return
	end
	Streams.active[player] = nil
	Streams.cooldown[player] = now + Config.StreamCooldown
	if session.challenge then
		Minigames.cleanup(player, session.challenge)
	end
	local p = Store.get(player)
	if not p then
		return
	end
	local video
	if now - session.startsAt >= Config.MinRecordingSeconds and session.report.challenges > 0 then
		video = Domain.publish(p, session.report, os.time(), session.id, rng:NextNumber())
		City.updateEquipment(player, p)
	end
	if notify then
		Streams.emit(player, "Report", { report = session.report, video = video })
	end
	return session.report
end

function Streams.input(player, data, now)
	local session = Streams.active[player]
	if not session or not session.challenge or data.id ~= session.challenge.id then
		return
	end
	Minigames.input(session.challenge, data.verb, data.value, now)
end

function Streams.tick(player, now)
	local s = Streams.active[player]
	local p = Store.get(player)
	if not s then
		return
	end
	if not p then
		Streams.finish(player, now, false)
		return
	end
	if now >= s.endsAt then
		Streams.finish(player, now, true)
		return
	end
	if s.challenge then
		local c = s.challenge
		local score = Minigames.tick(c, now)
		if score ~= nil then
			s.challenge = nil -- consume the challenge before any notification; duplicate inputs cannot settle again.
			Minigames.cleanup(player, c)
			s.combo = if score >= 0.5 then math.min(5, s.combo + 1) else 0
			local reward = Domain.reward(p, score, s.combo, c.kind)
			Domain.grant(p, reward)
			p.stats.challenges += 1
			for _, key in ipairs({ "money", "views", "subscribers", "donations" }) do
				s.report[key] += reward[key]
			end
			s.report.challenges += 1
			if score >= 0.5 then
				s.report.successes += 1
			end
			s.completedKinds[c.kind] = true
			s.nextAt, s.votes = now + Config.BreakSeconds, {}
			s.rotation = s.rotation % #Config.ChallengeNames + 1
			s.nextKind = Config.ChallengeNames[s.rotation]
			s.choices = {}
			for _, name in ipairs(Config.ChallengeNames) do
				if not s.completedKinds[name] then
					table.insert(s.choices, name)
				end
			end
			if #s.choices == 0 then
				s.choices = table.clone(Config.ChallengeNames)
			end
			if not table.find(s.choices, s.nextKind) then
				s.nextKind = s.choices[1]
			end
			Streams.emit(player, "Reward", { reward = reward, success = score >= 0.5 })
			local phrases = if score >= 0.5 then Strings.ChatGood else Strings.ChatMiss
			Streams.emit(player, "Chat", phrases[rng:NextInteger(1, #phrases)])
		end
	elseif now >= s.nextAt then
		local kind = Rules.winner(s.votes, s.choices, s.nextKind)
		s.challenge = Minigames.begin(player, kind, now)
	end
	if now >= s.chatAt then
		s.chatAt = now + rng:NextInteger(7, 11)
		Streams.emit(player, "Chat", Strings.ChatIdle[rng:NextInteger(1, #Strings.ChatIdle)])
	end
end

function Streams.public(player)
	local s = Streams.active[player]
	local p = Store.get(player)
	if not s or not p then
		return nil
	end
	local _, votes = Rules.winner(s.votes, s.choices, s.nextKind)
	return {
		id = s.id,
		startsAt = s.startsAt,
		endsAt = s.endsAt,
		nextAt = s.nextAt,
		combo = s.combo,
		report = s.report,
		challenge = Minigames.public(s.challenge),
		votes = votes,
		choices = s.choices,
		viewers = math.floor(5 + math.sqrt(p.subscribers) * 2 + s.combo * 3),
	}
end
return Streams
