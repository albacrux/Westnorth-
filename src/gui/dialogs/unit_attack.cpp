/*
	Copyright (C) 2010 - 2025
	by Mark de Wever <koraq@xs4all.nl>
	Part of the Battle for Wesnoth Project https://www.wesnoth.org/

	This program is free software; you can redistribute it and/or modify
	it under the terms of the GNU General Public License as published by
	the Free Software Foundation; either version 2 of the License, or
	(at your option) any later version.
	This program is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY.

	See the COPYING file for more details.
*/

#define GETTEXT_DOMAIN "wesnoth-lib"

#include "gui/dialogs/unit_attack.hpp"

#include "color.hpp"
#include "gui/dialogs/attack_predictions.hpp"
#include "actions/attack.hpp"
#include "attack_prediction.hpp"
#include "formula/string_utils.hpp"
#include "game_board.hpp"
#include "map/map.hpp"
#include "gui/widgets/button.hpp"
#include "gui/widgets/image.hpp"
#include "gui/widgets/label.hpp"
#include "resources.hpp"
#include "units/types.hpp"
#include "gui/widgets/listbox.hpp"
#include "gui/widgets/unit_preview_pane.hpp"
#include "gui/widgets/window.hpp"
#include "game_config.hpp"
#include "gettext.hpp"
#include "language.hpp"
#include "serialization/markup.hpp"
#include "units/unit.hpp"

#include <algorithm>
#include <cmath>
#include <functional>

