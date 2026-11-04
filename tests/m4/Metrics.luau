--!nonstrict
local Metrics = {}
function Metrics.print(prefix, value)
	local encoded = game:GetService("HttpService"):JSONEncode(value)
	-- Studio's disk logger truncates long print messages. Preserve every byte in bounded chunks.
	local count = math.ceil(#encoded / 700)
	for index = 1, count do
		print(
			prefix
				.. " "
				.. index
				.. "/"
				.. count
				.. " "
				.. string.sub(encoded, (index - 1) * 700 + 1, index * 700)
		)
	end
end
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
