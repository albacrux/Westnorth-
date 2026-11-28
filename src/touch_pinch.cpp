/*
	Copyright (C) 2026 by the Westnorth fork
	Part of the Battle for Wesnoth Project https://www.wesnoth.org/

	This program is free software; you can redistribute it and/or modify
	it under the terms of the GNU General Public License as published by
	the Free Software Foundation; either version 2 of the License, or
	(at your option) any later version.
	This program is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY.

	See the COPYING file for more details.
*/

#include "touch_pinch.hpp"

#include <cmath>
#include <iterator>

void touch_pinch::finger_down(std::int64_t id, double x, double y)
{
	if(fingers_.empty()) {
		happened_ = false;
	}
	fingers_[id] = {x, y};
	if(fingers_.size() == 2) {
		happened_ = true;
		base_distance_ = distance();
	}
}

int touch_pinch::finger_motion(std::int64_t id, double x, double y)
{
	auto f = fingers_.find(id);
	if(f == fingers_.end()) {
		return 0;
	}
	f->second = {x, y};
	if(fingers_.size() != 2 || base_distance_ <= 0.0) {
		return 0;
	}

	const double d = distance();
	int steps = 0;
	while(d >= base_distance_ * step_ratio) {
		base_distance_ *= step_ratio;
		++steps;
	}
	while(d <= base_distance_ / step_ratio) {
		base_distance_ /= step_ratio;
		--steps;
	}
	return steps;
}

void touch_pinch::finger_up(std::int64_t id)
{
	fingers_.erase(id);
	if(fingers_.size() < 2) {
		base_distance_ = 0.0;
	}
}

std::pair<double, double> touch_pinch::center() const
{
	if(fingers_.size() < 2) {
		return {0.0, 0.0};
	}
	const point& a = fingers_.begin()->second;
	const point& b = std::next(fingers_.begin())->second;
	return {(a.x + b.x) / 2.0, (a.y + b.y) / 2.0};
}

double touch_pinch::distance() const
{
	if(fingers_.size() < 2) {
		return 0.0;
	}
	const point& a = fingers_.begin()->second;
	const point& b = std::next(fingers_.begin())->second;
	return std::hypot(a.x - b.x, a.y - b.y);
}
