--!nonstrict
local Rules = require(game:GetService("ReplicatedStorage").Shared.Rules)
return function(c, now, last)
	if not c or now < c.startsAt or now >= c.endsAt or now - (last.at or 0) < 0.2 then
		return
	end
	local verb, value
	if
		c.kind == "Timing"
		and last.stop ~= c.id
		and Rules.timing(now - c.startsAt, c.center, c.width) > 0.93
	then
		verb = "Stop"
		last.stop = c.id
	elseif c.kind == "Rain" then
		for _, item in ipairs(c.items) do
			if not item.done and item.at > now and item.at - now < 0.65 then
				verb = "Lane"
				value = if item.good then item.lane else item.lane % 4 + 1
				break
			end
		end
	elseif c.kind == "Fall" and c.danger[c.cell] then
		for _, direction in ipairs({ "Left", "Right", "Up", "Down" }) do
			local target = Rules.move(c.cell, direction, 4)
			if target ~= c.cell and not c.danger[target] and not c.collapsed[target] then
				verb, value = "Move", direction
				break
			end
		end
	end
	if verb then
		last.at = now
		return { id = c.id, verb = verb, value = value }
	end
end
