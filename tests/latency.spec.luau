--!nonstrict
local Rules = require("../src/shared/Rules")
local Domain = require("../src/shared/Domain")(require("../src/shared/Balance"))
local p = Domain.new(0)
p.money = 1000
assert(Domain.buy(p, "PC", 0))
assert(not Domain.buy(p, "PC", 0))
assert(p.money == 920 and p.upgrades.PC == 1)
assert(Domain.buy(p, "PC", 1))
assert(p.money == 680 and p.upgrades.PC == 2)
print("PASS replayed purchase cannot buy the next level")
print("one_way_ms,old_center_score,compensated_center_score")
for _, delay in ipairs({ 0, 0.025, 0.05, 0.1, 0.15, 0.2, 0.25 }) do
	local received = 0.6 + delay
	local old = Rules.timing(received, 0.5, 0.28)
	local score = Rules.timing(received - Rules.inputDelay(delay * 2), 0.5, 0.28)
	assert(score > 0.999)
	print(string.format("%d,%.4f,%.4f", delay * 1000, old, score))
end
for _, ping in ipairs({ 0 / 0, math.huge, -math.huge, -1, "bad", {} }) do
	assert(Rules.inputDelay(ping) == 0)
end
assert(Rules.inputDelay(99) == 0.25)
assert(Rules.timing(0.1, 0.5, 0.28) == 0)
print("PASS server-measured compensation is finite and capped; misses still miss")
print("3 latency/purchase regression checks passed (deterministic model, not live network)")
