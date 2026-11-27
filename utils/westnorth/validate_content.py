#!/usr/bin/env python3
# Westnorth: static checks for the fork's own content in data/westnorth
# (roadmap M2 "script de validação de dados"). Cheap, no game binary needed,
# runs in the CI "checks" job.
#
# Checks:
#   - every [unit_type] has id, name, cost, description and a [base_unit] (or image)
#   - [base_unit] ids exist in data/core/units
#   - advances_to targets exist (fork or core) or are "null"
#   - every era recruit/leader id exists
#   - every Lua class level in data/westnorth/lua/classes.lua exists
#   - map files are rectangular and have exactly the starting positions their scenario needs
#   - basic balance sanity: level 1 cost 10..25, level 2 cost > level 1 of its class
import glob
import os
import re
import sys

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
errors = []


def err(msg):
    errors.append(msg)


def read(path):
    with open(path, encoding="utf-8") as f:
        return f.read()


def blocks(text, tag):
    """Top-level-ish [tag]...[/tag] blocks (no nesting of the same tag in our files)."""
    return re.findall(r"\[%s\](.*?)\[/%s\]" % (tag, tag), text, re.S)


def key(block, name):
    m = re.search(r"^\s*%s\s*=\s*(.*)$" % re.escape(name), block, re.M)
    return m.group(1).strip().strip('"') if m else None


def core_unit_ids():
    ids = set()
    for path in glob.glob(os.path.join(ROOT, "data/core/units/**/*.cfg"), recursive=True):
        for m in re.finditer(r"^\[unit_type\]\s*\n\s*id\s*=\s*(.+)$", read(path), re.M):
            ids.add(m.group(1).strip())
    return ids


def main():
    core = core_unit_ids()
    fork = {}
    for path in glob.glob(os.path.join(ROOT, "data/westnorth/units/*.cfg")):
        text = read(path)
        for b in blocks(text, "unit_type"):
            uid = key(b, "id")
            if not uid:
                err(f"{path}: [unit_type] without id")
                continue
            fork[uid] = b
            for k in ("name", "cost", "description"):
                if key(b, k) is None:
                    err(f"{uid}: missing {k}=")
            base = re.search(r"\[base_unit\]\s*id\s*=\s*(.+?)\s*\[/base_unit\]", b, re.S)
            if base:
                if base.group(1).strip() not in core:
                    err(f"{uid}: [base_unit] id={base.group(1).strip()} does not exist in data/core/units")
            elif key(b, "image") is None:
                err(f"{uid}: neither [base_unit] nor image=")
    known = core | set(fork)
    for uid, b in fork.items():
        adv = key(b, "advances_to")
        if adv and adv != "null":
            for target in adv.split(","):
                if target.strip() not in known:
                    err(f"{uid}: advances_to={target.strip()} does not exist")

    for path in glob.glob(os.path.join(ROOT, "data/westnorth/era/*.cfg")):
        for side in blocks(read(path), "multiplayer_side"):
            for k in ("recruit", "leader", "random_leader"):
                for t in (key(side, k) or "").split(","):
                    if t.strip() and t.strip() not in known:
                        err(f"{path}: {k} unit {t.strip()} does not exist")

    lua = read(os.path.join(ROOT, "data/westnorth/lua/classes.lua"))
    for t in re.findall(r'levels\s*=\s*\{\s*"([^"]+)",\s*"([^"]+)"\s*\}', lua):
        for i, tid in enumerate(t):
            if tid not in fork:
                err(f"classes.lua: level {i + 1} type {tid} is not a fork unit type")
                continue
            cost = int(key(fork[tid], "cost") or 0)
            if i == 0 and not 10 <= cost <= 25:
                err(f"{tid}: level 1 cost {cost} outside 10..25")
            if i == 1 and cost <= int(key(fork[t[0]], "cost") or 0):
                err(f"{tid}: level 2 must cost more than {t[0]}")

    for path in glob.glob(os.path.join(ROOT, "data/westnorth/scenarios/*.cfg")):
        text = read(path)
        map_file = key(text, "map_file")
        sides = len(re.findall(r"^\s*\[side\]", text, re.M))
        if not map_file:
            continue
        rows = [r for r in read(os.path.join(ROOT, "data", map_file)).splitlines() if r.strip()]
        widths = {len(r.split(",")) for r in rows}
        if len(widths) != 1:
            err(f"{map_file}: rows have different widths {sorted(widths)}")
        starts = re.findall(r"(?:^|,)\s*(\d+) ", "\n".join(rows), re.M)
        if sorted(int(s) for s in starts) != list(range(1, sides + 1)):
            err(f"{map_file}: starting positions {sorted(starts)} do not match {sides} sides")

    for e in errors:
        print("ERROR:", e)
    print(f"validate_content: {len(fork)} unit types, {len(errors)} error(s)")
    return 1 if errors else 0


if __name__ == "__main__":
    sys.exit(main())
