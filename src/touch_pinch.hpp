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

#pragma once

#include <cstdint>
#include <map>
#include <utility>

/**
 * Westnorth: two-finger pinch on the map, built from raw finger events so it
 * works on every platform (docs/westnorth/diagnostico-zoom.md).
 *
 * Feed it the finger events (positions in pixels); finger_motion() returns how
 * many zoom steps to apply (+ zoom in, - zoom out). One step each time the
 * distance between the two fingers grows or shrinks by @ref step_ratio since
 * the last step. A gesture is "pinch" from the moment a second finger touches
 * until the first finger of the next gesture touches the screen, so the
 * caller can ignore the tap/drag that the first finger would otherwise make.
 */
class touch_pinch
{
public:
	static constexpr double step_ratio = 1.25;

	void finger_down(std::int64_t id, double x, double y);
	int finger_motion(std::int64_t id, double x, double y);
	void finger_up(std::int64_t id);

	/** Two fingers are on the screen. */
	bool active() const { return fingers_.size() >= 2; }

	/** The current (or last, if no finger is down) gesture used two fingers. */
	bool happened() const { return happened_; }

	/** Midpoint between the first two fingers (0,0 with fewer than two). */
	std::pair<double, double> center() const;

private:
	struct point { double x, y; };

	double distance() const;

	std::map<std::int64_t, point> fingers_;
	double base_distance_ = 0.0;
	bool happened_ = false;
};
