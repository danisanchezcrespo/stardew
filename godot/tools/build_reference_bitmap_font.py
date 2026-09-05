"""Build a BMFont texture inspired by the supplied yellow/red/navy pixel lettering."""
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[1]
FONT_DIR = ROOT / "assets/fonts"
CELL = (24, 32)
COLUMNS = 16
CHARS = "".join(chr(value) for value in range(32, 127))
font = ImageFont.truetype(str(FONT_DIR / "AlegreyaSans-Bold.ttf"), 13)
rows = (len(CHARS) + COLUMNS - 1) // COLUMNS
atlas = Image.new("RGBA", (CELL[0] * COLUMNS, CELL[1] * rows))
for index, character in enumerate(CHARS):
    glyph = Image.new("RGBA", (CELL[0] // 2, CELL[1] // 2))
    draw = ImageDraw.Draw(glyph)
    shown = character.upper() if character.islower() else character
    box = draw.textbbox((0, 0), shown, font=font, stroke_width=1)
    width, height = box[2] - box[0], box[3] - box[1]
    x, y = (glyph.width - width) // 2 - box[0], (glyph.height - height) // 2 - box[1] - 1
    if character != " ":
        draw.text((x + 1, y + 1), shown, font=font, fill="#e7381f", stroke_width=1, stroke_fill="#17152c")
        draw.text((x, y), shown, font=font, fill="#ffdc45", stroke_width=1, stroke_fill="#17152c")
    atlas.alpha_composite(glyph.resize(CELL, Image.Resampling.NEAREST), ((index % COLUMNS) * CELL[0], (index // COLUMNS) * CELL[1]))
atlas_path = FONT_DIR / "settlement_pixel_font.png"
atlas.save(atlas_path, optimize=True)
lines = [
    'info face="Settlement Pixel" size=32 bold=1 italic=0 charset="" unicode=1 stretchH=100 smooth=0 aa=1 padding=0,0,0,0 spacing=0,0',
    f"common lineHeight=32 base=26 scaleW={atlas.width} scaleH={atlas.height} pages=1 packed=0",
    'page id=0 file="settlement_pixel_font.png"', f"chars count={len(CHARS)}",
]
for index, character in enumerate(CHARS):
    lines.append(f"char id={ord(character)} x={(index % COLUMNS) * CELL[0]} y={(index // COLUMNS) * CELL[1]} width={CELL[0]} height={CELL[1]} xoffset=0 yoffset=0 xadvance=20 page=0 chnl=15")
lines.append("kernings count=0")
(FONT_DIR / "settlement_pixel_font.fnt").write_text("\n".join(lines) + "\n", encoding="utf-8")
