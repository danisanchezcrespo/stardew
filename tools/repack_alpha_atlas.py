"""Repack separated alpha sprites into a strict, evenly divided atlas."""
from collections import deque
from pathlib import Path
import sys

from PIL import Image


def main() -> None:
    path = Path(sys.argv[1])
    columns = int(sys.argv[2])
    rows = int(sys.argv[3])
    image = Image.open(path).convert("RGBA")
    width, height = image.size
    alpha = image.getchannel("A")
    pixels = alpha.load()
    seen = bytearray(width * height)
    components: list[tuple[int, tuple[int, int, int, int], float, float]] = []
    for y in range(height):
        for x in range(width):
            offset = y * width + x
            if seen[offset] or pixels[x, y] < 24:
                continue
            queue = deque([(x, y)])
            seen[offset] = 1
            count = total_x = total_y = 0
            left = right = x
            top = bottom = y
            while queue:
                px, py = queue.popleft()
                count += 1
                total_x += px
                total_y += py
                left, right = min(left, px), max(right, px)
                top, bottom = min(top, py), max(bottom, py)
                for nx, ny in ((px - 1, py), (px + 1, py), (px, py - 1), (px, py + 1)):
                    if nx < 0 or ny < 0 or nx >= width or ny >= height:
                        continue
                    neighbor = ny * width + nx
                    if not seen[neighbor] and pixels[nx, ny] >= 24:
                        seen[neighbor] = 1
                        queue.append((nx, ny))
            if count >= 12:
                components.append((count, (left, top, right + 1, bottom + 1), total_x / count, total_y / count))

    cell_width, cell_height = width // columns, height // rows
    groups: list[list[tuple[int, tuple[int, int, int, int], float, float]]] = [[] for _ in range(columns * rows)]
    for component in components:
        _, _, center_x, center_y = component
        column = min(columns - 1, max(0, int(center_x / cell_width)))
        row = min(rows - 1, max(0, int(center_y / cell_height)))
        groups[row * columns + column].append(component)

    output = Image.new("RGBA", (cell_width * columns, cell_height * rows))
    margin = max(8, min(cell_width, cell_height) // 24)
    for index, group in enumerate(groups):
        if not group:
            continue
        # Tiny detached particles belong to the nearest dominant sprite in the
        # same cell; their union preserves smoke, grain and loose coins.
        left = min(item[1][0] for item in group)
        top = min(item[1][1] for item in group)
        right = max(item[1][2] for item in group)
        bottom = max(item[1][3] for item in group)
        sprite = image.crop((left, top, right, bottom))
        scale = min((cell_width - margin * 2) / sprite.width, (cell_height - margin * 2) / sprite.height, 1.0)
        if scale < 1.0:
            sprite = sprite.resize((max(1, round(sprite.width * scale)), max(1, round(sprite.height * scale))), Image.Resampling.LANCZOS)
        column, row = index % columns, index // columns
        x = column * cell_width + (cell_width - sprite.width) // 2
        y = row * cell_height + (cell_height - sprite.height) // 2
        output.alpha_composite(sprite, (x, y))
    output.save(path)


if __name__ == "__main__":
    main()
