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


def projection_runs(values: list[bool], bridge: int = 8, minimum: int = 4) -> list[tuple[int, int]]:
    active = [index for index, value in enumerate(values) if value]
    if not active:
        return []
    runs: list[tuple[int, int]] = []
    start = previous = active[0]
    for value in active[1:]:
        if value - previous > bridge:
            if previous - start + 1 >= minimum: runs.append((start, previous + 1))
            start = value
        previous = value
    if previous - start + 1 >= minimum: runs.append((start, previous + 1))
    return runs


def component_frames(image: Image.Image, columns: int, rows: int) -> list[Image.Image]:
    """Extract generated figures by transparent gaps, avoiding nominal-grid clipping."""
    cleaned = clear_border_background(image)
    try:
        import cv2
        import numpy as np
        alpha = np.array(cleaned.getchannel("A"))
        count, labels, stats, centers = cv2.connectedComponentsWithStats((alpha > 20).astype("uint8"), 8)
    except ImportError:
        return []
    grouped: list[list[tuple[float, tuple[int, int, int, int]]]] = [[] for _ in range(rows)]
    for index in range(1, count):
        if stats[index, cv2.CC_STAT_AREA] < 500:
            continue
        left, top, width, height = (int(value) for value in stats[index, :4])
        cx, cy = centers[index]
        row = min(rows - 1, max(0, int(cy * rows / cleaned.height)))
        grouped[row].append((float(cx), (left, top, left + width, top + height)))
    frames: list[Image.Image] = []
    for row_components in grouped:
        row_components.sort(key=lambda value: value[0])
        if len(row_components) not in (columns, columns - 1):
            return []
        extracted: list[Image.Image] = []
        for _, (left, top, right, bottom) in row_components:
            frame = cleaned.crop((max(0, left - 3), max(0, top - 3), min(cleaned.width, right + 3), min(cleaned.height, bottom + 3)))
            extracted.append(frame)
        # Some generators place the final lateral pose beyond the canvas. Frame
        # zero is the cycle-closing contact pose and is the safe deterministic fill.
        if len(extracted) == columns - 1:
            extracted.append(extracted[0].copy())
        frames.extend(extracted)
    return frames


def pack(source: Path, output: Path, columns: int, rows: int, cell_w: int, cell_h: int, clean_border: bool, component_grid: bool) -> None:
    image = Image.open(source).convert("RGBA")
    atlas = Image.new("RGBA", (columns * cell_w, rows * cell_h), (0, 0, 0, 0))
    detected = component_frames(image, columns, rows) if component_grid else []
    for row in range(rows):
        for column in range(columns):
            box = (
                round(column * image.width / columns), round(row * image.height / rows),
                round((column + 1) * image.width / columns), round((row + 1) * image.height / rows),
            )
            frame = detected[row * columns + column] if detected else image.crop(box)
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
    parser.add_argument("--component-grid", action="store_true")
    args = parser.parse_args()
    pack(args.source, args.output, args.columns, args.rows, args.cell_width, args.cell_height, args.clean_border, args.component_grid)
