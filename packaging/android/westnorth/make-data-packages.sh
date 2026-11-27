#!/bin/bash
# Westnorth: build the game-data packages that the Android app downloads on start.
#
# The APK carries no game data. On launch InitActivity fetches manifest.txt from
# the fork's "nightly" GitHub release and downloads the packages it lists:
#
#   core   upstream data at the imported snapshot (CORE_REF). Large (~350 MB),
#          only rebuilt when the snapshot changes (bump CORE_GEN).
#   patch  every data file the fork added or changed since CORE_REF, plus a
#          delete.list for removed files. Cumulative, so a phone that has core
#          only needs the newest patch. Small; rebuilt on every merge.
#   music  upstream's music package from SourceForge (unchanged by the fork).
#
# The app only compares the third number of a version ("1.21.N"), so:
#   core.version  = 1.21.$CORE_GEN
#   patch.version = 1.21.$BUILD   (CI run number, always increasing)
#
# Usage: make-data-packages.sh <core|patch|manifest> <outdir>
#   env: CORE_REF (git ref of the upstream snapshot), CORE_GEN, BUILD, RELEASE_BASE
set -euo pipefail

mode=${1:?mode: core|patch|manifest}
out=$(realpath -m "${2:?output directory}")
repo=$(git rev-parse --show-toplevel)
CORE_REF=${CORE_REF:?CORE_REF must point at the upstream snapshot commit}
CORE_GEN=${CORE_GEN:?CORE_GEN must be set}
BUILD=${BUILD:-0}
RELEASE_BASE=${RELEASE_BASE:-https://github.com/albacrux/Westnorth-/releases/download}

# Top-level directories the app needs (same list as upstream create_patch.sh).
DATA_DIRS="data images sounds fonts"
# Music ships in its own package, reuse upstream's.
MUSIC_DIR="data/core/music"
# Translation domains compiled to .mo (po/CMakeLists.txt NORMAL_DOMAINS).
mapfile -t DOMAINS < <(sed -n '/^set(NORMAL_DOMAINS/,/^)/p' "$repo/po/CMakeLists.txt" | grep -E '^\s+wesnoth' | tr -d '[:space:]' | tr -d ')')

mkdir -p "$out"
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT

# Compile all .po files of a checked-out tree into <dest>/translations.
compile_mo() {
	local src=$1 dest=$2
	for domain in "${DOMAINS[@]}"; do
		[ -d "$src/po/$domain" ] || continue
		for po in "$src/po/$domain"/*.po; do
			[ -e "$po" ] || continue
			local lang
			lang=$(basename "$po" .po)
			mkdir -p "$dest/translations/$lang/LC_MESSAGES"
			msgfmt -o "$dest/translations/$lang/LC_MESSAGES/$domain.mo" "$po"
		done
	done
}

export_tree() {
	local ref=$1 dest=$2
	mkdir -p "$dest"
	git -C "$repo" archive --format=tar "$ref" $DATA_DIRS po | tar -x -C "$dest"
	rm -rf "${dest:?}/$MUSIC_DIR"
}

case "$mode" in
core)
	export_tree "$CORE_REF" "$work/core"
	compile_mo "$work/core" "$work/core"
	rm -rf "$work/core/po"
	(cd "$work/core" && zip -q -r -X "$out/core.zip" .)
	ls -la "$out/core.zip"
	;;
patch)
	# Compiled translations of the snapshot, to know which .mo files changed.
	export_tree "$CORE_REF" "$work/base"
	compile_mo "$work/base" "$work/base"
	export_tree HEAD "$work/head"
	compile_mo "$work/head" "$work/head"
	rm -rf "$work/base/po" "$work/head/po"

	mkdir -p "$work/patch"
	# Added or changed files (data + compiled translations).
	(cd "$work/head" && find . -type f -print0) | while IFS= read -r -d '' f; do
		if ! cmp -s "$work/head/$f" "$work/base/$f"; then
			mkdir -p "$work/patch/$(dirname "$f")"
			cp "$work/head/$f" "$work/patch/$f"
		fi
	done
	# Files removed by the fork. delete.list must sit in the zip root.
	: > "$work/patch/delete.list"
	(cd "$work/base" && find . -type f -print0) | while IFS= read -r -d '' f; do
		[ -e "$work/head/$f" ] || echo "${f#./}" >> "$work/patch/delete.list"
	done
	echo "patch: $(find "$work/patch" -type f | wc -l) files, $(wc -l < "$work/patch/delete.list") deletions"
	(cd "$work/patch" && zip -q -r -X "$out/patch.zip" .)
	ls -la "$out/patch.zip"
	;;
manifest)
	cat > "$out/manifest.txt" <<EOF
packages=core,patch,music
core.name=Westnorth Core Data
core.version=1.21.$CORE_GEN
core.url=$RELEASE_BASE/core-data-$CORE_GEN/core.zip
patch.name=Westnorth Changes
patch.version=1.21.$BUILD
patch.url=$RELEASE_BASE/nightly/patch.zip
patch.depends=core==1.21.$CORE_GEN
music.name=Music
music.version=1.19.18
music.url=https://sourceforge.net/projects/wesnoth/files/android-music/music.zip/download
EOF
	cat "$out/manifest.txt"
	;;
*)
	echo "unknown mode $mode" >&2
	exit 2
	;;
esac
