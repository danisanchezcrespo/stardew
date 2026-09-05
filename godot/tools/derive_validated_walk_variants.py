"""Palette-costume variants that retain the validated Egypt pose sequence exactly."""
from pathlib import Path
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "assets/generated/character"


def egypt_sheet(female: bool) -> Image.Image:
    result = Image.new("RGBA", (640, 320))
    prefix = "egyptian_worker" if female else "egyptian_man"
    lateral = f"{prefix}_lateral_10frame_sheet.png" if female else f"{prefix}_lateral_sheet.png"
    vertical = f"{prefix}_vertical_10frame_sheet.png" if female else f"{prefix}_vertical_sheet.png"
    result.alpha_composite(Image.open(SOURCE / lateral).convert("RGBA"), (0, 0))
    result.alpha_composite(Image.open(SOURCE / vertical).convert("RGBA"), (0, 160))
    return result


def variant(era: str, female: bool) -> Image.Image:
    result = egypt_sheet(female)
    pixels = result.load()
    for y in range(result.height):
        for x in range(result.width):
            r, g, b, a = pixels[x, y]
            if a < 12:
                pixels[x, y] = (0, 0, 0, 0)
                continue
            blue = b > r * 1.12 and b > g * 1.03
            pale = min(r, g, b) > 125 and max(r, g, b) - min(r, g, b) < 90
            skin = r > 95 and r > g * 1.10 and g > b * 1.08
            local_y = y % 80
            if era == "prehistory":
                if blue: pixels[x, y] = (max(45, int(r * .55)), max(29, int(g * .38)), max(20, int(b * .22)), a)
                elif pale: pixels[x, y] = (min(255, int(r * 1.02)), int(g * .87), int(b * .60), a)
            elif era == "medieval":
                if blue: pixels[x, y] = (min(190, int(b * .70)), int(g * .34), int(r * .42), a)
                elif pale: pixels[x, y] = (min(255, int(r * 1.03)), int(g * .94), int(b * .78), a)
                elif skin and not female and local_y > 45: pixels[x, y] = (67, 45, 34, a)
            elif era == "mars":
                if not skin and max(r, g, b) < 105: pixels[x, y] = (10, 28, 44, a)
                elif blue: pixels[x, y] = (20, min(235, int(g * 1.22)), min(255, int(b * 1.18)), a)
                elif pale: pixels[x, y] = (224, 238, 240, a)
                elif skin and local_y > 28: pixels[x, y] = (218, 231, 235, a)
    if era == "mars":
        original = result
        helmets = Image.new("RGBA", result.size)
        draw = ImageDraw.Draw(helmets)
        for row in range(4):
            for column in range(10):
                frame = original.crop((column * 64, row * 80, column * 64 + 64, row * 80 + 80))
                box = frame.getchannel("A").getbbox()
                if box:
                    cx, cy = column * 64 + (box[0] + box[2]) // 2, row * 80 + box[1] + 12
                    draw.ellipse((cx - 13, cy - 13, cx + 13, cy + 13), fill=(12, 44, 65, 215), outline=(74, 222, 238, 255), width=3)
        helmets.alpha_composite(original)
        result = helmets
    return result


for era in ("prehistory", "medieval", "mars"):
    stem = f"{era}_{'hunter' if era == 'prehistory' else 'character' if era == 'medieval' else 'colonist'}"
    variant(era, False).save(ROOT / f"assets/generated/{era}/{stem}.png", optimize=True)
    variant(era, True).save(ROOT / f"assets/generated/{era}/{stem}_female.png", optimize=True)
