#!/usr/bin/env python3
# Westnorth: 36 px icons for the long-press menu on touch screens
# (images/icons/action/<command>_36.png, used by command_executor::show_menu),
# drawn in the game's title gold with a dark outline. Run from the repo root.
from PIL import Image, ImageDraw
import math

SS = 6
S = 36
GOLD = (186, 172, 125, 255)
CREAM = (245, 230, 193, 255)
DARK = (0, 0, 0, 200)


def canvas():
    im = Image.new("RGBA", (S * SS, S * SS), (0, 0, 0, 0))
    return im, ImageDraw.Draw(im)


def p(x, y):
    return (x * SS, y * SS)


def line(d, pts, w, color):
    d.line([p(*q) for q in pts], fill=color, width=int(w * SS), joint="curve")
    for q in (pts[0], pts[-1]):
        r = w * SS / 2
        d.ellipse([q[0] * SS - r, q[1] * SS - r, q[0] * SS + r, q[1] * SS + r], fill=color)


def stroke(d, pts, w=3.0, color=GOLD):
    line(d, pts, w + 2, DARK)
    line(d, pts, w, color)


def save(im, name):
    im = im.resize((S, S), Image.LANCZOS)
    im.save(f"images/icons/action/{name}_36.png")
    print(name)


# Recruit: banner on a pole and a plus sign
im, d = canvas()
stroke(d, [(9, 31), (9, 5)])
d.polygon([p(10, 6), p(24, 9), p(10, 15)], fill=GOLD, outline=DARK)
# outlines first, then the fills, so one bar does not cut the other
line(d, [(26, 20), (26, 32)], 5, DARK)
line(d, [(20, 26), (32, 26)], 5, DARK)
line(d, [(26, 20), (26, 32)], 3, CREAM)
line(d, [(20, 26), (32, 26)], 3, CREAM)
save(im, "recruit")

# Recall: an arrow turning back
im, d = canvas()
pts = [(18 + 10 * math.cos(math.radians(a)), 19 + 10 * math.sin(math.radians(a))) for a in range(200, 470, 15)]
stroke(d, pts)
end = pts[-1]
stroke(d, [(end[0] - 7, end[1] - 1), end, (end[0] - 1, end[1] - 7)])
save(im, "recall")

# Unit description: "i" in a circle
im, d = canvas()
d.ellipse([p(5, 5)[0], p(5, 5)[1], p(31, 31)[0], p(31, 31)[1]], outline=DARK, width=5 * SS)
d.ellipse([p(5, 5)[0], p(5, 5)[1], p(31, 31)[0], p(31, 31)[1]], outline=GOLD, width=3 * SS)
stroke(d, [(18, 16), (18, 25)], 3.2, CREAM)
stroke(d, [(18, 11), (18, 11.2)], 3.6, CREAM)
save(im, "describeunit")

# Terrain description: mountains
im, d = canvas()
stroke(d, [(4, 29), (13, 12), (19, 22), (24, 15), (32, 29), (4, 29)])
save(im, "describeterrain")

# Map label: a tag
im, d = canvas()
stroke(d, [(6, 18), (16, 8), (29, 8), (29, 28), (16, 28), (6, 18)])
stroke(d, [(23, 14), (23.2, 14)], 3.4, CREAM)
save(im, "labelterrain")

# Clear labels: a tag with a cross
im, d = canvas()
stroke(d, [(6, 18), (16, 8), (29, 8), (29, 28), (16, 28), (6, 18)])
line(d, [(18, 13), (26, 23)], 4.6, DARK)
line(d, [(26, 13), (18, 23)], 4.6, DARK)
line(d, [(18, 13), (26, 23)], 2.6, CREAM)
line(d, [(26, 13), (18, 23)], 2.6, CREAM)
save(im, "clearlabels")

# Continue move: arrow to the right
im, d = canvas()
stroke(d, [(6, 18), (29, 18)])
stroke(d, [(21, 10), (29, 18), (21, 26)])
save(im, "continue")
