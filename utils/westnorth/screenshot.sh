#!/bin/bash
# Westnorth: run the game in a virtual 1600x720 screen (the Galaxy A06 in
# landscape) and take screenshots, optionally following a small script of
# taps/clicks. Used for the before/after captures of UI pull requests.
#
# Usage:
#   utils/westnorth/screenshot.sh [-b BINARY] [-s SCRIPT] OUTDIR -- [wesnoth args...]
#
# SCRIPT is a text file, one command per line:
#   sleep SECONDS
#   click X Y        left mouse click
#   tap X Y          finger tap (needs a build with -DMOUSE_TOUCH_EMULATION,
#                    where the right mouse button acts as a finger)
#   longpress X Y    finger held for 1.2 s
#   drag X1 Y1 X2 Y2 finger drag
#   key KEYSYM       e.g. Return, Escape, ctrl+r
#   shot NAME        save OUTDIR/NAME.png
# Without a script it waits 25 s and saves OUTDIR/screen.png.
# Env: WESTNORTH_GUI_THEME=celes|default (UI theme), WESTNORTH_TIPS=yes (title tips).
#
# Example:
#   utils/westnorth/screenshot.sh out -- -c The_Rise_of_Wesnoth --campaign-skip-story
set -euo pipefail

bin=./wesnoth
script=""
while getopts "b:s:" opt; do
	case $opt in
		b) bin=$OPTARG ;;
		s) script=$OPTARG ;;
		*) exit 2 ;;
	esac
done
shift $((OPTIND - 1))
outdir=${1:?output directory}
shift
[ "${1:-}" = "--" ] && shift
mkdir -p "$outdir"

display=:${WESTNORTH_DISPLAY:-77}
userdata=$(mktemp -d)
export XDG_RUNTIME_DIR=${XDG_RUNTIME_DIR:-$(mktemp -d)}
chmod 700 "$XDG_RUNTIME_DIR"

Xvfb "$display" -screen 0 1600x720x24 -nolisten tcp >/dev/null 2>&1 &
xvfb_pid=$!
cleanup() {
	kill "${game_pid:-}" 2>/dev/null || true
	sleep 1
	kill -9 "${game_pid:-}" 2>/dev/null || true
	kill "$xvfb_pid" 2>/dev/null || true
	rm -rf "$userdata"
}
trap cleanup EXIT
sleep 1
export DISPLAY=$display

# Fixed preferences so captures are comparable: pt_BR, no sound, full window.
mkdir -p "$userdata/logs"  # an existing logs dir skips the first-run migration dialog
cat > "$userdata/preferences" <<EOF
locale="pt_BR"
fullscreen=no
maximized=no
xresolution=1600
yresolution=720
sound=no
music=no
turbo=yes
show_tip_of_day=${WESTNORTH_TIPS:-no}
gui2_theme="${WESTNORTH_GUI_THEME:-}"
EOF
"$bin" --nobanner --no-log-to-file --userdata-dir "$userdata" -r 1600x720 --windowed \
	--nosound --nomusic "$@" >"$outdir/game.log" 2>&1 &
game_pid=$!

move_window() {
	# Keep the game window at the origin so script coordinates match the capture.
	local w
	w=$(xdotool search --pid "$game_pid" 2>/dev/null | head -1 || true)
	[ -n "$w" ] && xdotool windowmove "$w" 0 0 2>/dev/null || true
}

shot() { move_window; import -window root "$outdir/$1.png"; echo "saved $outdir/$1.png"; }

if [ -z "$script" ]; then
	sleep 25
	kill -0 "$game_pid" 2>/dev/null || { echo "game exited, see $outdir/game.log" >&2; exit 1; }
	shot screen
	exit 0
fi

sleep 3
move_window
while read -r cmd a b c d; do
	case "$cmd" in
		""|\#*) ;;
		sleep) sleep "$a" ;;
		click) xdotool mousemove "$a" "$b" click 1 ;;
		tap) xdotool mousemove "$a" "$b" mousedown 3; sleep 0.08; xdotool mouseup 3 ;;
		longpress) xdotool mousemove "$a" "$b" mousedown 3; sleep 1.2; xdotool mouseup 3 ;;
		drag)
			xdotool mousemove "$a" "$b" mousedown 3
			for i in 1 2 3 4 5 6 7 8; do
				xdotool mousemove $((a + (c - a) * i / 8)) $((b + (d - b) * i / 8)); sleep 0.03
			done
			sleep 0.3  # let the game see the motion before the release
			xdotool mouseup 3 ;;
		key) xdotool key "$a" ;;
		shot) shot "$a" ;;
		*) echo "unknown command: $cmd" >&2; exit 2 ;;
	esac
	kill -0 "$game_pid" 2>/dev/null || { echo "game exited, see $outdir/game.log" >&2; exit 1; }
done < "$script"
