#!/usr/bin/env python3
# Westnorth: draws the images of the phone HUD theme ("Westnorth",
# data/themes/westnorth.cfg) in the game's palette (docs/westnorth/
# redesenho-combate.md). Run from the repository root after changing sizes.
from PIL import Image, ImageDraw

SS = 4  # supersampling
PANEL = (9, 13, 22, 219)
BORDER = (162, 127, 68, 255)
BORDER_BRIGHT = (185, 158, 75, 255)
HILITE = (185, 158, 75, 90)
TITLE = (186, 172, 125, 255)


def rounded(size, radius, fill, border=None, width=1, top=None, bottom=None, hilite=True):
    w, h = size
    W, H, R = w * SS, h * SS, radius * SS
    im = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    if top and bottom:
        grad = Image.new("RGBA", (W, H))
        gd = ImageDraw.Draw(grad)
        for y in range(H):
            t = y / max(1, H - 1)
            gd.line([(0, y), (W, y)], fill=tuple(int(top[i] + (bottom[i] - top[i]) * t) for i in range(3)) + (255,))
        mask = Image.new("L", (W, H), 0)
        ImageDraw.Draw(mask).rounded_rectangle([0, 0, W - 1, H - 1], R, fill=255)
        im.paste(grad, (0, 0), mask)
    else:
        ImageDraw.Draw(im).rounded_rectangle([0, 0, W - 1, H - 1], R, fill=fill)
    d = ImageDraw.Draw(im)
    if border:
        d.rounded_rectangle([0, 0, W - 1, H - 1], R, outline=border, width=width * SS)
    if hilite:
        d.rounded_rectangle([width * SS, width * SS, W - 1 - width * SS, H - 1 - width * SS],
                            max(0, R - width * SS), outline=HILITE, width=SS)
    return im.resize((w, h), Image.LANCZOS)


def save(im, path):
    im.save(path)
    print(path, im.size)


hud = "images/westnorth/hud/"
save(rounded((560, 52), 26, PANEL, BORDER), hud + "top-pill.png")
save(rounded((440, 46), 23, PANEL, BORDER), hud + "chip.png")
save(rounded((246, 150), 10, PANEL, BORDER), hud + "minimap-frame.png")

card = rounded((640, 200), 12, PANEL, BORDER)
d = ImageDraw.Draw(card)
# "i" hint in the top right corner: the card opens the unit details
cx, cy, r = 622, 18, 8
d.ellipse([cx - r, cy - r, cx + r, cy + r], outline=(128, 128, 128, 255), width=2)
d.line([cx, cy - 4, cx, cy - 3], fill=(128, 128, 128, 255), width=2)
d.line([cx, cy - 1, cx, cy + 4], fill=(128, 128, 128, 255), width=2)
save(card, hud + "card.png")

save(rounded((250, 18), 4, (0, 0, 0, 160), (213, 213, 213, 160), hilite=False), hud + "bar18-bg.png")
save(Image.new("RGBA", (248, 16), (255, 255, 255, 255)), hud + "bar18-fill.png")
save(rounded((250, 8), 3, (0, 0, 0, 160), (213, 213, 213, 140), hilite=False), hud + "bar8-bg.png")
save(rounded((320, 22), 5, (0, 0, 0, 160), (213, 213, 213, 160), hilite=False), hud + "bar22-bg.png")
save(Image.new("RGBA", (318, 20), (255, 255, 255, 255)), hud + "bar22-fill.png")
save(Image.new("RGBA", (248, 6), (255, 255, 255, 255)), hud + "bar8-fill.png")

# Buttons: GUI1 needs <name>.png, -active, -pressed, -active-pressed.
btn = "images/buttons/westnorth/"
NORMAL = ((0x1d, 0x3d, 0x5c), (0x0a, 0x1b, 0x2c))
ACTIVE = ((0x27, 0x52, 0x7a), (0x10, 0x26, 0x3c))
PRESSED = ((0x0a, 0x1b, 0x2c), (0x1d, 0x3d, 0x5c))
PRIMARY = ((0x2a, 0x5a, 0x84), (0x0f, 0x2a, 0x44))
PRIMARY_ACTIVE = ((0x36, 0x6e, 0xa0), (0x14, 0x36, 0x56))


def states(name, size, radius, normal, active, border, width, decorate=None):
    for suffix, colors in (("", normal), ("-active", active), ("-pressed", PRESSED), ("-active-pressed", PRESSED)):
        im = rounded(size, radius, None, border, width, colors[0], colors[1])
        if decorate:
            decorate(im)
        save(im, btn + name + suffix + ".png")


def hamburger(im):
    d = ImageDraw.Draw(im)
    w, h = im.size
    for i in (-9, 0, 9):
        d.rounded_rectangle([w // 2 - 14, h // 2 + i - 2, w // 2 + 14, h // 2 + i + 2], 2, fill=TITLE)


states("hud_menu", (60, 52), 12, NORMAL, ACTIVE, BORDER, 1, hamburger)
states("hud_endturn", (300, 92), 46, PRIMARY, PRIMARY_ACTIVE, BORDER_BRIGHT, 2)
states("hud_round", (84, 84), 42, NORMAL, ACTIVE, BORDER, 1)
states("hud_round64", (64, 64), 32, NORMAL, ACTIVE, BORDER, 1)

# Invisible button over the unit card; a faint highlight while pressed.
for suffix, alpha in (("", 0), ("-active", 0), ("-pressed", 28), ("-active-pressed", 28)):
    save(rounded((640, 200), 12, (255, 255, 255, alpha), hilite=False), btn + "hud_card" + suffix + ".png")
