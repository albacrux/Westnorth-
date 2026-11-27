-- Westnorth: job classes and class change (docs/westnorth/classes.md).
--
-- A unit of a Westnorth class standing on a village or castle hex can change to
-- another class of the same level. It keeps its experience (capped below the new
-- class's maximum, so it never advances on the spot), its traits and its share
-- of hit points, and spends the rest of its turn doing it.
--
-- Loaded with wesnoth.dofile("westnorth/lua/classes.lua"); returns the module and
-- also stores it in the global westnorth_classes for [command] code.

local _ = wesnoth.textdomain "wesnoth-westnorth"

local classes = {}

-- Order matters: it is the order of the options in the class change menu.
-- role: one line shown in the class change menu, saying what the class does.
classes.list = {
	{ id = "squire",    name = _ "Escudeiro",   levels = { "WN_Squire",    "WN_Squire2" },
	  role = _ "Segura a linha: firme na defesa" },
	{ id = "knight",    name = _ "Cavaleiro",   levels = { "WN_Knight",    "WN_Knight2" },
	  role = _ "Rápido; o golpe deixa o alvo lento" },
	{ id = "archer",    name = _ "Arqueiro",    levels = { "WN_Archer",    "WN_Archer2" },
	  role = _ "Arco certeiro: 60% de acerto no mínimo" },
	{ id = "thief",     name = _ "Ladino",      levels = { "WN_Thief",     "WN_Thief2" },
	  role = _ "Passa entre inimigos e ataca pelas costas" },
	{ id = "whitemage", name = _ "Mago Branco", levels = { "WN_WhiteMage", "WN_WhiteMage2" },
	  role = _ "Cura os aliados ao lado" },
	{ id = "blackmage", name = _ "Mago Negro",  levels = { "WN_BlackMage", "WN_BlackMage2" },
	  role = _ "Magia forte à distância, mas frágil" },
}

-- Terrain where a class change is allowed: villages, castles and keeps.
classes.change_terrain = "*^V*,C*,K*,C*^*,K*^*"

-- type id -> { class = <class table>, level = <1 or 2> }
classes.by_type = {}
for _, c in ipairs(classes.list) do
	for level, type_id in ipairs(c.levels) do
		classes.by_type[type_id] = { class = c, level = level }
	end
end

function classes.find(class_id)
	for _, c in ipairs(classes.list) do
		if c.id == class_id then return c end
	end
	return nil
end

--- Comma separated list of every class unit type (for WML filters).
function classes.all_types()
	local types = {}
	for _, c in ipairs(classes.list) do
		for _, t in ipairs(c.levels) do table.insert(types, t) end
	end
	return table.concat(types, ",")
end

--- Class info of a unit, or nil if it is not a Westnorth class unit.
function classes.of_unit(u)
	return classes.by_type[u.type]
end

--- Why the unit cannot change class right now, or nil if it can.
function classes.cannot_change_reason(u)
	if not classes.of_unit(u) then
		return _ "Esta unidade não tem classe do Westnorth."
	end
	if not wesnoth.map.matches(u.x, u.y, { terrain = classes.change_terrain }) then
		return _ "Só é possível mudar de classe numa vila ou num castelo."
	end
	if u.attacks_left < 1 then
		return _ "Esta unidade já atacou neste turno."
	end
	return nil
end

--- Changes the class of unit u (on the map or not). No UI, no checks: callers decide.
--- @return boolean true if the unit changed
function classes.change(u, class_id)
	local info = classes.of_unit(u)
	local target = classes.find(class_id)
	if not info or not target or target == info.class then
		return false
	end
	local new_type = target.levels[info.level]
	local xp = u.experience
	local hp_share = u.hitpoints / u.max_hitpoints

	u:transform(new_type)

	-- Keep the experience, but never enough to advance immediately.
	u.experience = math.min(xp, u.max_experience - 1)
	u.hitpoints = math.max(1, math.floor(hp_share * u.max_hitpoints + 0.5))
	-- Changing class takes the rest of the turn.
	u.moves = 0
	u.attacks_left = 0
	return true
end

--- Menu command: let the player pick the new class of the unit at x, y.
function classes.menu_change_class(x, y)
	local u = wesnoth.units.get(x, y)
	if not u then return end
	local reason = classes.cannot_change_reason(u)
	if reason then
		gui.show_prompt(_ "Mudar de classe", reason, "ok")
		return
	end
	local info = classes.of_unit(u)
	local options, ids = {}, {}
	for _, c in ipairs(classes.list) do
		if c ~= info.class then
			local t = wesnoth.unit_types[c.levels[info.level]]
			-- Two short lines instead of one long one: on the phone a single line
			-- ran off the dialog (docs/westnorth/manual-ui-android.md).
			local description = c.role
			if info.level > 1 then
				description = t.name .. "\n" .. c.role
			end
			table.insert(options, {
				image = t.image .. "~TC(" .. u.side .. ",magenta)",
				label = c.name,
				description = description,
			})
			table.insert(ids, c.id)
		end
	end
	table.insert(options, { label = _ "Cancelar" })

	local choice = gui.get_user_choice({
		speaker = "narrator",
		image = "wesnoth-icon.png",
		caption = _ "Mudar de classe",
		message = _ "Mantém experiência e traços; termina o turno.",
	}, options)

	local class_id = ids[choice]
	if class_id then
		local old_name = info.class.name
		classes.change(u, class_id)
		-- Same as [transform_unit]: the map does not redraw a transformed unit by itself.
		wesnoth.wml_actions.redraw {}
		if westnorth_achievements then
			westnorth_achievements.class_changed(u)
		end
		wesnoth.interface.float_label(u.x, u.y, old_name .. " → " .. classes.find(class_id).name)
	end
end

--- Adds "Mudar de classe..." to the context menu (long press on a unit).
--- Called once at prestart by {WN_CLASS_SYSTEM}, or directly by test scenarios.
function classes.add_menu_item()
	wesnoth.wml_actions.set_menu_item {
		id = "westnorth_change_class",
		description = _ "Mudar de classe...",
		image = "icons/action/editor-tool-unit_25.png",
		wml.tag.show_if {
			wml.tag.have_unit {
				x = "$x1", y = "$y1", side = "$side_number",
				wml.tag.filter_location { terrain = classes.change_terrain },
				wml.tag["and"] { lua_function = "westnorth_is_class_unit" },
			},
		},
		wml.tag.command {
			wml.tag.lua { code = "westnorth_classes.menu_change_class(wml.variables.x1, wml.variables.y1)" },
		},
	}
end

-- Unit filter hook for WML (lua_function=westnorth_is_class_unit).
function westnorth_is_class_unit(u)
	return classes.of_unit(u) ~= nil
end

westnorth_classes = classes
return classes
