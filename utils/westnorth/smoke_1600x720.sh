#!/bin/bash
# Westnorth: smoke test at the Galaxy A06 screen size (1600x720 landscape).
# Opens the title screen and a test scenario in both UI themes and fails if
# the log shows a dialog that does not fit or a WML error. Catches layout
# regressions that the headless unit/WML tests cannot see (e.g. buttons made
# so tall that the title screen no longer fits 720 px and the game quits).
#
# Usage: utils/westnorth/smoke_1600x720.sh [WESNOTH_BINARY]
set -uo pipefail

bin=${1:-./wesnoth}
here=$(dirname "$0")
out=$(mktemp -d)
fail=0

run() {
	local name=$1 theme=$2
	shift 2
	WESTNORTH_TIPS=yes WESTNORTH_GUI_THEME=$theme WESTNORTH_DISPLAY=${WESTNORTH_DISPLAY:-79} \
		timeout 120 "$here/screenshot.sh" -b "$bin" "$out/$name" -- "$@" >/dev/null 2>&1
	if grep -E "Failed to size window|WML exception|doesn’t fit on the screen|não cabe na tela" "$out/$name/game.log"; then
		echo "FAIL $name (theme=$theme)"
		fail=1
	elif [ ! -s "$out/$name/screen.png" ]; then
		echo "FAIL $name: no screenshot (game exited early?)"
		tail -5 "$out/$name/game.log"
		fail=1
	else
		echo "ok   $name (theme=$theme)"
	fi
}

for theme in default celes; do
	run "title-$theme" "$theme"
	run "scenario-$theme" "$theme" -t westnorth_touch
done

echo "screenshots and logs: $out"
exit $fail
