--!strict
-- Dimensions are the usable ScreenGui area, after Roblox safe-area insets.
local function rect(x: number, y: number, w: number, h: number)
	return { x = x, y = y, w = w, h = h }
end
return function(width: number, height: number)
	local compact = width > height and height < 560
	local desktop = width >= 720 and not compact
	local shortPortrait = not compact and not desktop and height < 600
	local gw = if compact
		then math.min(350, math.floor(width * 0.53))
		elseif desktop then math.min(370, math.floor(width * 0.44))
		else width - 24
	local hw = if compact then width - gw - 36 elseif desktop then math.min(470, width - 24) else width - 24
	local gh = if compact then height - 82 else math.max(174, math.min(300, height - 270))
	local gx = if compact or desktop then width - gw - 12 else 12
	local gy = if compact then 8 elseif desktop or shortPortrait then 110 else 136
	local tw = if compact or desktop then math.min(410, width - gw - 36) else width - 24
	local ty = if compact then 88 elseif desktop then height - 200 else gy + gh + 10
	return {
		compact = compact,
		shortPortrait = shortPortrait,
		header = rect(12, 8, hw, if compact then 76 else 86),
		game = rect(gx, gy, gw, gh),
		toast = rect(12, ty, tw, if compact then 72 else 66),
		footer = rect(12, height - 58, width - 24, 50),
		chat = rect(18, height - 122, math.min(360, width - 36), 36),
	}
end
