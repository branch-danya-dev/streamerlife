--!nonstrict
local Metrics = {}
function Metrics.add(m, key, value)
	if type(value) ~= "number" or value ~= value then
		return
	end
	local x = m[key] or { n = 0, sum = 0, max = -math.huge, min = math.huge }
	m[key] = x
	x.n += 1
	x.sum += value
	x.max = math.max(x.max, value)
	x.min = math.min(x.min, value)
end
function Metrics.report(m)
	local result = {}
	for key, x in pairs(m) do
		result[key] = {
			samples = x.n,
			mean = math.round(x.sum / x.n * 1000) / 1000,
			max = math.round(x.max * 1000) / 1000,
			min = math.round(x.min * 1000) / 1000,
		}
	end
	return result
end
return Metrics
