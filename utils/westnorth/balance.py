#!/usr/bin/env python3
# Westnorth: headless AI-vs-AI games to check balance (roadmap M7).
#
# Plays N games per side order (the two factions swap starting positions) with
# different RNG seeds and prints win rates per faction and per side. The result
# of each game comes from the "westnorth-result" line printed by
# data/westnorth/lua/report.lua, which the 2p Encruzilhada scenario loads for
# any era.
#
# Usage:
#   utils/westnorth/balance.py -n 20                    # Westnorth factions
#   utils/westnorth/balance.py -n 20 --era era_default --factions Loyalists Loyalists
#                                                       # mirror match: measures the map itself
# AI-vs-AI is only a rough signal (the AI never changes classes, for one): use it
# to catch a lopsided faction or map, not to fine-tune numbers.
import argparse
import collections
import os
import re
import subprocess
import sys
import tempfile

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
SCENARIO = "westnorth_2p_encruzilhada"
RESULT = re.compile(r"westnorth-result reason=(\w+)(?: loser=(\d+):(\S+))? turn=(\d+)")


def play(binary, era, f1, f2, seed, turns, userdata, scenario=SCENARIO):
    """Returns (winner_side or None for a draw or "error", turn)."""
    cmd = [binary, "--nogui", "--noaddons", "--nobanner", "--no-log-to-file",
           "--userdata-dir", userdata, "-m", "--scenario", scenario, "--era", era,
           "--side", f"1:{f1}", "--side", f"2:{f2}",
           "--controller", "1:ai", "--controller", "2:ai",
           "--turns", str(turns), "--rng-seed", str(seed)]
    env = dict(os.environ, SDL_VIDEODRIVER="dummy")
    out = subprocess.run(cmd, cwd=ROOT, env=env, capture_output=True, text=True, timeout=600)
    for line in (out.stdout + out.stderr).splitlines():
        m = RESULT.search(line)
        if m:
            reason, loser_side, _, turn = m.groups()
            if reason == "leader_killed":
                return (2 if loser_side == "1" else 1), int(turn)
            return None, int(turn)
    return "error", 0


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("-n", type=int, default=10, help="games per side order")
    ap.add_argument("-b", default=os.path.join(ROOT, "wesnoth"), help="wesnoth binary")
    ap.add_argument("--turns", type=int, default=40)
    ap.add_argument("--era", default="westnorth_classes")
    ap.add_argument("--factions", nargs=2, default=["WN_Crown", "WN_Shadow"])
    ap.add_argument("--scenario", default=SCENARIO, help="must load {WN_RESULT_REPORT}")
    args = ap.parse_args()
    fa, fb = args.factions

    by_faction = collections.Counter()
    by_side = collections.Counter()
    turns = []
    draws = errors = games = 0
    with tempfile.TemporaryDirectory() as userdata:
        for order in ((fa, fb), (fb, fa)):
            for i in range(args.n):
                seed = 1000 + i
                side, turn = play(args.b, args.era, order[0], order[1], seed, args.turns, userdata, args.scenario)
                games += 1
                if side == "error":
                    errors += 1
                    label = "ERRO"
                elif side is None:
                    draws += 1
                    label = "empate"
                else:
                    by_side[side] += 1
                    turns.append(turn)
                    label = f"lado {side} ({order[side - 1]})"
                    if fa != fb:
                        by_faction[order[side - 1]] += 1
                print(f"{order[0]} x {order[1]}, semente {seed}: vence {label}, turno {turn}", flush=True)

    print(f"\n{games} partidas ({errors} com erro, {draws} empates), turno médio "
          f"{sum(turns) / len(turns) if turns else 0:.1f}")
    for side in (1, 2):
        print(f"  lado {side}: {by_side[side]} vitórias ({100 * by_side[side] / games:.0f}%)")
    if fa != fb:
        for f in (fa, fb):
            print(f"  {f}: {by_faction[f]} vitórias ({100 * by_faction[f] / games:.0f}%)")
    return 1 if errors else 0


if __name__ == "__main__":
    sys.exit(main())
