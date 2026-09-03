from pathlib import Path
from PIL import Image

source = Path("godot/assets/generated/buildings/egypt_buildings_source.png")
target = source.with_name("egypt_buildings_sheet.png")
image = Image.open(source).convert("RGBA")
pixels = image.load()
for y in range(image.height):
    for x in range(image.width):
        red, green, blue, alpha = pixels[x, y]
        if red > 120 and blue > 100 and red > green * 1.45 and blue > green * 1.35:
            pixels[x, y] = (red, green, blue, 0)

sheet = Image.new("RGBA", (1024, 256))
bounds = [round(image.width * index / 4) for index in range(5)]
for index in range(4):
    cell = image.crop((bounds[index], 0, bounds[index + 1], image.height))
    box = cell.getbbox()
    if box is None:
        continue
    sprite = cell.crop(box)
    scale = min(240 / sprite.width, 240 / sprite.height)
    size = (round(sprite.width * scale), round(sprite.height * scale))
    sprite = sprite.resize(size, Image.Resampling.LANCZOS)
    sheet.alpha_composite(sprite, (index * 256 + (256 - size[0]) // 2, 256 - size[1]))
sheet.save(target)
