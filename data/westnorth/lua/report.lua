-- Westnorth: one console line with the result of a game, for the headless
-- balance runs of utils/westnorth/balance.py (roadmap M7). Harmless elsewhere:
-- it only writes to stdout, which nobody reads on the phone.

local on_event = wesnoth.require "on_event"

local function unit_counts()
	local counts = {}
	for _, s in ipairs(wesnoth.sides) do
		table.insert(counts, string.format("%d:%d", s.side, #wesnoth.units.find_on_map { side = s.side }))
	end
	return table.concat(counts, ",")
end

on_event("die", function(ctx)
	local u = wesnoth.units.get(ctx.x1, ctx.y1)
	if u and u.canrecruit then
		local s = wesnoth.sides[u.side]
		std_print(string.format("westnorth-result reason=leader_killed loser=%d:%s turn=%d units=%s",
			u.side, s.faction or "?", wesnoth.current.turn, unit_counts()))
	end
end)

on_event("time over", function()
	std_print(string.format("westnorth-result reason=time_over turn=%d units=%s",
		wesnoth.current.turn, unit_counts()))
end)
