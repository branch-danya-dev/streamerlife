--!nonstrict
-- Pure economy. Dependency injection keeps the exact runtime logic executable in the Luau CLI.
return function(Config)
	local Domain = {}
	function Domain.number(value, default, maximum)
		if type(value) ~= "number" or value ~= value or math.abs(value) == math.huge then
			return default or 0
		end
		return math.clamp(math.floor(value), 0, maximum or Config.MaxValue)
	end
	function Domain.copy(value)
		if type(value) ~= "table" then
			return value
		end
		local result = {}
		for key, child in pairs(value) do
			result[key] = Domain.copy(child)
		end
		return result
	end
	function Domain.new(now)
		return {
			version = Config.Schema,
			money = 0,
			subscribers = 0,
			views = 0,
			upgrades = { PC = 0, Microphone = 0, Camera = 0 },
			videos = {},
			stats = { streams = 0, challenges = 0 },
			cosmetics = { trophy = "Normal" },
			lastSeen = now,
			socialDay = math.floor(now / 86400),
			socialEarned = 0,
		}
	end
	function Domain.normalize(raw, now)
		if type(raw) ~= "table" then
			return Domain.new(now)
		end
		local p = Domain.new(now)
		for _, key in ipairs({ "money", "subscribers", "views", "lastSeen", "socialDay", "socialEarned" }) do
			p[key] = Domain.number(raw[key], p[key], if key == "lastSeen" then 10_000_000_000 else nil)
		end
		for name, prices in pairs(Config.Costs) do
			p.upgrades[name] =
				Domain.number(if type(raw.upgrades) == "table" then raw.upgrades[name] else nil, 0, #prices)
		end
		if type(raw.stats) == "table" then
			p.stats.streams = Domain.number(raw.stats.streams)
			p.stats.challenges = Domain.number(raw.stats.challenges)
		end
		local tiers = {}
		for _, tier in ipairs(Config.Popularity) do
			tiers[tier.id] = true
		end
		if type(raw.cosmetics) == "table" and tiers[raw.cosmetics.trophy] then
			p.cosmetics.trophy = raw.cosmetics.trophy
		end
		if type(raw.videos) == "table" then
			for _, video in ipairs(raw.videos) do
				if #p.videos >= Config.MaxVideos then
					break
				end
				if
					type(video) == "table"
					and type(video.id) == "string"
					and #video.id <= 64
					and tiers[video.tier]
				then
					table.insert(p.videos, {
						id = video.id,
						tier = video.tier,
						views = Domain.number(video.views),
						created = Domain.number(video.created, now, 10_000_000_000),
						cashRate = Domain.number(video.cashRate, 1, 60),
						viewRate = Domain.number(video.viewRate, 1, 600),
						paidSeconds = Domain.number(video.paidSeconds, 0, Config.OfflineCap),
					})
				end
			end
		end
		return p
	end
	function Domain.grant(p, reward)
		for _, key in ipairs({ "money", "views", "subscribers" }) do
			p[key] = math.min(Config.MaxValue, p[key] + Domain.number(reward[key]))
		end
	end
	function Domain.price(p, category)
		local prices = Config.Costs[category]
		return if prices then prices[p.upgrades[category] + 1] else nil
	end
	function Domain.buy(p, category)
		local cost = Domain.price(p, category)
		if not cost or p.money < cost then
			return false
		end
		p.money -= cost
		p.upgrades[category] += 1
		return true
	end
	function Domain.reward(p, score, combo, kind)
		if type(score) ~= "number" or score ~= score then
			score = 0
		end
		score = math.clamp(score, 0, 1)
		combo = Domain.number(combo, 0, 5)
		local mic = 1 + p.upgrades.Microphone * 0.18
		local views = math.floor((8 + score * 50) * (1 + p.upgrades.PC * 0.25) * (1 + combo * 0.1))
		local money = math.floor((3 + score * 20) * mic)
		return {
			money = money,
			views = views,
			subscribers = math.floor((1 + score * 6) * mic),
			donations = if kind == "Rain" then money else 0,
		}
	end
	function Domain.odds(p)
		local result = {}
		local camera = p.upgrades.Camera
		local extra = camera * 2
		for i, tier in ipairs(Config.Popularity) do
			result[i] = { id = tier.id, weight = tier.weight, multiplier = tier.multiplier }
		end
		result[1].weight -= extra
		result[2].weight += extra * 0.7
		result[3].weight += extra * 0.25
		result[4].weight += extra * 0.05
		return result
	end
	function Domain.roll(p, randomUnit)
		local roll = math.clamp(randomUnit, 0, 1) * 100
		local odds = Domain.odds(p)
		for _, tier in ipairs(odds) do
			roll -= tier.weight
			if roll < 0 then
				return tier
			end
		end
		return odds[#odds]
	end
	function Domain.publish(p, report, now, id, randomUnit)
		local tier = Domain.roll(p, randomUnit)
		local video = {
			id = id,
			tier = tier.id,
			views = report.views,
			created = now,
			paidSeconds = 0,
			cashRate = math.min(60, math.max(1, math.floor(report.money / 30)) * tier.multiplier),
			viewRate = math.min(600, math.max(5, math.floor(report.views / 8)) * tier.multiplier),
		}
		table.insert(p.videos, 1, video)
		while #p.videos > Config.MaxVideos do
			table.remove(p.videos)
		end
		local rank = {}
		for i, entry in ipairs(Config.Popularity) do
			rank[entry.id] = i
		end
		if rank[tier.id] > rank[p.cosmetics.trophy] then
			p.cosmetics.trophy = tier.id
		end
		p.stats.streams += 1
		return video
	end
	function Domain.offline(p, now)
		-- Future cursor is never moved backwards, preventing clock rollback from replaying time.
		local elapsed = math.clamp(now - p.lastSeen, 0, Config.OfflineCap)
		local result = { money = 0, views = 0, seconds = elapsed }
		for _, video in ipairs(p.videos) do
			local before = video.paidSeconds
			local used = math.min(elapsed, Config.OfflineCap - before, math.max(0, now - video.created))
			video.paidSeconds += used
			result.money += math.floor(video.paidSeconds * video.cashRate / 3600) - math.floor(
				before * video.cashRate / 3600
			)
			local views = math.floor(video.paidSeconds * video.viewRate / 3600)
				- math.floor(before * video.viewRate / 3600)
			result.views += views
			video.views = math.min(Config.MaxValue, video.views + views)
		end
		p.lastSeen = math.max(p.lastSeen, now)
		Domain.grant(p, result)
		return result
	end
	function Domain.social(p, now)
		local day = math.floor(now / 86400)
		if day > p.socialDay then
			p.socialDay, p.socialEarned = day, 0
		end
		if p.socialEarned >= Config.SocialDailyCap then
			return false
		end
		p.socialEarned += 1
		Domain.grant(p, { money = 1 })
		return true
	end
	return Domain
end
