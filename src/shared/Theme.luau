--!nonstrict
-- Presentation only: no economy, probability, timing or input rules belong here.
return function(rgb)
	return table.freeze({
		cream = rgb(246, 237, 220),
		paper = rgb(255, 250, 240),
		oak = rgb(203, 156, 107),
		ink = rgb(32, 62, 67),
		sage = rgb(135, 166, 139),
		coral = rgb(237, 132, 109),
		mint = rgb(101, 185, 172),
		gold = rgb(233, 188, 98),
		sky = rgb(169, 204, 209),
		leaf = rgb(91, 133, 93),
		paving = rgb(211, 202, 182),
		muted = rgb(90, 113, 113),
		white = rgb(255, 253, 247),
		red = rgb(192, 70, 62),
		rarity = {
			Normal = rgb(101, 185, 172),
			Popular = rgb(89, 147, 196),
			Viral = rgb(182, 122, 196),
			Legendary = rgb(233, 188, 98),
		},
	})
end
