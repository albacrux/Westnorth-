/*
	Copyright (C) 2016 - 2025
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

#include "gui/dialogs/unit_advance.hpp"

#include "font/standard_colors.hpp"
#include "gettext.hpp"
#include "gui/widgets/button.hpp"
#include "gui/widgets/listbox.hpp"
#include "gui/widgets/unit_preview_pane.hpp"
#include "gui/widgets/window.hpp"
#include "units/unit.hpp"
#include "units/types.hpp"
#include "units/attack_type.hpp"
#include "help/help.hpp"
#include "serialization/markup.hpp"
#include "serialization/string_utils.hpp"

#include <functional>

namespace gui2::dialogs
{

REGISTER_DIALOG(unit_advance)

unit_advance::unit_advance(const std::vector<unit_const_ptr>& samples, std::size_t real,
		unit_const_ptr base)
	: modal_dialog(window_id())
	, previews_(samples)
	, base_(std::move(base))
	, selected_index_(0)
	, last_real_advancement_(real)
{
}

void unit_advance::pre_show()
{
	listbox& list = find_widget<listbox>("advance_choice");

	connect_signal_notify_modified(list, std::bind(&unit_advance::list_item_clicked, this));

	keyboard_capture(&list);

	connect_signal_mouse_left_click(
		find_widget<button>("show_help"),
		std::bind(&unit_advance::show_help, this));

	for(std::size_t i = 0; i < previews_.size(); i++) {
		const unit& sample = *previews_[i];

		widget_data row_data;
		widget_item column;

		std::string image_string, name = sample.type_name();

		// This checks if we've finished iterating over the last unit type advancements
		// and are into the modification-based advancements.
		if(i >= last_real_advancement_) {
			const auto range = sample.get_modifications().child_range("advancement");
			const auto& back = range.back();

			if(back.has_attribute("image")) {
				image_string = back["image"].str();
			}

			name = back["description"].str();
		}

		// Westnorth: card art (portrait when the type has one) and a summary of
		// what the new unit brings, so the cards can be compared at a glance.
		if(image_string.empty()) {
			const std::string& profile = sample.big_profile();
			image_string = profile != sample.absolute_image()
				? profile + "~SCALE_INTO(200,200)"
				: sample.type().image() + sample.image_mods() + "~SCALE_INTO_SHARP(144,144)";
		} else {
			image_string += "~SCALE_INTO_SHARP(144,144)";
		}

		column["label"] = image_string;
		row_data.emplace("advancement_image", column);

		column["label"] = name;
		row_data.emplace("advancement_name", column);

		// Westnorth: numbers that change read "before -> after" with the new
		// value in green; attacks the unit did not have are tagged as new.
		std::ostringstream stats;
		const auto stat = [&stats](const std::string& label, int value, int before) {
			stats << markup::span_color("#808080", label, " ");
			if(before >= 0 && before != value) {
				stats << markup::span_color("#808080", before, " → ")
					<< markup::bold(markup::span_color(font::GOOD_COLOR, value));
			} else {
				stats << markup::bold(markup::span_color(font::weapon_color, value));
			}
			stats << "    ";
		};
		stat(_("HP"), sample.max_hitpoints(), base_ ? base_->max_hitpoints() : -1);
		stat(_("MP"), sample.total_movement(), base_ ? base_->total_movement() : -1);
		if(sample.can_advance()) {
			stat(_("XP"), sample.max_experience(), -1);
		}
		for(const auto& at : sample.attacks()) {
			const attack_type* old_attack = nullptr;
			if(base_) {
				for(const auto& b : base_->attacks()) {
					if(b.id() == at.id()) {
						old_attack = &b;
					}
				}
			}
			stats << "\n";
			if(old_attack && (old_attack->damage() != at.damage()
				|| old_attack->num_attacks() != at.num_attacks())) {
				stats << markup::span_color("#808080", old_attack->damage(),
					font::weapon_numbers_sep, old_attack->num_attacks(), " → ");
			}
			stats << markup::bold(markup::span_color(
					base_ && !old_attack ? font::GOOD_COLOR : font::weapon_color,
					at.damage(), font::weapon_numbers_sep, at.num_attacks()))
				<< " " << at.name()
				<< markup::span_color("#808080", " · ", translation::dgettext("wesnoth", at.type().c_str()));
			if(base_ && !old_attack) {
				stats << " " << markup::span_color(font::GOOD_COLOR, _("attack^new"));
			}
		}
		std::vector<std::string> abilities;
		for(const auto& ab : sample.ability_tooltips()) {
			abilities.push_back(ab.name.str());
		}
		if(!abilities.empty()) {
			stats << "\n" << markup::span_color("#baac7d", utils::join(abilities, ", "));
		}
		column["label"] = stats.str();
		row_data.emplace("wn_advancement_stats", column);

		list.add_row(row_data);
	}

	list_item_clicked();

	// Disable ESC existing
	set_escape_disabled(true);
}

void unit_advance::list_item_clicked()
{
	const int selected_row
		= find_widget<listbox>("advance_choice").get_selected_row();

	if(selected_row == -1) {
		return;
	}

	// Westnorth: the phone layout shows the cards only (no preview pane).
	if(auto pane = find_widget<unit_preview_pane>("advancement_details", false, false)) {
		pane->set_display_data(*previews_[selected_row]);
	}
}

void unit_advance::show_help()
{
	help::show_help("advancement");
}

void unit_advance::post_show()
{
	if(get_retval() == retval::OK) {
		selected_index_ = find_widget<listbox>("advance_choice")
			.get_selected_row();
	}
}

} // namespace dialogs