namespace gui2::dialogs
{

REGISTER_DIALOG(unit_attack)

unit_attack::unit_attack(const unit_map::iterator& attacker_itor,
						   const unit_map::iterator& defender_itor,
						   std::vector<battle_context>&& weapons,
						   const int best_weapon,
						   std::vector<gui2::widget_data>& bc_widget_data_vector)
	: modal_dialog(window_id())
	, selected_weapon_(-1)
	, attacker_itor_(attacker_itor)
	, defender_itor_(defender_itor)
	, weapons_(std::move(weapons))
	, best_weapon_(best_weapon)
	, bc_widget_data_vector_(bc_widget_data_vector)
{
}

void unit_attack::damage_calc_callback()
{
	const std::size_t index = find_widget<listbox>("weapon_list").get_selected_row();
	attack_predictions::display(weapons_[index], attacker_itor_.get_shared_ptr(), defender_itor_.get_shared_ptr());
}

namespace
{
// Westnorth: a 320x22 bar showing the expected HP after the fight, and the HP
// expected to be lost (in red) up to the current HP.
std::string forecast_bar(int hp, double expected, int max_hp)
{
	static const int inner_w = 318;
	if(max_hp <= 0) {
		return "westnorth/hud/bar22-bg.png";
	}
	const int w_now = std::clamp(hp * inner_w / max_hp, 0, inner_w);
	const int w_exp = std::clamp(static_cast<int>(std::lround(expected * inner_w / max_hp)), 0, w_now);
	const color_t c = game_config::red_to_green(100.0 * expected / max_hp);
	std::ostringstream img;
	img << "westnorth/hud/bar22-bg.png";
	if(w_exp > 0) {
		img << "~BLIT(westnorth/hud/bar22-fill.png~CROP(0,0," << w_exp << ",20)~BLEND("
			<< int(c.r) << "," << int(c.g) << "," << int(c.b) << ",1.0),1,1)";
	}
	if(w_now > w_exp) {
		img << "~BLIT(westnorth/hud/bar22-fill.png~CROP(0,0," << (w_now - w_exp) << ",20)"
			<< "~BLEND(255,0,0,1.0)~O(0.6)," << (1 + w_exp) << ",1)";
	}
	return img.str();
}

std::string percent(double p)
{
	return std::to_string(static_cast<int>(std::lround(100.0 * p))) + "%";
}
} // namespace

void unit_attack::fill_side(const std::string& side, const unit& u, bool mirror)
{
	if(auto portrait = find_widget<image>("wn_" + side + "_portrait", false, false)) {
		const std::string& profile = u.big_profile();
		std::string img = profile == u.absolute_image()
			? u.absolute_image() + u.image_mods() + "~SCALE_INTO_SHARP(216,216)"
			: profile + "~SCALE_INTO(240,240)";
		if(mirror) {
			img += "~FL(horiz)";
		}
		portrait->set_label(img);
	}
	if(auto name = find_widget<label>("wn_" + side + "_name", false, false)) {
		name->set_label(u.type_name());
	}
	if(auto info = find_widget<label>("wn_" + side + "_info", false, false)) {
		std::ostringstream str;
		str << markup::span_color("#808080", VGETTEXT("Lvl $lvl", {{"lvl", std::to_string(u.level())}}), " · ")
			<< unit_type::alignment_description(u.alignment(), u.gender());
		if(resources::gameboard) {
			const int bonus = combat_modifier(resources::gameboard->units(), resources::gameboard->map(),
				u.get_location(), u.alignment(), u.is_fearless());
			if(bonus != 0) {
				str << " " << markup::span_color(bonus > 0 ? "#00b51a" : "#ff0000", utils::signed_percent(bonus));
			}
			const int defense = 100 - u.defense_modifier(
				resources::gameboard->map().get_terrain(u.get_location()), u.get_location());
			str << markup::span_color("#808080", " · ", _("attack^Defense"), " ") << defense << "%";
		}
		info->set_label(str.str());
	}
}

void unit_attack::update_forecast()
{
	const int index = find_widget<listbox>("weapon_list").get_selected_row();
	if(index < 0 || static_cast<std::size_t>(index) >= weapons_.size()) {
		return;
	}
	battle_context& bc = weapons_[index];
	const combatant& att = bc.get_attacker_combatant();
	const combatant& def = bc.get_defender_combatant();

	const auto set_hp = [this](const std::string& side, const unit& u, const combatant& c) {
		const double expected = c.average_hp();
		const color_t ec = game_config::red_to_green(100.0 * expected / std::max(1, u.max_hitpoints()));
		if(auto hp = find_widget<label>("wn_" + side + "_hp", false, false)) {
			std::ostringstream str;
			str << markup::span_color("#808080", markup::span_size("small", _("HP"), "  "))
				<< markup::span_size("xx-large", markup::bold(markup::span_color("#f5e6c1", u.hitpoints())))
				<< markup::span_size("x-large", markup::span_color("#808080", "  →  "))
				<< markup::span_size("xx-large", markup::bold(markup::span_color(ec, "~", std::lround(expected))))
				<< markup::span_color("#808080", " /", u.max_hitpoints());
			hp->set_label(str.str());
		}
		if(auto bar = find_widget<image>("wn_" + side + "_hp_bar", false, false)) {
			bar->set_label(forecast_bar(u.hitpoints(), expected, u.max_hitpoints()));
		}
	};
	set_hp("attacker", *attacker_itor_, att);
	set_hp("defender", *defender_itor_, def);

	const double kill = def.hp_dist.empty() ? 0.0 : def.hp_dist[0];
	const double death = att.hp_dist.empty() ? 0.0 : att.hp_dist[0];
	if(auto l = find_widget<label>("wn_kill", false, false)) {
		l->set_label(markup::span_color("#808080", _("attack^Defeat the enemy")) + "\n"
			+ markup::span_size("xx-large", markup::bold(markup::span_color("#00b51a", percent(kill)))));
	}
	if(auto l = find_widget<label>("wn_death", false, false)) {
		l->set_label(markup::span_color("#808080", _("attack^Your unit dies")) + "\n"
			+ markup::span_size("xx-large", markup::bold(markup::span_color(death > 0 ? "#ff0000" : "#f5e6c1", percent(death)))));
	}
	queue_redraw();
}

void unit_attack::pre_show()
{
	connect_signal_mouse_left_click(
			find_widget<button>("damage_calculation"),
			std::bind(&unit_attack::damage_calc_callback, this));

	// Westnorth: the phone layout has no preview panes (see unit_attack.cfg).
	if(auto pane = find_widget<unit_preview_pane>("attacker_pane", false, false)) {
		pane->set_display_data(*attacker_itor_);
	}
	if(auto pane = find_widget<unit_preview_pane>("defender_pane", false, false)) {
		pane->set_display_data(*defender_itor_);
	}
	fill_side("attacker", *attacker_itor_, false);
	fill_side("defender", *defender_itor_, true);

	selected_weapon_ = -1;

	listbox& weapon_list = find_widget<listbox>("weapon_list");
	keyboard_capture(&weapon_list);

	for(widget_data& data : bc_widget_data_vector_) {
		weapon_list.add_row(data);
	}

	// If these two aren't the same size, we can't use list selection incides
	// to access to weapons list!
	assert(weapons_.size() == weapon_list.get_item_count());

	weapon_list.select_row(best_weapon_);

	// Westnorth: expected HP and odds follow the selected weapon.
	connect_signal_notify_modified(weapon_list, std::bind(&unit_attack::update_forecast, this));
	update_forecast();
}

void unit_attack::post_show()
{
	if(get_retval() == retval::OK) {
		selected_weapon_ = find_widget<listbox>("weapon_list").get_selected_row();
	}
}


} // namespace dialogs
