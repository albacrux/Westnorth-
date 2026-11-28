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

// Westnorth: two-finger pinch zoom (src/touch_pinch.hpp).

#define GETTEXT_DOMAIN "wesnoth-test"

#include <boost/test/unit_test.hpp>

#include "touch_pinch.hpp"

BOOST_AUTO_TEST_SUITE(test_touch_pinch)

BOOST_AUTO_TEST_CASE(one_finger_is_not_a_pinch)
{
	touch_pinch p;
	p.finger_down(1, 100, 100);
	BOOST_CHECK(!p.active());
	BOOST_CHECK_EQUAL(p.finger_motion(1, 400, 100), 0);
	p.finger_up(1);
	BOOST_CHECK(!p.happened());
}

BOOST_AUTO_TEST_CASE(spreading_zooms_in_one_step_per_ratio)
{
	touch_pinch p;
	p.finger_down(1, 100, 100);
	p.finger_down(2, 200, 100); // 100 px apart
	BOOST_CHECK(p.active());
	BOOST_CHECK(p.happened());
	BOOST_CHECK_EQUAL(p.finger_motion(2, 220, 100), 0);  // 120: below 125
	BOOST_CHECK_EQUAL(p.finger_motion(2, 226, 100), 1);  // 126: one step
	BOOST_CHECK_EQUAL(p.finger_motion(2, 230, 100), 0);  // 130: next step at 156.25
	BOOST_CHECK_EQUAL(p.finger_motion(2, 300, 100), 2);  // 200: 156.25 and 195.3
}

BOOST_AUTO_TEST_CASE(closing_zooms_out)
{
	touch_pinch p;
	p.finger_down(1, 0, 0);
	p.finger_down(2, 0, 400);
	BOOST_CHECK_EQUAL(p.finger_motion(1, 0, 90), -1); // 310 <= 320
	BOOST_CHECK_EQUAL(p.finger_motion(1, 0, 150), -1); // 250 <= 256
}

BOOST_AUTO_TEST_CASE(gesture_stays_a_pinch_until_the_next_first_finger)
{
	touch_pinch p;
	p.finger_down(1, 0, 0);
	p.finger_down(2, 100, 0);
	p.finger_up(2);
	BOOST_CHECK(!p.active());
	BOOST_CHECK_EQUAL(p.finger_motion(1, 500, 0), 0); // one finger left: no zoom
	p.finger_up(1);
	BOOST_CHECK(p.happened()); // the release of the last finger is still part of it
	p.finger_down(3, 10, 10);
	BOOST_CHECK(!p.happened()); // a new gesture
}

BOOST_AUTO_TEST_CASE(center_is_the_midpoint_of_the_fingers)
{
	touch_pinch p;
	p.finger_down(1, 100, 200);
	BOOST_CHECK(p.center() == std::make_pair(0.0, 0.0));
	p.finger_down(2, 300, 400);
	BOOST_CHECK(p.center() == std::make_pair(200.0, 300.0));
	p.finger_motion(2, 500, 200);
	BOOST_CHECK(p.center() == std::make_pair(300.0, 200.0));
}

BOOST_AUTO_TEST_SUITE_END()
