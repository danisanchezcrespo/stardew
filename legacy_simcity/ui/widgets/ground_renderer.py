from pathlib import Path

from PIL import Image


class GroundRenderer:
    def __init__(self, texture_path: str | Path) -> None:
        self.texture_path = Path(texture_path)
        self._source_tile: Image.Image | None = None
        self._scaled_tile_cache: dict[int, Image.Image] = {}

    def _load_source_tile(self) -> Image.Image | None:
        if self._source_tile is not None:
            return self._source_tile

        if not self.texture_path.exists():
            return None

        try:
            self._source_tile = Image.open(self.texture_path).convert("RGBA")
        except Exception:
            self._source_tile = None

        return self._source_tile

    def _get_scaled_tile(self, target_size: int) -> Image.Image | None:
        target_size = max(8, int(target_size))

        cached = self._scaled_tile_cache.get(target_size)
        if cached is not None:
            return cached

        source = self._load_source_tile()
        if source is None:
            return None

        if source.width == target_size and source.height == target_size:
            tile = source
        else:
            tile = source.resize((target_size, target_size), Image.LANCZOS)

        self._scaled_tile_cache[target_size] = tile
        return tile

    def draw(
        self,
        frame: Image.Image,
        *,
        width: int,
        height: int,
        cell_size: int,
        pan_x: float,
        pan_y: float,
    ) -> None:
        tile = self._get_scaled_tile(cell_size)
        if tile is None:
            return

        tile_size = tile.width
        if tile_size <= 0:
            return

        offset_x = int(pan_x) % tile_size
        offset_y = int(pan_y) % tile_size

        start_x = -offset_x - tile_size
        start_y = -offset_y - tile_size

        y = start_y
        while y < height + tile_size:
            x = start_x
            while x < width + tile_size:
                frame.alpha_composite(tile, (x, y))
                x += tile_size
            y += tile_size