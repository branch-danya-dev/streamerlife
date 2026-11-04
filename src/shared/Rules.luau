--!nonstrict
local Rules = {}
function Rules.integer(value, low, high)
	return type(value) == "number" and value == value and value % 1 == 0 and value >= low and value <= high
end
function Rules.slider(elapsed)
	local phase = math.max(0, elapsed) % 2.4 / 1.2
	return if phase <= 1 then phase else 2 - phase
end
function Rules.timing(elapsed, center, width)
	return math.clamp(1 - math.abs(Rules.slider(elapsed) - center) / (width / 2), 0, 1)
end
function Rules.move(cell, direction, size)
	local x, z = (cell - 1) % size, math.floor((cell - 1) / size)
	if direction == "Left" then
		x -= 1
	elseif direction == "Right" then
		x += 1
	elseif direction == "Up" then
		z -= 1
	elseif direction == "Down" then
		z += 1
	else
		return cell
	end
	if x < 0 or x >= size or z < 0 or z >= size then
		return cell
	end
	return z * size + x + 1
end
function Rules.allowed(last, now, gap)
	return last == nil or now - last >= gap
end
function Rules.ballot(votes, userId, choice, choices)
	if votes[userId] ~= nil or not table.find(choices, choice) then
		return false
	end
	votes[userId] = choice
	return true
end
function Rules.winner(votes, choices, fallback)
	local count = {}
	for _, choice in ipairs(choices) do
		count[choice] = 0
	end
	for _, choice in pairs(votes) do
		if count[choice] then
			count[choice] += 1
		end
	end
	local winner, best = fallback, count[fallback] or 0
	for _, choice in ipairs(choices) do
		if count[choice] > best then
			winner, best = choice, count[choice]
		end
	end
	return winner, count
end
return Rules
