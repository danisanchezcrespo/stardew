"""Normalize one 10-frame right-facing row and mirror it for left-facing motion."""

from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "godot/assets/generated/character/egyptian_worker_lateral_10frame_transparent.png"
OUTPUT = ROOT / "godot/assets/generated/character/egyptian_worker_lateral_10frame_sheet.png"
COLUMNS = 10
SOURCE_ROWS = 1
OUTPUT_ROWS = 2
FRAME_WIDTH = 64
FRAME_HEIGHT = 80
ART_SIZE = 64
FOOT_BASELINE = 72


def main() -> None:
    source = Image.open(SOURCE).convert("RGBA")
    output = Image.new("RGBA", (COLUMNS * FRAME_WIDTH, OUTPUT_ROWS * FRAME_HEIGHT))

    for column in range(COLUMNS):
        left = round(column * source.width / COLUMNS)
        right = round((column + 1) * source.width / COLUMNS)
        cell = source.crop((left, 0, right, source.height // SOURCE_ROWS))
        bounds = cell.getbbox()
        if bounds is None:
            continue
        sprite = cell.crop(bounds)
        scale = min(ART_SIZE / sprite.width, ART_SIZE / sprite.height)
        size = (round(sprite.width * scale), round(sprite.height * scale))
        sprite = sprite.resize(size, Image.Resampling.LANCZOS)
        for row, directional_sprite in enumerate(
            (sprite.transpose(Image.Transpose.FLIP_LEFT_RIGHT), sprite)
        ):
            x = column * FRAME_WIDTH + (FRAME_WIDTH - size[0]) // 2
            y = row * FRAME_HEIGHT + FOOT_BASELINE - size[1]
            output.alpha_composite(directional_sprite, (x, y))

    output.save(OUTPUT, optimize=True)
    print(f"Wrote {OUTPUT} ({output.width}x{output.height})")


if __name__ == "__main__":
    main()
