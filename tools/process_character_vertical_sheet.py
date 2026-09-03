"""Normalize the generated 10x2 vertical walk sheet into 64x80 Godot frames."""

from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "godot/assets/generated/character/egyptian_worker_vertical_10frame_transparent.png"
OUTPUT = ROOT / "godot/assets/generated/character/egyptian_worker_vertical_10frame_sheet.png"
COLUMNS = 10
ROWS = 2
FRAME_WIDTH = 64
FRAME_HEIGHT = 80
MAX_ART_WIDTH = 60
MAX_ART_HEIGHT = 64
FOOT_BASELINE = 72


def occupied_runs(image: Image.Image) -> list[tuple[int, int]]:
    alpha = image.getchannel("A")
    occupied = [x for x in range(image.width) if alpha.crop((x, 0, x + 1, image.height)).getbbox()]
    runs: list[tuple[int, int]] = []
    start = previous = occupied[0]
    for x in occupied[1:]:
        if x > previous + 1:
            runs.append((start, previous + 1))
            start = x
        previous = x
    runs.append((start, previous + 1))
    return runs


def main() -> None:
    source = Image.open(SOURCE).convert("RGBA")
    output = Image.new("RGBA", (COLUMNS * FRAME_WIDTH, ROWS * FRAME_HEIGHT))

    for row in range(ROWS):
        top = round(row * source.height / ROWS)
        bottom = round((row + 1) * source.height / ROWS)
        source_row = source.crop((0, top, source.width, bottom))
        runs = occupied_runs(source_row)
        if len(runs) != COLUMNS:
            raise ValueError(f"Row {row}: expected {COLUMNS} isolated sprites, found {len(runs)}")
        for column, (left, right) in enumerate(runs):
            cell = source_row.crop((left, 0, right, source_row.height))
            bounds = cell.getbbox()
            if bounds is None:
                continue
            sprite = cell.crop(bounds)
            scale = min(MAX_ART_WIDTH / sprite.width, MAX_ART_HEIGHT / sprite.height)
            size = (round(sprite.width * scale), round(sprite.height * scale))
            sprite = sprite.resize(size, Image.Resampling.LANCZOS)
            x = column * FRAME_WIDTH + (FRAME_WIDTH - size[0]) // 2
            y = row * FRAME_HEIGHT + FOOT_BASELINE - size[1]
            output.alpha_composite(sprite, (x, y))

    output.save(OUTPUT, optimize=True)
    print(f"Wrote {OUTPUT} ({output.width}x{output.height})")


if __name__ == "__main__":
    main()
