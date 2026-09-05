from collections import deque
from pathlib import Path
from PIL import Image, ImageDraw
import math

ROOT = Path(__file__).resolve().parents[1]
GENERATED = ROOT / "assets" / "generated"


def mirrored_tile(source: Path, output: Path) -> Image.Image:
    image = Image.open(source).convert("RGB").resize((256, 256), Image.Resampling.LANCZOS)
    quadrant = image.crop((96, 96, 160, 160))
    tile = Image.new("RGB", (128, 128))
    tile.paste(quadrant, (0, 0))
    tile.paste(quadrant.transpose(Image.Transpose.FLIP_LEFT_RIGHT), (64, 0))
    tile.paste(quadrant.transpose(Image.Transpose.FLIP_TOP_BOTTOM), (0, 64))
    tile.paste(quadrant.transpose(Image.Transpose.ROTATE_180), (64, 64))
    tile.save(output)
    return tile


def shoreline_atlas(sand: Image.Image, output: Path) -> None:
    cell = 64
    atlas = Image.new("RGBA", (cell * 4, cell * 4), (0, 0, 0, 0))
    for bits in range(16):
        mask = Image.new("L", (cell, cell), 0)
        pixels = mask.load()
        for y in range(cell):
            for x in range(cell):
                wave_x = 10 + 2.2 * math.sin((y + bits * 7) * 0.23) + 1.2 * math.sin(y * 0.53)
                wave_y = 10 + 2.2 * math.sin((x + bits * 5) * 0.21) + 1.2 * math.sin(x * 0.47)
                north = bool(bits & 1) and y < wave_y
                east = bool(bits & 2) and x > cell - 1 - wave_x
                south = bool(bits & 4) and y > cell - 1 - wave_y
                west = bool(bits & 8) and x < wave_x
                alpha = 255 if north or east or south or west else 0
                # A soft wet-sand fringe makes the join readable without a hard square edge.
                if alpha == 0:
                    distances = []
                    if bits & 1: distances.append(y - wave_y)
                    if bits & 2: distances.append((cell - 1 - wave_x) - x)
                    if bits & 4: distances.append((cell - 1 - wave_y) - y)
                    if bits & 8: distances.append(x - wave_x)
                    if distances and min(distances) < 3: alpha = 150
                pixels[x, y] = alpha
        phase_x = (bits % 2) * 64
        phase_y = ((bits // 2) % 2) * 64
        patch = sand.crop((phase_x, phase_y, phase_x + 64, phase_y + 64)).convert("RGBA")
        patch.putalpha(mask)
        atlas.paste(patch, ((bits % 4) * cell, (bits // 4) * cell), patch)
    atlas.save(output)


def inner_corner_atlas(sand: Image.Image, output: Path) -> None:
    cell = 64
    atlas = Image.new("RGBA", (cell * 4, cell), (0, 0, 0, 0))
    corners = [(0, 0), (cell - 1, 0), (cell - 1, cell - 1), (0, cell - 1)]
    for index, (cx, cy) in enumerate(corners):
        mask = Image.new("L", (cell, cell), 0)
        pixels = mask.load()
        for y in range(cell):
            for x in range(cell):
                radius = 15 + 1.8 * math.sin((x + y + index * 9) * 0.35)
                distance = math.hypot(x - cx, y - cy)
                pixels[x, y] = 255 if distance < radius else (140 if distance < radius + 2.5 else 0)
        patch = sand.crop((0, 0, cell, cell)).convert("RGBA")
        patch.putalpha(mask)
        atlas.paste(patch, (index * cell, 0), patch)
    atlas.save(output)


def clean_tree_sheet(source: Path, output: Path) -> None:
    image = Image.open(source).convert("RGBA")
    width, height = image.size
    pixels = image.load()
    for y in range(height):
        for x in range(width):
            r, g, b, a = pixels[x, y]
            magenta = r > 105 and b > 105 and (r + b) * 0.5 - g > 38
            if magenta:
                pixels[x, y] = (r, g, b, 0)
    # Remove disconnected chroma remnants independently from each animation cell.
    cell_width = width // 4
    for cell_index in range(4):
        left = cell_index * cell_width
        visited = set()
        components = []
        for y in range(height):
            for x in range(left, left + cell_width):
                if (x, y) in visited or pixels[x, y][3] < 32:
                    continue
                queue = deque([(x, y)])
                visited.add((x, y))
                component = []
                while queue:
                    px, py = queue.popleft()
                    component.append((px, py))
                    for nx, ny in ((px - 1, py), (px + 1, py), (px, py - 1), (px, py + 1)):
                        if left <= nx < left + cell_width and 0 <= ny < height and (nx, ny) not in visited and pixels[nx, ny][3] >= 32:
                            visited.add((nx, ny)); queue.append((nx, ny))
                components.append(component)
        if components:
            keep = set(max(components, key=len))
            for component in components:
                if component is not max(components, key=len):
                    for x, y in component: pixels[x, y] = (*pixels[x, y][:3], 0)
    image.save(output)


def normalize_tree_sheet(source: Path, output: Path) -> None:
    """Give every generated stage an exact, roomy atlas cell without distorting it."""
    image = Image.open(source).convert("RGBA")
    width, height = image.size
    # Square cells keep source and destination scaling uniform in Godot.
    cell_size = (512, 512)
    atlas = Image.new("RGBA", (cell_size[0] * 4, cell_size[1]), (0, 0, 0, 0))
    alpha = image.getchannel("A")
    runs = []
    start = None
    for x in range(width):
        occupied = alpha.crop((x, 0, x + 1, height)).getbbox() is not None
        if occupied and start is None: start = x
        if not occupied and start is not None:
            runs.append((start, x)); start = None
    if start is not None: runs.append((start, width))
    if len(runs) != 4:
        raise ValueError(f"Expected four separated growth stages, found {len(runs)}")
    for index, (left, right) in enumerate(runs):
        stage_alpha = alpha.crop((left, 0, right, height))
        bounds = stage_alpha.getbbox()
        top = bounds[1] if bounds else 0
        bottom = bounds[3] if bounds else height
        stage = image.crop((max(0, left - 8), max(0, top - 8), min(width, right + 8), min(height, bottom + 8)))
        stage.thumbnail((cell_size[0] - 32, cell_size[1] - 32), Image.Resampling.LANCZOS)
        x = index * cell_size[0] + (cell_size[0] - stage.width) // 2
        y = cell_size[1] - stage.height - 16
        atlas.alpha_composite(stage, (x, y))
    atlas.save(output)


if __name__ == "__main__":
    terrain = GENERATED / "terrain"
    crops = GENERATED / "crops"
    sand = mirrored_tile(terrain / "sand_v2_source.png", terrain / "sand_v2.png")
    mirrored_tile(terrain / "water_v2_source.png", terrain / "water_v2.png")
    shoreline_atlas(sand, terrain / "shoreline_v2.png")
    inner_corner_atlas(sand, terrain / "shoreline_inner_corners_v2.png")
    clean_tree_sheet(crops / "tree_growth_source.png", crops / "tree_growth_v2.png")
    normalize_tree_sheet(crops / "tree_growth_v3.png", crops / "tree_growth_v3.png")
