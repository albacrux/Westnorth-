-- Westnorth: awards the achievements of the job class system
-- (data/westnorth/achievements.cfg, roadmap M5).
--
-- Achievements live in the local player's preferences, so they are only given
-- for sides that are human-controlled on this machine (never to the AI, never
-- to the other player of a network game). Event handlers are registered on
-- every (re)load by {WN_CLASS_SYSTEM}.

local classes = wesnoth.dofile "westnorth/lua/classes.lua"
local on_event = wesnoth.require "on_event"

local ach = {}
ach.content_for = "westnorth"

-- WML variable set when the local player loses a unit (for "Sem Baixas").
local LOST_VAR = "westnorth_ach_lost_unit"
local BLITZ_TURNS = 12

local function is_local_human(side)
	local s = wesnoth.sides[side]
	return s ~= nil and s.controller == "human" and s.is_local
end

local function award(id)
	if not wesnoth.achievements.has(ach.content_for, id) then
		wesnoth.achievements.set(ach.content_for, id)
	end
end

--- The unit now belongs to a class: count it for "Mestre de Todos os Ofícios".
function ach.class_used(u)
	local info = classes.of_unit(u)
	if info and is_local_human(u.side) then
		wesnoth.achievements.set_sub_achievement(ach.content_for, "WN_all_classes", info.class.id)
	end
end

--- Called by classes.menu_change_class after a successful change.
function ach.class_changed(u)
	if not is_local_human(u.side) then return end
	award("WN_first_change")
	if u.level >= 2 then
		award("WN_veteran_change")
	end
	ach.class_used(u)
end

local function killer_class(ctx)
	local killer = ctx.x2 and wesnoth.units.get(ctx.x2, ctx.y2)
	if not killer or not is_local_human(killer.side) then return nil end
	local info = classes.of_unit(killer)
	return info and info.class.id
end

function ach.register_events()
	on_event("recruit", function(ctx)
		local u = wesnoth.units.get(ctx.x1, ctx.y1)
		if u then ach.class_used(u) end
	end)

	on_event("post advance", function(ctx)
		local u = wesnoth.units.get(ctx.x1, ctx.y1)
		local info = u and classes.of_unit(u)
		if info and info.level >= 2 and is_local_human(u.side) then
			award("WN_promotion")
			ach.class_used(u)
		end
	end)

	on_event("attacker hits", function(ctx)
		local u = wesnoth.units.get(ctx.x1, ctx.y1)
		local info = u and classes.of_unit(u)
		if info and info.class.id == "knight" and is_local_human(u.side)
			and ctx.weapon and ctx.weapon.range == "melee" then
			wesnoth.achievements.progress(ach.content_for, "WN_slow_10", 1)
		end
	end)

	on_event("die", function(ctx)
		local dead = wesnoth.units.get(ctx.x1, ctx.y1)
		if dead and is_local_human(dead.side) then
			wml.variables[LOST_VAR] = true
		end
		local k = killer_class(ctx)
		if k == "thief" then
			award("WN_backstab")
		elseif k == "blackmage" then
			award("WN_dark_magic")
		end
	end)

	on_event("victory", function()
		-- "victory" only fires on the winners' machines.
		local local_side = false
		for _, s in ipairs(wesnoth.sides) do
			if is_local_human(s.side) then local_side = true end
		end
		if not local_side then return end
		if wesnoth.scenario.id == "westnorth_2p_encruzilhada" then
			award("WN_win_crossroads")
		end
		if not wml.variables[LOST_VAR] then
			award("WN_flawless")
		end
		if wesnoth.current.turn <= BLITZ_TURNS then
			award("WN_blitz")
		end
	end)
end

westnorth_achievements = ach
return ach
