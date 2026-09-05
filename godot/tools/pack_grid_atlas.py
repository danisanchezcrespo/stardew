"""Normalize generated grid art into exact game-ready cell dimensions."""
from collections import deque
from pathlib import Path
from PIL import Image
import argparse


def clear_border_background(frame: Image.Image) -> Image.Image:
    frame = frame.convert("RGBA")
    px = frame.load()
    width, height = frame.size
    seen: set[tuple[int, int]] = set()
    queue = deque()
    for x in range(width):
        queue.extend(((x, 0), (x, height - 1)))
    for y in range(height):
        queue.extend(((0, y), (width - 1, y)))
    while queue:
        x, y = queue.popleft()
        if (x, y) in seen:
            continue
        seen.add((x, y))
        r, g, b, a = px[x, y]
        # Generated sheets occasionally return transparent, white/magenta, or
        # black cell backdrops. Flood only from borders so dark subject outlines survive.
        background = a < 32 or max(r, g, b) < 38 or min(r, g, b) > 170 or (r > 180 and b > 170 and g < 80)
        if not background:
            continue
        px[x, y] = (r, g, b, 0)
        for nx, ny in ((x - 1, y), (x + 1, y), (x, y - 1), (x, y + 1)):
            if 0 <= nx < width and 0 <= ny < height and (nx, ny) not in seen:
                queue.append((nx, ny))
    return frame


def pack(source: Path, output: Path, columns: int, rows: int, cell_w: int, cell_h: int, clean_border: bool) -> None:
    image = Image.open(source).convert("RGBA")
    atlas = Image.new("RGBA", (columns * cell_w, rows * cell_h), (0, 0, 0, 0))
    for row in range(rows):
        for column in range(columns):
            box = (
                round(column * image.width / columns), round(row * image.height / rows),
                round((column + 1) * image.width / columns), round((row + 1) * image.height / rows),
            )
            frame = image.crop(box)
            if clean_border:
                frame = clear_border_background(frame)
            bounds = frame.getchannel("A").getbbox()
            if bounds is None:
                continue
            subject = frame.crop(bounds)
            subject.thumbnail((cell_w - 6, cell_h - 6), Image.Resampling.LANCZOS)
            x = column * cell_w + (cell_w - subject.width) // 2
            y = row * cell_h + cell_h - 3 - subject.height
            atlas.alpha_composite(subject, (x, y))
    output.parent.mkdir(parents=True, exist_ok=True)
    atlas.save(output)


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("source", type=Path)
    parser.add_argument("output", type=Path)
    parser.add_argument("--columns", type=int, required=True)
    parser.add_argument("--rows", type=int, required=True)
    parser.add_argument("--cell-width", type=int, required=True)
    parser.add_argument("--cell-height", type=int, required=True)
    parser.add_argument("--clean-border", action="store_true")
    args = parser.parse_args()
    pack(args.source, args.output, args.columns, args.rows, args.cell_width, args.cell_height, args.clean_border)
