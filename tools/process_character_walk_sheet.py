"""Normalize the generated 8x4 walk sheet into Godot's 64x80 frame grid."""

from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "godot/assets/generated/character/egyptian_worker_8frame_transparent.png"
OUTPUT = ROOT / "godot/assets/generated/character/egyptian_worker_8frame_sheet.png"
COLUMNS = 8
ROWS = 4
FRAME_WIDTH = 64
FRAME_HEIGHT = 80
ART_SIZE = 64
TOP_PADDING = 8


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
            cell = cell.resize((ART_SIZE, ART_SIZE), Image.Resampling.LANCZOS)
            output.alpha_composite(cell, (column * FRAME_WIDTH, row * FRAME_HEIGHT + TOP_PADDING))

    output.save(OUTPUT, optimize=True)
    print(f"Wrote {OUTPUT} ({output.width}x{output.height})")


if __name__ == "__main__":
    main()
