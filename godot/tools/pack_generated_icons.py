"""Pack chroma-key-cleaned generated art into exact game atlas cells."""
from pathlib import Path
from PIL import Image
import numpy as np
import sys


def pack(source_path: Path, destination_path: Path, columns: int, cell_size: int, padding: int, flip_cell: int = -1) -> None:
    source = Image.open(source_path).convert("RGBA")
    result = Image.new("RGBA", (columns * cell_size, cell_size))
    source_cell_width = source.width / columns
    alpha = np.asarray(source.getchannel("A"))
    occupied = (alpha > 20).sum(axis=0) > 5
    starts = np.flatnonzero(occupied & ~np.r_[False, occupied[:-1]])
    ends = np.flatnonzero(occupied & ~np.r_[occupied[1:], False]) + 1
    runs = list(zip(starts.tolist(), ends.tolist()))
    for index in range(columns):
        left, right = runs[index] if len(runs) == columns else (round(index * source_cell_width), round((index + 1) * source_cell_width))
        frame = source.crop((left, 0, right, source.height))
        box = frame.getchannel("A").getbbox()
        if box is None:
            raise ValueError(f"Empty generated cell {index} in {source_path}")
        frame = frame.crop(box)
        maximum = cell_size - padding * 2
        scale = min(maximum / frame.width, maximum / frame.height)
        frame = frame.resize((round(frame.width * scale), round(frame.height * scale)), Image.Resampling.LANCZOS)
        if index == flip_cell:
            frame = frame.transpose(Image.Transpose.FLIP_LEFT_RIGHT)
        x = index * cell_size + (cell_size - frame.width) // 2
        y = (cell_size - frame.height) // 2
        result.alpha_composite(frame, (x, y))
    result.save(destination_path, optimize=True)


if __name__ == "__main__":
    pack(Path(sys.argv[1]), Path(sys.argv[2]), int(sys.argv[3]), int(sys.argv[4]), int(sys.argv[5]), int(sys.argv[6]) if len(sys.argv) > 6 else -1)
