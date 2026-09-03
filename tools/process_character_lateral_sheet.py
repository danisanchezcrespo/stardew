"""Normalize the generated 10x2 lateral walk sheet into 64x80 Godot frames."""

from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "godot/assets/generated/character/egyptian_worker_lateral_10frame_transparent.png"
OUTPUT = ROOT / "godot/assets/generated/character/egyptian_worker_lateral_10frame_sheet.png"
COLUMNS = 10
ROWS = 2
FRAME_WIDTH = 64
FRAME_HEIGHT = 80
ART_SIZE = 64
FOOT_BASELINE = 72


def main() -> None:
    source = Image.open(SOURCE).convert("RGBA")
    output = Image.new("RGBA", (COLUMNS * FRAME_WIDTH, ROWS * FRAME_HEIGHT))

    for row in range(ROWS):
        top = round(row * source.height / ROWS)
        bottom = round((row + 1) * source.height / ROWS)
        for column in range(COLUMNS):
            left = round(column * source.width / COLUMNS)
            right = round((column + 1) * source.width / COLUMNS)
            cell = source.crop((left, top, right, bottom))
            bounds = cell.getbbox()
            if bounds is None:
                continue
            sprite = cell.crop(bounds)
            scale = min(ART_SIZE / sprite.width, ART_SIZE / sprite.height)
            size = (round(sprite.width * scale), round(sprite.height * scale))
            sprite = sprite.resize(size, Image.Resampling.LANCZOS)
            x = column * FRAME_WIDTH + (FRAME_WIDTH - size[0]) // 2
            y = row * FRAME_HEIGHT + FOOT_BASELINE - size[1]
            output.alpha_composite(sprite, (x, y))

    output.save(OUTPUT, optimize=True)
    print(f"Wrote {OUTPUT} ({output.width}x{output.height})")


if __name__ == "__main__":
    main()
